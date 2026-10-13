-module(erl_data_shift_init).
-export([run/1]).

-define(ENV_EXAMPLE_CONTENT,
    "PG_HOST=change-me\n"
    "PG_PORT=change-me\n"
    "PG_USER=change-me\n"
    "PG_PASSWORD=change-me\n"
    "PG_DATABASE=change-me\n").

-define(CONFIG_EXAMPLE_CONTENT,
    "%% Copy to eds.config to set persistent project defaults.\n"
    "%% CLI flags (-f/--path/path) always override these.\n"
    "[\n"
    "    {migrations_dir, \"migrations\"}\n"
    "].\n").

%% Scaffolds a migrations/ directory, .env.example, and eds.config.example
%% in TargetDir. Never overwrites existing files. Returns
%% {ok, #{created => [...], skipped => [...]}}.
-spec run(file:filename()) -> {ok, #{created := [string()], skipped := [string()]}} | {error, term()}.
run(TargetDir) ->
    MigrationsDir = filename:join(TargetDir, "migrations"),
    EnvExamplePath = filename:join(TargetDir, ".env.example"),
    ConfigExamplePath = filename:join(TargetDir, "eds.config.example"),
    case ensure_migrations_dir(MigrationsDir) of
        {error, Reason} ->
            {error, Reason};
        {ok, DirStatus} ->
            case ensure_file(EnvExamplePath, ?ENV_EXAMPLE_CONTENT) of
                {error, Reason} ->
                    {error, Reason};
                {ok, EnvStatus} ->
                    case ensure_file(ConfigExamplePath, ?CONFIG_EXAMPLE_CONTENT) of
                        {error, Reason} ->
                            {error, Reason};
                        {ok, ConfigStatus} ->
                            {Created, Skipped} = classify([
                                {"migrations/", DirStatus},
                                {".env.example", EnvStatus},
                                {"eds.config.example", ConfigStatus}
                            ]),
                            {ok, #{created => Created, skipped => Skipped}}
                    end
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

ensure_file(Path, Content) ->
    case filelib:is_regular(Path) of
        true -> {ok, skipped};
        false ->
            case file:write_file(Path, Content) of
                ok -> {ok, created};
                {error, Reason} -> {error, Reason}
            end
    end.

classify(Entries) ->
    Created = [Name || {Name, created} <- Entries],
    Skipped = [Name || {Name, skipped} <- Entries],
    {Created, Skipped}.
