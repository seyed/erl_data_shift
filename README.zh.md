```
▓█████ ▓█████▄   ██████ 
▓█   ▀ ▒██▀ ██▌▒██    ▒ 
▒███   ░██   █▌░ ▓██▄   
▒▓█  ▄ ░▓█▄   ▌  ▒   ██▒
░▒████▒░▒████▓ ▒██████▒▒
░░ ▒░ ░ ▒▒▓  ▒ ▒ ▒▓▒ ▒ ░
 ░ ░  ░ ░ ▒  ▒ ░ ░▒  ░ ░
   ░    ░ ░  ░ ░  ░  ░  
   ░  ░   ░          ░  
        ░   
```
🇨🇳 中文* | [🇬🇧 English](README.md) | [🇯🇵 日本語](README.ja.md) | [🇮🇱 עברית](README.he.md) | [🇸🇦 العربية](README.ar.md) | [🇫🇷 Français](README.fr.md) | [🇩🇪 Deutsch](README.de.md) | [🇳🇴 Norsk](README.no.md) | [🇸🇪 Svenska](README.sv.md) | [🇹🇷 Türkçe](README.tr.md) | [🇲🇾 Bahasa Melayu](README.ms.md) | [🇮🇩 Bahasa Indonesia](README.id.md) | [🇪🇸 Español](README.es.md)   

**独立的 Postgres 迁移命令行工具** 

