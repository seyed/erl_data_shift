-module(erl_data_shift_config).
-export([load/0, get/3]).

%% Config file name, sitting next to .env at the project root. Uses plain
%% Erlang term syntax (parsed via the OTP-native file:consult/1) rather
%% than TOML/YAML/JSON — avoids adding a parsing dependency just for this.
%% Expected content: a single top-level list of {Key, Value} pairs, e.g.
%%   [{migrations_dir, "db/migrations"}].
-define(CONFIG_FILE, "eds.config").

%% Loads eds.config from the caller's actual invocation directory (same
%% EDS_ORIGINAL_CWD mechanism used elsewhere). A missing file is NOT a
%% caller-facing error — it just means "use built-in defaults" — so callers
%% should treat {error, enoent} as an empty config, not surface it as a
%% failure.
-spec load() -> {ok, [{atom(), term()}]} | {error, term()}.
load() ->
    Path = filename:join(erl_data_shift_env:get_original_cwd(), ?CONFIG_FILE),
    case file:consult(Path) of
        {ok, [Terms]} when is_list(Terms) -> {ok, Terms};
        {ok, _Other} -> {error, {invalid_config_format, Path}};
        {error, Reason} -> {error, Reason}
    end.

%% Fetches Key from a loaded config proplist, returning Default if absent.
-spec get(atom(), [{atom(), term()}], term()) -> term().
get(Key, Config, Default) ->
    proplists:get_value(Key, Config, Default).
