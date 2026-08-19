-module(erl_data_shift_db).
-export([check_connection/1, get_table_stats/1, get_migration_history/1,
         with_connection/2, ensure_migrations_table/1, get_applied_versions/1,
         apply_migration/3, get_last_applied_version/1, revert_migration/3,
         acquire_migration_lock/1, release_migration_lock/1]).

-define(REQUIRED_KEYS, [<<"PG_HOST">>, <<"PG_PORT">>, <<"PG_USER">>, <<"PG_PASSWORD">>, <<"PG_DATABASE">>]).

%% Fixed advisory-lock key shared by every eds instance targeting the same
%% DB, so concurrent `migrate`/`migrate down` runs serialize instead of
%% racing each other. Arbitrary but stable — never change this value.
-define(MIGRATION_LOCK_KEY, 727625172).

%% Attempts a Postgres connection using PG_* keys from the given env map.
%% Returns {ok, connected} or {error, Reason}.
-spec check_connection(map()) -> {ok, connected} | {error, term()}.
check_connection(Env) ->
    with_params(Env, fun(Params) -> run_isolated(fun(_Conn) -> {ok, connected} end, Params) end).

%% Fetches table name, estimated row count, and total size (table + indexes)
%% for all tables in the 'public' schema, ordered largest first.
-spec get_table_stats(map()) -> {ok, [map()]} | {error, term()}.
get_table_stats(Env) ->
    with_params(Env, fun(Params) -> run_isolated(fun query_stats/1, Params) end).

%% Fetches rows from whichever known migration-tracker table exists
%% (schema_migrations, flyway_schema_history, ecto_schema_migrations,
%% alembic_version), reading columns dynamically so it works regardless of
%% which tool created it. Returns {ok, {TableName, ColumnNames, Rows}}.
-define(MIGRATION_TABLE_CANDIDATES,
    [<<"schema_migrations">>, <<"flyway_schema_history">>,
     <<"ecto_schema_migrations">>, <<"alembic_version">>]).

-spec get_migration_history(map()) -> {ok, {binary(), [binary()], [tuple()]}} | {error, term()}.
get_migration_history(Env) ->
    with_params(Env, fun(Params) -> run_isolated(fun query_history/1, Params) end).

%% Opens a connection (crash-isolated, same as the other functions here) and
%% runs Fun(Conn) against it, closing it afterward. For callers that need to
%% run multiple queries in sequence on the same connection (e.g. the migrator).
-spec with_connection(map(), fun((epgsql:connection()) -> term())) -> term() | {error, term()}.
with_connection(Env, Fun) ->
    with_params(Env, fun(Params) -> run_isolated(Fun, Params) end).

%% Creates the schema_migrations tracking table if missing, and adds
%% applied_by/reverted_at columns via ALTER TABLE IF NOT EXISTS so existing
%% installs from before this feature get upgraded in place, idempotently.
-spec ensure_migrations_table(epgsql:connection()) -> ok | {error, term()}.
ensure_migrations_table(Conn) ->
    Statements = [
        "CREATE TABLE IF NOT EXISTS schema_migrations ("
        "id SERIAL PRIMARY KEY, "
        "version TEXT NOT NULL UNIQUE, "
        "applied_at TIMESTAMPTZ NOT NULL DEFAULT now())",
        "ALTER TABLE schema_migrations ADD COLUMN IF NOT EXISTS applied_by TEXT",
        "ALTER TABLE schema_migrations ADD COLUMN IF NOT EXISTS reverted_at TIMESTAMPTZ"
    ],
    run_statements(Conn, Statements).

run_statements(_Conn, []) -> ok;
run_statements(Conn, [Sql | Rest]) ->
    case epgsql:squery(Conn, Sql) of
        {error, Reason} -> {error, Reason};
        _ -> run_statements(Conn, Rest)
    end.

%% Returns the list of currently-applied (i.e. not reverted) migration
%% versions, as strings.
-spec get_applied_versions(epgsql:connection()) -> {ok, [string()]} | {error, term()}.
get_applied_versions(Conn) ->
    Sql = "SELECT version FROM schema_migrations WHERE reverted_at IS NULL",
    case epgsql:equery(Conn, Sql, []) of
        {ok, _Cols, Rows} -> {ok, [binary_to_list(V) || {V} <- Rows]};
        {error, Reason} -> {error, Reason}
    end.

