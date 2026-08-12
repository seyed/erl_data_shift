-module(erl_data_shift_app).
-behaviour(application).
-export([start/2, stop/1, dispatch/1]).

%% Registry mapping subcommand name -> handler fun/0. Add new commands here.
-define(COMMANDS, #{
    "con_check" => fun(_Args) -> con_check() end,
    "migrate"   => fun migrate/1,
    "stat"      => fun(_Args) -> stat() end
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

print_env_summary(Env) ->
    io:format("  PG_HOST=~ts~n", [maps:get(<<"PG_HOST">>, Env, <<>>)]),
    io:format("  PG_PORT=~ts~n", [maps:get(<<"PG_PORT">>, Env, <<>>)]),
    io:format("  PG_USER=~ts~n", [maps:get(<<"PG_USER">>, Env, <<>>)]),
    io:format("  PG_PASSWORD=****~n"),
    io:format("  PG_DATABASE=~ts~n", [maps:get(<<"PG_DATABASE">>, Env, <<>>)]).