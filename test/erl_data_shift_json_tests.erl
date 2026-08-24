-module(erl_data_shift_json_tests).
-include_lib("eunit/include/eunit.hrl").

encode_simple_map_test() ->
    Result = erl_data_shift_json:encode(#{<<"status">> => <<"ok">>}),
    ?assertEqual(<<"{\"status\":\"ok\"}">>, Result).

encode_nested_list_test() ->
    Result = erl_data_shift_json:encode(#{<<"items">> => [<<"a">>, <<"b">>]}),
    ?assertEqual(<<"{\"items\":[\"a\",\"b\"]}">>, Result).

encode_numbers_and_booleans_test() ->
    Result = erl_data_shift_json:encode(#{<<"count">> => 3, <<"ok">> => true}),
    Decoded = json:decode(Result),
    ?assertEqual(#{<<"count">> => 3, <<"ok">> => true}, Decoded).

encode_returns_binary_test() ->
    Result = erl_data_shift_json:encode(#{}),
    ?assert(is_binary(Result)).