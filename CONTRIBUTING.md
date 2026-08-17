# Contributing to erl_data_shift

Thank you for considering a contribution.

## Getting started
1. Read README and understand the tool's aim and goals and available commands.  
2. Fork and clone the repo.
3. Run `rebar3 eunit` to confirm tests pass before you start.
4. Copy `.env.example` to `.env` and fill in real Postgres credentials for local testing (or run `eds init` after building).

## Making changes

- Keep modules modular — one responsibility per module (see `erl_data_shift_db.erl`, `erl_data_shift_migrations.erl`, `erl_data_shift_migrator.erl` for the current split).
- Every new function should have a corresponding EUnit test. PRs without test coverage for new logic will be asked to add it.
- Run `rebar3 as prod release` locally (or `./scripts/release/build_mac.sh` / `build_linux.sh`) to confirm the packaged binary still builds before submitting.
- Keep commit messages scoped per file/concern where practical (see recent commit history for the convention used).

## Submitting a PR

1. Ensure `rebar3 eunit` passes.
2. Open a PR against `main` with a clear description of what changed and why.
3. CI will run tests automatically; releases are cut from version tags (`vX.Y.Z`) by maintainers.

## Reporting bugs / requesting features

Use the issue templates under `.github/ISSUE_TEMPLATE/`.