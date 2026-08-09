-module(erl_data_shift_env).
-export([load/0, load/1, get/2]).

%% Loads .env from the current working directory.
load() ->
    load(".env").

%% Loads a KEY=VALUE file into a map. Skips blank lines and lines starting
%% with '#'. Returns {ok, Map} or {error, Reason} if the file is missing.
-spec load(file:filename()) -> {ok, map()} | {error, term()}.
load(Path) ->
    case file:read_file(Path) of
        {ok, Bin} ->
            Lines = binary:split(Bin, <<"\n">>, [global]),
            Map = lists:foldl(fun parse_line/2, #{}, Lines),
            {ok, Map};
        {error, Reason} ->
            {error, Reason}
    end.

%% Fetches Key from an env map, returning Default if absent.
-spec get(binary(), map()) -> binary() | undefined.
get(Key, Env) ->
    maps:get(Key, Env, undefined).

%% -- internal --

parse_line(Line, Acc) ->
    Trimmed = string:trim(Line),
    case Trimmed of
        <<>> -> Acc;
        <<"#", _/binary>> -> Acc;
        _ ->
            case binary:split(Trimmed, <<"=">>) of
                [Key, Value] -> maps:put(string:trim(Key), string:trim(Value), Acc);
                _ -> Acc
            end
    end.