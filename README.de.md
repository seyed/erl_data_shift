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
🇩🇪 Deutsch*  | [🇬🇧 English](README.md) | [🇯🇵 日本語](README.ja.md) | [🇨🇳 中文](README.zh.md) | [🇮🇱 עברית](README.he.md) | [🇸🇦 العربية](README.ar.md) | [🇫🇷 Français](README.fr.md) | [🇳🇴 Norsk](README.no.md) | [🇸🇪 Svenska](README.sv.md) | [🇹🇷 Türkçe](README.tr.md) | [🇲🇾 Bahasa Melayu](README.ms.md) | [🇮🇩 Bahasa Indonesia](README.id.md) | [🇪🇸 Español](README.es.md)   

**Ein eigenständiges Postgres-Migrations-CLI** 

[![CI](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml/badge.svg)](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml)
[![Sous licence MIT](https://img.shields.io/github/license/seyed/erl_data_shift)](LICENSE)
[![Dernière version](https://img.shields.io/github/v/release/seyed/erl_data_shift)](https://github.com/seyed/erl_data_shift/releases)
![macOS](https://img.shields.io/badge/macOS-supported-success)
![Linux](https://img.shields.io/badge/Linux-supported-success)
![Windows](https://img.shields.io/badge/Windows-supported-success)
![Erlang/OTP](https://img.shields.io/badge/OTP-27%2B-blue)
![Les PR sont les bienvenues](https://img.shields.io/badge/PRs-welcome-brightgreen)

* Bitte beachten Sie, dass dieses Dokument eine maschinelle Übersetzung ist. Wenn Sie diese Sprache als Muttersprache verwenden, senden Sie bitte Ihre README-Version per Pull Request ein.


## ⚠️ Haftungsausschluss
```
╔══════════════════════════════════════════════════════════════╗
║                   Nutzung auf eigene Gefahr                  ║
╚══════════════════════════════════════════════════════════════╝
```

Diese Software (nachfolgend „das Tool") ist ein Open-Source-Datenmigrationstool, das „wie besehen" bereitgestellt wird, ohne Gewährleistung jeglicher Art, ausdrücklich oder stillschweigend, einschließlich, aber nicht beschränkt auf Gewährleistungen der Vermarktlichkeit, Eignung für einen bestimmten Zweck und Nichtverletzung von Rechten Dritter.

Verantwortung des Nutzers:

*   Sie allein sind verantwortlich für das Sichern Ihrer Daten, bevor Sie Migrationen ausführen.
*   Sie allein sind verantwortlich dafür, dieses Tool in einer Nicht-Produktionsumgebung zu testen, bevor Sie es auf Live-Daten anwenden.
*   Die Autoren und Mitwirkenden dieses Tools haften nicht für Datenverlust, Datenkorruption, Ausfallzeiten oder sonstige direkte, indirekte, zufällige oder Folgeschäden, die aus der Nutzung oder der Unmöglichkeit der Nutzung dieser Software entstehen.
*   Durch die Nutzung dieses Tools bestätigen Sie, dass Sie diese Bedingungen gelesen, verstanden und akzeptiert haben. Wenn Sie nicht zustimmen, verwenden Sie diese Software nicht.

---

## 🎯 Ziel und Ziele

**Ziel.** Ein plattformübergreifendes CLI-Tool für PostgreSQL-Migrationen.

**Ziele:**

*   Datenbank-Schemawechsel über einfache Befehle erstellen, ausführen und verifizieren.
*   Keine Abhängigkeiten für den Endbenutzer.
-- 
## Vergleich von eds mit den etablierten Tools

_eds ist ein neues Tool — die folgenden sind etablierte, weit verbreitete Tools. Hier ein ehrlicher Blick darauf, wo eds passt und wo es (noch) nicht reicht._

**Wo eds passt:** eine kleine, abhängigkeitsfreie CLI für Teams auf PostgreSQL, die Flyway-ähnliche Sicherheit (Transaktionen, Checksums, Locking) ohne JVM oder kostenpflichtiges Tier wollen — nicht geeignet, wenn Multi-Datenbank-Unterstützung benötigt wird, wenn man bereits tief in Atlas/Flyway steckt, oder wenn man eine Elixir-App baut, bei der Ecto die natürliche Wahl ist.

### Kosten, Datenerhebung und Lizenz

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| Kosten | ✅ (kostenlos, kein bezahltes Tier — alle Funktionen enthalten) | ⚠️ (Kern kostenlos, aber Rollback/Dry-Run erfordern bezahltes Teams/Enterprise) | ✅ (kostenlos, kein bezahltes Tier) | ⚠️ (CLI kostenlos, aber fortgeschrittene Funktionen hinter bezahltem Atlas Cloud) | ✅ (kostenlos, kein bezahltes Tier) |
| Datenerhebung zur Nutzung | ✅ (keine — eds sendet nichts irgendwohin) | ⚠️ (Telemetrie standardmäßig aktiv, Opt-out über Umgebungsvariable — [Redgate-Docs](https://documentation.red-gate.com/fd/redgate-disable-telemetry-environment-variable-277579301.html)) | ✅ (keine Telemetrie in deren Docs/Repo gefunden) | ⚠️ (Telemetrie standardmäßig aktiv — ausgeführte Befehle, OS, Hostname — Opt-out über Umgebungsvariable — [Atlas-Datenschutz-Docs](https://atlasgo.io/cli/data-privacy)) | ✅ (keine Telemetrie gefunden. Elixirs `:telemetry`-Bibliothek ist lokale Instrumentierung/Hooks, keine externe Analyse) |
| Lizenz | MIT | Community kostenlos / Teams bezahlt | MIT | Apache 2.0 (bezahlte Cloud-Funktionen) | Apache 2.0 |

### Funktionen und Reifegrad

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| Runtime-Abhängigkeit | ✅ (keine — einzelnes Binary, bündelt ERTS) | ❌ (benötigt eine JVM, oder deren CLI, die eine bündelt) | ✅ (keine — einzelnes Go-Binary) | ✅ (keine — einzelnes Go-Binary) | ❌ (benötigt Elixir + Erlang/OTP + Mix installiert — eine Bibliothek, kein standalone Binary) |
| Datenbank-Unterstützung | ❌ (nur PostgreSQL) | ✅ (PostgreSQL, MySQL, Oracle und mehr) | ✅ (viele) | ✅ (viele) | ✅ (PostgreSQL, MySQL, SQLite, MSSQL und mehr via Adapter) |
| Transaktionale Migrationen | ✅ (pro Datei) | ✅ | ⚠️ (treiberabhängig) | ✅ | ✅ |
| Rollback | ✅ (`migrate down`, handgeschriebene `.down.sql`) | ❌ (nur Teams/Enterprise) | ✅ (handgeschriebene Down-Skripte) | ✅ (automatisch berechnetes Reverse-Diff) | ✅ (`mix ecto.rollback`, handgeschriebene `down`/`change`) |
| Checksum-Drift-Erkennung | ✅ (blockiert standardmäßig) | ✅ | ❌ | ✅ (via lint) | ❌ (in Ecto-Core nicht gefunden) |
| Concurrency-Lock | ✅ (Postgres Advisory Lock, immer aktiv) | ✅ | ⚠️ (treiberabhängig) | ✅ | ⚠️ (Table Lock standardmäßig; Advisory Lock verfügbar, aber muss konfiguriert werden) |
| Dry-Run / Vorschau | ✅ | ❌ (nur Enterprise) | ❌ | ✅ (`migrate lint`) | ⚠️ (`mix ecto.migrations` zeigt ausstehenden Status, keine echte SQL-Vorschau) |
| JSON-Ausgabe für CI | ✅ | ⚠️ (begrenzt) | ❌ | ✅ | ❌ (Standard-Mix-Task-Ausgabe ist textuell) |
| Ungefähre Binary/Download-Größe | ~40–60 MB* (bündelt Erlang-Runtime) | ~100+ MB (bündelt JRE) | ~10–20 MB (natives Go-Binary) | ~15–25 MB (natives Go-Binary) | N/A (Bibliothek, kein distribuiertes Binary) |
| Reifegrad | ❌ (neu) | ✅ (10+ Jahre, weit verbreitet) | ✅ (10+ Jahre, weit verbreitet) | ⚠️ (jünger, wächst schnell) | ✅ (Kern des Elixir/Phoenix-Ökosystems seit 2015) |

\* Größenangaben sind annähernd und ändern sich zwischen Releases — prüft mit `ls -lh` euer heruntergeladenes `eds`-Binary und die jeweils neueste Release-Seite jedes Tools für aktuelle exakte Zahlen.   

--   

## Sicherheit

<!-- CHECKSUMS-START -->
### 🔒 SHA256-Prüfsummen für Release v0.9.0

```
be6b4fb705849ea6a39eefb7cb2588ea53ac85fd36e69a7cabe9ca2e82f5d4f6  eds-linux-x86_64
a883258573b3b1c389f90209497861d6eeefcbaef2624bbd50cb2b08a7717923  eds-macos-arm64
c286b463b130481c243dcc9341aa32a1709c0097fd45cdd8dcd6299abff645d9  eds-windows-x86_64
```
<!-- CHECKSUMS-END -->



## 🖥️ Verwendung

**Installation:**
```bash
curl -fsSL https://raw.githubusercontent.com/seyed/erl_data_shift/main/scripts/install.sh | bash
```
Oder manuelle Installation: Laden Sie die Binärdatei für Ihr Betriebssystem von Releases herunter und führen Sie chmod +x eds aus. 

## Einrichtung:

```bash 
eds init          # Erzeugt migrations/ und .env.example im aktuellen Verzeichnis
# .env.example bearbeiten, echte Postgres-Werte eintragen, als .env speichern   
```

## Befehle

| Befehl | Beschreibung |
|---|---|
| `con_check` | Testet die Postgres-Verbindung mit den Zugangsdaten aus `.env`. |
| `stat` | Zeigt Tabellennamen, Zeilenzahlen und Speichernutzung, sortiert nach Größe (absteigend). |
| `history` | Zeigt angewendete Migrationen an – Zeitpunkt, wer welche angewendet/rückgängig gemacht hat, sowie lokale/DB-Drift-Prüfung. |
| `migrate` | Führt alle ausstehenden `.sql`-Dateien aus `./migrations` transaktional aus. Weigert sich, wenn eine bereits angewendete Migration bearbeitet wurde (Checksummen-Drift). |
| `migrate force` | Wie `migrate`, aber umgeht die Checksummen-Drift-Prüfung. Bewusst verwenden, nicht als Standard. |
| `migrate dry-run` | Listet ausstehende Migrationen auf, ohne sie anzuwenden. |
| `migrate down` | Macht die zuletzt angewendete Migration rückgängig. |
| `migrate -f <path>` | Wie `migrate`, aber zeigt auf ein benutzerdefiniertes Migrationsverzeichnis. |
| `new <name>` | Erzeugt ein nummeriertes up+down-Migrationsdateipaar. |
| `validate` | Testet ausstehende Migrationen in einer zurückgerollten Transaktion, um Fehler früh zu erkennen. |
| `verify` | Prüft, ob angewendete Migrationsdateien seit ihrer Ausführung bearbeitet wurden (Checksummen-Drift). |
| `init` | Erzeugt `migrations/` und `.env.example` im aktuellen Verzeichnis. |
| `--version` | Gibt die `eds`-Version aus. |
| `--help` / `-h` | Zeigt diese Hilfe an. |





<!-- COVERAGE-START -->
### 🧪 Testabdeckung — Gesamt: 91%

[📊 Interaktiven zeilenweisen Abdeckungsbericht anzeigen](https://seyed.github.io/erl_data_shift/)

| Modul | Abdeckung |
|---|---|
| ✅ erl_data_shift_bench | 100% |
| ✅ erl_data_shift_json | 100% |
| ✅ erl_data_shift_migrations | 97% |
| ✅ erl_data_shift_env | 94% |
| ✅ erl_data_shift_db | 93% |
| ✅ erl_data_shift_migrator | 93% |
| ✅ erl_data_shift_app | 90% |
| ✅ erl_data_shift_scaffold | 82% |
| ✅ erl_data_shift_init | 80% |
<!-- COVERAGE-END -->
