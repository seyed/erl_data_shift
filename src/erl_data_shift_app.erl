-module(erl_data_shift_app).
-behaviour(application).
-export([start/2, stop/1, dispatch/1, format_duration/1, extract_leading_digits/1]).

%% Registry mapping subcommand name -> handler fun/0. Add new commands here.
-define(COMMANDS, #{
    "con_check" => fun(_Args) -> con_check() end,
    "migrate"   => fun migrate/1,
    "stat"      => fun(_Args) -> stat() end,
    "history"   => fun(_Args) -> history() end
}).

start(_StartType, _StartArgs) ->
    io:setopts(standard_io, [{encoding, unicode}]),
    print_caution(),
    Args = init:get_plain_arguments(),
    dispatch(Args),
    init:stop(0),
    {ok, self()}.

stop(_State) ->
    ok.

%% -- dispatch --

%% relx passes its own boot verb (foreground/console/start/...) through as
%% part of the plain arguments — strip any leading one before dispatching.
-define(BOOT_VERBS, ["foreground", "console", "start", "daemon"]).

dispatch([Verb | Rest]) ->
    case lists:member(Verb, ?BOOT_VERBS) of
        true -> dispatch(Rest);
        false -> run_command([Verb | Rest])
    end;
dispatch([]) ->
    print_usage("No command given.").

run_command([Cmd | Rest]) ->
    case maps:find(Cmd, ?COMMANDS) of
        {ok, Handler} -> Handler(Rest);
        error -> print_usage(io_lib:format("Unknown command: ~ts", [Cmd]))
    end.

print_usage(Message) ->
    io:format("\033[31m~ts~n\033[0m", [Message]),
    io:format("Usage: eds <command>~n"),
    io:format("Commands:~n"),
    lists:foreach(fun(Name) -> io:format("  ~ts~n", [Name]) end, maps:keys(?COMMANDS)).

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
    io:format("\033[33m~ts~n", [Border]),
    lists:foreach(fun(L) ->
        io:format("| ~ts |~n", [pad(L, InnerWidth)])
    end, Lines),
    io:format("~ts~n\033[0m", [Border]).

pad(Text, Width) ->
    Text ++ lists:duplicate(Width - length(Text), $\s).

%% -- commands --

con_check() ->
    try
        case erl_data_shift_env:load() of
            {ok, Env} ->
                case erl_data_shift_db:check_connection(Env) of
                    {ok, connected} ->
                        io:format("\033[32m✅ Connected to Postgres.~n\033[0m");
                    {error, Reason} ->
                        io:format("\033[31m❌ Postgres is not reachable with the following .env values:~n\033[0m"),
                        print_env_summary(Env),
                        io:format("\033[31mReason: ~p~n\033[0m", [Reason])
                end;
            {error, Reason} ->
                io:format("\033[31m❌ Could not read .env: ~p (create one with PG_HOST, PG_PORT, PG_USER, PG_PASSWORD, PG_DATABASE)~n\033[0m", [Reason])
        end
    catch
        Class:Err ->
            io:format("\033[31m❌ Unexpected error (~p): ~p~n\033[0m", [Class, Err])
    end.

%% Path detection + graceful error handling first — actual migration
%% execution (running pending .sql files against Postgres) lands next.
migrate(Args) ->
    {Dir, _RemainingArgs} = erl_data_shift_migrations:resolve_dir(Args),
    case erl_data_shift_migrations:list_sql_files(Dir) of
        {ok, Files} ->
            io:format("Migrations directory: ~ts~n", [Dir]),
            io:format("Found ~B .sql file(s).~n", [length(Files)]);
        {error, {directory_not_found, Dir}} ->
            io:format("\033[33m⚠️  Migrations directory not found: ~ts~n\033[0m", [Dir]),
            io:format("Create it, or point to another one with: eds migrate -f <path>~n");
        {error, Reason} ->
            io:format("\033[31m❌ Could not list migrations: ~p~n\033[0m", [Reason])
    end.

stat() ->
    try
        case erl_data_shift_env:load() of
            {ok, Env} ->
                case erl_data_shift_db:get_table_stats(Env) of
                    {ok, Rows} -> print_stats(Rows);
                    {error, Reason} ->
                        io:format("\033[31m❌ Could not fetch stats:~n\033[0m"),
                        print_env_summary(Env),
                        io:format("\033[31mReason: ~p~n\033[0m", [Reason])
                end;
            {error, Reason} ->
                io:format("\033[31m❌ Could not read .env: ~p~n\033[0m", [Reason])
        end
    catch
        Class:Err ->
            io:format("\033[31m❌ Unexpected error (~p): ~p~n\033[0m", [Class, Err])
    end.

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
                        print_drift_check(Cols, Rows);
                    {error, no_migration_table_found} ->
                        io:format("\033[33m⚠️  No known migrations table found "
                                  "(looked for schema_migrations, flyway_schema_history, "
                                  "ecto_schema_migrations, alembic_version).~n\033[0m");
                    {error, Reason} ->
                        io:format("\033[31m❌ Could not fetch migration history: ~p~n\033[0m", [Reason])
                end;
            {error, Reason} ->
                io:format("\033[31m❌ Could not read .env: ~p~n\033[0m", [Reason])
        end
    catch
        Class:Err ->
            io:format("\033[31m❌ Unexpected error (~p): ~p~n\033[0m", [Class, Err])
    end.

print_history(_Table, _Cols, []) ->
    io:format("No migrations recorded yet.~n");
print_history(Table, Cols, Rows) ->
    io:format("\033[36m~n=== ~ts (~B applied) ===~n\033[0m", [Table, length(Rows)]),
    Widths = [max(length(binary_to_list(C)), 12) || C <- Cols],
    print_row([binary_to_list(C) || C <- Cols], Widths),
    io:format("~s~n", [lists:duplicate(lists:sum(Widths) + length(Widths) - 1, $-)]),
    lists:foreach(fun(Row) ->
        Cells = [format_cell(V) || V <- tuple_to_list(Row)],
        print_row(Cells, Widths)
    end, Rows).

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
                    MissingLocally = sets:to_list(sets:subtract(DbVersions, LocalVersions)),
                    NotYetApplied = sets:to_list(sets:subtract(LocalVersions, DbVersions)),
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

extract_leading_digits(Str) when is_list(Str) ->
    case re:run(Str, "^([0-9]+)", [{capture, first, list}]) of
        {match, [Digits]} -> Digits;
        nomatch -> Str
    end.

print_drift_lines(_Label, []) -> ok;
print_drift_lines(Label, Items) ->
    io:format("\033[33m~ts: ~ts~n\033[0m", [Label, string:join(Items, ", ")]).

print_env_summary(Env) ->
    io:format("  PG_HOST=~ts~n", [maps:get(<<"PG_HOST">>, Env, <<>>)]),
    io:format("  PG_PORT=~ts~n", [maps:get(<<"PG_PORT">>, Env, <<>>)]),
    io:format("  PG_USER=~ts~n", [maps:get(<<"PG_USER">>, Env, <<>>)]),
    io:format("  PG_PASSWORD=****~n"),
    io:format("  PG_DATABASE=~ts~n", [maps:get(<<"PG_DATABASE">>, Env, <<>>)]).