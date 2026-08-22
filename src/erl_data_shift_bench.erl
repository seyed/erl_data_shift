-module(erl_data_shift_bench).
-export([start/0, stop/1]).

%% Captures baseline timing/resource stats. Call immediately before the work
%% being measured.
-spec start() -> map().
start() ->
    {CpuMs, _} = erlang:statistics(runtime),
    #{
        wall_start => erlang:monotonic_time(millisecond),
        cpu_start => CpuMs,
        mem_start => erlang:memory(total)
    }.

%% Computes elapsed wall time, Erlang VM CPU time, and VM memory delta since
%% Start. These reflect the Erlang VM's own accounting, not a full OS-level
%% process profile (which would need shelling out to ps/proc, unreliable
%% across macOS/Linux) — labeled as such wherever displayed.
-spec stop(map()) -> #{wall_ms := integer(), cpu_ms := integer(), mem_delta_bytes := integer()}.
stop(#{wall_start := WallStart, cpu_start := CpuStart, mem_start := MemStart}) ->
    {CpuMsNow, _} = erlang:statistics(runtime),
    #{
        wall_ms => erlang:monotonic_time(millisecond) - WallStart,
        cpu_ms => CpuMsNow - CpuStart,
        mem_delta_bytes => erlang:memory(total) - MemStart
    }.