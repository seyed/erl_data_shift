-module(erl_data_shift_app_tests).
-include_lib("eunit/include/eunit.hrl").

%% Placeholder coverage: confirms erl_data_shift_app satisfies the `application`
%% behaviour contract. TODO: Replace/expand once real business logic lands.
exports_required_callbacks_test() ->
    Exports = erl_data_shift_app:module_info(exports),
    ?assert(lists:member({start, 2}, Exports)),
    ?assert(lists:member({stop, 1}, Exports)).

stop_returns_ok_test() ->
    ?assertEqual(ok, erl_data_shift_app:stop(unused_state)).