-module(erl_data_shift_env_tests).
-include_lib("eunit/include/eunit.hrl").

parses_key_value_pairs_test() ->
    Path = "/tmp/erl_data_shift_test.env",
    ok = file:write_file(Path, <<"PG_HOST=localhost\nPG_PORT=5432\n# comment\n\nPG_USER=admin\n">>),
    {ok, Env} = erl_data_shift_env:load(Path),
    ?assertEqual(<<"localhost">>, erl_data_shift_env:get(<<"PG_HOST">>, Env)),
    ?assertEqual(<<"5432">>, erl_data_shift_env:get(<<"PG_PORT">>, Env)),
    ?assertEqual(<<"admin">>, erl_data_shift_env:get(<<"PG_USER">>, Env)),
    file:delete(Path).

missing_key_returns_undefined_test() ->
    ?assertEqual(undefined, erl_data_shift_env:get(<<"NOPE">>, #{})).

missing_file_returns_error_test() ->
    ?assertMatch({error, enoent}, erl_data_shift_env:load("/tmp/does_not_exist.env")).