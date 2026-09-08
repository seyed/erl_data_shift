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

## Hur eds jämför sig med de stora

_eds är nytt — dessa är etablerade, brett adopterade verktyg. Här är en ärlig bild av var eds passar och var det inte (ännu) gör._

**Var eds passar:** ett litet, beroendefritt CLI för team på Postgres som vill ha Flyway-lik säkerhet (transaktioner, kontrollsummor, låsning) utan en JVM eller en betald tier — inte ett passande val om du behöver flerdatabasstöd eller redan är djupt inne i ett Atlas/Flyway-uppsättning.

### Kostnad, data och licensiering

| | **eds** | Flyway | golang-migrate | Atlas |
|---|---|---|---|---|
| Kostnad | ✅ (gratis, ingen betald tier — alla funktioner inkluderade) | ⚠️ (gratis kärna, men rollback/dry-run kräver betald Teams/Enterprise) | ✅ (gratis, ingen betald tier) | ⚠️ (gratis CLI, men avancerade funktioner låsta bakom betald Atlas Cloud) |
| Insamling av användningsdata | ✅ (ingen — eds skickar ingenting någonstans) | ⚠️ (telemetri på som standard, opt-out via miljövariabel — [Redgate-dokumentation](https://documentation.red-gate.com/fd/redgate-disable-telemetry-environment-variable-277579301.html)) | ✅ (ingen telemetri hittad i deras dokumentation/repo) | ⚠️ (telemetri på som standard — kommandon körs, OS, värdname — opt-out via miljövariabel — [Atlas' egna integritetsdokument](https://atlasgo.io/cli/data-privacy)) |
| Licens | MIT | Community gratis / Teams betalt | MIT | Apache 2.0 (betalda cloud-funktioner) |

### Funktioner och mognad

| | **eds** | Flyway | golang-migrate | Atlas |
|---|---|---|---|---|
| Runtime-beroende | ✅ (inget — enkel binär, inbäddar ERTS) | ❌ (kräver en JVM, eller deras CLI som inbäddar en) | ✅ (inget — enkel Go-binär) | ✅ (inget — enkel Go-binär) |
| Databasstöd | ❌ (endast PostgreSQL) | ✅ (PostgreSQL, MySQL, Oracle och mer) | ✅ (många) | ✅ (många) |
| Transaktionsbaserade migrationer | ✅ (per fil) | ✅ | ⚠️ (driverberoende) | ✅ |
| Tillbakarullning | ✅ (`migrate down`, handskrivna `.down.sql`) | ❌ (endast Teams/Enterprise-tier) | ✅ (handskrivna down-skript) | ✅ (automatiskt beräknad revers diff) |
| Kontrollsum-drift-detektering | ✅ (blockerar som standard) | ✅ | ❌ | ✅ (via lint) |
| Konkurrenslås | ✅ (Postgres rådgivande lås) | ✅ | ⚠️ (driverberoende) | ✅ |
| Dry-run / förhandsvisning | ✅ | ❌ (endast Enterprise) | ❌ | ✅ (`migrate lint`) |
| JSON-utdata för CI | ✅ | ⚠️ (begränsad) | ❌ | ✅ |
| Ungefärlig binär/nedladdningsstorlek | ~40–60 MB* (inbäddar Erlang-runtime) | ~100+ MB (inbäddar JRE) | ~10–20 MB (nativ Go-binär) | ~15–25 MB (nativ Go-binär) |
| Mognad | ❌ (nytt) | ✅ (10+ år, brett adopterat) | ✅ (10+ år, brett adopterat) | ⚠️ (nyare, växer snabbt) |

\* Störrelsefigurer är ungefärliga och ändras mellan utgåvor — kontrollera `ls -lh` på din egen nedladdade `eds`-binär och varje verktygs senaste utgåvssida för exakta aktuella siffror i stället för att lita på denna tabell.   

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