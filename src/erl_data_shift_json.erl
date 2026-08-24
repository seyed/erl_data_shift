-module(erl_data_shift_json).

-export([encode/1]).

-type json_term() :: integer() | float() | boolean() | null | binary() | atom() | [json_term()] | #{binary() | atom() | integer() => json_term()}.

-spec encode(json_term()) -> iodata().
encode(Term) ->
    json:encode(Term).