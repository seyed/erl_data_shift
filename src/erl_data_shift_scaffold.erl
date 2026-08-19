-module(erl_data_shift_scaffold).
-export([create_migration/2]).

-define(VERSION_WIDTH, 4).
-define(UP_TEMPLATE, "-- Write your migration SQL here.\n").
-define(DOWN_TEMPLATE, "-- Write the SQL to reverse this migration here.\n").

%% Creates a new "<NNNN>_<name>.sql" + "<NNNN>_<name>.down.sql" pair in Dir,
%% where NNNN is one greater than the highest existing version (zero-padded
%% to 4 digits), or "0001" if Dir has no migrations yet. Name is sanitized
%% to a filesystem-safe slug. Returns {ok, {UpFile, DownFile}}.
-spec create_migration(file:filename(), string()) -> {ok, {string(), string()}} | {error, term()}.
create_migration(Dir, Name) ->
    case filelib:ensure_dir(Dir ++ "/") of
        {error, Reason} ->
            {error, Reason};
        ok ->
            case erl_data_shift_migrations:list_sql_files(Dir) of
                {error, {directory_not_found, _}} -> build_files(Dir, Name, []);
                {error, Reason} -> {error, Reason};
                {ok, Files} -> build_files(Dir, Name, Files)
            end
    end.

%% -- internal --

build_files(Dir, Name, ExistingFiles) ->
    NextVersion = next_version(ExistingFiles),
    Slug = slugify(Name),
    UpFile = NextVersion ++ "_" ++ Slug ++ ".sql",
    DownFile = NextVersion ++ "_" ++ Slug ++ ".down.sql",
    case write_new(filename:join(Dir, UpFile), ?UP_TEMPLATE) of
        {error, Reason} -> {error, Reason};
        ok ->
            case write_new(filename:join(Dir, DownFile), ?DOWN_TEMPLATE) of
                {error, Reason} -> {error, Reason};
                ok -> {ok, {UpFile, DownFile}}
            end
    end.

%% Refuses to overwrite an existing file (shouldn't normally happen given
%% the version increment, but guards against manual filename collisions).
write_new(Path, Content) ->
    case filelib:is_regular(Path) of
        true -> {error, {already_exists, Path}};
        false -> file:write_file(Path, Content)
    end.

next_version(Files) ->
    Versions = [list_to_integer(erl_data_shift_migrations:extract_version(F))
                || F <- Files, is_numeric_version(erl_data_shift_migrations:extract_version(F))],
    Next = case Versions of
        [] -> 1;
        _ -> lists:max(Versions) + 1
    end,
    zero_pad(Next, ?VERSION_WIDTH).

is_numeric_version(Str) ->
    Str =/= [] andalso lists:all(fun(C) -> C >= $0 andalso C =< $9 end, Str).

zero_pad(N, Width) ->
    Str = integer_to_list(N),
    Padding = Width - length(Str),
    case Padding > 0 of
        true -> lists:duplicate(Padding, $0) ++ Str;
        false -> Str
    end.

%% Lowercases, replaces anything that isn't [a-z0-9_] with underscore, and
%% collapses repeats, so "Add Users Table!!" -> "add_users_table".
slugify(Name) ->
    Lower = string:lowercase(Name),
    Replaced = [case C of
        C when (C >= $a andalso C =< $z) orelse (C >= $0 andalso C =< $9) -> C;
        _ -> $_
    end || C <- Lower],
    collapse_underscores(Replaced).

collapse_underscores(Str) ->
    collapse_underscores(Str, []).

collapse_underscores([$_, $_ | Rest], Acc) ->
    collapse_underscores([$_ | Rest], Acc);
collapse_underscores([C | Rest], Acc) ->
    collapse_underscores(Rest, [C | Acc]);
collapse_underscores([], Acc) ->
    string:trim(lists:reverse(Acc), both, "_").