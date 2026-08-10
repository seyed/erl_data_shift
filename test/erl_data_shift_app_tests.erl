-module(erl_data_shift_app_tests).
-include_lib("eunit/include/eunit.hrl").

%% Confirms erl_data_shift_app satisfies the `application` behaviour contract.
exports_required_callbacks_test() ->
    Exports = erl_data_shift_app:module_info(exports),
    ?assert(lists:member({start, 2}, Exports)),
    ?assert(lists:member({stop, 1}, Exports)).

stop_returns_ok_test() ->
    ?assertEqual(ok, erl_data_shift_app:stop(unused_state)).

%% "migrate" is currently a placeholder — just confirm it dispatches without
%% crashing. Real assertions land once migration logic is implemented.
dispatch_migrate_does_not_crash_test() ->
    ?assertEqual(ok, erl_data_shift_app:dispatch(["migrate"])).

%% con_check hits erl_data_shift_env/db under the hood; here we only assert
%% it dispatches without crashing. .env may or may not be present in the
%% test working dir — both are valid, already-handled outcomes (see
%% erl_data_shift_env_tests / erl_data_shift_db_tests for that coverage).
dispatch_con_check_does_not_crash_test() ->
    ?assertEqual(ok, erl_data_shift_app:dispatch(["con_check"])).

dispatch_unknown_command_does_not_crash_test() ->
    ?assertEqual(ok, erl_data_shift_app:dispatch(["not_a_real_command"])).

dispatch_empty_args_does_not_crash_test() ->
    ?assertEqual(ok, erl_data_shift_app:dispatch([])).