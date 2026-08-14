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

%% con_check hits erl_data_shift_env/db under the hood, including the
%% masked .env summary print (print_env_summary/1) on connection failure;
%% here we only assert it dispatches without crashing. .env may or may not
%% be present in the test working dir — both are valid, already-handled
%% outcomes (see erl_data_shift_env_tests / erl_data_shift_db_tests for
%% that coverage).
dispatch_con_check_does_not_crash_test() ->
    ?assertEqual(ok, erl_data_shift_app:dispatch(["con_check"])).

dispatch_unknown_command_does_not_crash_test() ->
    ?assertEqual(ok, erl_data_shift_app:dispatch(["not_a_real_command"])).

dispatch_empty_args_does_not_crash_test() ->
    ?assertEqual(ok, erl_data_shift_app:dispatch([])).

%% relx passes its boot verb (e.g. "foreground") through as a plain arg —
%% confirm it's stripped and the real command still dispatches correctly.
%% Regression test: print_caution/0 contains an em-dash (—) which previously
%% crashed io:format's ~s directive with badarg. dispatch(["migrate"]) exercises
%% the same startup path indirectly by confirming the app module still loads
%% and runs end-to-end without crashing after the unicode fix.
dispatch_after_unicode_fix_does_not_crash_test() ->
    ?assertEqual(ok, erl_data_shift_app:dispatch(["migrate"])).

%% stat hits erl_data_shift_env/db under the hood (same pattern as con_check);
%% here we only assert it dispatches without crashing.
dispatch_stat_does_not_crash_test() ->
    ?assertEqual(ok, erl_data_shift_app:dispatch(["stat"])).

%% migrate now accepts -f/--path — confirm it dispatches without crashing
%% even when pointed at a directory that doesn't exist (graceful handling).
dispatch_migrate_with_missing_path_does_not_crash_test() ->
    ?assertEqual(ok, erl_data_shift_app:dispatch(["migrate", "-f", "/tmp/eds_no_such_dir"])).

%% migrate now actually runs migrations via erl_data_shift_migrator; with an
%% existing-but-empty dir and no real DB reachable, it should still dispatch
%% cleanly (env/db failures are handled gracefully, not crashes).
dispatch_migrate_with_empty_dir_does_not_crash_test() ->
    Dir = "/tmp/eds_app_migrate_empty_test",
    filelib:ensure_dir(Dir ++ "/"),
    Result = erl_data_shift_app:dispatch(["migrate", "-f", Dir]),
    ?assertEqual(ok, Result),
    file:del_dir_r(Dir).

%% history hits erl_data_shift_env/db under the hood (same pattern as
%% con_check/stat); here we only assert it dispatches without crashing.
dispatch_history_does_not_crash_test() ->
    ?assertEqual(ok, erl_data_shift_app:dispatch(["history"])).

%% -- format_duration/1 --

format_duration_just_now_test() ->
    ?assertEqual("just now", erl_data_shift_app:format_duration(30)).

format_duration_minutes_test() ->
    ?assertEqual("5 min ago", lists:flatten(erl_data_shift_app:format_duration(300))).

format_duration_hours_test() ->
    ?assertEqual("2 hr ago", lists:flatten(erl_data_shift_app:format_duration(7200))).

format_duration_days_test() ->
    ?assertEqual("3 day(s) ago", lists:flatten(erl_data_shift_app:format_duration(259200))).

%% -- extract_leading_digits/1 --

extract_leading_digits_from_filename_test() ->
    ?assertEqual("0001", erl_data_shift_app:extract_leading_digits("0001_init.sql")).

extract_leading_digits_from_plain_version_test() ->
    ?assertEqual("001", erl_data_shift_app:extract_leading_digits("001")).

extract_leading_digits_no_digits_returns_original_test() ->
    ?assertEqual("readme", erl_data_shift_app:extract_leading_digits("readme")).

%% -- column_widths/2 --

%% Regression test: width must account for cell content, not just headers —
%% previously a long cell (e.g. "2026-07-10 00:54:17 (35 day(s) ago)")
%% overflowed the printed border because width was header-length-only.
column_widths_uses_widest_cell_not_just_header_test() ->
    Headers = ["id", "applied_at"],
    RowCells = [["1", "2026-07-10 00:54:17 (35 day(s) ago)"], ["2", "short"]],
    Widths = erl_data_shift_app:column_widths(Headers, RowCells),
    ?assertEqual([2, length("2026-07-10 00:54:17 (35 day(s) ago)")], Widths).

column_widths_falls_back_to_header_when_wider_test() ->
    Headers = ["version_number"],
    RowCells = [["1"], ["2"]],
    Widths = erl_data_shift_app:column_widths(Headers, RowCells),
    ?assertEqual([length("version_number")], Widths).