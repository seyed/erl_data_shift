-module(erl_data_shift_migrator_tests).
-include_lib("eunit/include/eunit.hrl").

setup() ->
    Dir = "/tmp/eds_migrator_test",
    filelib:ensure_dir(Dir ++ "/"),
    file:write_file(filename:join(Dir, "0001_init.sql"), <<"CREATE TABLE a(id int);">>),
    file:write_file(filename:join(Dir, "0002_add_b.sql"), <<"CREATE TABLE b(id int);">>),
    Dir.

teardown(Dir) ->
    file:del_dir_r(Dir).

%% Runs all pending migrations, calling ProgressFun once per file, in order,
%% and applying each via erl_data_shift_db.
run_applies_all_pending_in_order_test() ->
    Dir = setup(),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, with_connection, fun(_Env, Fun) -> Fun(fake_conn) end),
    meck:expect(erl_data_shift_db, ensure_migrations_table, fun(_Conn) -> ok end),
    meck:expect(erl_data_shift_db, get_applied_versions, fun(_Conn) -> {ok, []} end),
    meck:expect(erl_data_shift_db, apply_migration, fun(_Conn, _Version, _Sql) -> ok end),

    Self = self(),
    ProgressFun = fun(Idx, Total, File) -> Self ! {progress, Idx, Total, File} end,
    Result = erl_data_shift_migrator:run(#{}, Dir, ProgressFun),

    ?assertEqual({ok, 2}, Result),
    Msg1 = receive {progress, 1, 2, "0001_init.sql"} -> ok after 1000 -> timeout end,
    ?assertEqual(ok, Msg1),
    Msg2 = receive {progress, 2, 2, "0002_add_b.sql"} -> ok after 1000 -> timeout end,
    ?assertEqual(ok, Msg2),

    meck:unload(erl_data_shift_db),
    teardown(Dir).

%% Already-applied versions are skipped entirely.
run_skips_already_applied_test() ->
    Dir = setup(),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, with_connection, fun(_Env, Fun) -> Fun(fake_conn) end),
    meck:expect(erl_data_shift_db, ensure_migrations_table, fun(_Conn) -> ok end),
    meck:expect(erl_data_shift_db, get_applied_versions, fun(_Conn) -> {ok, ["0001"]} end),
    meck:expect(erl_data_shift_db, apply_migration, fun(_Conn, _Version, _Sql) -> ok end),

    Result = erl_data_shift_migrator:run(#{}, Dir, fun(_, _, _) -> ok end),

    ?assertEqual({ok, 1}, Result),
    ?assertEqual(1, meck:num_calls(erl_data_shift_db, apply_migration, '_')),
    meck:unload(erl_data_shift_db),
    teardown(Dir).

%% Nothing pending -> {ok, 0}, no apply_migration calls at all.
run_no_pending_migrations_test() ->
    Dir = setup(),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, with_connection, fun(_Env, Fun) -> Fun(fake_conn) end),
    meck:expect(erl_data_shift_db, ensure_migrations_table, fun(_Conn) -> ok end),
    meck:expect(erl_data_shift_db, get_applied_versions, fun(_Conn) -> {ok, ["0001", "0002"]} end),
    meck:expect(erl_data_shift_db, apply_migration, fun(_Conn, _Version, _Sql) -> ok end),

    Result = erl_data_shift_migrator:run(#{}, Dir, fun(_, _, _) -> ok end),

    ?assertEqual({ok, 0}, Result),
    ?assertEqual(0, meck:num_calls(erl_data_shift_db, apply_migration, '_')),
    meck:unload(erl_data_shift_db),
    teardown(Dir).

%% A failing migration stops the run and reports which file failed; earlier
%% ones in the batch were already committed independently (per-file transactions).
run_stops_on_first_failure_test() ->
    Dir = setup(),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, with_connection, fun(_Env, Fun) -> Fun(fake_conn) end),
    meck:expect(erl_data_shift_db, ensure_migrations_table, fun(_Conn) -> ok end),
    meck:expect(erl_data_shift_db, get_applied_versions, fun(_Conn) -> {ok, []} end),
    meck:expect(erl_data_shift_db, apply_migration, fun(_Conn, "0001", _Sql) -> ok;
                                                        (_Conn, "0002", _Sql) -> {error, syntax_error}
                                                     end),

    Result = erl_data_shift_migrator:run(#{}, Dir, fun(_, _, _) -> ok end),

    ?assertMatch({error, {migration_failed, "0002_add_b.sql", syntax_error}}, Result),
    meck:unload(erl_data_shift_db),
    teardown(Dir).

%% Missing migrations directory is a graceful error, not a crash.
run_missing_directory_test() ->
    Result = erl_data_shift_migrator:run(#{}, "/tmp/eds_no_such_migrations_dir", fun(_, _, _) -> ok end),
    ?assertMatch({error, {directory_not_found, _}}, Result).

%% ensure_migrations_table failure short-circuits before touching files.
run_ensure_table_failure_test() ->
    Dir = setup(),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, with_connection, fun(_Env, Fun) -> Fun(fake_conn) end),
    meck:expect(erl_data_shift_db, ensure_migrations_table, fun(_Conn) -> {error, ddl_error} end),

    Result = erl_data_shift_migrator:run(#{}, Dir, fun(_, _, _) -> ok end),

    ?assertEqual({error, ddl_error}, Result),
    meck:unload(erl_data_shift_db),
    teardown(Dir).

%% -- rollback_last/2 --

rollback_setup() ->
    Dir = "/tmp/eds_migrator_rollback_test",
    filelib:ensure_dir(Dir ++ "/"),
    file:write_file(filename:join(Dir, "0001_init.sql"), <<"CREATE TABLE a(id int);">>),
    file:write_file(filename:join(Dir, "0001_init.down.sql"), <<"DROP TABLE a;">>),
    Dir.

rollback_teardown(Dir) ->
    file:del_dir_r(Dir).

rollback_last_success_test() ->
    Dir = rollback_setup(),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, with_connection, fun(_Env, Fun) -> Fun(fake_conn) end),
    meck:expect(erl_data_shift_db, get_last_applied_version, fun(_Conn) -> {ok, "0001"} end),
    meck:expect(erl_data_shift_db, revert_migration, fun(_Conn, "0001", _Sql) -> ok end),

    Result = erl_data_shift_migrator:rollback_last(#{}, Dir),

    ?assertEqual({ok, "0001"}, Result),
    meck:unload(erl_data_shift_db),
    rollback_teardown(Dir).

rollback_last_no_applied_migrations_test() ->
    Dir = rollback_setup(),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, with_connection, fun(_Env, Fun) -> Fun(fake_conn) end),
    meck:expect(erl_data_shift_db, get_last_applied_version, fun(_Conn) -> {ok, none} end),

    Result = erl_data_shift_migrator:rollback_last(#{}, Dir),

    ?assertEqual({error, no_applied_migrations}, Result),
    meck:unload(erl_data_shift_db),
    rollback_teardown(Dir).

rollback_last_missing_down_file_test() ->
    Dir = "/tmp/eds_migrator_rollback_no_down_test",
    filelib:ensure_dir(Dir ++ "/"),
    file:write_file(filename:join(Dir, "0001_init.sql"), <<"CREATE TABLE a(id int);">>),
    %% no matching .down.sql written

    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, with_connection, fun(_Env, Fun) -> Fun(fake_conn) end),
    meck:expect(erl_data_shift_db, get_last_applied_version, fun(_Conn) -> {ok, "0001"} end),

    Result = erl_data_shift_migrator:rollback_last(#{}, Dir),

    ?assertMatch({error, {down_file_missing, "0001_init.down.sql"}}, Result),
    meck:unload(erl_data_shift_db),
    rollback_teardown(Dir).

rollback_last_up_file_missing_locally_test() ->
    Dir = "/tmp/eds_migrator_rollback_no_up_test",
    filelib:ensure_dir(Dir ++ "/"),
    %% DB says version 0099 was applied, but no local file matches it

    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, with_connection, fun(_Env, Fun) -> Fun(fake_conn) end),
    meck:expect(erl_data_shift_db, get_last_applied_version, fun(_Conn) -> {ok, "0099"} end),

    Result = erl_data_shift_migrator:rollback_last(#{}, Dir),

    ?assertMatch({error, {up_file_missing, "0099"}}, Result),
    meck:unload(erl_data_shift_db),
    rollback_teardown(Dir).

rollback_last_revert_failure_test() ->
    Dir = rollback_setup(),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, with_connection, fun(_Env, Fun) -> Fun(fake_conn) end),
    meck:expect(erl_data_shift_db, get_last_applied_version, fun(_Conn) -> {ok, "0001"} end),
    meck:expect(erl_data_shift_db, revert_migration, fun(_Conn, "0001", _Sql) -> {error, fk_violation} end),

    Result = erl_data_shift_migrator:rollback_last(#{}, Dir),

    ?assertMatch({error, {rollback_failed, "0001_init.sql", fk_violation}}, Result),
    meck:unload(erl_data_shift_db),
    rollback_teardown(Dir).

rollback_last_missing_directory_test() ->
    Result = erl_data_shift_migrator:rollback_last(#{}, "/tmp/eds_no_such_rollback_dir"),
    ?assertMatch({error, {directory_not_found, _}}, Result).

%% -- run/3 acquires and releases the lock --

run_acquires_and_releases_lock_test() ->
    Dir = setup(),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, with_connection, fun(_Env, Fun) -> Fun(fake_conn) end),
    meck:expect(erl_data_shift_db, acquire_migration_lock, fun(_Conn) -> ok end),
    meck:expect(erl_data_shift_db, release_migration_lock, fun(_Conn) -> ok end),
    meck:expect(erl_data_shift_db, ensure_migrations_table, fun(_Conn) -> ok end),
    meck:expect(erl_data_shift_db, get_applied_versions, fun(_Conn) -> {ok, []} end),
    meck:expect(erl_data_shift_db, apply_migration, fun(_Conn, _Version, _Sql) -> ok end),

    Result = erl_data_shift_migrator:run(#{}, Dir, fun(_, _, _) -> ok end),

    ?assertEqual({ok, 2}, Result),
    ?assertEqual(1, meck:num_calls(erl_data_shift_db, acquire_migration_lock, '_')),
    ?assertEqual(1, meck:num_calls(erl_data_shift_db, release_migration_lock, '_')),
    meck:unload(erl_data_shift_db),
    teardown(Dir).

%% Lock already held -> clean error, no migrations attempted.
run_fails_cleanly_when_locked_test() ->
    Dir = setup(),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, with_connection, fun(_Env, Fun) -> Fun(fake_conn) end),
    meck:expect(erl_data_shift_db, acquire_migration_lock, fun(_Conn) -> {error, migration_locked} end),

    Result = erl_data_shift_migrator:run(#{}, Dir, fun(_, _, _) -> ok end),

    ?assertEqual({error, migration_locked}, Result),
    ?assertEqual(0, meck:num_calls(erl_data_shift_db, ensure_migrations_table, '_')),
    meck:unload(erl_data_shift_db),
    teardown(Dir).

%% Lock is released even if a migration fails mid-run.
run_releases_lock_even_on_failure_test() ->
    Dir = setup(),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, with_connection, fun(_Env, Fun) -> Fun(fake_conn) end),
    meck:expect(erl_data_shift_db, acquire_migration_lock, fun(_Conn) -> ok end),
    meck:expect(erl_data_shift_db, release_migration_lock, fun(_Conn) -> ok end),
    meck:expect(erl_data_shift_db, ensure_migrations_table, fun(_Conn) -> ok end),
    meck:expect(erl_data_shift_db, get_applied_versions, fun(_Conn) -> {ok, []} end),
    meck:expect(erl_data_shift_db, apply_migration, fun(_Conn, _Version, _Sql) -> {error, boom} end),

    Result = erl_data_shift_migrator:run(#{}, Dir, fun(_, _, _) -> ok end),

    ?assertMatch({error, {migration_failed, _, boom}}, Result),
    ?assertEqual(1, meck:num_calls(erl_data_shift_db, release_migration_lock, '_')),
    meck:unload(erl_data_shift_db),
    teardown(Dir).

%% rollback_last/2 also acquires/releases the lock.
rollback_last_acquires_and_releases_lock_test() ->
    Dir = rollback_setup(),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, with_connection, fun(_Env, Fun) -> Fun(fake_conn) end),
    meck:expect(erl_data_shift_db, acquire_migration_lock, fun(_Conn) -> ok end),
    meck:expect(erl_data_shift_db, release_migration_lock, fun(_Conn) -> ok end),
    meck:expect(erl_data_shift_db, get_last_applied_version, fun(_Conn) -> {ok, "0001"} end),
    meck:expect(erl_data_shift_db, revert_migration, fun(_Conn, "0001", _Sql) -> ok end),

    Result = erl_data_shift_migrator:rollback_last(#{}, Dir),

    ?assertEqual({ok, "0001"}, Result),
    ?assertEqual(1, meck:num_calls(erl_data_shift_db, acquire_migration_lock, '_')),
    ?assertEqual(1, meck:num_calls(erl_data_shift_db, release_migration_lock, '_')),
    meck:unload(erl_data_shift_db),
    rollback_teardown(Dir).

%% -- dry_run/2 --

dry_run_lists_pending_without_applying_test() ->
    Dir = setup(),
    meck:new(erl_data_shift_db, [non_strict]),
    meck:expect(erl_data_shift_db, with_connection, fun(_Env, Fun) -> Fun(fake_conn) end),
    meck:expect(erl_data_shift_db, ensure_migrations_table, fun(_Conn) -> ok end),
    meck:expect(erl_data_shift_db, get_applied_versions, fun(_Conn) -> {ok, ["0001"]} end),

    Result = erl_data_shift_migrator:dry_run(#{}, Dir),

    ?assertEqual({ok, ["0002_add_b.sql"]}, Result),
    ?assertEqual(0, meck:num_calls(erl_data_shift_db, apply_migration, '_')),
    meck:unload(erl_data_shift_db),
    teardown(Dir).

dry_run_missing_directory_test() ->
    Result = erl_data_shift_migrator:dry_run(#{}, "/tmp/eds_no_such_dry_run_dir"),
    ?assertMatch({error, {directory_not_found, _}}, Result).