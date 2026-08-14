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