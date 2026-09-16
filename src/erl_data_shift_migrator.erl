-module(erl_data_shift_migrator).
-export([run/3, run/4, rollback_last/2, rollback_to/3, dry_run/2, validate/2, verify_checksums/2]).

-define(NO_APPLIED_MIGRATIONS, no_applied_migrations).
-define(DOWN_FILE_MISSING, down_file_missing).
-define(UP_FILE_MISSING, up_file_missing).

%% Runs all pending migrations in Dir against Env's DB. ProgressFun(Idx,
%% Total, Filename) is called before each file (decoupled from printing so
%% it's easily testable). Acquires a DB advisory lock first so two concurrent
%% eds instances can't apply migrations at the same time. Returns
%% {ok, AppliedCount} or {error, Reason}.
-spec run(map(), file:filename(), fun((integer(), integer(), string()) -> any())) ->
    {ok, integer()} | {error, term()}.
run(Env, Dir, ProgressFun) ->
    run(Env, Dir, ProgressFun, #{force => false}).

%% Same as run/3, but Opts may include force => true to bypass the checksum
%% drift check (see check_drift/3) — an explicit, deliberate override for
%% cases where drift is known and accepted, not a silent default.
-spec run(map(), file:filename(), fun((integer(), integer(), string()) -> any()), map()) ->
    {ok, integer()} | {error, term()}.
run(Env, Dir, ProgressFun, Opts) ->
    Force = maps:get(force, Opts, false),
    case erl_data_shift_migrations:list_sql_files(Dir) of
        {error, Reason} ->
            {error, Reason};
        {ok, Files} ->
            erl_data_shift_db:with_connection(Env, fun(Conn) ->
                with_lock(Conn, fun() -> run_with_conn(Conn, Dir, Files, ProgressFun, Force) end)
            end)
    end.

%% Lists pending migrations without applying any of them — no lock needed
%% since nothing is written. Returns {ok, [Filename]}.
-spec dry_run(map(), file:filename()) -> {ok, [string()]} | {error, term()}.
dry_run(Env, Dir) ->
    case erl_data_shift_migrations:list_sql_files(Dir) of
        {error, Reason} ->
            {error, Reason};
        {ok, Files} ->
            erl_data_shift_db:with_connection(Env, fun(Conn) ->
                pending_files(Conn, Files)
            end)
    end.

pending_files(Conn, Files) ->
    case erl_data_shift_db:ensure_migrations_table(Conn) of
        {error, Reason} -> {error, Reason};
        ok ->
            case erl_data_shift_db:get_applied_versions(Conn) of
                {error, Reason} -> {error, Reason};
                {ok, Applied} ->
                    Pending = [F || F <- Files,
                               not lists:member(erl_data_shift_migrations:extract_version(F), Applied)],
                    {ok, Pending}
            end
    end.

%% Test-runs every pending migration's SQL inside a rolled-back transaction
%% (never persists anything, no lock needed). Unlike run/3, continues past
%% failures so all problems are reported at once — useful for CI checks.
%% Returns {ok, [{Filename, ok | {error, Reason}}]}.
-spec validate(map(), file:filename()) -> {ok, [{string(), ok | {error, term()}}]} | {error, term()}.
validate(Env, Dir) ->
    case erl_data_shift_migrations:list_sql_files(Dir) of
        {error, Reason} ->
            {error, Reason};
        {ok, Files} ->
            erl_data_shift_db:with_connection(Env, fun(Conn) ->
                case pending_files(Conn, Files) of
                    {error, Reason} -> {error, Reason};
                    {ok, Pending} -> {ok, validate_each(Conn, Dir, Pending)}
                end
            end)
    end.

validate_each(Conn, Dir, Files) ->
    [{File, validate_one(Conn, Dir, File)} || File <- Files].

validate_one(Conn, Dir, File) ->
    case erl_data_shift_migrations:read_file(filename:join(Dir, File)) of
        {error, Reason} -> {error, {read_failed, Reason}};
        {ok, Sql} ->
            case erl_data_shift_migrations:detect_non_transactional_statements(Sql) of
                [] -> erl_data_shift_db:validate_migration(Conn, Sql);
                Matches -> {error, {non_transactional_statement, Matches}}
            end
    end.

%% Detects drift: for every applied (not reverted) migration with a stored
%% checksum, recomputes the checksum of its local up-file and compares.
%% Flags mismatches (file edited after being applied) and missing local
%% files separately. No lock needed — read-only, nothing is written.
%% Returns {ok, [{Version, Status}]} where Status is one of:
%%   ok | {mismatch, StoredChecksum, LocalChecksum} | missing_local_file
-spec verify_checksums(map(), file:filename()) ->
    {ok, [{string(), ok | {mismatch, string(), string()} | missing_local_file}]} | {error, term()}.
verify_checksums(Env, Dir) ->
    case erl_data_shift_migrations:list_sql_files(Dir) of
        {error, Reason} ->
            {error, Reason};
        {ok, Files} ->
            erl_data_shift_db:with_connection(Env, fun(Conn) ->
                case erl_data_shift_db:get_applied_checksums(Conn) of
                    {error, Reason} -> {error, Reason};
                    {ok, Checksums} -> {ok, verify_each(Dir, Files, Checksums)}
                end
            end)
    end.

verify_each(Dir, Files, Checksums) ->
    [{Version, verify_one(Dir, Files, Version, StoredChecksum)} || {Version, StoredChecksum} <- Checksums].

verify_one(Dir, Files, Version, StoredChecksum) ->
    case find_up_file(Files, Version) of
        not_found ->
            missing_local_file;
        UpFile ->
            case erl_data_shift_migrations:read_file(filename:join(Dir, UpFile)) of
                {error, _Reason} ->
                    missing_local_file;
                {ok, Sql} ->
                    LocalChecksum = erl_data_shift_migrations:compute_checksum(Sql),
                    case LocalChecksum =:= StoredChecksum of
                        true -> ok;
                        false -> {mismatch, StoredChecksum, LocalChecksum}
                    end
            end
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
                with_lock(Conn, fun() -> rollback_with_conn(Conn, Dir, Files) end)
            end)
    end.

%% Acquires the DB advisory lock, runs Fun/0, releases the lock afterward
%% regardless of success or failure (best-effort release, never masks Fun's
%% own result/error).
with_lock(Conn, Fun) ->
    case erl_data_shift_db:acquire_migration_lock(Conn) of
        {error, Reason} ->
            {error, Reason};
        ok ->
            try
                Fun()
            after
                erl_data_shift_db:release_migration_lock(Conn)
            end
    end.

rollback_with_conn(Conn, Dir, Files) ->
    case erl_data_shift_db:get_last_applied_version(Conn) of
        {error, Reason} ->
            {error, Reason};
        {ok, none} ->
            {error, ?NO_APPLIED_MIGRATIONS};
        {ok, Version} ->
            case revert_one_version(Conn, Dir, Files, Version) of
                {ok, Version} -> {ok, Version};
                {error, Reason} -> {error, Reason}
            end
    end.

%% Rolls back every applied migration newer than Target (exclusive), in
%% reverse chronological order — or every applied migration at all if
%% Target is the atom `all`. Reuses the same single-step revert logic as
%% rollback_last/2 (revert_one_version/4), just looped. Stops at the first
%% failure and reports which versions were successfully reverted before it,
%% so a partial rollback is never silently lost from view.
%% Returns {ok, [Version]} (reverted, most-recent-first) or
%% {error, {Reason, [Version]}} (Reason plus what succeeded before it).
-spec rollback_to(map(), file:filename(), all | string()) ->
    {ok, [string()]} | {error, {term(), [string()]}} | {error, term()}.
rollback_to(Env, Dir, Target) ->
    case erl_data_shift_migrations:list_sql_files(Dir) of
        {error, Reason} ->
            {error, Reason};
        {ok, Files} ->
            erl_data_shift_db:with_connection(Env, fun(Conn) ->
                with_lock(Conn, fun() -> rollback_to_with_conn(Conn, Dir, Files, Target) end)
            end)
    end.

rollback_to_with_conn(Conn, Dir, Files, Target) ->
    case validate_target(Target) of
        {error, Reason} ->
            {error, Reason};
        ok ->
            case erl_data_shift_db:get_applied_versions_desc(Conn) of
                {error, Reason} ->
                    {error, Reason};
                {ok, AppliedDesc} ->
                    ToRevert = versions_to_revert(AppliedDesc, Target),
                    revert_many(Conn, Dir, Files, ToRevert, [])
            end
    end.

%% Target must be `all` or a purely numeric version string (matching what
%% extract_version/1 produces from filenames) — rejecting anything else
%% outright rather than silently reverting nothing or everything.
validate_target(all) -> ok;
validate_target(Target) when is_list(Target) ->
    case Target =/= [] andalso lists:all(fun(C) -> C >= $0 andalso C =< $9 end, Target) of
        true -> ok;
        false -> {error, {invalid_target_version, Target}}
    end.

versions_to_revert(AppliedDesc, all) ->
    AppliedDesc;
versions_to_revert(AppliedDesc, TargetVersion) ->
    TargetNum = list_to_integer(TargetVersion),
    [V || V <- AppliedDesc, list_to_integer(V) > TargetNum].

revert_many(_Conn, _Dir, _Files, [], Acc) ->
    {ok, lists:reverse(Acc)};
revert_many(Conn, Dir, Files, [Version | Rest], Acc) ->
    case revert_one_version(Conn, Dir, Files, Version) of
        {ok, Version} -> revert_many(Conn, Dir, Files, Rest, [Version | Acc]);
        {error, Reason} -> {error, {Reason, lists:reverse(Acc)}}
    end.

%% Shared single-migration revert: finds the up-file matching Version,
%% derives and reads its *.down.sql, and reverts it transactionally via
%% db:revert_migration/3. Used by both rollback_last/2 (single step) and
%% rollback_to/3 (looped for multi-step rollback).
revert_one_version(Conn, Dir, Files, Version) ->
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
    end.

find_up_file(Files, Version) ->
    case [F || F <- Files, erl_data_shift_migrations:extract_version(F) =:= Version] of
        [F | _] -> F;
        [] -> not_found
    end.

run_with_conn(Conn, Dir, Files, ProgressFun, Force) ->
    case erl_data_shift_db:ensure_migrations_table(Conn) of
        {error, Reason} ->
            {error, Reason};
        ok ->
            DriftCheck = case Force of
                true -> ok;
                false -> check_drift(Conn, Dir, Files)
            end,
            case DriftCheck of
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
            end
    end.

%% Refuses to apply new migrations if any already-applied one has been
%% edited since it ran (checksum mismatch) — that's a real integrity
%% problem worth stopping for. A missing local file is NOT blocking (could
%% be legitimate, e.g. an old migration archived out of the repo).
check_drift(Conn, Dir, Files) ->
    case erl_data_shift_db:get_applied_checksums(Conn) of
        {error, Reason} ->
            {error, Reason};
        {ok, Checksums} ->
            Results = verify_each(Dir, Files, Checksums),
            Mismatches = [R || {_Version, {mismatch, _, _}} = R <- Results],
            case Mismatches of
                [] -> ok;
                _ -> {error, {checksum_drift, Mismatches}}
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
            case erl_data_shift_migrations:detect_non_transactional_statements(Sql) of
                [] ->
                    case erl_data_shift_db:apply_migration(Conn, Version, Sql) of
                        ok -> apply_pending(Conn, Dir, Rest, Total, Idx + 1, ProgressFun, AppliedCount + 1);
                        {error, Reason} -> {error, {migration_failed, File, Reason}}
                    end;
                Matches ->
                    {error, {non_transactional_statement, File, Matches}}
            end
    end.

