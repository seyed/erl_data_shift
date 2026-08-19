-module(erl_data_shift_env_fixture_tests).
-include_lib("eunit/include/eunit.hrl").

%% Happy path: a well-formed env file parses expected keys. Writes its own
%% temp fixture rather than relying on a checked-in sample file (removed —
%% superseded by root .env.example + `eds init`).
loads_env_file_test() ->
    Path = "/tmp/erl_data_shift_fixture_test.env",
    ok = file:write_file(Path,
        <<"PG_HOST=localhost\nPG_PORT=5432\nPG_USER=postgres\n"
          "PG_PASSWORD=postgres\nPG_DATABASE=erl_data_shift\n">>),
    {ok, Env} = erl_data_shift_env:load(Path),
    ?assertEqual(<<"localhost">>, erl_data_shift_env:get(<<"PG_HOST">>, Env)),
    ?assertEqual(<<"5432">>, erl_data_shift_env:get(<<"PG_PORT">>, Env)),
    ?assertEqual(<<"postgres">>, erl_data_shift_env:get(<<"PG_USER">>, Env)),
    ?assertEqual(<<"postgres">>, erl_data_shift_env:get(<<"PG_PASSWORD">>, Env)),
    ?assertEqual(<<"erl_data_shift">>, erl_data_shift_env:get(<<"PG_DATABASE">>, Env)),
    file:delete(Path).

%% Happy path: a key genuinely absent from the file returns undefined, not a crash.
missing_key_returns_undefined_test() ->
    Path = "/tmp/erl_data_shift_fixture_missing_key_test.env",
    ok = file:write_file(Path, <<"PG_HOST=localhost\n">>),
    {ok, Env} = erl_data_shift_env:load(Path),
    ?assertEqual(undefined, erl_data_shift_env:get(<<"PG_SSLMODE">>, Env)),
    file:delete(Path).

%% Sad path: pointing at a non-existent file returns {error, enoent}.
load_nonexistent_file_test() ->
    ?assertMatch({error, enoent}, erl_data_shift_env:load("/tmp/eds_definitely_does_not_exist.env")).

%% Sad path: an empty/malformed file yields an empty map, not a crash.
load_malformed_file_test() ->
    Path = "/tmp/erl_data_shift_malformed_test.env",
    ok = file:write_file(Path, <<"NOT_A_VALID_LINE_NO_EQUALS\n\n# comment only\n">>),
    {ok, Env} = erl_data_shift_env:load(Path),
    ?assertEqual(#{}, Env),
    file:delete(Path).