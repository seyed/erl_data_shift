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

🇯🇵 日本語*  | [🇬🇧 English](README.md) | [🇨🇳 中文](README.zh.md) | [🇮🇱 עברית](README.he.md) | [🇸🇦 العربية](README.ar.md) | [🇫🇷 Français](README.fr.md) | [🇩🇪 Deutsch](README.de.md) | [🇳🇴 Norsk](README.no.md) | [🇸🇪 Svenska](README.sv.md) | [🇹🇷 Türkçe](README.tr.md) | [🇲🇾 Bahasa Melayu](README.ms.md) | [🇮🇩 Bahasa Indonesia](README.id.md) | [🇪🇸 Español](README.es.md)   

**スタンドアロンの Postgres マイグレーション CLI**

[![CI](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml/badge.svg)](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/github/license/seyed/erl_data_shift)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/seyed/erl_data_shift)](https://github.com/seyed/erl_data_shift/releases)
![macOS](https://img.shields.io/badge/macOS-supported-success)
![Linux](https://img.shields.io/badge/Linux-supported-success)
![Windows](https://img.shields.io/badge/Windows-supported-success)
![Erlang/OTP](https://img.shields.io/badge/OTP-27%2B-blue)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)

* この文書は機械翻訳によるものであることに注意してください。この言語が母語である場合は、README のバージョンを Pull Request として送信してください。


⚠️ 免責事項
```
╔══════════════════════════════════════════════════════════════╗
║                   利用者の責任において使用してください             ║
╚══════════════════════════════════════════════════════════════╝
``` 
本ソフトウェア（以下「本ツール」といいます）は、オープンソースのデータ移行ユーティリティであり、「現状のまま」提供されます。黙示的保証の一切を含むいかなる明示的または黙示的な保証（売買適性、特定目的への適合性、非侵害性の保証を含むがこれらに限定されない）は一切付随しません。

ユーザーの責任：

*   いかなる移行を実行する前に、データのバックアップを行う責任はすべてユーザーにあります。
*   本ツールを生産環境のデータに使用する前に、非生産環境でテストを行う責任はすべてユーザーにあります。
*   本ソフトウェアの使用または使用不能に起因するいかなるデータ損失、データ破損、サービス停止、または直接・間接・付随的・結果的損害についても、本ツールの著者および貢献者は一切責任を負いません。
*   本ツールを使用することにより、これらの条項を読み、理解し、同意したものとみなされます。同意されない場合は、本ソフトウェアを使用しないでください。

---

## 🎯 目的と目標

**目的。** PostgreSQL 移行用のクロスプラットフォーム CLI ツール。

**目標：**

*   シンプルなコマンドでデータベーススキーマの変更をビルド、実行、検証する。
*   エンドユーザーへの依存関係ゼロ。

---

## 主要ツールとの比較

_eds は新しいうちです——これらは成熟し、広く採用されているツールです。eds がどこに位置し、（まだ）どこに適合しないかの率直な評価です。_

**eds の適した場面：** 小型で依存関係のない CLI。Postgres を使用するチームが、JVM や有料プランなしで Flyway 同等の安全性（トランザクション、チェックサム、ロック）を確保したい場合に適します。マルチデータベース対応が必要이거나、すでに Atlas/Flyway に深く組み込んでいる場合は適しません。

| | **eds** | Flyway | golang-migrate | Atlas |
|---|---|---|---|---|
| 費用 | ✅（無料、有料プランなし——全機能込み） | ⚠️（コア無料、ただしロールバック/ドライランは有料の Teams/Enterprise が必要） | ✅（無料、有料プランなし） | ⚠️（CLI 無料、ただし高度な機能は有料の Atlas Cloud が必要） |
| 使用データ収集 | ✅（なし——eds はどこにもデータを送信しない） | ⚠️（テレメトリはデフォルトで有効、環境変数で無効化可能——[Redgate ドキュメント](https://documentation.red-gate.com/fd/redgate-disable-telemetry-environment-variable-277579301.html)） | ✅（ドキュメント/リポジトリにテレメトリの記載なし） | ⚠️（テレメトリはデフォルトで有効——実行コマンド、OS、ホスト名——環境変数で無効化可能——[Atlas 公式プライバシードキュメント](https://atlasgo.io/cli/data-privacy)） |
| ライセンス | MIT | コミュニティ無料 / Teams 有料 | MIT | Apache 2.0（クラウド機能は有料） |

### 機能と成熟度

| | **eds** | Flyway | golang-migrate | Atlas |
|---|---|---|---|---|
| ランタイム依存 | ✅（なし——単一バイナリ、ERTS を同梱） | ❌（JVM が必要、または同梱 CLI） | ✅（なし——単一 Go バイナリ） | ✅（なし——単一 Go バイナリ） |
| データベース対応 | ❌（PostgreSQL のみ） | ✅（PostgreSQL、MySQL、Oracle など） | ✅（多数） | ✅（多数） |
| トランザクション付き移行 | ✅（ファイル単位） | ✅ | ⚠️（ドライバー依存） | ✅ |
| ロールバック | ✅（`migrate down`、手書きの `.down.sql`） | ❌（Teams/Enterprise のみ） | ✅（手書きの down スクリプト） | ✅（自動計算の逆方向 diff） |
| チェックサムドリフト検出 | ✅（デフォルトでブロック） | ✅ | ❌ | ✅（lint 経由） |
| 並行ロック | ✅（Postgres アドバイザリロック） | ✅ | ⚠️（ドライバー依存） | ✅ |
| ドライラン / プレビュー | ✅ | ❌（Enterprise のみ） | ❌ | ✅（`migrate lint`） |
| CI 用 JSON 出力 | ✅ | ⚠️（限定的） | ❌ | ✅ |
| バイナリ/ダウンロードサイズ（概算） | ~40–60 MB*（Erlang ランタイム同梱） | ~100+ MB（JRE 同梱） | ~10–20 MB（ネイティブ Go バイナリ） | ~15–25 MB（ネイティブ Go バイナリ） |
| 成熟度 | ❌（新設） | ✅（10 年以上、広く採用） | ✅（10 年以上、広く採用） | ⚠️（比較的新しい、急成長中） |

\* サイズは概算であり、リリースごとに変動します——正確な数値は、ダウンロードした `eds` バイナリで `ls -lh` を実行し、各ツールの最新リリースページを確認してください。

---
<!-- CHECKSUMS-START -->
### 🔒 リリース v0.8.9 の SHA256 チェックサム

```
da04b5dcd5a146f4231e99e429335c7f82ac39e2e3a9e05abff7578222ed8729  eds-linux-x86_64
4940f53560beac56cca6aa454caf1ef8911b891e44678b13ac4ce3e748aad7a0  eds-macos-arm64
8e95964c4595df3aa2b52571aab5f64248a82eaf8798e37fa7765456332b04cc  eds-windows-x86_64
```
<!-- CHECKSUMS-END -->
セキュリティに関するお問い合わせ： seyed@swiftter.com

## 🖥️ 使い方

**インストール：**
```bash
curl -fsSL https://raw.githubusercontent.com/seyed/erl_data_shift/main/scripts/install.sh | bash   
```
または手動ダウンロード：Releases から OS に対応するバイナリを取得し、chmod +x eds を実行してください。


## セットアップ：
```bash 
eds init          # 現在のディレクトリに migrations/ と .env.example を生成
# .env.example を編集し、実際の Postgres 値を記入して .env として保存
```
## コマンド

| コマンド | 説明 |
|---|---|
| `con_check` | `.env` の認証情報を使用して Postgres への接続をテスト。 |
| `stat` | テーブル名、行数、ストレージサイズを表示（大きい順）。 |
| `history` | 適用済みマイグレーションを表示——適用時刻、適用/ロールバックした人、ローカル/DB ドリフトチェック。 |
| `migrate` | `./migrations` の未適用 `.sql` ファイルをすべてトランザクションで実行。適用済みマイグレーションが編集されている場合（チェックサムドリフト）は拒否。 |
| `migrate force` | migrate と同じだが、チェックサムドリフトチェックをバイパス。意図的に使用し、デフォルトでは使用しないこと。 |
| `migrate dry-run` | 未適用のマイグレーションを列挙するが適用しない。 |
| `migrate down` | 直前に適用したマイグレーションをロールバック。 |
| `migrate -f <path>` | `migrate` と同じだが、カスタムマイグレーションディレクトリを指定。 |
| `new <name>` | 番号付き up+down マイグレーションファイルのペアを生成。 |
| `validate` | ロールバックされるトランザクション内で未適用マイグレーションをテスト実行し、早期にエラーを検出。 |
| `verify` | 適用済みマイグレーションファイルが実行後編集されていないか確認（チェックサムドリフト）。 |
| `init` | 現在のディレクトリに `migrations/` と `.env.example` を生成。 |
| `--version` | `eds` のバージョンを表示。 |
| `--help` / `-h` | このヘルプメッセージを表示。 |

## 🔬 テスト 

<!-- COVERAGE-START -->
### 🧪 テストカバレッジ — 合計: 92%

[📊 インタラクティブなカバレッジレポートを見る](https://seyed.github.io/erl_data_shift/)

| モジュール | カバレッジ |
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







