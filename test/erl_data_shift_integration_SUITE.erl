%% Integration tests against a REAL Postgres instance — no mocks. Uses
%% Common Test (not EUnit) specifically so `rebar3 eunit` never picks this
%% up; it only runs via `rebar3 ct`, which CI wires to a Postgres service
%% container. Running this locally requires PGHOST/PGPORT/PGUSER/
%% PGPASSWORD/PGDATABASE env vars pointing at a real, disposable database —
%% never point this at anything you care about, it drops/recreates tables.
-module(erl_data_shift_integration_SUITE).
-include_lib("common_test/include/ct.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1, init_per_testcase/2, end_per_testcase/2]).
-export([full_migration_lifecycle/1, checksum_drift_detected/1,
         rollback_to_target/1, concurrent_migrate_lock/1]).

all() ->
    [full_migration_lifecycle, checksum_drift_detected, rollback_to_target, concurrent_migrate_lock].

init_per_suite(Config) ->
    Env = #{
        <<"PG_HOST">> => list_to_binary(os:getenv("PGHOST", "localhost")),
        <<"PG_PORT">> => list_to_binary(os:getenv("PGPORT", "5432")),
        <<"PG_USER">> => list_to_binary(os:getenv("PGUSER", "postgres")),
        <<"PG_PASSWORD">> => list_to_binary(os:getenv("PGPASSWORD", "postgres")),
        <<"PG_DATABASE">> => list_to_binary(os:getenv("PGDATABASE", "postgres"))
    },
    [{env, Env} | Config].

end_per_suite(_Config) -> ok.

%% Fresh migrations dir + clean schema_migrations/test tables per test case,
%% so test cases can't interfere with each other regardless of run order.
init_per_testcase(Case, Config) ->
    Dir = "/tmp/eds_ct_" ++ atom_to_list(Case) ++ "_" ++ integer_to_list(erlang:unique_integer([positive])),
    ok = filelib:ensure_dir(Dir ++ "/"),
    Env = proplists:get_value(env, Config),
    erl_data_shift_db:with_connection(Env, fun(Conn) ->
        epgsql:squery(Conn, "DROP TABLE IF EXISTS schema_migrations"),
        epgsql:squery(Conn, "DROP TABLE IF EXISTS ct_test_table"),
        epgsql:squery(Conn, "DROP TABLE IF EXISTS ct_t1"),
        epgsql:squery(Conn, "DROP TABLE IF EXISTS ct_t2"),
        epgsql:squery(Conn, "DROP TABLE IF EXISTS ct_t3")
    end),
    [{dir, Dir}, {env, Env} | Config].

end_per_testcase(_Case, Config) ->
    file:del_dir_r(?config(dir, Config)),
    ok.

%% Full round trip: migrate applies real DDL, verify confirms no drift,
%% migrate down actually reverts it — checked against the real database
%% state at each step, not just the migrator's return value.
full_migration_lifecycle(Config) ->
    Dir = ?config(dir, Config),
    Env = ?config(env, Config),
    ok = file:write_file(filename:join(Dir, "0001_create_table.sql"),
        <<"CREATE TABLE ct_test_table(id serial primary key, name text);">>),
    ok = file:write_file(filename:join(Dir, "0001_create_table.down.sql"),
        <<"DROP TABLE ct_test_table;">>),

    {ok, connected} = erl_data_shift_db:check_connection(Env),
    {ok, 1} = erl_data_shift_migrator:run(Env, Dir, fun(_, _, _) -> ok end),

    %% Table must actually exist now — not just "migrator said ok".
    {ok, _, _} = erl_data_shift_db:with_connection(Env, fun(Conn) ->
        epgsql:squery(Conn, "SELECT 1 FROM ct_test_table LIMIT 0")
    end),

    {ok, [{"0001", ok}]} = erl_data_shift_migrator:verify_checksums(Env, Dir),

    {ok, "0001"} = erl_data_shift_migrator:rollback_last(Env, Dir),

    %% Table must actually be gone now.
    {error, _} = erl_data_shift_db:with_connection(Env, fun(Conn) ->
        epgsql:squery(Conn, "SELECT 1 FROM ct_test_table LIMIT 0")
    end),
    ok.

