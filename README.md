# erl_data_shift (アールデータシフト)

## Table of Contents 

- [Aim & Goals](#-aim-and-goals)
- [Security](#security)
- [Disclaimer](#️-disclaimer)
- [Usage Examples](#usage-examples)
- [Code Coverage](#testing)
- [Authors](#authors)


## 🎯 **Aim and Goals**
**Aim**. Cross-platform CLI for PostgreSQL migrations. 

**Goals** 
1. Builds, runs, and verifies database schemas via simple commands. 
2. Zero dependencies for the end-user. 

## 🔓 Security 

<!-- CHECKSUMS-START -->
### 🔒 Release v0.7.0 SHA256 Checksums

```
f1f348c1e22dba9c22aa6fcf11ec2fa34a6a16b236637bd66644a5e12c85d229  eds-linux-x86_64
a848da6e37a636fd5925978ac8c0f4b1efd9432ae2e06187e85a46dda2e239f2  eds-macos-arm64
```
<!-- CHECKSUMS-END -->
 For security issues, please contact: [seyed@swiftter.com] 

## ⚠️ Disclaimer

**USE AT YOUR OWN RISK.**

This software (the "Tool") is an open-source data migration utility provided **"AS IS"**, without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement.

**User Responsibility:**
- You are solely responsible for **backing up your data** before running any migrations.
- You are solely responsible for testing this Tool in a non-production environment before using it on live data.
- The authors and contributors of this Tool **shall not be held liable** for any data loss, corruption, service downtime, or any direct, indirect, incidental, or consequential damages arising from the use or inability to use this software.

By using this Tool, you acknowledge that you have read, understood, and agreed to these terms. If you do not agree, do not use this software.   


## 🖥️ Usage 

Go to release and download the binary based on your OS and make it executable (`chmod +x eds`); and then use the following commands: 

```
Usage: eds <command>

Commands:
  con_check                Tests Postgres connectivity using your .env credentials.
  stat                     Shows table names, row counts, and storage size, largest first.
  history                  Shows applied migrations, with time-since-applied and local/DB drift check.
  migrate                  Runs all pending .sql files from ./migrations transactionally.
  migrate down             Rolls back the most recently applied migration.
  migrate -f <path>        Same as migrate, but points to a custom migrations directory.
  init                     Scaffolds migrations/ and .env.example in the current directory.
  --version                Prints the eds version.
  --help / -h              Shows this help message.
```

## 🔬Testing 

<!-- COVERAGE-START -->
### 🧪 Test Coverage — Overall: 80%

[📊 View interactive line-by-line coverage report](https://seyed.github.io/erl_data_shift/)

| Module | Coverage |
|---|---|
| ✅ erl_data_shift_migrations | 96% |
| ✅ erl_data_shift_db | 94% |
| ✅ erl_data_shift_env | 94% |
| ✅ erl_data_shift_migrator | 89% |
| ✅ erl_data_shift_scaffold | 82% |
| ✅ erl_data_shift_init | 80% |
| ⚠️ erl_data_shift_app | 65% |
<!-- COVERAGE-END -->