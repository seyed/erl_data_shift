-module(erl_data_shift_db_tests).
-include_lib("eunit/include/eunit.hrl").

sample_env() ->
    #{
        <<"PG_HOST">> => <<"localhost">>,
        <<"PG_PORT">> => <<"5432">>,
        <<"PG_USER">> => <<"admin">>,
        <<"PG_PASSWORD">> => <<"secret">>,
        <<"PG_DATABASE">> => <<"mydb">>
    }.

check_connection_success_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> {ok, fake_conn} end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),

    Result = erl_data_shift_db:check_connection(sample_env()),

    ?assertEqual({ok, connected}, Result),
    meck:unload(epgsql).

check_connection_failure_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> {error, econnrefused} end),

    Result = erl_data_shift_db:check_connection(sample_env()),

    ?assertEqual({error, econnrefused}, Result),
    meck:unload(epgsql).

%% Sad path: missing required keys short-circuits before ever touching epgsql.
check_connection_missing_config_test() ->
    IncompleteEnv = #{<<"PG_HOST">> => <<"localhost">>},
    Result = erl_data_shift_db:check_connection(IncompleteEnv),
    ?assertMatch({error, {missing_config, _}}, Result).

%% Sad path: non-numeric PG_PORT (e.g. leftover "change-me" placeholder)
%% fails cleanly instead of crashing list_to_integer.
check_connection_invalid_port_test() ->
    BadEnv = maps:put(<<"PG_PORT">>, <<"change-me">>, sample_env()),
    Result = erl_data_shift_db:check_connection(BadEnv),
    ?assertMatch({error, {invalid_port, _}}, Result).

%% epgsql:connect can crash a linked process (e.g. econnrefused) instead of
%% returning {error, Reason} — confirm the spawn_monitor isolation in
%% connect/5 still yields a clean {error, _} instead of killing the caller.
check_connection_survives_epgsql_crash_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> exit(econnrefused) end),

    Result = erl_data_shift_db:check_connection(sample_env()),

    ?assertMatch({error, _}, Result),
    meck:unload(epgsql).

%% -- get_table_stats/1 --

get_table_stats_success_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> {ok, fake_conn} end),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, _Params) ->
        {ok, [col1, col2, col3], [{<<"users">>, 100, 8192}, {<<"orders">>, 50, 4096}]}
    end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),

    Result = erl_data_shift_db:get_table_stats(sample_env()),

    ?assertEqual({ok, [
        #{name => <<"users">>, rows => 100, size_bytes => 8192},
        #{name => <<"orders">>, rows => 50, size_bytes => 4096}
    ]}, Result),
    meck:unload(epgsql).

get_table_stats_query_failure_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> {ok, fake_conn} end),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, _Params) -> {error, some_sql_error} end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),

    Result = erl_data_shift_db:get_table_stats(sample_env()),

    ?assertEqual({error, some_sql_error}, Result),
    meck:unload(epgsql).

get_table_stats_missing_config_test() ->
    Result = erl_data_shift_db:get_table_stats(#{}),
    ?assertMatch({error, {missing_config, _}}, Result).

%% SQL NULL (e.g. n_live_tup on an unanalyzed table) previously crashed
%% downstream size arithmetic with badarith — confirm it's coerced to 0.
get_table_stats_coerces_null_to_zero_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> {ok, fake_conn} end),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, _Params) ->
        {ok, [col1, col2, col3], [{<<"new_table">>, null, null}]}
    end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),

    Result = erl_data_shift_db:get_table_stats(sample_env()),

    ?assertEqual({ok, [#{name => <<"new_table">>, rows => 0, size_bytes => 0}]}, Result),
    meck:unload(epgsql).

%% -- get_migration_history/1 --

get_migration_history_success_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> {ok, fake_conn} end),
    meck:expect(epgsql, equery, fun(_Conn, Sql, _Params) ->
        case string:find(Sql, "information_schema") of
            nomatch ->
                %% the SELECT * FROM schema_migrations query
                {ok, [{column, <<"version">>, int8, 0, 8, -1, 0}], [{20240101000000}, {20240102000000}]};
            _ ->
                %% the table-detection query
                {ok, [{column, <<"table_name">>, text, 0, -1, -1, 0}], [{<<"schema_migrations">>}]}
        end
    end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),

    Result = erl_data_shift_db:get_migration_history(sample_env()),

    ?assertMatch({ok, {<<"schema_migrations">>, [<<"version">>], [{20240101000000}, {20240102000000}]}}, Result),
    meck:unload(epgsql).

get_migration_history_no_table_found_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> {ok, fake_conn} end),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, _Params) ->
        {ok, [{column, <<"table_name">>, text, 0, -1, -1, 0}], []}
    end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),

    Result = erl_data_shift_db:get_migration_history(sample_env()),

    ?assertEqual({error, no_migration_table_found}, Result),
    meck:unload(epgsql).

