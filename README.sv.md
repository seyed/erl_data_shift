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
🇸🇪 Svenska* | [🇬🇧 English](README.md) | [🇯🇵 日本語](README.ja.md) | [🇨🇳 中文](README.zh.md) | [🇮🇱 עברית](README.he.md) | [🇸🇦 العربية](README.ar.md) | [🇫🇷 Français](README.fr.md) | [🇩🇪 Deutsch](README.de.md) | [🇳🇴 Norsk](README.no.md) | [🇹🇷 Türkçe](README.tr.md) | [🇲🇾 Bahasa Melayu](README.ms.md) | [🇮🇩 Bahasa Indonesia](README.id.md) | [🇪🇸 Español](README.es.md) 

**erl_data_shift – Ett fristående Postgres-migrerings-CLI**

[![CI](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml/badge.svg)](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml)
[![Sous licence MIT](https://img.shields.io/github/license/seyed/erl_data_shift)](LICENSE)
[![Dernière version](https://img.shields.io/github/v/release/seyed/erl_data_shift)](https://github.com/seyed/erl_data_shift/releases)
![macOS](https://img.shields.io/badge/macOS-supported-success)
![Linux](https://img.shields.io/badge/Linux-supported-success)
![Windows](https://img.shields.io/badge/Windows-supported-success)
![Erlang/OTP](https://img.shields.io/badge/OTP-27%2B-blue)
![Les PR sont les bienvenues](https://img.shields.io/badge/PRs-welcome-brightgreen)

* Observera att detta dokument är en maskinöversättning. Om du använder detta språk som modersmål, skicka gärna README-versionen via pull request.


## ⚠️ Ansvarsfriskrivning
```
╔══════════════════════════════════════════════════════════════╗
║                   ANVÄND PÅ EGEN RISK                        ║
╚══════════════════════════════════════════════════════════════╝
```
**Denna programvara (verktyget) är ett open source-verktyg för datamigrering som levereras "SOM DEN ÄR,"** utan garanti av något slag, uttryckt eller underförstådd, inklusive men inte begränsat till garantier för säljbarhet, lämplighet för ett visst ändamål och icke överträdelse.

**Användarens ansvar:**
- Du är enbart ansvarig för att **säkerhetskopiera dina data** innan du kör någon migration.
- Du är enbart ansvarig för att testa verktyget i en icke-produktionsmiljö innan du använder det på live-data.
- Verktygets författare och bidragsgivare **får inte hållas ansvariga** för dataförlust, korruption, tjänstestopp eller någon direkt, indirekt, tillfälligt eller följdskada som uppstår vid användning eller oförmåga att använda programvaran.

Genom att använda verktyget intygar du att du har läst, förstått och godkänt dessa villkor. Om du inte är med, använd inte programvaran.

---
## 🎯 Mål och syften

**Mål.** Ett plattformsoberoende kommandotolksverktyg för PostgreSQL-migrationer.

**Syften**

1. Bygga, köra och verifiera databasschemabyten via enkla kommandon.
2. Noll beroenden för slutanvändaren.

-- 
## Jämförelse av eds med de ledande verktygen

_eds är ett nytt verktyg — följande är etablerade, brett använda verktyg. Här är en ärlig bild på var eds passar och var det (ännu) inte gör det._

**Var eds passar:** ett litet, beroendefritt CLI för team som använder PostgreSQL och vill ha Flyway-liknande säkerhet (transaktioner, checksummor, lås) utan JVM eller betald nivå — inte lämpligt om du behöver multi-databas-stöd, om du redan är djupt inne i Atlas/Flyway, eller om du bygger en Elixir-app där Ecto är det naturliga valet.

### Kostnad, datainsamling och licens

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| Kostnad | ✅ (gratis, ingen betald nivå — alla funktioner ingår) | ⚠️ (kärnan gratis, men rollback/dry-run kräver betald Teams/Enterprise) | ✅ (gratis, ingen betald nivå) | ⚠️ (CLI gratis, men avancerade funktioner bakom betald Atlas Cloud) | ✅ (gratis, ingen betald nivå) |
| Insamling av användningsdata | ✅ (ingen — eds skickar ingenting vartans) | ⚠️ (telemetri aktiv som standard, opt-out via miljövariabel — [Redgate-dokumentation](https://documentation.red-gate.com/fd/redgate-disable-telemetry-environment-variable-277579301.html)) | ✅ (ingen telemetri hittad i deras dokumentation/repo) | ⚠️ (telemetri aktiv som standard — körda kommandon, OS, hostname — opt-out via miljövariabel — [Atlas integritetsdokumentation](https://atlasgo.io/cli/data-privacy)) | ✅ (ingen telemetri hittad. Elixirs `:telemetry`-bibliotek är lokal instrumentering/hooks, inte analys som skickar data ut) |
| Licens | MIT | Community gratis / Teams betald | MIT | Apache 2.0 (betalda cloud-funktioner) | Apache 2.0 |

### Funktioner och mognadsgrad

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| Runtime-beroende | ✅ (inget — enstaka binär, inbäddar ERTS) | ❌ (kräver JVM, eller deras CLI som inbäddar en) | ✅ (inget — enstaka Go-binär) | ✅ (inget — enstaka Go-binär) | ❌ (kräver Elixir + Erlang/OTP + Mix installerat — ett bibliotek, inte en fristående binär) |
| Databasstöd | ❌ (endast PostgreSQL) | ✅ (PostgreSQL, MySQL, Oracle och mer) | ✅ (många) | ✅ (många) | ✅ (PostgreSQL, MySQL, SQLite, MSSQL och mer via adapters) |
| Transaktionsbaserade migrationer | ✅ (per fil) | ✅ | ⚠️ (driverberoende) | ✅ | ✅ |
| Rollback | ✅ (`migrate down`, handskrivna `.down.sql`) | ❌ (endast Teams/Enterprise) | ✅ (handskrivna down-skript) | ✅ (automatiskt beräknad reverse diff) | ✅ (`mix ecto.rollback`, handskrivna `down`/`change`) |
| Checksum-drift-detektion | ✅ (blockerar som standard) | ✅ | ❌ | ✅ (via lint) | ❌ (ej hittad i Ecto-kärnan) |
| Konkurrenslås | ✅ (Postgres advisory lock, alltid aktiv) | ✅ | ⚠️ (driverberoende) | ✅ | ⚠️ (table lock som standard; advisory lock tillgänglig men kräver konfiguration) |
| Dry-run / förhandsvisning | ✅ | ❌ (endast Enterprise) | ❌ | ✅ (`migrate lint`) | ⚠️ (`mix ecto.migrations` visar väntande status, inte en riktig SQL-förhandsvisning) |
| JSON-output för CI | ✅ | ⚠️ (begränsad) | ❌ | ✅ | ❌ (standard Mix-task-output är textuell) |
| Ungefärlig binär/download-storlek | ~40–60 MB* (inbäddar Erlang-runtime) | ~100+ MB (inbäddar JRE) | ~10–20 MB (nativ Go-binär) | ~15–25 MB (nativ Go-binär) | N/A (bibliotek, inte en distribuerad binär) |
| Mognadsgrad | ❌ (nytt) | ✅ (10+ år, brett använt) | ✅ (10+ år, brett använt) | ⚠️ (nyare, växer snabbt) | ✅ (kärnan i Elixir/Phoenix-ekosystemet sedan 2015) |

\* Storleksangivelserna är ungefärliga och ändras mellan utgåvor — kontrollera med `ls -lh` på din nedladdade `eds`-binär och varje verktygs senaste utgåvssida för exakta siffror.   
-- 
## Säkerhet


<!-- CHECKSUMS-START -->
<!-- CHECKSUMS-END -->

För säkerhetsproblem, kontakta vänligen: [seyed@swiftter.com]

## 🖥️ Användning

**Installation:**
```bash
curl -fsSL https://raw.githubusercontent.com/seyed/erl_data_shift/main/scripts/install.sh | bash
```

Eller ladda ner manuellt: hämta binärfilen för ditt operativsystem från [Releases](../../releases), sedan `chmod +x eds`.

**Konfiguration:**
```bash
eds init          # skapar migrations/ och .env.example i aktuell katalog
# redigera .env.example, fyll i riktiga Postgres-värden, spara som .env
```

## Kommandon

| Kommando | Beskrivning |
|---|---|
| `con_check` | Testar Postgres-konnektivitet med dina `.env`-uppgifter. |
| `stat` | Visar tabellnamn, radantal och lagringsstorlek, störst först. |
| `history` | Visar tillämpade migrationer — tid sedan tillämpning, vem som tillämpade/återvände varje, och lokal/DB-driftskoll. |
| `migrate` | Kör alla väntande `.sql`-filer från `./migrations` transaktionsbaserat. Avvisar om en redan tillämpad migration har redigerats (kontrollsum-drift). |
| `migrate force` | Samma som migrate, men kringgår kontrollsum-driftskollen. Använd medvetet, inte som standard. |
| `migrate dry-run` | Listar väntande migrationer utan att tillämpa dem. |
| `migrate down` | Återvinner den senast tillämpade migrationen. |
| `migrate -f <path>` | Samma som `migrate`, men pekar på en anpassad migrationskatalog. |
| `new <name>` | Skapar ett nytt numrerat up+down-migrationsfilpar. |
| `validate` | Testkör väntande migrationer i en återvunnen transaktion för att fånga fel tidigt. |
| `verify` | Kollar att tillämpade migrationsfiler inte har redigerats sedan de kördes (kontrollsum-drift). |
| `init` | Skapar `migrations/` och `.env.example` i aktuell katalog. |
| `--version` | Skriver ut `eds`-versionen. |
| `--help` / `-h` | Visar detta hjälpmeddelande. |

## 🔬 Testning   





<!-- COVERAGE-START -->
### 🧪 Testtäckning — Totalt: 92%

[📊 Visa interaktiv rad-för-rad-täckningsrapport](https://seyed.github.io/erl_data_shift/)

| Modul | Täckning |
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
