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
  

## Sicherheit

<!-- CHECKSUMS-START -->
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
### 🧪 Testabdeckung — Gesamt: 92%

[📊 Interaktiven zeilenweisen Abdeckungsbericht anzeigen](https://seyed.github.io/erl_data_shift/)

| Modul | Abdeckung |
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
