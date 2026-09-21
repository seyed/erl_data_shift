-module(erl_data_shift_app).
-behaviour(application).
-export([start/2, stop/1, dispatch/1, format_duration/1, extract_leading_digits/1,
         column_widths/2, human_size/1, time_ago/1, format_datetime/1, format_cell/1,
         stop_vm/1]).

%% Registry mapping subcommand name -> handler fun/0. Add new commands here.
-define(HELP_ENTRIES, [
    {"con_check", "Tests Postgres connectivity using your .env credentials."},
    {"con_check json", "Same as con_check, output as JSON (for CI/tooling)."},
    {"stat", "Shows table names, row counts, and storage size, largest first."},
    {"stat json", "Same as stat, output as JSON."},
    {"history", "Shows applied migrations, with time-since-applied and local/DB drift check."},
    {"migrate", "Runs all pending .sql files from ./migrations transactionally. Refuses if an already-applied migration was edited (checksum drift)."},
    {"migrate force", "Same as migrate, but bypasses the checksum drift check. Use deliberately, not by default."},
    {"migrate dry-run", "Lists pending migrations without applying them."},
    {"migrate dry-run json", "Same as migrate dry-run, output as JSON."},
    {"migrate down", "Rolls back the most recently applied migration."},
    {"migrate down to <version>", "Rolls back every migration applied after <version> (exclusive), newest first."},
    {"migrate down all", "Rolls back every applied migration."},
    {"migrate path <dir>", "Same as migrate, but points to a custom migrations directory. Also: -f <dir> / --path <dir>."},
    {"new <name>", "Scaffolds a new numbered up+down migration file pair."},
    {"validate", "Test-runs pending migrations in a rolled-back transaction to catch errors early."},
    {"validate json", "Same as validate, output as JSON."},
    {"verify", "Checks that applied migration files haven't been edited since they ran (checksum drift)."},
    {"verify json", "Same as verify, output as JSON."},
    {"init", "Scaffolds migrations/ and .env.example in the current directory."},
    {"--version", "Prints the eds version."},
    {"--help / -h", "Shows this help message."}
]).

-define(COMMANDS, #{
    "con_check" => fun con_check/1,
    "migrate"   => fun migrate/1,
    "stat"      => fun stat/1,
    "history"   => fun(_Args) -> history() end,
    "init"      => fun(_Args) -> init_cmd() end,
    "new"       => fun new_cmd/1,
    "validate"  => fun validate_cmd/1,
    "verify"    => fun verify_cmd/1,
    "version"   => fun(_Args) -> print_version() end,
    "help"      => fun(_Args) -> print_help() end
}).

start(_StartType, _StartArgs) ->
    io:setopts(standard_io, [{encoding, unicode}]),
    print_caution(),
    Args = init:get_plain_arguments(),
    Result = dispatch(Args),
    ?MODULE:stop_vm(Result),
    {ok, self()}.

%% Isolated so tests can safely mock this module's own stop_vm/1 instead of
%% mocking the 'init' kernel module directly — mocking init:stop/1 via
%% unstick/passthrough is unreliable and can genuinely kill the VM (init is
%% tightly coupled to real VM shutdown, not just a regular callable module).
%% Exit code reflects the actual command outcome: 0 for ok, 1 for error —
%% previously every invocation exited 0 regardless of success or failure,
%% silently undermining any CI/scripting use of this tool.
stop_vm(ok) -> init:stop(0);
stop_vm(error) -> init:stop(1).

stop(_State) ->
    ok.

%% -- dispatch --

%% relx passes its own boot verb (foreground/console/start/...) through as
%% part of the plain arguments — strip any leading one before dispatching.
-define(BOOT_VERBS, ["foreground", "console", "start", "daemon"]).
-define(DOWN_ARG, "down").
-define(DRY_RUN_ARG, "dry-run").
-define(FORCE_ARG, "force").
-define(JSON_ARG, "json").

dispatch([Verb | Rest]) ->
    case lists:member(Verb, ?BOOT_VERBS) of
        true -> dispatch(Rest);
        false -> run_command([Verb | Rest])
    end;
dispatch([]) ->
    print_usage("No command given."),
    error.

run_command([Cmd | Rest]) ->
    case maps:find(Cmd, ?COMMANDS) of
        {ok, Handler} -> Handler(Rest);
        error ->
            print_usage(io_lib:format("Unknown command: ~ts", [Cmd])),
            error
    end.

print_usage(Message) ->
    io:format("\033[31m~ts~n\033[0m", [Message]),
    io:format("Usage: eds <command>~n"),
    io:format("Commands:~n"),
    lists:foreach(fun({Cmd, _Desc}) -> io:format("  ~ts~n", [Cmd]) end, ?HELP_ENTRIES).

print_help() ->
    io:format("Usage: eds <command>~n~nCommands:~n"),
    lists:foreach(fun({Cmd, Desc}) -> io:format("  ~-24ts ~ts~n", [Cmd, Desc]) end, ?HELP_ENTRIES),
    ok.

