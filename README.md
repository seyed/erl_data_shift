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
### Release v0.6.0 SHA256 Checksums

```
49c285b6f8ae6f15fe97c603020f399854b86fb7b6298d36480d79f4171aa492  eds-linux-x86_64
ed7d09452eea8f274420c045e45516eaecc87a8ed3dd6718cea2385b931ecfba  eds-macos-arm64
```
<!-- CHECKSUMS-END -->


## ⚠️ Disclaimer

**USE AT YOUR OWN RISK.**

This software (the "Tool") is an open-source data migration utility provided **"AS IS"**, without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement.

**User Responsibility:**
- You are solely responsible for **backing up your data** before running any migrations.
- You are solely responsible for testing this Tool in a non-production environment before using it on live data.
- The authors and contributors of this Tool **shall not be held liable** for any data loss, corruption, service downtime, or any direct, indirect, incidental, or consequential damages arising from the use or inability to use this software.

By using this Tool, you acknowledge that you have read, understood, and agreed to these terms. If you do not agree, do not use this software.   


## 🖥️ Usage Examples
Go to release and download the binary based on your OS and make it executable (`chmod +x eds`); and then use the following commands: 

1. **Connection Check**:  `eds con_check`

2. **DB Stats**:          `eds stats` 

3. **Migration History**: `eds history` **Note** It highlights inconsistencies between the target DB and your `migrations/` folder. 

4. **Migrate**: `eds migrate` **Note**: have the `migrations/` folder or point to the folder (`-f /path-to-folder`).   


## 🔬Testing 

<!-- COVERAGE-START -->
### 🧪 Test Coverage — Overall: 81%

[📊 View interactive line-by-line coverage report](https://seyed.github.io/erl_data_shift/)

| Module | Coverage |
|---|---|
| ✅ erl_data_shift_migrations | 96% |
| ✅ erl_data_shift_env | 94% |
| ✅ erl_data_shift_db | 93% |
| ✅ erl_data_shift_migrator | 89% |
| ⚠️ erl_data_shift_app | 68% |
<!-- COVERAGE-END -->



## Authors

Maintained by:  
 - [@seyed](https://github.com/seyed). For security issues, please contact: [seyed@swiftter.com]
 - You? Send a PR. 




