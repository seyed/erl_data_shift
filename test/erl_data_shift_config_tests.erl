-module(erl_data_shift_config_tests).
-include_lib("eunit/include/eunit.hrl").

setup_dir() ->
    Dir = "/tmp/eds_config_test_" ++ integer_to_list(erlang:unique_integer([positive])),
    filelib:ensure_dir(Dir ++ "/"),
    Dir.

teardown(Dir) -> file:del_dir_r(Dir).

%% -- load/0 --

load_missing_file_returns_error_test() ->
    Dir = setup_dir(),
    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, get_original_cwd, fun() -> Dir end),

    Result = erl_data_shift_config:load(),

    ?assertMatch({error, enoent}, Result),
    meck:unload(erl_data_shift_env),
    teardown(Dir).

load_valid_config_test() ->
    Dir = setup_dir(),
    ok = file:write_file(filename:join(Dir, "eds.config"),
        <<"[{migrations_dir, \"custom_migrations\"}].">>),
    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, get_original_cwd, fun() -> Dir end),

    Result = erl_data_shift_config:load(),

    ?assertEqual({ok, [{migrations_dir, "custom_migrations"}]}, Result),
    meck:unload(erl_data_shift_env),
    teardown(Dir).

%% A config file that doesn't contain a single top-level list (e.g. two
%% separate terms, or a non-list term) is rejected with a clear error
%% rather than silently misbehaving.
load_malformed_config_not_a_single_list_test() ->
    Dir = setup_dir(),
    ok = file:write_file(filename:join(Dir, "eds.config"), <<"{migrations_dir, \"x\"}.">>),
    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, get_original_cwd, fun() -> Dir end),

    Result = erl_data_shift_config:load(),

    ?assertMatch({error, {invalid_config_format, _}}, Result),
    meck:unload(erl_data_shift_env),
    teardown(Dir).

%% Invalid Erlang term syntax surfaces file:consult's own error reason.
load_invalid_syntax_test() ->
    Dir = setup_dir(),
    ok = file:write_file(filename:join(Dir, "eds.config"), <<"this is not valid erlang">>),
    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, get_original_cwd, fun() -> Dir end),

    Result = erl_data_shift_config:load(),

    ?assertMatch({error, _}, Result),
    meck:unload(erl_data_shift_env),
    teardown(Dir).

%% -- get/3 --

get_returns_value_when_present_test() ->
    Config = [{migrations_dir, "custom"}],
    ?assertEqual("custom", erl_data_shift_config:get(migrations_dir, Config, "default")).

get_returns_default_when_absent_test() ->
    Config = [{migrations_dir, "custom"}],
    ?assertEqual("default", erl_data_shift_config:get(other_key, Config, "default")).

get_returns_default_for_empty_config_test() ->
    ?assertEqual("default", erl_data_shift_config:get(migrations_dir, [], "default")).
