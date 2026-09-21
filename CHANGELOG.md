# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Nothing yet.


[0.9.2]
Fixed
Every command now returns a real exit code (0 for success, 1 for failure) — previously the VM always exited 0 regardless of the actual outcome, silently undermining CI/scripting use of this tool.

---

## Pre-0.9.1 releases

> Everything below shipped across 36 tagged releases before this changelog
> existed. Rather than reconstruct exact per-tag history after the fact,
> this is a single summary of what's in the codebase as of v0.9.1. From
> here on, new entries go under [Unreleased] above, one version at a time.

### Added
- `eds init`, `eds new <name>` — scaffold `migrations/`, `.env.example`, and numbered up+down migration file pairs.
- `eds con_check`, `eds stat`, `eds history` — connectivity check, table stats, and migration history with drift detection.
- `eds migrate`, `eds migrate down`, `eds migrate dry-run` — transactional migration apply/rollback/preview.
- `eds migrate down to <version>` / `eds migrate down all` — target-version and full rollback.
- `eds migrate force` — explicit override to bypass checksum drift enforcement.
- `eds validate` — test-runs pending migrations in a rolled-back transaction, no persistence.
- `eds verify` — detects drift between applied migrations and their local files via SHA256 checksum.
- Checksum drift enforcement — `migrate` refuses to proceed if an already-applied migration was edited.
- Detection of non-transactional SQL statements (e.g. `CREATE INDEX CONCURRENTLY`) before they'd otherwise fail confusingly inside a transaction.
- Postgres advisory lock — prevents concurrent `migrate`/`migrate down` runs against the same database.
- `applied_by` and revert tracking in `schema_migrations` (reverts are marked, not deleted, preserving history).
- `--json` output mode for `con_check`, `stat`, `validate`, `verify`, and `migrate dry-run`.
- Always-on migration benchmarking (file count, SQL size, wall time, Erlang VM CPU/memory).
- `PG_SSLMODE` support (`disable`/`require`/`verify-ca`/`verify-full`).
- Standalone single-file binaries for macOS, Linux, and Windows — no runtime install required.
- Shell completions (bash, zsh, fish) and a man page (`eds.1`).
- Standalone installer scripts (`install.sh`, `install.ps1`) and a Homebrew tap.
- CI: automated test coverage reporting (GitHub Pages), per-release SHA256 checksums, PR coverage comments, and a real-Postgres integration test suite.

### Fixed
- CLI argument parsing (`resolve_dir`) was silently dropping tokens preceding `-f`/`--path`, breaking `migrate down -f <path>` and `migrate dry-run -f <path>`. Added a dash-free `path` keyword as the more robust alternative.
- `--version`/`--help`/`-h` were being swallowed by the Erlang VM's own argument parser before reaching the app; now translated to dash-free equivalents in the release wrapper scripts.
- `schema_migrations` NULL values (`n_live_tup`, etc.) previously caused arithmetic crashes in `stat`; now sanitized.

### Security
- No usage telemetry is collected or transmitted by this tool.
