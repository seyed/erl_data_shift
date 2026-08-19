-module(erl_data_shift_scaffold_tests).
-include_lib("eunit/include/eunit.hrl").

setup_dir() ->
    Dir = "/tmp/eds_scaffold_test_" ++ integer_to_list(erlang:unique_integer([positive])),
    Dir.

teardown(Dir) -> file:del_dir_r(Dir).

%% Fresh (nonexistent) dir: first migration gets version 0001.
create_migration_first_in_empty_dir_test() ->
    Dir = setup_dir(),
    {ok, {UpFile, DownFile}} = erl_data_shift_scaffold:create_migration(Dir, "Add Users Table"),
    ?assertEqual("0001_add_users_table.sql", UpFile),
    ?assertEqual("0001_add_users_table.down.sql", DownFile),
    ?assert(filelib:is_regular(filename:join(Dir, UpFile))),
    ?assert(filelib:is_regular(filename:join(Dir, DownFile))),
    teardown(Dir).

%% Existing migrations: next version increments from the highest.
create_migration_increments_from_existing_test() ->
    Dir = setup_dir(),
    filelib:ensure_dir(Dir ++ "/"),
    file:write_file(filename:join(Dir, "0001_init.sql"), <<"-- sql">>),
    file:write_file(filename:join(Dir, "0007_something.sql"), <<"-- sql">>),

    {ok, {UpFile, _DownFile}} = erl_data_shift_scaffold:create_migration(Dir, "next one"),

    ?assertEqual("0008_next_one.sql", UpFile),
    teardown(Dir).

%% Name slugification: spaces, punctuation, mixed case all normalize.
create_migration_slugifies_messy_name_test() ->
    Dir = setup_dir(),
    {ok, {UpFile, _}} = erl_data_shift_scaffold:create_migration(Dir, "  Add Users!! Table--now  "),
    ?assertEqual("0001_add_users_table_now.sql", UpFile),
    teardown(Dir).

%% Up file content is a helpful template, not empty.
create_migration_writes_template_content_test() ->
    Dir = setup_dir(),
    {ok, {UpFile, DownFile}} = erl_data_shift_scaffold:create_migration(Dir, "init"),
    {ok, UpContent} = file:read_file(filename:join(Dir, UpFile)),
    {ok, DownContent} = file:read_file(filename:join(Dir, DownFile)),
    ?assert(byte_size(UpContent) > 0),
    ?assert(byte_size(DownContent) > 0),
    ?assertNotEqual(UpContent, DownContent),
    teardown(Dir).

%% Down files present alongside up files don't affect version detection
%% (list_sql_files already excludes them).
create_migration_ignores_down_files_when_versioning_test() ->
    Dir = setup_dir(),
    filelib:ensure_dir(Dir ++ "/"),
    file:write_file(filename:join(Dir, "0003_x.sql"), <<"-- sql">>),
    file:write_file(filename:join(Dir, "0003_x.down.sql"), <<"-- sql">>),

    {ok, {UpFile, _}} = erl_data_shift_scaffold:create_migration(Dir, "y"),

    ?assertEqual("0004_y.sql", UpFile),
    teardown(Dir).