-module(erl_data_shift_migrations_tests).
-include_lib("eunit/include/eunit.hrl").

%% -- resolve_dir/1 --

resolve_dir_uses_f_flag_test() ->
    {Dir, Rest} = erl_data_shift_migrations:resolve_dir(["-f", "/tmp/custom_migrations"]),
    ?assertEqual("/tmp/custom_migrations", Dir),
    ?assertEqual([], Rest).

resolve_dir_uses_path_flag_test() ->
    {Dir, Rest} = erl_data_shift_migrations:resolve_dir(["--path", "/tmp/custom_migrations", "extra"]),
    ?assertEqual("/tmp/custom_migrations", Dir),
    ?assertEqual(["extra"], Rest).

resolve_dir_defaults_when_no_flag_test() ->
    {Dir, Rest} = erl_data_shift_migrations:resolve_dir([]),
    ?assertEqual(filename:join(erl_data_shift_env:get_original_cwd(), "migrations"), Dir),
    ?assertEqual([], Rest).

%% -- list_sql_files/1 --

list_sql_files_happy_path_test() ->
    Dir = "/tmp/eds_migrations_test",
    ok = filelib:ensure_dir(Dir ++ "/"),
    ok = file:write_file(filename:join(Dir, "0001_init.sql"), <<"-- sql">>),
    ok = file:write_file(filename:join(Dir, "0002_add_users.sql"), <<"-- sql">>),
    ok = file:write_file(filename:join(Dir, "readme.txt"), <<"not sql">>),

    {ok, Files} = erl_data_shift_migrations:list_sql_files(Dir),

    ?assertEqual(["0001_init.sql", "0002_add_users.sql"], Files),
    file:del_dir_r(Dir).

list_sql_files_missing_dir_returns_error_test() ->
    Result = erl_data_shift_migrations:list_sql_files("/tmp/eds_definitely_does_not_exist"),
    ?assertMatch({error, {directory_not_found, _}}, Result).