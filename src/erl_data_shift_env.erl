-module(erl_data_shift_env).
-export([load/0
         , load/1
         , get/2
         , get_original_cwd/0]).

%% The directory the user actually invoked eds from. relx's launcher cd's
%% into the release root before starting the VM, so the wrapper script
%% exports EDS_ORIGINAL_CWD before exec — fall back to "." if unset (e.g.
%% when running via `rebar3 shell` in dev, where no cd happens).
get_original_cwd() ->
    case os:getenv("EDS_ORIGINAL_CWD") of
        false -> ".";
        Dir -> Dir
    end.

%% Loads .env from the directory the user actually invoked the binary from.
%% relx's launcher script cd's into the release root before starting the VM,
%% so plain "." would resolve to the wrong place — get_original_cwd/0 finds
%% the real invocation directory via EDS_ORIGINAL_CWD (set by the wrapper).
load() ->
    load(filename:join(get_original_cwd(), ".env")).

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