%% Runs Sql and records Version + the OS user running eds in
%% schema_migrations, both inside a single transaction.
-spec apply_migration(epgsql:connection(), string(), string()) -> ok | {error, term()}.
apply_migration(Conn, Version, Sql) ->
    {ok, [], []} = epgsql:squery(Conn, "BEGIN"),
    case classify(epgsql:squery(Conn, Sql)) of
        ok ->
            InsertSql = "INSERT INTO schema_migrations (version, applied_by) VALUES ($1, $2)",
            case epgsql:equery(Conn, InsertSql, [Version, current_user()]) of
                {ok, _} ->
                    epgsql:squery(Conn, "COMMIT"),
                    ok;
                {error, Reason} ->
                    epgsql:squery(Conn, "ROLLBACK"),
                    {error, Reason}
            end;
        {error, Reason} ->
            epgsql:squery(Conn, "ROLLBACK"),
            {error, Reason}
    end.

%% epgsql:squery on multi-statement SQL returns a list of per-statement
%% results — treat any {error, _} among them as a failure.
classify(Results) when is_list(Results) ->
    case lists:keyfind(error, 1, Results) of
        false -> ok;
        {error, Reason} -> {error, Reason}
    end;
classify({error, Reason}) -> {error, Reason};
classify(_Other) -> ok.

%% Best-effort identification of who ran eds — the OS user, not the DB user
%% (which is usually a shared service account, not useful for an audit trail).
current_user() ->
    case os:getenv("USER") of
        false ->
            case os:getenv("USERNAME") of
                false -> "unknown";
                U -> U
            end;
        U -> U
    end.

%% Returns the most recently applied (not reverted) migration's version, or
%% {ok, none} if nothing is currently applied.
-spec get_last_applied_version(epgsql:connection()) -> {ok, string() | none} | {error, term()}.
get_last_applied_version(Conn) ->
    Sql = "SELECT version FROM schema_migrations WHERE reverted_at IS NULL ORDER BY id DESC LIMIT 1",
    case epgsql:equery(Conn, Sql, []) of
        {ok, _Cols, [{Version}]} -> {ok, binary_to_list(Version)};
        {ok, _Cols, []} -> {ok, none};
        {error, Reason} -> {error, Reason}
    end.

%% Runs DownSql and marks Version as reverted (reverted_at = now()) rather
%% than deleting its row, so the audit trail in `eds history` still shows it
%% was applied and later reverted. Guards against reverting an
%% already-reverted or nonexistent version (0 rows affected -> error).
-spec revert_migration(epgsql:connection(), string(), string()) -> ok | {error, term()}.
revert_migration(Conn, Version, DownSql) ->
    {ok, [], []} = epgsql:squery(Conn, "BEGIN"),
    case classify(epgsql:squery(Conn, DownSql)) of
        ok ->
            UpdateSql = "UPDATE schema_migrations SET reverted_at = now() "
                        "WHERE version = $1 AND reverted_at IS NULL",
            case epgsql:equery(Conn, UpdateSql, [Version]) of
                {ok, 1} ->
                    epgsql:squery(Conn, "COMMIT"),
                    ok;
                {ok, 0} ->
                    epgsql:squery(Conn, "ROLLBACK"),
                    {error, already_reverted_or_missing};
                {error, Reason} ->
                    epgsql:squery(Conn, "ROLLBACK"),
                    {error, Reason}
            end;
        {error, Reason} ->
            epgsql:squery(Conn, "ROLLBACK"),
            {error, Reason}
    end.

%% Tries to acquire a Postgres advisory lock so only one eds process can run
%% migrate/migrate-down against this DB at a time. Non-blocking: returns
%% {error, migration_locked} immediately if another process holds it.
-spec acquire_migration_lock(epgsql:connection()) -> ok | {error, term()}.
acquire_migration_lock(Conn) ->
    case epgsql:equery(Conn, "SELECT pg_try_advisory_lock($1)", [?MIGRATION_LOCK_KEY]) of
        {ok, _Cols, [{true}]} -> ok;
        {ok, _Cols, [{false}]} -> {error, migration_locked};
        {error, Reason} -> {error, Reason}
    end.

%% Releases the advisory lock. Best-effort — the lock also auto-releases
%% when the connection closes, so a failed unlock here isn't fatal.
-spec release_migration_lock(epgsql:connection()) -> ok.
release_migration_lock(Conn) ->
    epgsql:equery(Conn, "SELECT pg_advisory_unlock($1)", [?MIGRATION_LOCK_KEY]),
    ok.

with_params(Env, Fun) ->
    Missing = [K || K <- ?REQUIRED_KEYS, erl_data_shift_env:get(K, Env) =:= undefined],
    case Missing of
        [] -> parse_params(Env, Fun);
        _  -> {error, {missing_config, Missing}}
    end.

-define(VALID_SSLMODES, [<<"disable">>, <<"require">>, <<"verify-ca">>, <<"verify-full">>]).