get_migration_history_missing_config_test() ->
    Result = erl_data_shift_db:get_migration_history(#{}),
    ?assertMatch({error, {missing_config, _}}, Result).

%% A real query error during table detection (e.g. type mismatch) must be
%% surfaced, not silently collapsed into no_migration_table_found.
get_migration_history_detection_query_error_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> {ok, fake_conn} end),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, _Params) -> {error, some_detection_error} end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),

    Result = erl_data_shift_db:get_migration_history(sample_env()),

    ?assertEqual({error, some_detection_error}, Result),
    meck:unload(epgsql).

%% -- ensure_migrations_table/1 (now runs CREATE + 2 ALTER statements) --

ensure_migrations_table_success_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, squery, fun(_Conn, _Sql) -> {ok, [], []} end),
    ?assertEqual(ok, erl_data_shift_db:ensure_migrations_table(fake_conn)),
    ?assertEqual(4, meck:num_calls(epgsql, squery, '_')),
    meck:unload(epgsql).

ensure_migrations_table_failure_on_create_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, squery, fun(_Conn, _Sql) -> {error, some_ddl_error} end),
    ?assertEqual({error, some_ddl_error}, erl_data_shift_db:ensure_migrations_table(fake_conn)),
    meck:unload(epgsql).

%% A failure on a later ALTER statement (e.g. applied_by column) also
%% short-circuits and surfaces the error.
ensure_migrations_table_failure_on_alter_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, squery, fun
        (_Conn, "CREATE TABLE IF NOT EXISTS schema_migrations" ++ _) -> {ok, [], []};
        (_Conn, _Sql) -> {error, alter_failed}
    end),
    ?assertEqual({error, alter_failed}, erl_data_shift_db:ensure_migrations_table(fake_conn)),
    meck:unload(epgsql).

%% -- get_applied_versions/1 (now filters WHERE reverted_at IS NULL) --

get_applied_versions_success_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, equery, fun(_Conn, Sql, []) ->
        ?assert(string:find(Sql, "reverted_at IS NULL") =/= nomatch),
        {ok, [col], [{<<"0001">>}, {<<"0002">>}]}
    end),
    ?assertEqual({ok, ["0001", "0002"]}, erl_data_shift_db:get_applied_versions(fake_conn)),
    meck:unload(epgsql).

get_applied_versions_failure_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, []) -> {error, table_missing} end),
    ?assertEqual({error, table_missing}, erl_data_shift_db:get_applied_versions(fake_conn)),
    meck:unload(epgsql).

%% -- apply_migration/3 (INSERT now includes applied_by) --

apply_migration_success_commits_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, squery, fun
        (_Conn, "BEGIN") -> {ok, [], []};
        (_Conn, "COMMIT") -> {ok, [], []};
        (_Conn, "ROLLBACK") -> {ok, [], []};
        (_Conn, _Sql) -> {ok, [], []} %% the migration's own SQL
    end),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, [_Version, _AppliedBy, _Checksum]) -> {ok, 1} end),

    Result = erl_data_shift_db:apply_migration(fake_conn, "0001", "CREATE TABLE t(id int);"),

    ?assertEqual(ok, Result),
    ?assert(meck:called(epgsql, squery, [fake_conn, "COMMIT"])),
    meck:unload(epgsql).

