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
## 🎯 **Aim and Goals**
**Aim**. Cross-platform CLI for PostgreSQL migrations. 

**Goals** 
1. Builds, runs, and verifies database schemas via simple commands. 
2. Zero dependencies for the end-user. 

## Security 

<!-- CHECKSUMS-START -->
### Release v0.8.0 SHA256 Checksums

```
ca4d2b6bc1f77a0be2b12eb23d2de7f6f0810a6e212ce36e3a9ca777158f0524  eds-linux-x86_64
0c1dbd2b61ad7625bb34ea60cdf16381a6318af2ff51e752bdc6a7bc5b05d2ab  eds-macos-arm64
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
| `migrate` | Runs all pending `.sql` files from `./migrations` transactionally. |
| `migrate dry-run` | Lists pending migrations without applying them. |
| `migrate down` | Rolls back the most recently applied migration. |
| `migrate -f <path>` | Same as `migrate`, but points to a custom migrations directory. |
| `new <name>` | Scaffolds a new numbered up+down migration file pair. |
| `init` | Scaffolds `migrations/` and `.env.example` in the current directory. |
| `--version` | Prints the `eds` version. |
| `--help` / `-h` | Shows this help message. |

## 🔬Testing 

<!-- COVERAGE-START -->
### 🧪 Test Coverage — Overall: 82%

[📊 View interactive line-by-line coverage report](https://seyed.github.io/erl_data_shift/)

| Module | Coverage |
|---|---|
| ✅ erl_data_shift_migrations | 96% |
| ✅ erl_data_shift_env | 94% |
| ✅ erl_data_shift_db | 92% |
| ✅ erl_data_shift_migrator | 90% |
| ✅ erl_data_shift_scaffold | 82% |
| ✅ erl_data_shift_init | 80% |
| ⚠️ erl_data_shift_app | 71% |
<!-- COVERAGE-END -->
