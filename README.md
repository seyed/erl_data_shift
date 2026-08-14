# erl_data_shift (アールデータシフト)


## 🎯 <b>Aim and Goals</b>
<b>Aim</b>. Cross-platform CLI for PostgreSQL migrations. 

<b>Goal #1</b>: 
Builds, runs, and verifies database schemas via simple commands. 

<b>Goal #2</b>: 
Zero dependencies for the end-user. 

## How to use it 
Go to release and download the binary based on your OS and make it executable (`chmod +x eds`); and then use the following commands: 

1. **Connection Check**:  `eds con_check`

2. **DB Stats**:          `eds stats` 

3. **Migration History**: `eds history` **Note** It highlights inconsistencies between the target DB and your `migrations/` folder. 

4. **Migrate**: `eds migrate` **Note**: have the `migrations/` folder or point to the folder (`-f /path-to-folder`).   


## Security 
<!-- CHECKSUMS-START -->
### 🔒 Release v0.3.5 SHA256 Checksums

```
b309d8f92b4eefe560ebf99204b3e05c86d911157c71521dbdcf987db2d2e4ea  eds-linux-x86_64
291d96f586abc741a254c6008b0e922f7d2731edb91e09677a8dc865821d98ef  eds-macos-arm64
```
<!-- CHECKSUMS-END -->

## Authors

Maintained by:  
 - [@seyed](https://github.com/seyed). For security issues, please contact: [seyed@swiftter.com]
 - You? Send a PR! 

## ⚠️ Disclaimer

**USE AT YOUR OWN RISK.**

This software (the "Tool") is an open-source data migration utility provided **"AS IS"**, without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement.

**User Responsibility:**
- You are solely responsible for **backing up your data** before running any migrations.
- You are solely responsible for testing this Tool in a non-production environment before using it on live data.
- The authors and contributors of this Tool **shall not be held liable** for any data loss, corruption, service downtime, or any direct, indirect, incidental, or consequential damages arising from the use or inability to use this software.

By using this Tool, you acknowledge that you have read, understood, and agreed to these terms. If you do not agree, do not use this software.   

--- 

<!-- COVERAGE-START -->
### 🧪 Test Coverage — Overall: 53%

| Module | Coverage |
|---|---|
| ✅ erl_data_shift_db | 95% |
| ✅ erl_data_shift_env | 94% |
| ✅ erl_data_shift_migrations | 84% |
| ❌ erl_data_shift_app | 27% |
<!-- COVERAGE-END -->



