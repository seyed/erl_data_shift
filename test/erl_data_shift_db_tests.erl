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