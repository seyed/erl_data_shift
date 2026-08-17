-module(erl_data_shift_init).
-export([run/1]).

-define(ENV_EXAMPLE_CONTENT,
    "PG_HOST=change-me\n"
    "PG_PORT=change-me\n"
    "PG_USER=change-me\n"
    "PG_PASSWORD=change-me\n"
    "PG_DATABASE=change-me\n").

%% Scaffolds a migrations/ directory and .env.example in TargetDir. Never
%% overwrites existing files. Returns {ok, #{created => [...], skipped => [...]}}.
-spec run(file:filename()) -> {ok, #{created := [string()], skipped := [string()]}} | {error, term()}.
run(TargetDir) ->
    MigrationsDir = filename:join(TargetDir, "migrations"),
    EnvExamplePath = filename:join(TargetDir, ".env.example"),
    case ensure_migrations_dir(MigrationsDir) of
        {error, Reason} ->
            {error, Reason};
        {ok, DirStatus} ->
            case ensure_env_example(EnvExamplePath) of
                {error, Reason} ->
                    {error, Reason};
                {ok, EnvStatus} ->
                    {Created, Skipped} = classify([{"migrations/", DirStatus}, {".env.example", EnvStatus}]),
                    {ok, #{created => Created, skipped => Skipped}}
            end
    end.

%% -- internal --

ensure_migrations_dir(Dir) ->
    case filelib:is_dir(Dir) of
        true -> {ok, skipped};
        false ->
            case filelib:ensure_dir(Dir ++ "/") of
                ok -> {ok, created};
                {error, Reason} -> {error, Reason}
            end
    end.

ensure_env_example(Path) ->
    case filelib:is_regular(Path) of
        true -> {ok, skipped};
        false ->
            case file:write_file(Path, ?ENV_EXAMPLE_CONTENT) of
                ok -> {ok, created};
                {error, Reason} -> {error, Reason}
            end
    end.

classify(Entries) ->
    Created = [Name || {Name, created} <- Entries],
    Skipped = [Name || {Name, skipped} <- Entries],
    {Created, Skipped}.