apply_migration_sql_failure_rolls_back_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, squery, fun
        (_Conn, "BEGIN") -> {ok, [], []};
        (_Conn, "ROLLBACK") -> {ok, [], []};
        (_Conn, _Sql) -> {error, bad_sql}
    end),

    Result = erl_data_shift_db:apply_migration(fake_conn, "0001", "NOT VALID SQL"),

    ?assertEqual({error, bad_sql}, Result),
    ?assert(meck:called(epgsql, squery, [fake_conn, "ROLLBACK"])),
    meck:unload(epgsql).

apply_migration_insert_failure_rolls_back_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, squery, fun
        (_Conn, "BEGIN") -> {ok, [], []};
        (_Conn, "ROLLBACK") -> {ok, [], []};
        (_Conn, _Sql) -> {ok, [], []}
    end),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, [_Version, _AppliedBy, _Checksum]) -> {error, duplicate_version} end),

    Result = erl_data_shift_db:apply_migration(fake_conn, "0001", "CREATE TABLE t(id int);"),

    ?assertEqual({error, duplicate_version}, Result),
    ?assert(meck:called(epgsql, squery, [fake_conn, "ROLLBACK"])),
    meck:unload(epgsql).

%% -- with_connection/2 --

with_connection_runs_fun_and_closes_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(_Opts) -> {ok, fake_conn} end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),

    Result = erl_data_shift_db:with_connection(sample_env(), fun(Conn) -> {ok, Conn} end),

    ?assertEqual({ok, fake_conn}, Result),
    ?assert(meck:called(epgsql, close, [fake_conn])),
    meck:unload(epgsql).

%% -- get_last_applied_version/1 --

get_last_applied_version_success_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, []) -> {ok, [col], [{<<"0003">>}]} end),
    ?assertEqual({ok, "0003"}, erl_data_shift_db:get_last_applied_version(fake_conn)),
    meck:unload(epgsql).

get_last_applied_version_none_applied_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, []) -> {ok, [col], []} end),
    ?assertEqual({ok, none}, erl_data_shift_db:get_last_applied_version(fake_conn)),
    meck:unload(epgsql).

get_last_applied_version_query_error_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, []) -> {error, table_missing} end),
    ?assertEqual({error, table_missing}, erl_data_shift_db:get_last_applied_version(fake_conn)),
    meck:unload(epgsql).

%% -- revert_migration/3 (now UPDATE...reverted_at, not DELETE) --

revert_migration_success_commits_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, squery, fun
        (_Conn, "BEGIN") -> {ok, [], []};
        (_Conn, "COMMIT") -> {ok, [], []};
        (_Conn, "ROLLBACK") -> {ok, [], []};
        (_Conn, _Sql) -> {ok, [], []}
    end),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, [_Version]) -> {ok, 1} end),

    Result = erl_data_shift_db:revert_migration(fake_conn, "0003", "DROP TABLE c;"),

    ?assertEqual(ok, Result),
    ?assert(meck:called(epgsql, squery, [fake_conn, "COMMIT"])),
    meck:unload(epgsql).

revert_migration_sql_failure_rolls_back_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, squery, fun
        (_Conn, "BEGIN") -> {ok, [], []};
        (_Conn, "ROLLBACK") -> {ok, [], []};
        (_Conn, _Sql) -> {error, bad_sql}
    end),

    Result = erl_data_shift_db:revert_migration(fake_conn, "0003", "NOT VALID"),

    ?assertEqual({error, bad_sql}, Result),
    ?assert(meck:called(epgsql, squery, [fake_conn, "ROLLBACK"])),
    meck:unload(epgsql).

revert_migration_update_failure_rolls_back_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, squery, fun
        (_Conn, "BEGIN") -> {ok, [], []};
        (_Conn, "ROLLBACK") -> {ok, [], []};
        (_Conn, _Sql) -> {ok, [], []}
    end),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, [_Version]) -> {error, update_failed} end),

    Result = erl_data_shift_db:revert_migration(fake_conn, "0003", "DROP TABLE c;"),

    ?assertEqual({error, update_failed}, Result),
    ?assert(meck:called(epgsql, squery, [fake_conn, "ROLLBACK"])),
    meck:unload(epgsql).

