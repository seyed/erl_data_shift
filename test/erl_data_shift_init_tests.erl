-module(erl_data_shift_init_tests).
-include_lib("eunit/include/eunit.hrl").

setup_dir() ->
    Dir = "/tmp/eds_init_test_" ++ integer_to_list(erlang:unique_integer([positive])),
    filelib:ensure_dir(Dir ++ "/"),
    Dir.

teardown(Dir) -> file:del_dir_r(Dir).

%% Fresh directory: both migrations/ and .env.example get created.
run_creates_both_when_missing_test() ->
    Dir = setup_dir(),
    Result = erl_data_shift_init:run(Dir),
    ?assertMatch({ok, #{created := ["migrations/", ".env.example"], skipped := []}}, Result),
    ?assert(filelib:is_dir(filename:join(Dir, "migrations"))),
    ?assert(filelib:is_regular(filename:join(Dir, ".env.example"))),
    teardown(Dir).

%% Running twice is idempotent: second run skips both, doesn't error or overwrite.
run_is_idempotent_test() ->
    Dir = setup_dir(),
    {ok, _} = erl_data_shift_init:run(Dir),
    Result = erl_data_shift_init:run(Dir),
    ?assertMatch({ok, #{created := [], skipped := ["migrations/", ".env.example"]}}, Result),
    teardown(Dir).

%% Existing .env.example content is never overwritten.
run_does_not_overwrite_existing_env_example_test() ->
    Dir = setup_dir(),
    EnvPath = filename:join(Dir, ".env.example"),
    ok = file:write_file(EnvPath, <<"PG_HOST=my_custom_value\n">>),

    {ok, _} = erl_data_shift_init:run(Dir),

    {ok, Content} = file:read_file(EnvPath),
    ?assertEqual(<<"PG_HOST=my_custom_value\n">>, Content),
    teardown(Dir).

%% Existing migrations/ dir (with files in it) is left alone.
run_does_not_touch_existing_migrations_dir_test() ->
    Dir = setup_dir(),
    MigrationsDir = filename:join(Dir, "migrations"),
    ok = filelib:ensure_dir(MigrationsDir ++ "/"),
    ok = file:write_file(filename:join(MigrationsDir, "0001_init.sql"), <<"-- existing">>),

    {ok, Result} = erl_data_shift_init:run(Dir),

    ?assertEqual(["migrations/"], maps:get(skipped, Result) -- [".env.example"]),
    ?assert(filelib:is_regular(filename:join(MigrationsDir, "0001_init.sql"))),
    teardown(Dir).