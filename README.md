# erl_data_shift (アールデータシフト)

--- 
## ⚠️ Disclaimer
```
╔══════════════════════════════════════════════════════════════╗
║                   USE AT YOUR OWN RISK                       ║
╚══════════════════════════════════════════════════════════════╝
```
**This software (the "Tool") is an open-source data migration utility provided "AS IS,"** without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement.

**User Responsibility:**
- You are solely responsible for **backing up your data** before running any migrations.
- You are solely responsible for testing this Tool in a non-production environment before using it on live data.
- The authors and contributors of this Tool **shall not be held liable** for any data loss, corruption, service downtime, or any direct, indirect, incidental, or consequential damages arising from the use or inability to use this software.

By using this Tool, you acknowledge that you have read, understood, and agreed to these terms. If you do not agree, do not use this software.

--- 
## 🎯 Aim and Goals
 
**Aim.** A cross-platform CLI for PostgreSQL migrations.
 
**Goals**
 
1. Build, run, and verify database schema changes via simple commands.
2. Zero dependencies for the end user.
 
## How eds compares to the heavy hitters

_eds is new — these are established, widely-adopted tools. Here's an honest look at where eds fits and where it doesn't (yet)._

**Where eds fits:** a small, dependency-free CLI for teams on Postgres who want Flyway-style safety (transactions, checksums, locking) without a JVM or a paid tier — not a fit if you need multi-database support or you're already deep in an Atlas/Flyway setup.

### Cost, data, and licensing

| | **eds** | Flyway | golang-migrate | Atlas |
|---|---|---|---|---|
| Cost | ✅ (free, no paid tier — all features included) | ⚠️ (free core, but rollback/dry-run require paid Teams/Enterprise) | ✅ (free, no paid tier) | ⚠️ (free CLI, but advanced features gated behind paid Atlas Cloud) |
| Usage data collection | ✅ (none — eds sends nothing anywhere) | ⚠️ (telemetry on by default, opt-out via env var — [Redgate docs](https://documentation.red-gate.com/fd/redgate-disable-telemetry-environment-variable-277579301.html)) | ✅ (no telemetry found in their docs/repo) | ⚠️ (telemetry on by default — commands run, OS, hostname — opt-out via env var — [Atlas's own privacy docs](https://atlasgo.io/cli/data-privacy)) |
| License | MIT | Community free / Teams paid | MIT | Apache 2.0 (paid cloud features) |

### Features and maturity

| | **eds** | Flyway | golang-migrate | Atlas |
|---|---|---|---|---|
| Runtime dependency | ✅ (none — single binary, bundles ERTS) | ❌ (needs a JVM, or their CLI which bundles one) | ✅ (none — single Go binary) | ✅ (none — single Go binary) |
| Database support | ❌ (PostgreSQL only) | ✅ (PostgreSQL, MySQL, Oracle, and more) | ✅ (many) | ✅ (many) |
| Transactional migrations | ✅ (per-file) | ✅ | ⚠️ (driver-dependent) | ✅ |
| Rollback | ✅ (`migrate down`, hand-written `.down.sql`) | ❌ (Teams/Enterprise tier only) | ✅ (hand-written down scripts) | ✅ (auto-computed reverse diff) |
| Checksum drift detection | ✅ (blocks by default) | ✅ | ❌ | ✅ (via lint) |
| Concurrency lock | ✅ (Postgres advisory lock) | ✅ | ⚠️ (driver-dependent) | ✅ |
| Dry-run / preview | ✅ | ❌ (Enterprise only) | ❌ | ✅ (`migrate lint`) |
| JSON output for CI | ✅ | ⚠️ (limited) | ❌ | ✅ |
| Approx. binary/download size | ~40–60 MB* (bundles Erlang runtime) | ~100+ MB (bundles a JRE) | ~10–20 MB (native Go binary) | ~15–25 MB (native Go binary) |
| Maturity | ❌ (new) | ✅ (10+ years, widely adopted) | ✅ (10+ years, widely adopted) | ⚠️ (newer, growing fast) |

\* Size figures are approximate and change between releases — check `ls -lh` on your own downloaded `eds` binary and each tool's latest release page for exact current numbers rather than relying on this table.  

## Security 

<!-- CHECKSUMS-START -->
### 🔒 Release v0.8.7 SHA256 Checksums

```
d24e8b4283282a47b06e06867ba8a0b255b65fe52c09dc6ea3946f75202e543b  eds-linux-x86_64
fa6c68e22308223f3df47d26b814f7a96c57f2a78d86e94840365819c2fc1142  eds-macos-arm64
```
<!-- CHECKSUMS-END -->
 For security issues, please contact: [seyed@swiftter.com] 




## 🖥️ Usage

**Install:**
```bash
curl -fsSL https://raw.githubusercontent.com/seyed/erl_data_shift/main/scripts/install.sh | bash
```

Or download manually: grab the binary for your OS from [Releases](../../releases), then `chmod +x eds`.

**Setup:**
```bash
eds init          # scaffolds migrations/ and .env.example in the current directory
# edit .env.example, fill in real Postgres values, save as .env
```

## Commands

| Command | Description |
|---|---|
| `con_check` | Tests Postgres connectivity using your `.env` credentials. |
| `stat` | Shows table names, row counts, and storage size, largest first. |
| `history` | Shows applied migrations — time-since-applied, who applied/reverted each, and local/DB drift check. |
| `migrate` | Runs all pending `.sql` files from `./migrations` transactionally. Refuses if an already-applied migration was edited (checksum drift).|
| `migrate force`| Same as migrate, but bypasses the checksum drift check. Use deliberately, not by default. | 
| `migrate dry-run` | Lists pending migrations without applying them. |
| `migrate down` | Rolls back the most recently applied migration. |
| `migrate -f <path>` | Same as `migrate`, but points to a custom migrations directory. |
| `new <name>` | Scaffolds a new numbered up+down migration file pair. |
| `validate`| Test-runs pending migrations in a rolled-back transaction to catch errors early. | 
| `verify`| Checks that applied migration files haven't been edited since they ran (checksum drift).| 
| `init` | Scaffolds `migrations/` and `.env.example` in the current directory. |
| `--version` | Prints the `eds` version. |
| `--help` / `-h` | Shows this help message. |

## 🔬Testing 

<!-- COVERAGE-START -->
### 🧪 Test Coverage — Overall: 92%

[📊 View interactive line-by-line coverage report](https://seyed.github.io/erl_data_shift/)

| Module | Coverage |
|---|---|
| ✅ erl_data_shift_bench | 100% |
| ✅ erl_data_shift_json | 100% |
| ✅ erl_data_shift_migrations | 96% |
| ✅ erl_data_shift_env | 94% |
| ✅ erl_data_shift_app | 93% |
| ✅ erl_data_shift_db | 93% |
| ✅ erl_data_shift_migrator | 92% |
| ✅ erl_data_shift_scaffold | 82% |
| ✅ erl_data_shift_init | 80% |
<!-- COVERAGE-END -->

