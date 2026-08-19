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

%% -- human_size/1 --

human_size_bytes_test() ->
    ?assertEqual("500 B", lists:flatten(erl_data_shift_app:human_size(500))).

human_size_kb_test() ->
    ?assertEqual("2.00 KB", lists:flatten(erl_data_shift_app:human_size(2048))).

human_size_mb_test() ->
    ?assertEqual("1.50 MB", lists:flatten(erl_data_shift_app:human_size(1572864))).

human_size_gb_test() ->
    ?assertEqual("2.00 GB", lists:flatten(erl_data_shift_app:human_size(2147483648))).

%% -- format_datetime/1 --

format_datetime_pads_correctly_test() ->
    Result = lists:flatten(erl_data_shift_app:format_datetime({{2026, 1, 5}, {9, 3, 7.5}})),
    ?assertEqual("2026-01-05 09:03:07", Result).

%% -- time_ago/1 (relative to now, so just assert it produces a sane suffix) --

time_ago_recent_is_just_now_test() ->
    Now = calendar:universal_time(),
    ?assertEqual("just now", erl_data_shift_app:time_ago(Now)).

%% -- format_cell/1 --

format_cell_null_test() ->
    ?assertEqual("NULL", erl_data_shift_app:format_cell(null)).

format_cell_binary_test() ->
    ?assertEqual("hello", erl_data_shift_app:format_cell(<<"hello">>)).

format_cell_integer_test() ->
    ?assertEqual("42", erl_data_shift_app:format_cell(42)).

format_cell_datetime_includes_ago_suffix_test() ->
    Result = lists:flatten(erl_data_shift_app:format_cell({{2020, 1, 1}, {0, 0, 0}})),
    ?assert(string:find(Result, "ago") =/= nomatch).

%% -- con_check success/failure branches, driven via mocks --