print_version() ->
    Vsn = case application:get_key(erl_data_shift, vsn) of
        {ok, V} -> V;
        undefined -> "unknown"
    end,
    io:format("eds ~ts~n", [Vsn]),
    ok.

new_cmd([]) ->
    io:format("\033[31m❌ Usage: eds new <name>~n\033[0m"),
    error;
new_cmd([Name | _Rest]) ->
    try
        {Dir, _} = erl_data_shift_migrations:resolve_dir([]),
        case erl_data_shift_scaffold:create_migration(Dir, Name) of
            {ok, {UpFile, DownFile}} ->
                io:format("\033[32m✅ Created ~ts~n\033[0m", [filename:join(Dir, UpFile)]),
                io:format("\033[32m✅ Created ~ts~n\033[0m", [filename:join(Dir, DownFile)]),
                ok;
            {error, {already_exists, Path}} ->
                io:format("\033[31m❌ ~ts already exists.~n\033[0m", [Path]),
                error;
            {error, Reason} ->
                io:format("\033[31m❌ Could not create migration: ~p~n\033[0m", [Reason]),
                error
        end
    catch
        Class:Err ->
            io:format("\033[31m❌ Unexpected error (~p): ~p~n\033[0m", [Class, Err]),
            error
    end.

validate_cmd(Args) ->
    {Dir, RemainingArgs} = erl_data_shift_migrations:resolve_dir(Args),
    Json = lists:member(?JSON_ARG, RemainingArgs),
    try
        case erl_data_shift_env:load() of
            {error, Reason} when Json ->
                print_json(#{<<"status">> => <<"error">>, <<"reason">> => reason_to_binary(Reason)}),
                error;
            {error, Reason} ->
                io:format("\033[31m❌ Could not read .env: ~p~n\033[0m", [Reason]),
                error;
            {ok, Env} ->
                case erl_data_shift_migrator:validate(Env, Dir) of
                    {ok, Results} when Json ->
                        print_validate_results_json(Results);
                    {ok, []} ->
                        io:format("\033[32m✅ No pending migrations to validate.~n\033[0m"),
                        ok;
                    {ok, Results} ->
                        print_validate_results(Results);
                    {error, {directory_not_found, D}} when Json ->
                        print_json(#{<<"status">> => <<"error">>, <<"reason">> => <<"directory_not_found">>, <<"directory">> => list_to_binary(D)}),
                        error;
                    {error, {directory_not_found, Dir}} ->
                        io:format("\033[33m⚠️  Migrations directory not found: ~ts~n\033[0m", [Dir]),
                        error;
                    {error, Reason} when Json ->
                        print_json(#{<<"status">> => <<"error">>, <<"reason">> => reason_to_binary(Reason)}),
                        error;
                    {error, Reason} ->
                        io:format("\033[31m❌ Could not validate migrations: ~p~n\033[0m", [Reason]),
                        error
                end
        end
    catch
        Class:Err when Json ->
            print_json(#{<<"status">> => <<"error">>, <<"reason">> => reason_to_binary({Class, Err})}),
            error;
        Class:Err ->
            io:format("\033[31m❌ Unexpected error (~p): ~p~n\033[0m", [Class, Err]),
            error
    end.

%% Returns error if any file failed validation, so CI correctly sees a
%% nonzero exit code — previously this always returned ok regardless.
print_validate_results_json(Results) ->
    Items = [case R of
        {File, ok} -> #{<<"file">> => list_to_binary(File), <<"status">> => <<"ok">>};
        {File, {error, Reason}} -> #{<<"file">> => list_to_binary(File), <<"status">> => <<"error">>, <<"reason">> => reason_to_binary(Reason)}
    end || R <- Results],
    print_json(#{<<"results">> => Items}),
    case lists:any(fun({_, R}) -> R =/= ok end, Results) of
        true -> error;
        false -> ok
    end.

print_validate_results(Results) ->
    lists:foreach(fun({File, Result}) ->
        case Result of
            ok -> io:format("\033[32m✅ ~ts~n\033[0m", [File]);
            {error, {non_transactional_statement, Matches}} ->
                io:format("\033[31m❌ ~ts — contains statement(s) that cannot run inside a transaction: ~ts~n\033[0m",
                          [File, string:join(Matches, ", ")]);
            {error, Reason} -> io:format("\033[31m❌ ~ts — ~p~n\033[0m", [File, Reason])
        end
    end, Results),
    FailCount = length([R || {_, {error, _}} = R <- Results]),
    case FailCount of
        0 ->
            io:format("\033[32m~nAll ~B migration(s) validated successfully.~n\033[0m", [length(Results)]),
            ok;
        _ ->
            io:format("\033[31m~n~B of ~B migration(s) failed validation.~n\033[0m", [FailCount, length(Results)]),
            error
    end.

verify_cmd(Args) ->
    {Dir, RemainingArgs} = erl_data_shift_migrations:resolve_dir(Args),
    Json = lists:member(?JSON_ARG, RemainingArgs),
    try
        case erl_data_shift_env:load() of
            {error, Reason} when Json ->
                print_json(#{<<"status">> => <<"error">>, <<"reason">> => reason_to_binary(Reason)}),
                error;
            {error, Reason} ->
                io:format("\033[31m❌ Could not read .env: ~p~n\033[0m", [Reason]),
                error;
            {ok, Env} ->
                case erl_data_shift_migrator:verify_checksums(Env, Dir) of
                    {ok, Results} when Json ->
                        print_verify_results_json(Results);
                    {ok, []} ->
                        io:format("\033[32m✅ No checksummed migrations to verify.~n\033[0m"),
                        ok;
                    {ok, Results} ->
                        print_verify_results(Results);
                    {error, {directory_not_found, D}} when Json ->
                        print_json(#{<<"status">> => <<"error">>, <<"reason">> => <<"directory_not_found">>, <<"directory">> => list_to_binary(D)}),
                        error;
                    {error, {directory_not_found, Dir}} ->
                        io:format("\033[33m⚠️  Migrations directory not found: ~ts~n\033[0m", [Dir]),
                        error;
                    {error, Reason} when Json ->
                        print_json(#{<<"status">> => <<"error">>, <<"reason">> => reason_to_binary(Reason)}),
                        error;
                    {error, Reason} ->
                        io:format("\033[31m❌ Could not verify checksums: ~p~n\033[0m", [Reason]),
                        error
                end
        end
    catch
        Class:Err when Json ->
            print_json(#{<<"status">> => <<"error">>, <<"reason">> => reason_to_binary({Class, Err})}),
            error;
        Class:Err ->
            io:format("\033[31m❌ Unexpected error (~p): ~p~n\033[0m", [Class, Err]),
            error
    end.

print_verify_results_json(Results) ->
    Items = [case R of
        {Version, ok} ->
            #{<<"version">> => list_to_binary(Version), <<"status">> => <<"ok">>};
        {Version, missing_local_file} ->
            #{<<"version">> => list_to_binary(Version), <<"status">> => <<"missing_local_file">>};
        {Version, {mismatch, Stored, Local}} ->
            #{<<"version">> => list_to_binary(Version), <<"status">> => <<"mismatch">>,
              <<"stored_checksum">> => list_to_binary(Stored), <<"local_checksum">> => list_to_binary(Local)}
    end || R <- Results],
    print_json(#{<<"results">> => Items}),
    case lists:any(fun({_, S}) -> S =/= ok end, Results) of
        true -> error;
        false -> ok
    end.

print_verify_results(Results) ->
    lists:foreach(fun({Version, Status}) ->
        case Status of
            ok ->
                io:format("\033[32m✅ ~ts — unchanged~n\033[0m", [Version]);
            missing_local_file ->
                io:format("\033[33m⚠️  ~ts — no matching local file found~n\033[0m", [Version]);
            {mismatch, _Stored, _Local} ->
                io:format("\033[31m❌ ~ts — file was edited after being applied~n\033[0m", [Version])
        end
    end, Results),
    Problems = length([R || {_, S} = R <- Results, S =/= ok]),
    case Problems of
        0 ->
            io:format("\033[32m~nAll ~B applied migration(s) match their local files.~n\033[0m", [length(Results)]),
            ok;
        _ ->
            io:format("\033[31m~n~B of ~B applied migration(s) have drifted from local files.~n\033[0m", [Problems, length(Results)]),
            error
    end.

init_cmd() ->
    try
        BaseDir = erl_data_shift_env:get_original_cwd(),
        case erl_data_shift_init:run(BaseDir) of
            {ok, #{created := Created, skipped := Skipped}} ->
                lists:foreach(fun(Name) -> io:format("\033[32m✅ Created ~ts~n\033[0m", [Name]) end, Created),
                lists:foreach(fun(Name) -> io:format("\033[33m⏭️  Skipped ~ts (already exists)~n\033[0m", [Name]) end, Skipped),
                case Created of
                    [] -> io:format("Already initialized — nothing to do.~n");
                    _ -> io:format("Edit .env.example, fill in real values, save as .env.~n")
                end,
                ok;
            {error, Reason} ->
                io:format("\033[31m❌ Init failed: ~p~n\033[0m", [Reason]),
                error
        end
    catch
        Class:Err ->
            io:format("\033[31m❌ Unexpected error (~p): ~p~n\033[0m", [Class, Err]),
            error
    end.

print_caution() ->
    Lines = [
        "erl_data_shift",
        "",
        "CAUTION: You are responsible for any actions",
        "taken by this tool. We accept no liability for",
        "data loss — back up your data before proceeding."
    ],
    InnerWidth = lists:max([length(L) || L <- Lines]),
    Border = "+" ++ lists:duplicate(InnerWidth + 2, $-) ++ "+",
    io:format(standard_error, "\033[33m~ts~n", [Border]),
    lists:foreach(fun(L) ->
        io:format(standard_error, "| ~ts |~n", [pad(L, InnerWidth)])
    end, Lines),
    io:format(standard_error, "~ts~n\033[0m", [Border]).

pad(Text, Width) ->
    Text ++ lists:duplicate(Width - length(Text), $\s).

%% -- commands --

con_check(Args) ->
    Json = lists:member(?JSON_ARG, Args),
    try
        case erl_data_shift_env:load() of
            {ok, Env} ->
                case erl_data_shift_db:check_connection(Env) of
                    {ok, connected} when Json ->
                        print_json(#{<<"status">> => <<"connected">>}),
                        ok;
                    {ok, connected} ->
                        io:format("\033[32m✅ Connected to Postgres.~n\033[0m"),
                        ok;
                    {error, Reason} when Json ->
                        print_json(#{<<"status">> => <<"error">>, <<"reason">> => reason_to_binary(Reason)}),
                        error;
                    {error, Reason} ->
                        io:format("\033[31m❌ Postgres is not reachable with the following .env values:~n\033[0m"),
                        print_env_summary(Env),
                        io:format("\033[31mReason: ~p~n\033[0m", [Reason]),
                        error
                end;
            {error, Reason} when Json ->
                print_json(#{<<"status">> => <<"error">>, <<"reason">> => reason_to_binary(Reason)}),
                error;
            {error, Reason} ->
                io:format("\033[31m❌ Could not read .env: ~p (create one with PG_HOST, PG_PORT, PG_USER, PG_PASSWORD, PG_DATABASE)~n\033[0m", [Reason]),
                error
        end
    catch
        Class:Err when Json ->
            print_json(#{<<"status">> => <<"error">>, <<"reason">> => reason_to_binary({Class, Err})}),
            error;
        Class:Err ->
            io:format("\033[31m❌ Unexpected error (~p): ~p~n\033[0m", [Class, Err]),
            error
    end.

%% Prints a JSON blob to stdout (pure — no ANSI, no decoration — so CI tools
%% can pipe and parse it directly). Human-readable diagnostics like
%% print_caution/0 go to stderr instead, keeping stdout clean either way.
print_json(Map) ->
    io:format("~ts~n", [erl_data_shift_json:encode(Map)]).

%% Converts an arbitrary (possibly opaque) error reason term into a binary
%% string for JSON output — reasons can be any Erlang term, not natively
%% JSON-safe, so this is a deliberate, explicit stringification rather than
%% a generic auto-sanitizer.
reason_to_binary(Reason) ->
    iolist_to_binary(io_lib:format("~p", [Reason])).

migrate(Args) ->
    {Dir, RemainingArgs} = erl_data_shift_migrations:resolve_dir(Args),
    Force = lists:member(?FORCE_ARG, RemainingArgs),
    case {lists:member(?DOWN_ARG, RemainingArgs), lists:member(?DRY_RUN_ARG, RemainingArgs)} of
        {true, _} -> migrate_down(Dir, RemainingArgs);
        {false, true} -> migrate_dry_run(Dir, RemainingArgs);
        {false, false} -> migrate_up(Dir, Force)
    end.

migrate_dry_run(Dir, RemainingArgs) ->
    Json = lists:member(?JSON_ARG, RemainingArgs),
    try
        case erl_data_shift_env:load() of
            {error, Reason} when Json ->
                print_json(#{<<"status">> => <<"error">>, <<"reason">> => reason_to_binary(Reason)}),
                error;
            {error, Reason} ->
                io:format("\033[31m❌ Could not read .env: ~p~n\033[0m", [Reason]),
                error;
            {ok, Env} ->
                case erl_data_shift_migrator:dry_run(Env, Dir) of
                    {ok, Files} when Json ->
                        print_json(#{<<"pending">> => [list_to_binary(F) || F <- Files]}),
                        ok;
                    {ok, []} ->
                        io:format("\033[32m✅ No pending migrations — already up to date.~n\033[0m"),
                        ok;
                    {ok, Files} ->
                        io:format("Pending migrations (~B):~n", [length(Files)]),
                        lists:foreach(fun(F) -> io:format("  ~ts~n", [F]) end, Files),
                        ok;
                    {error, {directory_not_found, D}} when Json ->
                        print_json(#{<<"status">> => <<"error">>, <<"reason">> => <<"directory_not_found">>, <<"directory">> => list_to_binary(D)}),
                        error;
                    {error, {directory_not_found, Dir}} ->
                        io:format("\033[33m⚠️  Migrations directory not found: ~ts~n\033[0m", [Dir]),
                        error;
                    {error, Reason} when Json ->
                        print_json(#{<<"status">> => <<"error">>, <<"reason">> => reason_to_binary(Reason)}),
                        error;
                    {error, Reason} ->
                        io:format("\033[31m❌ Could not list pending migrations: ~p~n\033[0m", [Reason]),
                        error
                end
        end
    catch
        Class:Err when Json ->
            print_json(#{<<"status">> => <<"error">>, <<"reason">> => reason_to_binary({Class, Err})}),
            error;
        Class:Err ->
            io:format("\033[31m❌ Unexpected error (~p): ~p~n\033[0m", [Class, Err]),
            error
    end.

migrate_up(Dir, Force) ->
    case erl_data_shift_migrations:list_sql_files(Dir) of
        {error, {directory_not_found, Dir}} ->
            io:format("\033[33m⚠️  Migrations directory not found: ~ts~n\033[0m", [Dir]),
            io:format("Create it, or point to another one with: eds migrate path <dir>~n"),
            error;
        {error, Reason} ->
            io:format("\033[31m❌ Could not list migrations: ~p~n\033[0m", [Reason]),
            error;
        {ok, _Files} ->
            run_migrate(Dir, Force)
    end.

migrate_down(Dir, RemainingArgs) ->
    case parse_down_target(RemainingArgs) of
        last_only -> migrate_down_last(Dir);
        {ok, Target} -> migrate_down_to(Dir, Target);
        {error, {invalid_target_version, Bad}} ->
            io:format("\033[31m❌ Invalid target version: ~ts (expected a numeric version, e.g. eds migrate down to 0003)~n\033[0m", [Bad]),
            error
    end.

%% Parses "to <version>" or "all" out of the args following "down".
%% "all" is checked first since "to all" would otherwise be ambiguous —
%% "all" alone is the unambiguous, documented form.
parse_down_target(Args) ->
    case lists:member("all", Args) of
        true -> {ok, all};
        false ->
            case find_to_version(Args) of
                {ok, Version} ->
                    case is_numeric_version(Version) of
                        true -> {ok, Version};
                        false -> {error, {invalid_target_version, Version}}
                    end;
                none -> last_only
            end
    end.

find_to_version(["to", Version | _Rest]) -> {ok, Version};
find_to_version([_ | Rest]) -> find_to_version(Rest);
find_to_version([]) -> none.

is_numeric_version(Str) ->
    Str =/= [] andalso lists:all(fun(C) -> C >= $0 andalso C =< $9 end, Str).

migrate_down_last(Dir) ->
    try
        case erl_data_shift_env:load() of
            {error, Reason} ->
                io:format("\033[31m❌ Could not read .env: ~p~n\033[0m", [Reason]),
                error;
            {ok, Env} ->
                case erl_data_shift_migrator:rollback_last(Env, Dir) of
                    {ok, Version} ->
                        io:format("\033[32m✅ Rolled back migration ~ts.~n\033[0m", [Version]),
                        ok;
                    {error, no_applied_migrations} ->
                        io:format("\033[33m⚠️  No applied migrations to roll back.~n\033[0m"),
                        ok;
                    {error, {down_file_missing, DownFile}} ->
                        io:format("\033[31m❌ Cannot roll back: ~ts not found.~n\033[0m", [DownFile]),
                        error;
                    {error, {up_file_missing, Version}} ->
                        io:format("\033[31m❌ Cannot roll back: no local migration file found for version ~ts.~n\033[0m", [Version]),
                        error;
                    {error, {directory_not_found, Dir}} ->
                        io:format("\033[33m⚠️  Migrations directory not found: ~ts~n\033[0m", [Dir]),
                        error;
                    {error, {rollback_failed, File, Reason}} ->
                        io:format("\033[31m❌ Rollback failed for ~ts: ~p~n\033[0m", [File, Reason]),
                        error;
                    {error, Reason} ->
                        io:format("\033[31m❌ Rollback failed: ~p~n\033[0m", [Reason]),
                        error
                end
        end
    catch
        Class:Err ->
            io:format("\033[31m❌ Unexpected error (~p): ~p~n\033[0m", [Class, Err]),
            error
    end.

migrate_down_to(Dir, Target) ->
    try
        case erl_data_shift_env:load() of
            {error, Reason} ->
                io:format("\033[31m❌ Could not read .env: ~p~n\033[0m", [Reason]),
                error;
            {ok, Env} ->
                case erl_data_shift_migrator:rollback_to(Env, Dir, Target) of
                    {ok, []} ->
                        io:format("\033[32m✅ Nothing to roll back — already at or below the target.~n\033[0m"),
                        ok;
                    {ok, Versions} ->
                        io:format("\033[32m✅ Rolled back ~B migration(s):~n\033[0m", [length(Versions)]),
                        lists:foreach(fun(V) -> io:format("  ~ts~n", [V]) end, Versions),
                        ok;
                    {error, {directory_not_found, D}} ->
                        io:format("\033[33m⚠️  Migrations directory not found: ~ts~n\033[0m", [D]),
                        error;
                    {error, {{down_file_missing, DownFile}, Reverted}} ->
                        report_partial_rollback(Reverted),
                        io:format("\033[31m❌ Stopped: ~ts not found.~n\033[0m", [DownFile]),
                        error;
                    {error, {{up_file_missing, Version}, Reverted}} ->
                        report_partial_rollback(Reverted),
                        io:format("\033[31m❌ Stopped: no local migration file found for version ~ts.~n\033[0m", [Version]),
                        error;
                    {error, {{rollback_failed, File, Reason}, Reverted}} ->
                        report_partial_rollback(Reverted),
                        io:format("\033[31m❌ Stopped: rollback failed for ~ts: ~p~n\033[0m", [File, Reason]),
                        error;
                    {error, {Reason, Reverted}} ->
                        report_partial_rollback(Reverted),
                        io:format("\033[31m❌ Stopped: ~p~n\033[0m", [Reason]),
                        error;
                    {error, Reason} ->
                        io:format("\033[31m❌ Rollback failed: ~p~n\033[0m", [Reason]),
                        error
                end
        end
    catch
        Class:Err ->
            io:format("\033[31m❌ Unexpected error (~p): ~p~n\033[0m", [Class, Err]),
            error
    end.

%% On a mid-sequence failure, always show what DID succeed before the error —
%% a multi-step rollback stopping partway is a state the user needs to see
%% clearly, not have buried inside an error tuple.
report_partial_rollback([]) -> ok;
report_partial_rollback(Reverted) ->
    io:format("\033[33mSuccessfully rolled back before stopping:~n\033[0m"),
    lists:foreach(fun(V) -> io:format("  ~ts~n", [V]) end, Reverted).

run_migrate(Dir, Force) ->
    try
        case erl_data_shift_env:load() of
            {error, Reason} ->
                io:format("\033[31m❌ Could not read .env: ~p~n\033[0m", [Reason]),
                error;
            {ok, Env} ->
                io:format("Migrations directory: ~ts~n", [Dir]),
                case Force of
                    true ->
                        io:format("\033[33m⚠️  --force: skipping checksum drift check. "
                                  "This bypasses an integrity safeguard — use only if you "
                                  "understand and accept the drift.~n\033[0m");
                    false -> ok
                end,
                %% Snapshot which files are pending before the run, purely for
                %% accurate file-count/byte-size reporting in the benchmark
                %% summary below — not used for correctness (run/3 does its
                %% own independent pending calculation under the lock).
                PendingFiles = case erl_data_shift_migrator:dry_run(Env, Dir) of
                    {ok, Files} -> Files;
                    _ -> []
                end,
                ProgressFun = fun(Idx, Total, File) ->
                    Pct = case Total of 0 -> 100; _ -> (Idx - 1) * 100 div Total end,
                    io:format("[~B%] Applying ~ts (~B/~B)...~n", [Pct, File, Idx, Total])
                end,
                BenchState = erl_data_shift_bench:start(),
                RunResult = case Force of
                    true -> erl_data_shift_migrator:run(Env, Dir, ProgressFun, #{force => true});
                    false -> erl_data_shift_migrator:run(Env, Dir, ProgressFun)
                end,
                case RunResult of
                    {ok, 0} ->
                        io:format("\033[32m✅ No pending migrations — already up to date.~n\033[0m"),
                        ok;
                    {ok, Count} ->
                        io:format("\033[32m✅ Applied ~B migration(s) successfully.~n\033[0m", [Count]),
                        print_bench_summary(Count, total_bytes(Dir, PendingFiles), erl_data_shift_bench:stop(BenchState)),
                        ok;
                    {error, {migration_failed, File, Reason}} ->
                        io:format("\033[31m❌ Migration failed: ~ts~nReason: ~p~n\033[0m", [File, Reason]),
                        io:format("\033[33mStopped — earlier migrations in this run were committed, this one was rolled back.~n\033[0m"),
                        error;
                    {error, {non_transactional_statement, File, Matches}} ->
                        io:format("\033[31m❌ ~ts contains statement(s) that cannot run inside a transaction:~n\033[0m", [File]),
                        lists:foreach(fun(M) -> io:format("  ~ts~n", [M]) end, Matches),
                        io:format("Split this into its own migration file, or run it manually outside eds.~n"),
                        error;
                    {error, {checksum_drift, Mismatches}} ->
                        io:format("\033[31m❌ Refusing to migrate: the following already-applied migration(s) "
                                  "have been edited since they ran:~n\033[0m"),
                        lists:foreach(fun({Version, _}) ->
                            io:format("  ~ts~n", [Version])
                        end, Mismatches),
                        io:format("Run 'eds verify' for details, or 'eds migrate force' to override.~n"),
                        error;
                    {error, Reason} ->
                        io:format("\033[31m❌ Migration run failed: ~p~n\033[0m", [Reason]),
                        error
                end
        end
    catch
        Class:Err ->
            io:format("\033[31m❌ Unexpected error (~p): ~p~n\033[0m", [Class, Err]),
            error
    end.

total_bytes(Dir, Files) ->
    lists:sum([safe_file_size(filename:join(Dir, F)) || F <- Files]).

safe_file_size(Path) ->
    case filelib:is_regular(Path) of
        true -> filelib:file_size(Path);
        false -> 0
    end.

%% Reports file count + total SQL size (accurate) alongside Erlang VM timing
%% and memory stats. Deliberately does NOT claim an exact "SQL statements
%% executed" count — that would require a real SQL parser (naive semicolon
%% splitting breaks on strings/comments), so file-level granularity is what
%% we can honestly report.
print_bench_summary(FileCount, TotalBytes, #{wall_ms := WallMs, cpu_ms := CpuMs, mem_delta_bytes := MemDelta}) ->
    io:format("~nRan ~B migration file(s) (~ts total SQL) in ~B ms.~n",
               [FileCount, human_size(TotalBytes), WallMs]),
    MemSign = case MemDelta >= 0 of true -> "+"; false -> "-" end,
    io:format("Erlang VM CPU time: ~B ms | VM memory delta: ~ts~ts~n",
               [CpuMs, MemSign, human_size(abs(MemDelta))]).

stat(Args) ->
    Json = lists:member(?JSON_ARG, Args),
    try
        case erl_data_shift_env:load() of
            {ok, Env} ->
                case erl_data_shift_db:get_table_stats(Env) of
                    {ok, Rows} when Json -> print_stats_json(Rows), ok;
                    {ok, Rows} -> print_stats(Rows), ok;
                    {error, Reason} when Json ->
                        print_json(#{<<"status">> => <<"error">>, <<"reason">> => reason_to_binary(Reason)}),
                        error;
                    {error, Reason} ->
                        io:format("\033[31m❌ Could not fetch stats:~n\033[0m"),
                        print_env_summary(Env),
                        io:format("\033[31mReason: ~p~n\033[0m", [Reason]),
                        error
                end;
            {error, Reason} when Json ->
                print_json(#{<<"status">> => <<"error">>, <<"reason">> => reason_to_binary(Reason)}),
                error;
            {error, Reason} ->
                io:format("\033[31m❌ Could not read .env: ~p~n\033[0m", [Reason]),
                error
        end
    catch
        Class:Err when Json ->
            print_json(#{<<"status">> => <<"error">>, <<"reason">> => reason_to_binary({Class, Err})}),
            error;
        Class:Err ->
            io:format("\033[31m❌ Unexpected error (~p): ~p~n\033[0m", [Class, Err]),
            error
    end.

print_stats_json(Rows) ->
    Tables = [#{<<"name">> => Name, <<"rows">> => RowCount, <<"size_bytes">> => Bytes}
              || #{name := Name, rows := RowCount, size_bytes := Bytes} <- Rows],
    print_json(#{<<"tables">> => Tables}).

print_stats([]) ->
    io:format("No tables found.~n");
print_stats(Rows) ->
    io:format("~n~-30s ~12s ~12s~n", ["Table", "Rows", "Size"]),
    io:format("~s~n", [lists:duplicate(56, $-)]),
    lists:foreach(fun(#{name := Name, rows := RowCount, size_bytes := Bytes}) ->
        io:format("~-30ts ~12B ~12s~n", [Name, RowCount, human_size(Bytes)])
    end, Rows).

human_size(Bytes) when Bytes >= 1073741824 -> io_lib:format("~.2f GB", [Bytes / 1073741824]);
human_size(Bytes) when Bytes >= 1048576    -> io_lib:format("~.2f MB", [Bytes / 1048576]);
human_size(Bytes) when Bytes >= 1024       -> io_lib:format("~.2f KB", [Bytes / 1024]);
human_size(Bytes)                          -> io_lib:format("~B B", [Bytes]).

history() ->
    try
        case erl_data_shift_env:load() of
            {ok, Env} ->
                case erl_data_shift_db:get_migration_history(Env) of
                    {ok, {Table, Cols, Rows}} ->
                        print_history(Table, Cols, Rows),
                        print_drift_check(Cols, Rows),
                        ok;
                    {error, no_migration_table_found} ->
                        io:format("\033[33m⚠️  No known migrations table found "
                                  "(looked for schema_migrations, flyway_schema_history, "
                                  "ecto_schema_migrations, alembic_version).~n\033[0m"),
                        error;
                    {error, Reason} ->
                        io:format("\033[31m❌ Could not fetch migration history: ~p~n\033[0m", [Reason]),
                        error
                end;
            {error, Reason} ->
                io:format("\033[31m❌ Could not read .env: ~p~n\033[0m", [Reason]),
                error
        end
    catch
        Class:Err ->
            io:format("\033[31m❌ Unexpected error (~p): ~p~n\033[0m", [Class, Err]),
            error
    end.

print_history(_Table, _Cols, []) ->
    io:format("No migrations recorded yet.~n");
print_history(Table, Cols, Rows) ->
    io:format("\033[36m~n=== ~ts (~B applied) ===~n\033[0m", [Table, length(Rows)]),
    HeaderStrs = [binary_to_list(C) || C <- Cols],
    RowCells = [[format_cell(V) || V <- tuple_to_list(Row)] || Row <- Rows],
    Widths = column_widths(HeaderStrs, RowCells),
    print_row(HeaderStrs, Widths),
    io:format("~s~n", [lists:duplicate(lists:sum(Widths) + length(Widths) - 1, $-)]),
    lists:foreach(fun(Cells) -> print_row(Cells, Widths) end, RowCells).

%% Width per column = max(header length, longest cell in that column), so
%% wide content (e.g. "2026-07-10 00:54:17 (35 day(s) ago)") never overflows
%% the printed border.
column_widths(Headers, RowCells) ->
    lists:map(fun({Idx, Header}) ->
        ColValues = [lists:nth(Idx, Row) || Row <- RowCells],
        lists:max([length(lists:flatten(Header)) | [length(lists:flatten(V)) || V <- ColValues]])
    end, lists:zip(lists:seq(1, length(Headers)), Headers)).

print_row(Cells, Widths) ->
    Padded = lists:zipwith(fun(Cell, W) -> string:pad(Cell, W) end, Cells, Widths),
    io:format("~ts~n", [lists:join(" ", Padded)]).

format_cell(null) -> "NULL";
format_cell(V) when is_binary(V) -> binary_to_list(V);
format_cell(V) when is_integer(V) -> integer_to_list(V);
format_cell({{_, _, _}, {_, _, _}} = DateTime) ->
    format_datetime(DateTime) ++ " (" ++ time_ago(DateTime) ++ ")";
format_cell(V) -> io_lib:format("~p", [V]).

format_datetime({{Y, Mo, D}, {H, Mi, S}}) ->
    io_lib:format("~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B",
                   [Y, Mo, D, H, Mi, trunc(S)]).

%% Roughly formats how long ago a {{Y,M,D},{H,Mi,S}} timestamp was, tolerating
%% a fractional-seconds float (as returned for timestamptz by epgsql).
time_ago({{Y, Mo, D}, {H, Mi, S}}) ->
    IntS = trunc(S),
    Then = calendar:datetime_to_gregorian_seconds({{Y, Mo, D}, {H, Mi, IntS}}),
    Now = calendar:datetime_to_gregorian_seconds(calendar:universal_time()),
    DiffSec = max(0, Now - Then),
    format_duration(DiffSec).

format_duration(Sec) when Sec < 60 -> "just now";
format_duration(Sec) when Sec < 3600 -> io_lib:format("~B min ago", [Sec div 60]);
format_duration(Sec) when Sec < 86400 -> io_lib:format("~B hr ago", [Sec div 3600]);
format_duration(Sec) -> io_lib:format("~B day(s) ago", [Sec div 86400]).

%% Cross-references the DB's recorded migration versions against local
%% .sql files (using resolve_dir/1's default) to flag drift: files applied
%% in the DB but missing locally, or present locally but never applied.
print_drift_check(Cols, Rows) ->
    case find_version_index(Cols) of
        not_found -> ok;
        Idx ->
            DbVersions = sets:from_list([extract_leading_digits(format_cell(element(Idx, R))) || R <- Rows]),
            {Dir, _} = erl_data_shift_migrations:resolve_dir([]),
            case erl_data_shift_migrations:list_sql_files(Dir) of
                {ok, Files} ->
                    LocalVersions = sets:from_list([extract_leading_digits(F) || F <- Files]),
                    MissingLocally = lists:sort(sets:to_list(sets:subtract(DbVersions, LocalVersions))),
                    NotYetApplied = lists:sort(sets:to_list(sets:subtract(LocalVersions, DbVersions))),
                    print_drift_lines("Applied in DB but missing locally", MissingLocally),
                    print_drift_lines("Present locally but not yet applied", NotYetApplied);
                {error, _Reason} -> ok
            end
    end.

find_version_index(Cols) ->
    IndexedCols = lists:zip(lists:seq(1, length(Cols)), Cols),
    case [I || {I, C} <- IndexedCols, string:lowercase(binary_to_list(C)) =:= "version"] of
        [I | _] -> I;
        [] -> not_found
    end.

extract_leading_digits(Str) -> erl_data_shift_migrations:extract_version(Str).

print_drift_lines(_Label, []) -> ok;
print_drift_lines(Label, Items) ->
    io:format("\033[33m~ts: ~ts~n\033[0m", [Label, string:join(Items, ", ")]).

print_env_summary(Env) ->
    io:format("  PG_HOST=~ts~n", [maps:get(<<"PG_HOST">>, Env, <<>>)]),
    io:format("  PG_PORT=~ts~n", [maps:get(<<"PG_PORT">>, Env, <<>>)]),
    io:format("  PG_USER=~ts~n", [maps:get(<<"PG_USER">>, Env, <<>>)]),
    io:format("  PG_PASSWORD=****~n"),
    io:format("  PG_DATABASE=~ts~n", [maps:get(<<"PG_DATABASE">>, Env, <<>>)]).
