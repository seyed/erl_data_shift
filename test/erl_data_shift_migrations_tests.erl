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

%% -- extract_version/1 --

extract_version_from_filename_test() ->
    ?assertEqual("0001", erl_data_shift_migrations:extract_version("0001_init.sql")).

extract_version_from_plain_string_test() ->
    ?assertEqual("001", erl_data_shift_migrations:extract_version("001")).

extract_version_no_digits_returns_original_test() ->
    ?assertEqual("readme", erl_data_shift_migrations:extract_version("readme")).

%% -- read_file/1 --

read_file_happy_path_test() ->
    Path = "/tmp/eds_migration_read_test.sql",
    ok = file:write_file(Path, <<"CREATE TABLE t(id int);">>),
    Result = erl_data_shift_migrations:read_file(Path),
    ?assertEqual({ok, "CREATE TABLE t(id int);"}, Result),
    file:delete(Path).

read_file_missing_file_test() ->
    Result = erl_data_shift_migrations:read_file("/tmp/eds_definitely_missing.sql"),
    ?assertMatch({error, enoent}, Result).

%% -- down_file_for/1 --

down_file_for_derives_correct_name_test() ->
    ?assertEqual("0001_init.down.sql", erl_data_shift_migrations:down_file_for("0001_init.sql")).

%% -- has_down_file/2 --

has_down_file_true_test() ->
    Dir = "/tmp/eds_down_file_test",
    filelib:ensure_dir(Dir ++ "/"),
    ok = file:write_file(filename:join(Dir, "0001_init.down.sql"), <<"DROP TABLE a;">>),
    ?assert(erl_data_shift_migrations:has_down_file(Dir, "0001_init.sql")),
    file:del_dir_r(Dir).

has_down_file_false_test() ->
    Dir = "/tmp/eds_down_file_missing_test",
    filelib:ensure_dir(Dir ++ "/"),
    ?assertNot(erl_data_shift_migrations:has_down_file(Dir, "0001_init.sql")),
    file:del_dir_r(Dir).

%% -- list_sql_files/1 excludes down files (regression test) --

list_sql_files_excludes_down_files_test() ->
    Dir = "/tmp/eds_migrations_down_exclusion_test",
    ok = filelib:ensure_dir(Dir ++ "/"),
    ok = file:write_file(filename:join(Dir, "0001_init.sql"), <<"-- sql">>),
    ok = file:write_file(filename:join(Dir, "0001_init.down.sql"), <<"-- sql">>),

    {ok, Files} = erl_data_shift_migrations:list_sql_files(Dir),

    ?assertEqual(["0001_init.sql"], Files),
    file:del_dir_r(Dir).

%% -- compute_checksum/1 --

compute_checksum_is_deterministic_test() ->
    Sql = "CREATE TABLE a(id int);",
    ?assertEqual(erl_data_shift_migrations:compute_checksum(Sql),
                 erl_data_shift_migrations:compute_checksum(Sql)).

compute_checksum_differs_for_different_input_test() ->
    C1 = erl_data_shift_migrations:compute_checksum("CREATE TABLE a(id int);"),
    C2 = erl_data_shift_migrations:compute_checksum("CREATE TABLE b(id int);"),
    ?assertNotEqual(C1, C2).

compute_checksum_accepts_binary_and_list_identically_test() ->
    Sql = "CREATE TABLE a(id int);",
    ?assertEqual(erl_data_shift_migrations:compute_checksum(Sql),
                 erl_data_shift_migrations:compute_checksum(list_to_binary(Sql))).

compute_checksum_returns_64_char_hex_string_test() ->
    Checksum = erl_data_shift_migrations:compute_checksum("test"),
    ?assertEqual(64, length(Checksum)),
    ?assert(lists:all(fun(C) -> lists:member(C, "0123456789abcdef") end, Checksum)).