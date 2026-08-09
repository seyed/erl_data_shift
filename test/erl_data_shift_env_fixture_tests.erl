-module(erl_data_shift_env_fixture_tests).
-include_lib("eunit/include/eunit.hrl").

-define(SAMPLE_ENV, "test/samples/.env.example").

%% Happy path: fixture file exists and parses expected keys.
loads_sample_fixture_test() ->
    {ok, Env} = erl_data_shift_env:load(?SAMPLE_ENV),
    ?assertEqual(<<"localhost">>, erl_data_shift_env:get(<<"PG_HOST">>, Env)),
    ?assertEqual(<<"5432">>, erl_data_shift_env:get(<<"PG_PORT">>, Env)),
    ?assertEqual(<<"postgres">>, erl_data_shift_env:get(<<"PG_USER">>, Env)),
    ?assertEqual(<<"postgres">>, erl_data_shift_env:get(<<"PG_PASSWORD">>, Env)),
    ?assertEqual(<<"erl_data_shift">>, erl_data_shift_env:get(<<"PG_DATABASE">>, Env)).

%% Happy path: a key absent from the fixture returns undefined, not a crash.
missing_key_in_fixture_returns_undefined_test() ->
    {ok, Env} = erl_data_shift_env:load(?SAMPLE_ENV),
    ?assertEqual(undefined, erl_data_shift_env:get(<<"PG_SSLMODE">>, Env)).

%% Sad path: pointing at a non-existent file returns {error, enoent}.
load_nonexistent_file_test() ->
    ?assertMatch({error, enoent}, erl_data_shift_env:load("test/samples/does_not_exist.env")).

%% Sad path: an empty/malformed file yields an empty map, not a crash.
load_malformed_file_test() ->
    Path = "/tmp/erl_data_shift_malformed_test.env",
    ok = file:write_file(Path, <<"NOT_A_VALID_LINE_NO_EQUALS\n\n# comment only\n">>),
    {ok, Env} = erl_data_shift_env:load(Path),
    ?assertEqual(#{}, Env),
    file:delete(Path).