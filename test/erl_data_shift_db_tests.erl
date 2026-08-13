-module(erl_data_shift_db_tests).
-include_lib("eunit/include/eunit.hrl").

sample_env() ->
    #{
        <<"PG_HOST">> => <<"localhost">>,
        <<"PG_PORT">> => <<"5432">>,
        <<"PG_USER">> => <<"admin">>,
        <<"PG_PASSWORD">> => <<"secret">>,
        <<"PG_DATABASE">> => <<"mydb">>
    }.

check_connection_success_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> {ok, fake_conn} end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),

    Result = erl_data_shift_db:check_connection(sample_env()),

    ?assertEqual({ok, connected}, Result),
    meck:unload(epgsql).

check_connection_failure_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> {error, econnrefused} end),

    Result = erl_data_shift_db:check_connection(sample_env()),

    ?assertEqual({error, econnrefused}, Result),
    meck:unload(epgsql).

%% Sad path: missing required keys short-circuits before ever touching epgsql.
check_connection_missing_config_test() ->
    IncompleteEnv = #{<<"PG_HOST">> => <<"localhost">>},
    Result = erl_data_shift_db:check_connection(IncompleteEnv),
    ?assertMatch({error, {missing_config, _}}, Result).

%% Sad path: non-numeric PG_PORT (e.g. leftover "change-me" placeholder)
%% fails cleanly instead of crashing list_to_integer.
check_connection_invalid_port_test() ->
    BadEnv = maps:put(<<"PG_PORT">>, <<"change-me">>, sample_env()),
    Result = erl_data_shift_db:check_connection(BadEnv),
    ?assertMatch({error, {invalid_port, _}}, Result).

%% epgsql:connect can crash a linked process (e.g. econnrefused) instead of
%% returning {error, Reason} — confirm the spawn_monitor isolation in
%% connect/5 still yields a clean {error, _} instead of killing the caller.
check_connection_survives_epgsql_crash_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> exit(econnrefused) end),

    Result = erl_data_shift_db:check_connection(sample_env()),

    ?assertMatch({error, _}, Result),
    meck:unload(epgsql).

%% -- get_table_stats/1 --

get_table_stats_success_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> {ok, fake_conn} end),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, _Params) ->
        {ok, [col1, col2, col3], [{<<"users">>, 100, 8192}, {<<"orders">>, 50, 4096}]}
    end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),

    Result = erl_data_shift_db:get_table_stats(sample_env()),

    ?assertEqual({ok, [
        #{name => <<"users">>, rows => 100, size_bytes => 8192},
        #{name => <<"orders">>, rows => 50, size_bytes => 4096}
    ]}, Result),
    meck:unload(epgsql).

get_table_stats_query_failure_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> {ok, fake_conn} end),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, _Params) -> {error, some_sql_error} end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),

    Result = erl_data_shift_db:get_table_stats(sample_env()),

    ?assertEqual({error, some_sql_error}, Result),
    meck:unload(epgsql).

get_table_stats_missing_config_test() ->
    Result = erl_data_shift_db:get_table_stats(#{}),
    ?assertMatch({error, {missing_config, _}}, Result).

%% SQL NULL (e.g. n_live_tup on an unanalyzed table) previously crashed
%% downstream size arithmetic with badarith — confirm it's coerced to 0.
get_table_stats_coerces_null_to_zero_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> {ok, fake_conn} end),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, _Params) ->
        {ok, [col1, col2, col3], [{<<"new_table">>, null, null}]}
    end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),

    Result = erl_data_shift_db:get_table_stats(sample_env()),

    ?assertEqual({ok, [#{name => <<"new_table">>, rows => 0, size_bytes => 0}]}, Result),
    meck:unload(epgsql).

%% -- get_migration_history/1 --

get_migration_history_success_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> {ok, fake_conn} end),
    meck:expect(epgsql, equery, fun(_Conn, Sql, _Params) ->
        case string:find(Sql, "information_schema") of
            nomatch ->
                %% the SELECT * FROM schema_migrations query
                {ok, [{column, <<"version">>, int8, 0, 8, -1, 0}], [{20240101000000}, {20240102000000}]};
            _ ->
                %% the table-detection query
                {ok, [{column, <<"table_name">>, text, 0, -1, -1, 0}], [{<<"schema_migrations">>}]}
        end
    end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),

    Result = erl_data_shift_db:get_migration_history(sample_env()),

    ?assertMatch({ok, {<<"schema_migrations">>, [<<"version">>], [{20240101000000}, {20240102000000}]}}, Result),
    meck:unload(epgsql).

get_migration_history_no_table_found_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> {ok, fake_conn} end),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, _Params) ->
        {ok, [{column, <<"table_name">>, text, 0, -1, -1, 0}], []}
    end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),

    Result = erl_data_shift_db:get_migration_history(sample_env()),

    ?assertEqual({error, no_migration_table_found}, Result),
    meck:unload(epgsql).

get_migration_history_missing_config_test() ->
    Result = erl_data_shift_db:get_migration_history(#{}),
    ?assertMatch({error, {missing_config, _}}, Result).

%% A real query error during table detection (e.g. type mismatch) must be
%% surfaced, not silently collapsed into no_migration_table_found.
get_migration_history_detection_query_error_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> {ok, fake_conn} end),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, _Params) -> {error, some_detection_error} end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),

    Result = erl_data_shift_db:get_migration_history(sample_env()),

    ?assertEqual({error, some_detection_error}, Result),
    meck:unload(epgsql).