parse_params(Env, Fun) ->
    Host = binary_to_list(erl_data_shift_env:get(<<"PG_HOST">>, Env)),
    PortStr = binary_to_list(erl_data_shift_env:get(<<"PG_PORT">>, Env)),
    User = binary_to_list(erl_data_shift_env:get(<<"PG_USER">>, Env)),
    Pass = binary_to_list(erl_data_shift_env:get(<<"PG_PASSWORD">>, Env)),
    Db   = binary_to_list(erl_data_shift_env:get(<<"PG_DATABASE">>, Env)),
    SslMode = case erl_data_shift_env:get(<<"PG_SSLMODE">>, Env) of
        undefined -> <<"disable">>;
        V -> V
    end,
    case {string:to_integer(PortStr), validate_sslmode(SslMode)} of
        {{Port, ""}, {ok, UseSsl}} ->
            Fun(#{host => Host, port => Port, username => User,
                  password => Pass, database => Db, timeout => 5000,
                  ssl => UseSsl});
        {{_, _}, {error, _}} ->
            {error, {invalid_sslmode, SslMode}};
        {_, _} ->
            {error, {invalid_port, PortStr}}
    end.

%% PG_SSLMODE must be one of Postgres's own sslmode values. "disable" means
%% plaintext; anything else in the allow-list enables TLS. Unrecognized
%% values are rejected outright rather than silently guessing intent.
validate_sslmode(<<"disable">>) -> {ok, false};
validate_sslmode(Mode) ->
    case lists:member(Mode, ?VALID_SSLMODES) of
        true -> {ok, true};
        false -> {error, invalid}
    end.

%% Runs Fun(Conn) against a fresh connection, isolated in a monitored process
%% so any epgsql crash (e.g. econnrefused) yields a clean {error, _} instead
%% of killing the caller. Connection is always closed afterward.
run_isolated(Fun, ConnOpts) ->
    {Pid, Ref} = spawn_monitor(fun() ->
        case epgsql:connect(ConnOpts) of
            {ok, Conn} ->
                Result = Fun(Conn),
                epgsql:close(Conn),
                exit({eds_result, Result});
            {error, Reason} ->
                exit({eds_result, {error, Reason}})
        end
    end),
    receive
        {'DOWN', Ref, process, Pid, {eds_result, Result}} -> Result;
        {'DOWN', Ref, process, Pid, Reason} -> {error, Reason}
    after 6000 ->
        {error, timeout}
    end.

query_stats(Conn) ->
    Sql = "SELECT relname, n_live_tup, pg_total_relation_size(relid) "
          "FROM pg_stat_user_tables ORDER BY pg_total_relation_size(relid) DESC",
    case epgsql:equery(Conn, Sql, []) of
        {ok, _Cols, Rows} ->
            {ok, [#{name => Name, rows => sanitize_null(RowCount), size_bytes => sanitize_null(SizeBytes)}
                  || {Name, RowCount, SizeBytes} <- Rows]};
        {error, Reason} ->
            {error, Reason}
    end.

%% SQL NULL (e.g. an unanalyzed table's n_live_tup) comes back as the atom
%% 'null' from epgsql — sanitize it to 0 so downstream arithmetic doesn't crash.
sanitize_null(null) -> 0;
sanitize_null(Value) -> Value.

query_history(Conn) ->
    case find_migration_table(Conn) of
        {ok, Table} ->
            TableStr = binary_to_list(Table),
            Sql = "SELECT * FROM " ++ TableStr ++ " ORDER BY 1",
            case epgsql:equery(Conn, Sql, []) of
                {ok, Cols, Rows} ->
                    ColNames = [element(2, C) || C <- Cols], %% #column.name is field 2
                    {ok, {Table, ColNames, Rows}};
                {error, Reason} ->
                    {error, Reason}
            end;
        none ->
            {error, no_migration_table_found};
        {error, Reason} ->
            {error, Reason}
    end.

%% Checks information_schema for the first known migration-tracker table
%% name that actually exists (any schema on the search path, not just
%% 'public' — some tools create it elsewhere).
find_migration_table(Conn) ->
    Sql = "SELECT table_name FROM information_schema.tables "
          "WHERE table_name = ANY($1::text[]) "
          "ORDER BY array_position($1::text[], table_name) LIMIT 1",
    case epgsql:equery(Conn, Sql, [?MIGRATION_TABLE_CANDIDATES]) of
        {ok, _Cols, [{Name}]} -> {ok, Name};
        {ok, _Cols, []} -> none;
        {error, Reason} -> {error, Reason}
    end.