%% 0 rows affected means the version was already reverted or never applied —
%% must roll back and report a clear error, not silently claim success.
revert_migration_already_reverted_rolls_back_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, squery, fun
        (_Conn, "BEGIN") -> {ok, [], []};
        (_Conn, "ROLLBACK") -> {ok, [], []};
        (_Conn, _Sql) -> {ok, [], []}
    end),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, [_Version]) -> {ok, 0} end),

    Result = erl_data_shift_db:revert_migration(fake_conn, "0003", "DROP TABLE c;"),

    ?assertEqual({error, already_reverted_or_missing}, Result),
    ?assert(meck:called(epgsql, squery, [fake_conn, "ROLLBACK"])),
    meck:unload(epgsql).

%% -- acquire_migration_lock/1 --

acquire_migration_lock_success_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, equery, fun(_Conn, "SELECT pg_try_advisory_lock($1)", _Params) -> {ok, [col], [{true}]} end),
    ?assertEqual(ok, erl_data_shift_db:acquire_migration_lock(fake_conn)),
    meck:unload(epgsql).

acquire_migration_lock_already_held_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, equery, fun(_Conn, "SELECT pg_try_advisory_lock($1)", _Params) -> {ok, [col], [{false}]} end),
    ?assertEqual({error, migration_locked}, erl_data_shift_db:acquire_migration_lock(fake_conn)),
    meck:unload(epgsql).

acquire_migration_lock_query_error_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, equery, fun(_Conn, "SELECT pg_try_advisory_lock($1)", _Params) -> {error, some_error} end),
    ?assertEqual({error, some_error}, erl_data_shift_db:acquire_migration_lock(fake_conn)),
    meck:unload(epgsql).

%% -- release_migration_lock/1 --

release_migration_lock_always_returns_ok_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, equery, fun(_Conn, "SELECT pg_advisory_unlock($1)", _Params) -> {ok, [col], [{true}]} end),
    ?assertEqual(ok, erl_data_shift_db:release_migration_lock(fake_conn)),
    meck:unload(epgsql).

%% -- SSL param handling (via check_connection, asserting the ssl opt passed to epgsql:connect) --

connect_uses_ssl_false_by_default_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(Opts) ->
        ?assertEqual(false, maps:get(ssl, Opts)),
        {ok, fake_conn}
    end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),
    erl_data_shift_db:check_connection(sample_env()),
    meck:unload(epgsql).

connect_uses_ssl_true_when_sslmode_set_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(Opts) ->
        ?assertEqual(true, maps:get(ssl, Opts)),
        {ok, fake_conn}
    end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),
    EnvWithSsl = maps:put(<<"PG_SSLMODE">>, <<"require">>, sample_env()),
    erl_data_shift_db:check_connection(EnvWithSsl),
    meck:unload(epgsql).

connect_uses_ssl_false_when_sslmode_disable_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(Opts) ->
        ?assertEqual(false, maps:get(ssl, Opts)),
        {ok, fake_conn}
    end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),
    EnvWithSsl = maps:put(<<"PG_SSLMODE">>, <<"disable">>, sample_env()),
    erl_data_shift_db:check_connection(EnvWithSsl),
    meck:unload(epgsql).

connect_uses_ssl_true_for_verify_ca_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(Opts) ->
        ?assertEqual(true, maps:get(ssl, Opts)),
        {ok, fake_conn}
    end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),
    EnvWithSsl = maps:put(<<"PG_SSLMODE">>, <<"verify-ca">>, sample_env()),
    erl_data_shift_db:check_connection(EnvWithSsl),
    meck:unload(epgsql).

connect_uses_ssl_true_for_verify_full_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, connect, fun(Opts) ->
        ?assertEqual(true, maps:get(ssl, Opts)),
        {ok, fake_conn}
    end),
    meck:expect(epgsql, close, fun(_Conn) -> ok end),
    EnvWithSsl = maps:put(<<"PG_SSLMODE">>, <<"verify-full">>, sample_env()),
    erl_data_shift_db:check_connection(EnvWithSsl),
    meck:unload(epgsql).

