-module(erl_data_shift_app).
-behaviour(application).
-export([start/2, stop/1, dispatch/1]).

%% Registry mapping subcommand name -> handler fun/0. Add new commands here.
-define(COMMANDS, #{
    "con_check" => fun con_check/0,
    "migrate"   => fun migrate/0
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

run_command([Cmd | _Rest]) ->
    case maps:find(Cmd, ?COMMANDS) of
        {ok, Handler} -> Handler();
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
                        io:format("\033[31m❌ Connection failed: ~p~n\033[0m", [Reason])
                end;
            {error, Reason} ->
                io:format("\033[31m❌ Could not read .env: ~p (create one with PG_HOST, PG_PORT, PG_USER, PG_PASSWORD, PG_DATABASE)~n\033[0m", [Reason])
        end
    catch
        Class:Err ->
            io:format("\033[31m❌ Unexpected error (~p): ~p~n\033[0m", [Class, Err])
    end.

%% Placeholder for now — real step-by-step migration logic lands in a later tag.
migrate() ->
    io:format("migrate~n").