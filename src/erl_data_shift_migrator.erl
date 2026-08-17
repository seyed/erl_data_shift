-module(erl_data_shift_migrator).
-export([run/3, rollback_last/2]).

-define(NO_APPLIED_MIGRATIONS, no_applied_migrations).
-define(DOWN_FILE_MISSING, down_file_missing).
-define(UP_FILE_MISSING, up_file_missing).

%% Runs all pending migrations in Dir against Env's DB. ProgressFun(Idx,
%% Total, Filename) is called before each file (decoupled from printing so
%% it's easily testable). Returns {ok, AppliedCount} or {error, Reason}.
-spec run(map(), file:filename(), fun((integer(), integer(), string()) -> any())) ->
    {ok, integer()} | {error, term()}.
run(Env, Dir, ProgressFun) ->
    case erl_data_shift_migrations:list_sql_files(Dir) of
        {error, Reason} ->
            {error, Reason};
        {ok, Files} ->
            erl_data_shift_db:with_connection(Env, fun(Conn) ->
                run_with_conn(Conn, Dir, Files, ProgressFun)
            end)
    end.

%% Rolls back the most recently applied migration: finds its up-file in Dir
%% (to derive the matching *.down.sql), runs the down SQL, and removes its
%% schema_migrations row — all in one transaction via db:revert_migration/3.
-spec rollback_last(map(), file:filename()) -> {ok, string()} | {error, term()}.
rollback_last(Env, Dir) ->
    case erl_data_shift_migrations:list_sql_files(Dir) of
        {error, Reason} ->
            {error, Reason};
        {ok, Files} ->
            erl_data_shift_db:with_connection(Env, fun(Conn) ->
                rollback_with_conn(Conn, Dir, Files)
            end)
    end.

rollback_with_conn(Conn, Dir, Files) ->
    case erl_data_shift_db:get_last_applied_version(Conn) of
        {error, Reason} ->
            {error, Reason};
        {ok, none} ->
            {error, ?NO_APPLIED_MIGRATIONS};
        {ok, Version} ->
            case find_up_file(Files, Version) of
                not_found ->
                    {error, {?UP_FILE_MISSING, Version}};
                UpFile ->
                    case erl_data_shift_migrations:has_down_file(Dir, UpFile) of
                        false ->
                            {error, {?DOWN_FILE_MISSING, erl_data_shift_migrations:down_file_for(UpFile)}};
                        true ->
                            DownFile = erl_data_shift_migrations:down_file_for(UpFile),
                            case erl_data_shift_migrations:read_file(filename:join(Dir, DownFile)) of
                                {error, Reason} ->
                                    {error, {read_failed, DownFile, Reason}};
                                {ok, Sql} ->
                                    case erl_data_shift_db:revert_migration(Conn, Version, Sql) of
                                        ok -> {ok, Version};
                                        {error, Reason} -> {error, {rollback_failed, UpFile, Reason}}
                                    end
                            end
                    end
            end
    end.

find_up_file(Files, Version) ->
    case [F || F <- Files, erl_data_shift_migrations:extract_version(F) =:= Version] of
        [F | _] -> F;
        [] -> not_found
    end.

run_with_conn(Conn, Dir, Files, ProgressFun) ->
    case erl_data_shift_db:ensure_migrations_table(Conn) of
        {error, Reason} ->
            {error, Reason};
        ok ->
            case erl_data_shift_db:get_applied_versions(Conn) of
                {error, Reason} ->
                    {error, Reason};
                {ok, Applied} ->
                    Pending = [F || F <- Files,
                               not lists:member(erl_data_shift_migrations:extract_version(F), Applied)],
                    apply_pending(Conn, Dir, Pending, length(Pending), 1, ProgressFun, 0)
            end
    end.

apply_pending(_Conn, _Dir, [], _Total, _Idx, _ProgressFun, AppliedCount) ->
    {ok, AppliedCount};
apply_pending(Conn, Dir, [File | Rest], Total, Idx, ProgressFun, AppliedCount) ->
    ProgressFun(Idx, Total, File),
    Version = erl_data_shift_migrations:extract_version(File),
    case erl_data_shift_migrations:read_file(filename:join(Dir, File)) of
        {error, Reason} ->
            {error, {read_failed, File, Reason}};
        {ok, Sql} ->
            case erl_data_shift_db:apply_migration(Conn, Version, Sql) of
                ok -> apply_pending(Conn, Dir, Rest, Total, Idx + 1, ProgressFun, AppliedCount + 1);
                {error, Reason} -> {error, {migration_failed, File, Reason}}
            end
    end.