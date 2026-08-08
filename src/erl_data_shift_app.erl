-module(erl_data_shift_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    io:format("\033[36m~n=== erl_data_shift v0.1.0 ===~n\033[0m"),
    io:format("The binary is running successfully.~n"),
    %% Exit cleanly after printing
    init:stop(0),
    {ok, self()}.

stop(_State) ->
    ok.   
