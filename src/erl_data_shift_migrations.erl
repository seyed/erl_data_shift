-module(erl_data_shift_migrations).
-export([resolve_dir/1, list_sql_files/1, extract_version/1, read_file/1,
         down_file_for/1, has_down_file/2, compute_checksum/1]).

%% Suffix convention for rollback scripts: "0001_init.sql" pairs with
%% "0001_init.down.sql" in the same directory.
-define(DOWN_SUFFIX, ".down.sql").

%% Resolves the migrations directory from CLI args. Looks for "-f <path>" or
%% "--path <path>"; defaults to "<original_cwd>/migrations" if not given.
%% Returns {Dir, RemainingArgs} so callers can still see any other flags.
-spec resolve_dir([string()]) -> {file:filename(), [string()]}.
resolve_dir(Args) ->
    case take_flag(Args) of
        {ok, Path, Rest} -> {Path, Rest};
        none -> {filename:join(erl_data_shift_env:get_original_cwd(), "migrations"), Args}
    end.

%% Lists "up" .sql files in Dir, sorted by filename (so numeric/date-prefixed
%% migrations run in order). Excludes *.down.sql rollback scripts — those are
%% only ever read via down_file_for/1, never listed as pending migrations.
%% Returns {error, {directory_not_found, Dir}} instead of crashing if the
%% directory doesn't exist.
-spec list_sql_files(file:filename()) -> {ok, [string()]} | {error, term()}.
list_sql_files(Dir) ->
    case filelib:is_dir(Dir) of
        false ->
            {error, {directory_not_found, Dir}};
        true ->
            case file:list_dir(Dir) of
                {ok, Files} ->
                    SqlFiles = lists:sort([F || F <- Files,
                                            filename:extension(F) =:= ".sql",
                                            not is_down_file(F)]),
                    {ok, SqlFiles};
                {error, Reason} ->
                    {error, Reason}
            end
    end.

%% Derives the expected down-migration filename for a given up-migration
%% filename, e.g. "0001_init.sql" -> "0001_init.down.sql".
-spec down_file_for(string()) -> string().
down_file_for(UpFilename) ->
    Base = filename:rootname(UpFilename, ".sql"),
    Base ++ ?DOWN_SUFFIX.

%% Checks whether Dir contains a down-migration file for UpFilename.
-spec has_down_file(file:filename(), string()) -> boolean().
has_down_file(Dir, UpFilename) ->
    filelib:is_regular(filename:join(Dir, down_file_for(UpFilename))).

%% Computes a stable hex-encoded SHA256 checksum of migration SQL content,
%% used to detect if an already-applied migration file was edited afterward.
-spec compute_checksum(string() | binary()) -> string().
compute_checksum(Sql) when is_list(Sql) ->
    compute_checksum(list_to_binary(Sql));
compute_checksum(Sql) when is_binary(Sql) ->
    Hash = crypto:hash(sha256, Sql),
    lists:flatten([io_lib:format("~2.16.0b", [B]) || <<B>> <= Hash]).

%% -- internal --

take_flag(["-f", Path | Rest]) -> {ok, Path, Rest};
take_flag(["--path", Path | Rest]) -> {ok, Path, Rest};
take_flag([_ | Rest]) -> take_flag(Rest);
take_flag([]) -> none.

is_down_file(Filename) ->
    Suffix = ?DOWN_SUFFIX,
    SuffixLen = length(Suffix),
    Len = length(Filename),
    Len >= SuffixLen andalso lists:suffix(Suffix, Filename).

%% -- shared helpers (also used by app.erl's drift check) --

%% Extracts the leading numeric version prefix from a filename or a raw
%% version string, e.g. "0001_init.sql" -> "0001", "001" -> "001". Falls
%% back to the original string if no leading digits are found.
-spec extract_version(string()) -> string().
extract_version(Str) when is_list(Str) ->
    case re:run(Str, "^([0-9]+)", [{capture, first, list}]) of
        {match, [Digits]} -> Digits;
        nomatch -> Str
    end.

%% Reads a migration file's SQL content as a string.
-spec read_file(file:filename()) -> {ok, string()} | {error, term()}.
read_file(Path) ->
    case file:read_file(Path) of
        {ok, Bin} -> {ok, binary_to_list(Bin)};
        {error, Reason} -> {error, Reason}
    end.