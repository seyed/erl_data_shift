-module(erl_data_shift_bench_tests).
-include_lib("eunit/include/eunit.hrl").

%% start/0 followed immediately by stop/1 should yield non-negative wall
%% time and a well-formed result map, without needing to mock any BIFs.
stop_after_start_returns_nonnegative_wall_ms_test() ->
    State = erl_data_shift_bench:start(),
    timer:sleep(5),
    Result = erl_data_shift_bench:stop(State),
    ?assert(maps:is_key(wall_ms, Result)),
    ?assert(maps:is_key(cpu_ms, Result)),
    ?assert(maps:is_key(mem_delta_bytes, Result)),
    ?assert(maps:get(wall_ms, Result) >= 5).

%% cpu_ms should never be negative (VM cumulative runtime counter only
%% increases).
cpu_ms_is_nonnegative_test() ->
    State = erl_data_shift_bench:start(),
    Result = erl_data_shift_bench:stop(State),
    ?assert(maps:get(cpu_ms, Result) >= 0).