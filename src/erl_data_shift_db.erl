-module(erl_data_shift_db).
-export([check_connection/1, get_table_stats/1]).

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

%% -- internal --

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
    case epgsql:squery(Conn, Sql) of
        {ok, _Cols, Rows} ->
            {ok, [#{name => Name, rows => sanitize_null(RowCount), size_bytes => sanitize_null(SizeBytes)}
                  || {Name, RowCount, SizeBytes} <- Rows]};
        {error, Reason} ->
            {error, Reason}
    end.

%% SQL NULL (e.g. an unanalyzed table's n_live_tup) comes back as the atom
%% 'null' from epgsql — coerce it to 0 so downstream arithmetic doesn't crash.
sanitize_null(null) -> 0;
sanitize_null(Value) -> Value.