[![CI](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml/badge.svg)](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml)
[![Sous licence MIT](https://img.shields.io/github/license/seyed/erl_data_shift)](LICENSE)
[![Dernière version](https://img.shields.io/github/v/release/seyed/erl_data_shift)](https://github.com/seyed/erl_data_shift/releases)
![macOS](https://img.shields.io/badge/macOS-supported-success)
![Linux](https://img.shields.io/badge/Linux-supported-success)
![Windows](https://img.shields.io/badge/Windows-supported-success)
![Erlang/OTP](https://img.shields.io/badge/OTP-27%2B-blue)
![Les PR sont les bienvenues](https://img.shields.io/badge/PRs-welcome-brightgreen)

* 请注意，本文档为机器翻译。如果您以该语言为母语，请通过 pull request 提交您的 README 版本。


⚠️ 免责声明
```
╔══════════════════════════════════════════════════════════════╗
║                   使用风险自负                                 ║
╚══════════════════════════════════════════════════════════════╝
```
本软件（以下简称"该工具"）是一款开源数据迁移工具，按"原样"提供，不附带任何形式的明示或暗示担保，包括但不限于对适销性、特定用途适用性和不侵权的担保。

用户责任：

*   在运行任何迁移之前，您有责任自行备份数据。
*   在将本工具用于生产环境数据之前，您有责任自行在非生产环境中对其进行测试。
*   由于使用或无法使用本软件而引起的任何数据丢失、数据损坏、服务中断，或任何直接、间接、附带或后果性损害，本工具的作者和贡献者概不承担责任。
*   使用本工具即表示您已阅读、理解并同意这些条款。如果您不同意，请勿使用本软件。   


## 🎯 目标

**目的。** 一个用于 PostgreSQL 迁移的跨平台 CLI 工具。

**目标：**

*   通过简单命令构建、运行和验证数据库架构变更。
*   终端用户零依赖。   

-- 
## eds 与主流工具的对比

_eds 是一个新工具 — 以下这些是已经成熟且被广泛采用的工具。这里诚实地看看 eds 适合什么场景，以及（目前）还不适合什么。_

**eds 适合的场景：** 一个轻量、零依赖的 CLI，面向使用 PostgreSQL 的团队，想要 Flyway 级别的安全性（事务、校验和、锁）但不需要 JVM 或付费套餐 — 如果你需要多数据库支持、已经深度使用 Atlas/Flyway、或者正在构建 Elixir 应用（Ecto 是自然选择），则不适合。

### 成本、数据收集与许可证

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| 成本 | ✅（免费，无付费套餐 — 所有功能均包含） | ⚠️（核心免费，但回滚/干运行需要付费的 Teams/Enterprise） | ✅（免费，无付费套餐） | ⚠️（CLI 免费，但高级功能在付费的 Atlas Cloud 后面） | ✅（免费，无付费套餐） |
| 使用数据收集 | ✅（无 — eds 不向任何地方发送任何数据） | ⚠️（遥测默认开启，可通过环境变量关闭 — [Redgate 文档](https://documentation.red-gate.com/fd/redgate-disable-telemetry-environment-variable-277579301.html)） | ✅（其文档/仓库中未发现遥测） | ⚠️（遥测默认开启 — 执行的命令、操作系统、主机名 — 可通过环境变量关闭 — [Atlas 隐私文档](https://atlasgo.io/cli/data-privacy)） | ✅（未发现遥测。Elixir 的 `:telemetry` 库是本地 instrumentation/hooks，不是向外发送数据的分析） |
| 许可证 | MIT | 社区免费 / Teams 付费 | MIT | Apache 2.0（付费云功能） | Apache 2.0 |

### 功能与成熟度

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| 运行时依赖 | ✅（无 — 单一二进制文件，内嵌 ERTS） | ❌（需要 JVM，或其 CLI 内嵌 JVM） | ✅（无 — 单一 Go 二进制文件） | ✅（无 — 单一 Go 二进制文件） | ❌（需要安装 Elixir + Erlang/OTP + Mix — 是库，不是独立二进制文件） |
| 数据库支持 | ❌（仅 PostgreSQL） | ✅（PostgreSQL、MySQL、Oracle 等） | ✅（多种） | ✅（多种） | ✅（PostgreSQL、MySQL、SQLite、MSSQL 等，通过适配器） |
| 事务性迁移 | ✅（按文件） | ✅ | ⚠️（取决于驱动） | ✅ | ✅ |
| 回滚 | ✅（`migrate down`，手写 `.down.sql`） | ❌（仅 Teams/Enterprise） | ✅（手写 down 脚本） | ✅（自动计算反向 diff） | ✅（`mix ecto.rollback`，手写 `down`/`change`） |
| 校验和漂移检测 | ✅（默认阻止） | ✅ | ❌ | ✅（通过 lint） | ❌（Ecto 核心中未发现） |
| 并发锁 | ✅（Postgres advisory lock，始终开启） | ✅ | ⚠️（取决于驱动） | ✅ | ⚠️（默认 table lock；advisory lock 可用但需配置） |
| 干运行 / 预览 | ✅ | ❌（仅 Enterprise） | ❌ | ✅（`migrate lint`） | ⚠️（`mix ecto.migrations` 显示待执行状态，非真正的 SQL 预览） |
| CI 用 JSON 输出 | ✅ | ⚠️（有限） | ❌ | ✅ | ❌（标准 Mix task 输出为文本） |
| 大致二进制/下载大小 | ~40–60 MB*（内嵌 Erlang 运行时） | ~100+ MB（内嵌 JRE） | ~10–20 MB（原生 Go 二进制文件） | ~15–25 MB（原生 Go 二进制文件） | N/A（库，非分发的二进制文件） |
| 成熟度 | ❌（新） | ✅（10+ 年，广泛采用） | ✅（10+ 年，广泛采用） | ⚠️（较新，增长迅速） | ✅（2015 年起 Elixir/Phoenix 生态核心） |

\* 大小数字为近似值，各版本之间会变化 — 请用 `ls -lh` 检查你下载的 `eds` 二进制文件，并查看各工具最新 release 页面获取当前精确数字。   
-- 
<!-- CHECKSUMS-START -->
### 🔒 发布 v0.8.9 的 SHA256 校验和

```
da04b5dcd5a146f4231e99e429335c7f82ac39e2e3a9e05abff7578222ed8729  eds-linux-x86_64
4940f53560beac56cca6aa454caf1ef8911b891e44678b13ac4ce3e748aad7a0  eds-macos-arm64
8e95964c4595df3aa2b52571aab5f64248a82eaf8798e37fa7765456332b04cc  eds-windows-x86_64
```
<!-- CHECKSUMS-END -->
如有安全问题，请联系：seyed@swiftter.com 


## 🖥️ 用法

**安装：**
```bash
curl -fsSL https://raw.githubusercontent.com/seyed/erl_data_shift/main/scripts/install.sh | bash
```

或手动下载：从 Releases 获取对应操作系统的二进制文件，然后执行 chmod +x eds。


**配置**：
```bash
eds init          # 在当前目录生成 migrations/ 和 .env.example
# 编辑 .env.example，填入真实的 Postgres 值，保存为 .env
```
## 命令

| 命令 | 说明 |
|---|---|
| `con_check` | 使用 `.env` 中的凭据测试 Postgres 连接。 |
| `stat` | 显示表名、行数和存储大小，按大小降序排列。 |
| `history` | 显示已应用的迁移——应用时间、谁应用/回滚了每条迁移，以及本地/数据库漂移检查。 |
| `migrate` | 以事务方式运行 `./migrations` 中所有待执行的 `.sql` 文件。如果已应用的迁移被编辑过（校验和漂移），则拒绝执行。 |
| `migrate force` | 与 migrate 相同，但绕过校验和漂移检查。请有意使用，而非默认使用。 |
| `migrate dry-run` | 列出待执行的迁移但不应用。 |
| `migrate down` | 回滚最近一次应用的迁移。 |
| `migrate -f <path>` | 与 `migrate` 相同，但指向自定义迁移目录。 |
| `new <name>` | 生成一对带编号的 up+down 迁移文件。 |
| `validate` | 在回滚事务中试跑待执行的迁移，以尽早发现错误。 |
| `verify` | 检查已应用的迁移文件自运行以来是否被编辑过（校验和漂移）。 |
| `init` | 在当前目录生成 `migrations/` 和 `.env.example`。 |
| `--version` | 打印 `eds` 版本号。 |
| `--help` / `-h` | 显示此帮助信息。 |

## 🔬 测试   

<!-- COVERAGE-START -->
### 🧪 测试覆盖率 — 总计: 92%

[📊 查看交互式逐行覆盖率报告](https://seyed.github.io/erl_data_shift/)

| 模块 | 覆盖率 |
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
