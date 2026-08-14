-module(erl_data_shift_migrator).
-export([run/3]).

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

%% -- internal --

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