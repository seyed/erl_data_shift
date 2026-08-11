-module(erl_data_shift_db).
-export([check_connection/1]).

%% Attempts a Postgres connection using PG_* keys from the given env map.
%% Returns {ok, connected} or {error, Reason}.
-spec check_connection(map()) -> {ok, connected} | {error, term()}.
check_connection(Env) ->
    Required = [<<"PG_HOST">>, <<"PG_PORT">>, <<"PG_USER">>, <<"PG_PASSWORD">>, <<"PG_DATABASE">>],
    Missing = [K || K <- Required, erl_data_shift_env:get(K, Env) =:= undefined],
    case Missing of
        [] -> do_connect(Env);
        _  -> {error, {missing_config, Missing}}
    end.

%% -- internal --

do_connect(Env) ->
    Host = binary_to_list(erl_data_shift_env:get(<<"PG_HOST">>, Env)),
    PortStr = binary_to_list(erl_data_shift_env:get(<<"PG_PORT">>, Env)),
    User = binary_to_list(erl_data_shift_env:get(<<"PG_USER">>, Env)),
    Pass = binary_to_list(erl_data_shift_env:get(<<"PG_PASSWORD">>, Env)),
    Db   = binary_to_list(erl_data_shift_env:get(<<"PG_DATABASE">>, Env)),

    case string:to_integer(PortStr) of
        {Port, ""} -> connect(Host, Port, User, Pass, Db);
        _ -> {error, {invalid_port, PortStr}}
    end.

connect(Host, Port, User, Pass, Db) ->
    %% epgsql:connect can crash a linked process on refused/failed connections
    %% rather than always returning {error, Reason} — isolate it in a
    %% monitored process so failures never propagate and kill our caller.
    {Pid, Ref} = spawn_monitor(fun() ->
        Result = epgsql:connect(#{
            host => Host, port => Port, username => User,
            password => Pass, database => Db, timeout => 5000
        }),
        case Result of
            {ok, Conn} -> epgsql:close(Conn), exit({eds_result, {ok, connected}});
            {error, Reason} -> exit({eds_result, {error, Reason}})
        end
    end),
    receive
        {'DOWN', Ref, process, Pid, {eds_result, Result}} -> Result;
        {'DOWN', Ref, process, Pid, Reason} -> {error, Reason}
    after 6000 ->
        {error, timeout}
    end.