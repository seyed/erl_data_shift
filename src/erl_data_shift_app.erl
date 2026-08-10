-module(erl_data_shift_app).
-behaviour(application).
-export([start/2, stop/1, dispatch/1]).

%% Registry mapping subcommand name -> handler fun/0. Add new commands here.
-define(COMMANDS, #{
    "con_check" => fun con_check/0,
    "migrate"   => fun migrate/0
}).

start(_StartType, _StartArgs) ->
    print_caution(),
    Args = init:get_plain_arguments(),
    dispatch(Args),
    init:stop(0),
    {ok, self()}.

stop(_State) ->
    ok.

%% -- dispatch --
dispatch([Cmd | _Rest]) ->
    case maps:find(Cmd, ?COMMANDS) of
        {ok, Handler} -> Handler();
        error -> print_usage(io_lib:format("Unknown command: ~s", [Cmd]))
    end;
dispatch([]) ->
    print_usage("No command given.").

print_usage(Message) ->
    io:format("\033[31m~s~n\033[0m", [Message]),
    io:format("Usage: eds <command>~n"),
    io:format("Commands:~n"),
    lists:foreach(fun(Name) -> io:format("  ~s~n", [Name]) end, maps:keys(?COMMANDS)).

print_caution() ->
    io:format("\033[33mCAUTION: You are responsible for any actions taken by this tool. "
              "We accept no liability for data loss — back up your data before proceeding.~n\033[0m").

%% -- commands --
con_check() ->
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
    end.

%% Placeholder for now — real step-by-step migration logic lands in a later tag.
migrate() ->
    io:format("migrate~n").