-module(erl_data_shift_json).
-export([encode/1]).

%% Encodes a map/list/binary/number term to a JSON binary. Uses OTP 27's
%% built-in `json` module (json:encode/1) rather than pulling in an external
%% dependency like jsx/jiffy — keeps the standalone-binary philosophy intact
%% since json ships with the ERTS we already bundle.
%%
%% Callers are responsible for pre-converting any non-standard terms (atoms
%% other than true/false/null, tuples, opaque error reasons) into
%% binaries/maps/lists themselves before calling this — kept deliberately
%% unopinionated rather than guessing at a generic sanitization scheme.
-spec encode(term()) -> binary().
encode(Term) ->
    %% json:encode/1 returns iodata() which is efficient for I/O but
    %% inconvenient for APIs requiring a single binary blob.
    %% We force a flattening here to guarantee the spec `binary()`.
    iolist_to_binary(json:encode(Term)).