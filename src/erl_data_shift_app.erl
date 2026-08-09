-module(erl_data_shift_app).
-behaviour(application).
-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    io:format("\033[36m~n=== erl_data_shift v0.1.0 ===~n\033[0m"),
    menu_loop(),
    init:stop(0),
    {ok, self()}.

stop(_State) ->
    ok.

%% -- menu --

menu_loop() ->
    io:format("~n1) Test Postgres connectivity (via .env)~n"),
    io:format("2) Exit~n"),
    Choice = string:trim(io:get_line("Choice: ")),
    case Choice of
        "1" -> test_connectivity(), menu_loop();
        "2" -> io:format("Bye.~n");
        _   -> io:format("Invalid choice.~n"), menu_loop()
    end.

test_connectivity() ->
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