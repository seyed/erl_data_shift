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
🇪🇸 Español* | [🇬🇧 English](README.md) | [🇯🇵 日本語](README.ja.md) | [🇨🇳 中文](README.zh.md) | [🇮🇱 עברית](README.he.md) | [🇸🇦 العربية](README.ar.md) | [🇫🇷 Français](README.fr.md) | [🇩🇪 Deutsch](README.de.md) | [🇳🇴 Norsk](README.no.md) | [🇸🇪 Svenska](README.sv.md) | [🇹🇷 Türkçe](README.tr.md) | [🇲🇾 Bahasa Melayu](README.ms.md) | [🇮🇩 Bahasa Indonesia](README.id.md)   

**erl_data_shift – Una CLI de migración de Postgres autónoma**

[![CI](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml/badge.svg)](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml)
[![Sous licence MIT](https://img.shields.io/github/license/seyed/erl_data_shift)](LICENSE)
[![Dernière version](https://img.shields.io/github/v/release/seyed/erl_data_shift)](https://github.com/seyed/erl_data_shift/releases)
![macOS](https://img.shields.io/badge/macOS-supported-success)
![Linux](https://img.shields.io/badge/Linux-supported-success)
![Windows](https://img.shields.io/badge/Windows-supported-success)
![Erlang/OTP](https://img.shields.io/badge/OTP-27%2B-blue)
![Les PR sont les bienvenues](https://img.shields.io/badge/PRs-welcome-brightgreen)

* Tenga en cuenta que este documento es una traducción automática. Si esta es su lengua materna, por favor envíe su versión del README mediante pull request.

## ⚠️ Descargo de responsabilidad
```
╔══════════════════════════════════════════════════════════════╗
║             USO BAJO SU PROPIO RIESGO                        ║
╚══════════════════════════════════════════════════════════════╝
```
**Este software (la "Herramienta") es una utilidad de migración de datos de código abierto proporcionada "TAL CUAL,"** sin garantía de ningún tipo, expresa o implícita, incluyendo pero no limitado a las garantías de comerciabilidad, aptitud para un propósito particular y no infracción.

**Responsabilidad del usuario:**
- Usted es el único responsable de **realizar una copia de seguridad de sus datos** antes de ejecutar cualquier migración.
- Usted es el único responsable de probar esta Herramienta en un entorno no productivo antes de utilizarla con datos en vivo.
- Los autores y colaboradores de esta Herramienta **no serán responsables** de ninguna pérdida de datos, corrupción, interrupción del servicio, ni de ningún daño directo, indirecto, incidental o consecuente derivado del uso o la imposibilidad de usar este software.

Al utilizar esta Herramienta, usted reconoce haber leído, comprendido y aceptado estos términos. Si no está de acuerdo, no utilice este software.

---
## 🎯 Objetivo y metas

**Objetivo.** Una CLI multiplataforma para migraciones de PostgreSQL.

**Metas**

1. Construir, ejecutar y verificar cambios en el esquema de la base de datos mediante comandos simples.
2. Cero dependencias para el usuario final.
-- 
## Comparación de eds con las herramientas líderes

_eds es una herramienta nueva — estas son herramientas consolidadas y ampliamente adoptadas. Aquí hay una mirada honesta sobre dónde encaja eds y dónde aún no llega._

**Dónde encaja eds:** una CLI pequeña y sin dependencias, para equipos que usan PostgreSQL y quieren seguridad al estilo Flyway (transacciones, checksums, locks) sin JVM ni plan de pago — no es adecuado si necesitas soporte multi-base de datos, si ya estás profundamente en Atlas/Flyway, o si estás construyendo una app Elixir donde Ecto es la opción natural.

### Costo, recopilación de datos y licencia

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| Costo | ✅ (gratis, sin plan de pago — todas las funciones incluidas) | ⚠️ (núcleo gratis, pero rollback/dry-run requieren Teams/Enterprise de pago) | ✅ (gratis, sin plan de pago) | ⚠️ (CLI gratis, pero funciones avanzadas tras Atlas Cloud de pago) | ✅ (gratis, sin plan de pago) |
| Recopilación de datos de uso | ✅ (ninguna — eds no envía nada a ningún lugar) | ⚠️ (telemetría activada por defecto, opt-out vía variable de entorno — [Docs de Redgate](https://documentation.red-gate.com/fd/redgate-disable-telemetry-environment-variable-277579301.html)) | ✅ (no se encontró telemetría en sus docs/repo) | ⚠️ (telemetría activada por defecto — comandos ejecutados, OS, hostname — opt-out vía variable de entorno — [Docs de privacidad de Atlas](https://atlasgo.io/cli/data-privacy)) | ✅ (no se encontró telemetría. La librería `:telemetry` de Elixir es instrumentación/hooks local, no analítica que envía datos externamente) |
| Licencia | MIT | Comunidad gratis / Teams de pago | MIT | Apache 2.0 (funciones cloud de pago) | Apache 2.0 |

### Funciones y madurez

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| Dependencia de runtime | ✅ (ninguna — binario único, incluye ERTS) | ❌ (requiere JVM, o su CLI que incluye una) | ✅ (ninguna — binario Go único) | ✅ (ninguna — binario Go único) | ❌ (requiere Elixir + Erlang/OTP + Mix instalado — es una librería, no un binario standalone) |
| Soporte de bases de datos | ❌ (solo PostgreSQL) | ✅ (PostgreSQL, MySQL, Oracle, y más) | ✅ (muchas) | ✅ (muchas) | ✅ (PostgreSQL, MySQL, SQLite, MSSQL, y más vía adapters) |
| Migraciones transaccionales | ✅ (por archivo) | ✅ | ⚠️ (depende del driver) | ✅ | ✅ |
| Rollback | ✅ (`migrate down`, `.down.sql` escritos a mano) | ❌ (solo plan Teams/Enterprise) | ✅ (scripts down escritos a mano) | ✅ (diff inverso calculado automáticamente) | ✅ (`mix ecto.rollback`, `down`/`change` escritos a mano) |
| Detección de drift de checksum | ✅ (bloquea por defecto) | ✅ | ❌ | ✅ (vía lint) | ❌ (no se encontró en el core de Ecto) |
| Lock de concurrencia | ✅ (advisory lock de Postgres, siempre activo) | ✅ | ⚠️ (depende del driver) | ✅ | ⚠️ (table lock por defecto; advisory lock disponible pero requiere configuración) |
| Dry-run / preview | ✅ | ❌ (solo Enterprise) | ❌ | ✅ (`migrate lint`) | ⚠️ (`mix ecto.migrations` muestra estado pendiente, no es una preview SQL real) |
| Salida JSON para CI | ✅ | ⚠️ (limitada) | ❌ | ✅ | ❌ (la salida estándar de tareas Mix es textual) |
| Tamaño aproximado de binario/descarga | ~40–60 MB* (incluye runtime de Erlang) | ~100+ MB (incluye JRE) | ~10–20 MB (binario Go nativo) | ~15–25 MB (binario Go nativo) | N/A (librería, no un binario distribuido) |
| Madurez | ❌ (nuevo) | ✅ (10+ años, ampliamente adoptado) | ✅ (10+ años, ampliamente adoptado) | ⚠️ (más reciente, creciendo rápido) | ✅ (parte central del ecosistema Elixir/Phoenix desde 2015) |

\* Las cifras de tamaño son aproximadas y cambian entre releases — verifica con `ls -lh` en tu binario `eds` descargado y en la página de release más reciente de cada herramienta para obtener los números exactos actuales.   
-- 
## Seguridad

<!-- CHECKSUMS-START -->
### 🔒 Sumas de comprobación SHA256 de la versión v0.9.1

```
701f6cc72d8875d92347fed3655c1f07589ac9583a3d675de956a011c4ebd65d  eds-linux-x86_64
f42f6666ccad20bf75bfdfa32fc1f4a75227a31e13156202b11a9379ada3268b  eds-macos-arm64
21821a2e9a0eb41481aa6274df84ecc3d4d6fe04cfa1841f720733a91c33d0f1  eds-windows-x86_64
```
<!-- CHECKSUMS-END -->

Para problemas de seguridad, por favor contacte a: [seyed@swiftter.com]

## 🖥️ Uso

**Instalación:**
```bash
curl -fsSL https://raw.githubusercontent.com/seyed/erl_data_shift/main/scripts/install.sh | bash
```

O descárguelo manualmente: obtenga el binario para su sistema operativo desde [Releases](../../releases), luego `chmod +x eds`.

**Configuración:**
```bash
eds init          # crea el esqueleto de migrations/ y .env.example en el directorio actual
# edite .env.example, rellene los valores reales de Postgres, guarde como .env
```

## Comandos

| Comando | Descripción |
|---|---|
| `con_check` | Prueba la conectividad de Postgres usando sus credenciales de `.env`. |
| `stat` | Muestra nombres de tablas, recuento de filas y tamaño de almacenamiento, del mayor al menor. |
| `history` | Muestra migraciones aplicadas — tiempo desde la aplicación, quién aplicó/revertió cada una, y verificación de deriva local/DB. |
| `migrate` | Ejecuta todos los archivos `.sql` pendientes de `./migrations` de forma transaccional. Rechaza si una migración ya aplicada fue editada (deriva de suma de verificación). |
| `migrate force` | Igual que migrate, pero omite la verificación de deriva de suma de verificación. Úselo deliberadamente, no por defecto. |
| `migrate dry-run` | Lista migraciones pendientes sin aplicarlas. |
| `migrate down` | Revierte la migración aplicada más recientemente. |
| `migrate -f <path>` | Igual que `migrate`, pero apunta a un directorio de migraciones personalizado. |
| `new <name>` | Crea un nuevo par de archivos de migración up+down numerados. |
| `validate` | Ejecuta pruebas de migraciones pendientes en una transacción revertida para detectar errores temprano. |
| `verify` | Verifica que los archivos de migración aplicados no hayan sido editados desde que se ejecutaron (deriva de suma de verificación). |
| `init` | Crea el esqueleto de `migrations/` y `.env.example` en el directorio actual. |
| `--version` | Imprime la versión de `eds`. |
| `--help` / `-h` | Muestra este mensaje de ayuda. |

## 🔬 Pruebas   


<!-- COVERAGE-START -->
### 🧪 Cobertura de Pruebas — Total: 91%

[📊 Ver informe de cobertura interactivo línea por línea](https://seyed.github.io/erl_data_shift/)

| Módulo | Cobertura |
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
