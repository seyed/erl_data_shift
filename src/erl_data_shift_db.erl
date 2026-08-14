-module(erl_data_shift_db).
-export([check_connection/1, get_table_stats/1, get_migration_history/1,
         with_connection/2, ensure_migrations_table/1, get_applied_versions/1,
         apply_migration/3]).

-define(REQUIRED_KEYS, [<<"PG_HOST">>, <<"PG_PORT">>, <<"PG_USER">>, <<"PG_PASSWORD">>, <<"PG_DATABASE">>]).

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

%% Creates the schema_migrations tracking table if it doesn't already exist.
%% Safe to call every run (idempotent via IF NOT EXISTS).
-spec ensure_migrations_table(epgsql:connection()) -> ok | {error, term()}.
ensure_migrations_table(Conn) ->
    Sql = "CREATE TABLE IF NOT EXISTS schema_migrations ("
          "id SERIAL PRIMARY KEY, "
          "version TEXT NOT NULL UNIQUE, "
          "applied_at TIMESTAMPTZ NOT NULL DEFAULT now())",
    case epgsql:squery(Conn, Sql) of
        {error, Reason} -> {error, Reason};
        _ -> ok
    end.

%% Returns the list of already-applied migration versions (as strings).
-spec get_applied_versions(epgsql:connection()) -> {ok, [string()]} | {error, term()}.
get_applied_versions(Conn) ->
    case epgsql:equery(Conn, "SELECT version FROM schema_migrations", []) of
        {ok, _Cols, Rows} -> {ok, [binary_to_list(V) || {V} <- Rows]};
        {error, Reason} -> {error, Reason}
    end.

%% Runs Sql and records Version in schema_migrations, both inside a single
%% transaction — either both succeed or neither does (rollback on failure).
-spec apply_migration(epgsql:connection(), string(), string()) -> ok | {error, term()}.
apply_migration(Conn, Version, Sql) ->
    {ok, [], []} = epgsql:squery(Conn, "BEGIN"),
    case classify(epgsql:squery(Conn, Sql)) of
        ok ->
            case epgsql:equery(Conn, "INSERT INTO schema_migrations (version) VALUES ($1)", [Version]) of
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

with_params(Env, Fun) ->
    Missing = [K || K <- ?REQUIRED_KEYS, erl_data_shift_env:get(K, Env) =:= undefined],
    case Missing of
        [] -> parse_params(Env, Fun);
        _  -> {error, {missing_config, Missing}}
    end.

parse_params(Env, Fun) ->
    Host = binary_to_list(erl_data_shift_env:get(<<"PG_HOST">>, Env)),
    PortStr = binary_to_list(erl_data_shift_env:get(<<"PG_PORT">>, Env)),
    User = binary_to_list(erl_data_shift_env:get(<<"PG_USER">>, Env)),
    Pass = binary_to_list(erl_data_shift_env:get(<<"PG_PASSWORD">>, Env)),
    Db   = binary_to_list(erl_data_shift_env:get(<<"PG_DATABASE">>, Env)),
    case string:to_integer(PortStr) of
        {Port, ""} -> Fun(#{host => Host, port => Port, username => User,
                             password => Pass, database => Db, timeout => 5000});
        _ -> {error, {invalid_port, PortStr}}
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