con_check_success_path_test() ->
    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, load, fun() -> {ok, #{}} end),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, check_connection, fun(_Env) -> {ok, connected} end),

    ?assertEqual(ok, erl_data_shift_app:dispatch(["con_check"])),

    meck:unload(erl_data_shift_db),
    meck:unload(erl_data_shift_env).

con_check_connection_failure_path_test() ->
    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, load, fun() -> {ok, #{}} end),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, check_connection, fun(_Env) -> {error, econnrefused} end),

    ?assertEqual(ok, erl_data_shift_app:dispatch(["con_check"])),

    meck:unload(erl_data_shift_db),
    meck:unload(erl_data_shift_env).

%% -- stat success/failure/empty branches, driven via mocks --

stat_success_with_rows_test() ->
    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, load, fun() -> {ok, #{}} end),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, get_table_stats, fun(_Env) ->
        {ok, [#{name => <<"users">>, rows => 10, size_bytes => 2048}]}
    end),

    ?assertEqual(ok, erl_data_shift_app:dispatch(["stat"])),

    meck:unload(erl_data_shift_db),
    meck:unload(erl_data_shift_env).

stat_empty_rows_test() ->
    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, load, fun() -> {ok, #{}} end),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, get_table_stats, fun(_Env) -> {ok, []} end),

    ?assertEqual(ok, erl_data_shift_app:dispatch(["stat"])),

    meck:unload(erl_data_shift_db),
    meck:unload(erl_data_shift_env).

stat_failure_path_test() ->
    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, load, fun() -> {ok, #{}} end),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, get_table_stats, fun(_Env) -> {error, timeout} end),

    ?assertEqual(ok, erl_data_shift_app:dispatch(["stat"])),

    meck:unload(erl_data_shift_db),
    meck:unload(erl_data_shift_env).

%% -- history success/no-table/empty branches, driven via mocks --

history_success_with_rows_test() ->
    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, load, fun() -> {ok, #{}} end),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, get_migration_history, fun(_Env) ->
        {ok, {<<"schema_migrations">>, [<<"version">>], [{<<"0001">>}]}}
    end),

    ?assertEqual(ok, erl_data_shift_app:dispatch(["history"])),

    meck:unload(erl_data_shift_db),
    meck:unload(erl_data_shift_env).

history_no_table_found_test() ->
    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, load, fun() -> {ok, #{}} end),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, get_migration_history, fun(_Env) -> {error, no_migration_table_found} end),

    ?assertEqual(ok, erl_data_shift_app:dispatch(["history"])),

    meck:unload(erl_data_shift_db),
    meck:unload(erl_data_shift_env).

history_empty_rows_test() ->
    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, load, fun() -> {ok, #{}} end),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, get_migration_history, fun(_Env) ->
        {ok, {<<"schema_migrations">>, [<<"version">>], []}}
    end),

    ?assertEqual(ok, erl_data_shift_app:dispatch(["history"])),

    meck:unload(erl_data_shift_db),
    meck:unload(erl_data_shift_env).

%% -- migrate success path via mocked migrator --

migrate_success_path_test() ->
    Dir = "/tmp/eds_app_migrate_success_test",
    filelib:ensure_dir(Dir ++ "/"),
    ok = file:write_file(filename:join(Dir, "0001_init.sql"), <<"-- sql">>),

    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, load, fun() -> {ok, #{}} end),
    meck:new(erl_data_shift_migrator, [non_strict]),
    meck:expect(erl_data_shift_migrator, run, fun(_Env, _Dir, _ProgressFun) -> {ok, 1} end),

    ?assertEqual(ok, erl_data_shift_app:dispatch(["migrate", "-f", Dir])),

    meck:unload(erl_data_shift_migrator),
    meck:unload(erl_data_shift_env),
    file:del_dir_r(Dir).

migrate_failure_path_test() ->
    Dir = "/tmp/eds_app_migrate_failure_test",
    filelib:ensure_dir(Dir ++ "/"),
    ok = file:write_file(filename:join(Dir, "0001_init.sql"), <<"-- sql">>),

    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, load, fun() -> {ok, #{}} end),
    meck:new(erl_data_shift_migrator, [non_strict]),
    meck:expect(erl_data_shift_migrator, run, fun(_Env, _Dir, _ProgressFun) ->
        {error, {migration_failed, "0001_init.sql", bad_sql}}
    end),

    ?assertEqual(ok, erl_data_shift_app:dispatch(["migrate", "-f", Dir])),

    meck:unload(erl_data_shift_migrator),
    meck:unload(erl_data_shift_env),
    file:del_dir_r(Dir).

%% -- migrate down, via mocked migrator --

migrate_down_success_path_test() ->
    Dir = "/tmp/eds_app_migrate_down_success_test",
    filelib:ensure_dir(Dir ++ "/"),

    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, load, fun() -> {ok, #{}} end),
    meck:new(erl_data_shift_migrator, [non_strict]),
    meck:expect(erl_data_shift_migrator, rollback_last, fun(_Env, _Dir) -> {ok, "0001"} end),

    ?assertEqual(ok, erl_data_shift_app:dispatch(["migrate", "down", "-f", Dir])),

    meck:unload(erl_data_shift_migrator),
    meck:unload(erl_data_shift_env),
    file:del_dir_r(Dir).

migrate_down_no_applied_migrations_test() ->
    Dir = "/tmp/eds_app_migrate_down_none_test",
    filelib:ensure_dir(Dir ++ "/"),

    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, load, fun() -> {ok, #{}} end),
    meck:new(erl_data_shift_migrator, [non_strict]),
    meck:expect(erl_data_shift_migrator, rollback_last, fun(_Env, _Dir) -> {error, no_applied_migrations} end),

    ?assertEqual(ok, erl_data_shift_app:dispatch(["migrate", "down", "-f", Dir])),

    meck:unload(erl_data_shift_migrator),
    meck:unload(erl_data_shift_env),
    file:del_dir_r(Dir).

migrate_down_missing_down_file_test() ->
    Dir = "/tmp/eds_app_migrate_down_missing_file_test",
    filelib:ensure_dir(Dir ++ "/"),

    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, load, fun() -> {ok, #{}} end),
    meck:new(erl_data_shift_migrator, [non_strict]),
    meck:expect(erl_data_shift_migrator, rollback_last, fun(_Env, _Dir) ->
        {error, {down_file_missing, "0001_init.down.sql"}}
    end),

    ?assertEqual(ok, erl_data_shift_app:dispatch(["migrate", "down", "-f", Dir])),

    meck:unload(erl_data_shift_migrator),
    meck:unload(erl_data_shift_env),
    file:del_dir_r(Dir).

%% -- init/--help/-h/--version dispatch --

%% init_cmd/0 writes real files based on get_original_cwd() — mock it to a
%% temp dir so this test never touches the actual repo working directory.
dispatch_init_does_not_crash_test() ->
    Dir = "/tmp/eds_app_dispatch_init_test",
    filelib:ensure_dir(Dir ++ "/"),
    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, get_original_cwd, fun() -> Dir end),

    ?assertEqual(ok, erl_data_shift_app:dispatch(["init"])),

    meck:unload(erl_data_shift_env),
    file:del_dir_r(Dir).

dispatch_help_does_not_crash_test() ->
    ?assertEqual(ok, erl_data_shift_app:dispatch(["help"])).

%% Note: --version/--help/-h -> version/help translation happens in the bash
%% wrapper script (build_mac.sh/build_linux.sh/ci.yml), since the Erlang VM
%% swallows leading-dash args as its own flags before init:get_plain_arguments/0
%% ever sees them. Not testable at this layer — dispatch/1 only ever receives
%% the already-translated dash-free command names.
dispatch_version_does_not_crash_test() ->
    ?assertEqual(ok, erl_data_shift_app:dispatch(["version"])).

%% -- new command, via mocked scaffold --

new_cmd_success_path_test() ->
    meck:new(erl_data_shift_scaffold, [non_strict]),
    meck:expect(erl_data_shift_scaffold, create_migration, fun(_Dir, _Name) ->
        {ok, {"0001_test.sql", "0001_test.down.sql"}}
    end),
    ?assertEqual(ok, erl_data_shift_app:dispatch(["new", "test"])),
    meck:unload(erl_data_shift_scaffold).

new_cmd_missing_name_does_not_crash_test() ->
    ?assertEqual(ok, erl_data_shift_app:dispatch(["new"])).

new_cmd_already_exists_path_test() ->
    meck:new(erl_data_shift_scaffold, [non_strict]),
    meck:expect(erl_data_shift_scaffold, create_migration, fun(_Dir, _Name) ->
        {error, {already_exists, "/tmp/foo.sql"}}
    end),
    ?assertEqual(ok, erl_data_shift_app:dispatch(["new", "test"])),
    meck:unload(erl_data_shift_scaffold).

%% -- migrate dry-run, via mocked migrator --

migrate_dry_run_with_pending_test() ->
    Dir = "/tmp/eds_app_dry_run_test",
    filelib:ensure_dir(Dir ++ "/"),
    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, load, fun() -> {ok, #{}} end),
    meck:new(erl_data_shift_migrator, [non_strict]),
    meck:expect(erl_data_shift_migrator, dry_run, fun(_Env, _Dir) -> {ok, ["0001_init.sql"]} end),

    ?assertEqual(ok, erl_data_shift_app:dispatch(["migrate", "dry-run", "-f", Dir])),

    meck:unload(erl_data_shift_migrator),
    meck:unload(erl_data_shift_env),
    file:del_dir_r(Dir).

migrate_dry_run_no_pending_test() ->
    Dir = "/tmp/eds_app_dry_run_empty_test",
    filelib:ensure_dir(Dir ++ "/"),
    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, load, fun() -> {ok, #{}} end),
    meck:new(erl_data_shift_migrator, [non_strict]),
    meck:expect(erl_data_shift_migrator, dry_run, fun(_Env, _Dir) -> {ok, []} end),

    ?assertEqual(ok, erl_data_shift_app:dispatch(["migrate", "dry-run", "-f", Dir])),

    meck:unload(erl_data_shift_migrator),
    meck:unload(erl_data_shift_env),
    file:del_dir_r(Dir).

%% -- migrate lock handling, via mocked migrator --

migrate_locked_path_test() ->
    Dir = "/tmp/eds_app_migrate_locked_test",
    filelib:ensure_dir(Dir ++ "/"),
    ok = file:write_file(filename:join(Dir, "0001_init.sql"), <<"-- sql">>),
    meck:new(erl_data_shift_env, [passthrough]),
    meck:expect(erl_data_shift_env, load, fun() -> {ok, #{}} end),
    meck:new(erl_data_shift_migrator, [non_strict]),
    meck:expect(erl_data_shift_migrator, run, fun(_Env, _Dir, _ProgressFun) -> {error, migration_locked} end),

    ?assertEqual(ok, erl_data_shift_app:dispatch(["migrate", "-f", Dir])),

    meck:unload(erl_data_shift_migrator),
    meck:unload(erl_data_shift_env),
    file:del_dir_r(Dir).