%% Unrecognized sslmode is rejected outright, not silently treated as enable.
connect_rejects_invalid_sslmode_test() ->
    EnvWithBadSsl = maps:put(<<"PG_SSLMODE">>, <<"yolo">>, sample_env()),
    Result = erl_data_shift_db:check_connection(EnvWithBadSsl),
    ?assertEqual({error, {invalid_sslmode, <<"yolo">>}}, Result).

%% -- validate_migration/2 (always rolls back, regardless of outcome) --

validate_migration_success_still_rolls_back_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, squery, fun
        (_Conn, "BEGIN") -> {ok, [], []};
        (_Conn, "ROLLBACK") -> {ok, [], []};
        (_Conn, _Sql) -> {ok, [], []}
    end),

    Result = erl_data_shift_db:validate_migration(fake_conn, "CREATE TABLE t(id int);"),

    ?assertEqual(ok, Result),
    ?assert(meck:called(epgsql, squery, [fake_conn, "ROLLBACK"])),
    ?assertEqual(0, meck:num_calls(epgsql, squery, [fake_conn, "COMMIT"])),
    meck:unload(epgsql).

validate_migration_sql_error_rolls_back_and_reports_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, squery, fun
        (_Conn, "BEGIN") -> {ok, [], []};
        (_Conn, "ROLLBACK") -> {ok, [], []};
        (_Conn, _Sql) -> {error, syntax_error}
    end),

    Result = erl_data_shift_db:validate_migration(fake_conn, "NOT VALID SQL"),

    ?assertEqual({error, syntax_error}, Result),
    ?assert(meck:called(epgsql, squery, [fake_conn, "ROLLBACK"])),
    meck:unload(epgsql).

%% -- get_applied_checksums/1 --

get_applied_checksums_success_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, equery, fun(_Conn, Sql, []) ->
        ?assert(string:find(Sql, "reverted_at IS NULL") =/= nomatch),
        ?assert(string:find(Sql, "checksum IS NOT NULL") =/= nomatch),
        {ok, [col1, col2], [{<<"0001">>, <<"abc123">>}, {<<"0002">>, <<"def456">>}]}
    end),
    Result = erl_data_shift_db:get_applied_checksums(fake_conn),
    ?assertEqual({ok, [{"0001", "abc123"}, {"0002", "def456"}]}, Result),
    meck:unload(epgsql).

get_applied_checksums_empty_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, []) -> {ok, [col1, col2], []} end),
    ?assertEqual({ok, []}, erl_data_shift_db:get_applied_checksums(fake_conn)),
    meck:unload(epgsql).

get_applied_checksums_query_error_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, equery, fun(_Conn, _Sql, []) -> {error, table_missing} end),
    ?assertEqual({error, table_missing}, erl_data_shift_db:get_applied_checksums(fake_conn)),
    meck:unload(epgsql).

%% apply_migration now also stores a checksum of the SQL it just ran.
apply_migration_stores_checksum_test() ->
    meck:new(epgsql, [non_strict]),
    meck:expect(epgsql, squery, fun
        (_Conn, "BEGIN") -> {ok, [], []};
        (_Conn, "COMMIT") -> {ok, [], []};
        (_Conn, "ROLLBACK") -> {ok, [], []};
        (_Conn, _Sql) -> {ok, [], []}
    end),
    Sql = "CREATE TABLE t(id int);",
    ExpectedChecksum = erl_data_shift_migrations:compute_checksum(Sql),
    meck:expect(epgsql, equery, fun(_Conn, _InsertSql, [_Version, _AppliedBy, Checksum]) ->
        ?assertEqual(ExpectedChecksum, Checksum),
        {ok, 1}
    end),

    Result = erl_data_shift_db:apply_migration(fake_conn, "0001", Sql),

    ?assertEqual(ok, Result),
    meck:unload(epgsql).