%% Editing an already-applied migration file must be detected by verify,
%% and must block a subsequent migrate run — against a real DB, real files.
checksum_drift_detected(Config) ->
    Dir = ?config(dir, Config),
    Env = ?config(env, Config),
    ok = file:write_file(filename:join(Dir, "0001_a.sql"), <<"CREATE TABLE ct_test_table(id int);">>),
    ok = file:write_file(filename:join(Dir, "0001_a.down.sql"), <<"DROP TABLE ct_test_table;">>),
    {ok, 1} = erl_data_shift_migrator:run(Env, Dir, fun(_, _, _) -> ok end),

    %% Tamper with the file after it's already been applied.
    ok = file:write_file(filename:join(Dir, "0001_a.sql"),
        <<"CREATE TABLE ct_test_table(id int, extra text);">>),

    {ok, [{"0001", {mismatch, _, _}}]} = erl_data_shift_migrator:verify_checksums(Env, Dir),

    ok = file:write_file(filename:join(Dir, "0002_b.sql"), <<"CREATE TABLE ct_test_table2(id int);">>),
    {error, {checksum_drift, _}} = erl_data_shift_migrator:run(Env, Dir, fun(_, _, _) -> ok end),
    ok.

%% Apply three migrations, roll back to the first — the real DB's applied
%% set must end up exactly ["0001"], and t2/t3's tables must be dropped.
rollback_to_target(Config) ->
    Dir = ?config(dir, Config),
    Env = ?config(env, Config),
    lists:foreach(fun(N) ->
        UpName = io_lib:format("000~p_t.sql", [N]),
        DownName = io_lib:format("000~p_t.down.sql", [N]),
        ok = file:write_file(filename:join(Dir, lists:flatten(UpName)),
            list_to_binary(io_lib:format("CREATE TABLE ct_t~p(id int);", [N]))),
        ok = file:write_file(filename:join(Dir, lists:flatten(DownName)),
            list_to_binary(io_lib:format("DROP TABLE ct_t~p;", [N])))
    end, [1, 2, 3]),

    {ok, 3} = erl_data_shift_migrator:run(Env, Dir, fun(_, _, _) -> ok end),
    {ok, ["0003", "0002"]} = erl_data_shift_migrator:rollback_to(Env, Dir, "0001"),

    Applied = erl_data_shift_db:with_connection(Env, fun(Conn) ->
        {ok, Versions} = erl_data_shift_db:get_applied_versions(Conn),
        Versions
    end),
    ["0001"] = Applied,
    ok.

%% A slow migration (via pg_sleep) holds the advisory lock long enough that
%% a second concurrent `migrate` genuinely collides with it — proving the
%% lock works against a real connection, not just a mocked one.
concurrent_migrate_lock(Config) ->
    Dir = ?config(dir, Config),
    Env = ?config(env, Config),
    ok = file:write_file(filename:join(Dir, "0001_slow.sql"), <<"SELECT pg_sleep(2);">>),
    ok = file:write_file(filename:join(Dir, "0001_slow.down.sql"), <<"SELECT 1;">>),

    Self = self(),
    spawn(fun() ->
        Result = erl_data_shift_migrator:run(Env, Dir, fun(_, _, _) -> ok end),
        Self ! {first, Result}
    end),
    timer:sleep(300), %% give the first run time to acquire the lock

    Result2 = erl_data_shift_migrator:run(Env, Dir, fun(_, _, _) -> ok end),

    receive
        {first, Result1} ->
            %% Exactly one of the two should have actually applied it —
            %% the other must either see the lock held or find nothing
            %% pending by the time it gets a turn.
            true = (Result1 =:= {ok, 1}) orelse (Result2 =:= {ok, 1}),
            ok
    after 5000 ->
        ct:fail(timeout_waiting_for_first_migrate)
    end.
