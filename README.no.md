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
🇳🇴 Norsk* | [🇬🇧 English](README.md) | [🇯🇵 日本語](README.ja.md) | [🇨🇳 中文](README.zh.md) | [🇮🇱 עברית](README.he.md) | [🇸🇦 العربية](README.ar.md) | [🇫🇷 Français](README.fr.md) | [🇩🇪 Deutsch](README.de.md) | [🇸🇪 Svenska](README.sv.md) | [🇹🇷 Türkçe](README.tr.md) | [🇲🇾 Bahasa Melayu](README.ms.md) | [🇮🇩 Bahasa Indonesia](README.id.md) | [🇪🇸 Español](README.es.md)   

**erl_data_shift – Et selvstendig Postgres-migrerings-CLI**

[![CI](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml/badge.svg)](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml)
[![Sous licence MIT](https://img.shields.io/github/license/seyed/erl_data_shift)](LICENSE)
[![Dernière version](https://img.shields.io/github/v/release/seyed/erl_data_shift)](https://github.com/seyed/erl_data_shift/releases)
![macOS](https://img.shields.io/badge/macOS-supported-success)
![Linux](https://img.shields.io/badge/Linux-supported-success)
![Windows](https://img.shields.io/badge/Windows-supported-success)
![Erlang/OTP](https://img.shields.io/badge/OTP-27%2B-blue)
![Les PR sont les bienvenues](https://img.shields.io/badge/PRs-welcome-brightgreen)

* Merk at dette dokumentet er en maskinoversettelse. Hvis du bruker dette språket morsmål, vennligst send README-versjonen din via pull request.

## ⚠️ Fraskrivelse
```
╔══════════════════════════════════════════════════════════════╗
║                   BRUKER PÅ EGEN RISK                        ║
╚══════════════════════════════════════════════════════════════╝
```
**Denne programvaren (verktøyet) er et open source-verktøy for datamigrering og leveres "SOM DEN ER,"** uten garanti av noe slag, uttrykt eller underforstått, inkludert men ikke begrenset til garantier for salgbarehet, egnethet for et bestemt formål og ikke krenkelse.

**Brukers ansvar:**
- Du er alene ansvarlig for **sikkerhetskopiere dataene dine** før du kjører noen migreringer.
- Du er alene ansvarlig for å teste verktøyet i et ikke-produksjonsmiljø før du bruker det på live-data.
- Forfatterne og bidragsyterne til verktøyet **skal ikke holdes ansvarlige** for tap av data, korrupsjon, tjenesteavbrudd eller noen direkte, indirekte, tilfeldige eller konsekvensskader som oppstår ved bruk eller manglende evne til å bruke programvaren.

Ved å bruke verktøyet bekrefter du at du har lest, forstått og godkjent disse vilkårene. Hvis du ikke er enig, bruk ikke programvaren.

---
## 🎯 Mål og målsettinger

**Mål.** Et tverrplattformskommandolinjeverktøy for PostgreSQL-migreringer.

**Målsettinger**

1. Bygge, kjøre og verifisere endringer i databasens skjema via enkle kommandoer.
2. Ingen avhengigheter for sluttbrukeren.

-- 
## Sammenligning av eds med de ledende verktøyene

_eds er et nytt verktøy — følgende er etablerte, vidt utbredte verktøy. Her er et ærlig blikk på hvor eds passer og hvor det (ennå) ikke gjør det._

**Hvor eds passer:** et lite, avhengighetsfritt CLI for team som bruker PostgreSQL og vil ha Flyway-liknende sikkerhet (transaksjoner, checksums, låsing) uten JVM eller betalt tier — ikke egnet hvis du trenger multi-database-støtte, hvis du allerede er dypt inne i Atlas/Flyway, eller hvis du bygger en Elixir-app der Ecto er det naturlige valget.

### Kostnad, datainnsamling og lisens

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| Kostnad | ✅ (gratis, ingen betalt tier — alle funksjoner inkludert) | ⚠️ (kjernen gratis, men rollback/dry-run krever betalt Teams/Enterprise) | ✅ (gratis, ingen betalt tier) | ⚠️ (CLI gratis, men avanserte funksjoner bak betalt Atlas Cloud) | ✅ (gratis, ingen betalt tier) |
| Innsamling av bruksdata | ✅ (ingen — eds sender ingenting til noe sted) | ⚠️ (telemetri aktiv som standard, opt-out via miljøvariabel — [Redgate-dokumentasjon](https://documentation.red-gate.com/fd/redgate-disable-telemetry-environment-variable-277579301.html)) | ✅ (ingen telemetri funnet i deres dokumentasjon/repo) | ⚠️ (telemetri aktiv som standard — kjørte kommandoer, OS, vertsmaskin — opt-out via miljøvariabel — [Atlas sin personverndokumentasjon](https://atlasgo.io/cli/data-privacy)) | ✅ (ingen telemetri funnet. Elixirs `:telemetry`-bibliotek er lokal instrumentering/hooks, ikke analyse som sender data ut) |
| Lisens | MIT | Community gratis / Teams betalt | MIT | Apache 2.0 (betalte cloud-funksjoner) | Apache 2.0 |

### Funksjoner og modenhetsgrad

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| Runtime-avhengighet | ✅ (ingen — enkelt binær, innebygger ERTS) | ❌ (krever JVM, eller deres CLI som innebygger en) | ✅ (ingen — enkelt Go-binær) | ✅ (ingen — enkelt Go-binær) | ❌ (krever Elixir + Erlang/OTP + Mix installert — et bibliotek, ikke et selvstendig binær) |
| Databasestøtte | ❌ (kun PostgreSQL) | ✅ (PostgreSQL, MySQL, Oracle og mer) | ✅ (mange) | ✅ (mange) | ✅ (PostgreSQL, MySQL, SQLite, MSSQL og mer via adapters) |
| Transaksjonsbaserte migrasjoner | ✅ (per fil) | ✅ | ⚠️ (driver-avhengig) | ✅ | ✅ |
| Rollback | ✅ (`migrate down`, håndskrevne `.down.sql`) | ❌ (kun Teams/Enterprise) | ✅ (håndskrevne down-skript) | ✅ (automatisk beregnet reverse diff) | ✅ (`mix ecto.rollback`, håndskrevne `down`/`change`) |
| Checksum-drift-deteksjon | ✅ (blokkerer som standard) | ✅ | ❌ | ✅ (via lint) | ❌ (ikke funnet i Ecto-kjernen) |
| Konkurrenslås | ✅ (Postgres advisory lock, alltid aktiv) | ✅ | ⚠️ (driver-avhengig) | ✅ | ⚠️ (table lock som standard; advisory lock tilgjengelig men må konfigureres) |
| Dry-run / forhåndsvisning | ✅ | ❌ (kun Enterprise) | ❌ | ✅ (`migrate lint`) | ⚠️ (`mix ecto.migrations` viser ventende status, ikke en ekte SQL-forhåndsvisning) |
| JSON-output for CI | ✅ | ⚠️ (begrenset) | ❌ | ✅ | ❌ (standard Mix-task-output er tekstuell) |
| Omtrentlig binær/download-størrelse | ~40–60 MB* (innebygger Erlang-runtime) | ~100+ MB (innebygger JRE) | ~10–20 MB (nativt Go-binær) | ~15–25 MB (nativt Go-binær) | N/A (bibliotek, ikke et distribuert binær) |
| Modenhetsgrad | ❌ (nytt) | ✅ (10+ år, vidt utbredt) | ✅ (10+ år, vidt utbredt) | ⚠️ (nyere, vokser raskt) | ✅ (kjernen i Elixir/Phoenix-økosystemet siden 2015) |

\* Størrelsesangivelsene er omtrentlige og endres mellom utgaver — sjekk med `ls -lh` på ditt nedlastede `eds`-binær og hver verktøys nyeste utgave-side for nøyaktige tall.   

## Sikkerhet

<!-- CHECKSUMS-START -->
### 🔒 SHA256-sjekksummer for utgivelse v0.9.1

```
701f6cc72d8875d92347fed3655c1f07589ac9583a3d675de956a011c4ebd65d  eds-linux-x86_64
f42f6666ccad20bf75bfdfa32fc1f4a75227a31e13156202b11a9379ada3268b  eds-macos-arm64
21821a2e9a0eb41481aa6274df84ecc3d4d6fe04cfa1841f720733a91c33d0f1  eds-windows-x86_64
```
<!-- CHECKSUMS-END -->

For sikkerhetsproblemer, vennligst kontakt: [seyed@swiftter.com]

## 🖥️ Bruk

**Installasjon:**
```bash
curl -fsSL https://raw.githubusercontent.com/seyed/erl_data_shift/main/scripts/install.sh | bash
```

Eller last ned manuelt: hent binærfilen for ditt operativsystem fra [Releases](../../releases), deretter `chmod +x eds`.

**Oppsett:**
```bash
eds init          # skaper migrations/ og .env.example i gjeldende mappe
# rediger .env.example, fyll inn ekte Postgres-verdier, lagre som .env
```

## Kommandoer

| Kommando | Beskrivelse |
|---|---|
| `con_check` | Tester Postgres-konnektivitet ved hjelp av `.env`-credentialene dine. |
| `stat` | Viser tabellnavn, radantall og lagringsstørrelse, største først. |
| `history` | Viser appliede migreringer — tid siden påføring, hvem som påførte/tilbaketok hver, og lokal/DB-driftsjekk. |
| `migrate` | Kjører alle ventende `.sql`-filer fra `./migrations` transaksjonelt. Avviser hvis en allerede påført migrering har blitt redigert (kontrollsum-drift). |
| `migrate force` | Samme som migrate, men omgår kontrollsum-driftsjekken. Bruk bevisst, ikke som standard. |
| `migrate dry-run` | Listrer ventende migreringer uten å påføre dem. |
| `migrate down` | Ruller tilbake den senest påførte migreringen. |
| `migrate -f <path>` | Samme som `migrate`, men peker til en tilpasset migreringsmappe. |
| `new <name>` | Skaper et nytt nummerert up+down-migreringsfilpar. |
| `validate` | Testkjører ventende migreringer i en tilbakerullet transaksjon for å fange feil tidlig. |
| `verify` | Sjekker at påførte migreringsfiler ikke har blitt redigert siden de kjørte (kontrollsum-drift). |
| `init` | Skaper `migrations/` og `.env.example` i gjeldende mappe. |
| `--version` | Skriver ut `eds`-versjonen. |
| `--help` / `-h` | Viser denne hjelpemeldingen. |

## 🔬 Testing   


<!-- COVERAGE-START -->
### 🧪 Testdekning — Totalt: 89%

[📊 Vis interaktiv linje-for-linje dekningsrapport](https://seyed.github.io/erl_data_shift/)

| Modul | Dekning |
|---|---|
| ✅ erl_data_shift_bench | 100% |
| ✅ erl_data_shift_json | 100% |
| ✅ erl_data_shift_migrations | 97% |
| ✅ erl_data_shift_env | 94% |
| ✅ erl_data_shift_db | 93% |
| ✅ erl_data_shift_migrator | 93% |
| ✅ erl_data_shift_app | 86% |
| ✅ erl_data_shift_scaffold | 82% |
| ✅ erl_data_shift_init | 80% |
<!-- COVERAGE-END -->
