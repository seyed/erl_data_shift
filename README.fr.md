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

**CLI de migration Postgres autonome**

🇫🇷 Français* | [🇬🇧 English](README.md) | [🇯🇵 日本語](README.ja.md) | [🇨🇳 中文](README.zh.md) | [🇮🇱 עברית](README.he.md) | [🇸🇦 العربية](README.ar.md) | [🇩🇪 Deutsch](README.de.md) | [🇳🇴 Norsk](README.no.md) | [🇸🇪 Svenska](README.sv.md) | [🇹🇷 Türkçe](README.tr.md) | [🇲🇾 Bahasa Melayu](README.ms.md) | [🇮🇩 Bahasa Indonesia](README.id.md) | [🇪🇸 Español](README.es.md)   


[![CI](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml/badge.svg)](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml)
[![Sous licence MIT](https://img.shields.io/github/license/seyed/erl_data_shift)](LICENSE)
[![Dernière version](https://img.shields.io/github/v/release/seyed/erl_data_shift)](https://github.com/seyed/erl_data_shift/releases)
![macOS](https://img.shields.io/badge/macOS-supported-success)
![Linux](https://img.shields.io/badge/Linux-supported-success)
![Windows](https://img.shields.io/badge/Windows-supported-success)
![Erlang/OTP](https://img.shields.io/badge/OTP-27%2B-blue)
![Les PR sont les bienvenues](https://img.shields.io/badge/PRs-welcome-brightgreen)
 
*  Veuillez noter que ce document est une traduction automatique. Si cette langue est votre langue maternelle, veuillez envoyer votre version du README via une pull request.

--- 
## ⚠️ Avertissement
```
╔══════════════════════════════════════════════════════════════╗
║                UTILISEZ À VOS RISQUES ET PÉRILS              ║
╚══════════════════════════════════════════════════════════════╝
```
**Ce logiciel (l'« Outil ») est un utilitaire open-source de migration de données fourni « EN L'ÉTAT »"** sans garantie d'aucune sorte, expresse ou implicite, y compris, sans s'y limiter, les garanties de qualité marchande, d'adéquation à un usage particulier et de non-contrefaçon.

**Responsabilité de l'utilisateur:**
- Vous êtes seul responsable de la **sauvegarde de vos données** avant d'exécuter toute migration.
- Vous êtes seul responsable de tester cet Outil dans un environnement autre que de production avant de l'utiliser sur des données en direct.
- Les auteurs et contributeurs de cet Outil **ne sauraient être tenus responsables** de toute perte de données, corruption, interruption de service, ou de tout dommage direct, indirect, accessoire ou consécutif découlant de l'utilisation ou de l'impossibilité d'utiliser ce logiciel.

*En utilisant cet Outil, vous reconnaissez avoir lu, compris et accepté ces conditions. Si vous n'êtes pas d'accord, n'utilisez pas ce logiciel.*



## 🎯 Objectif et Buts

**Objectif.** Une CLI multiplateforme pour les migrations PostgreSQL.

**Buts**

1. Construire, exécuter et vérifier les changements de schéma de base de données via des commandes simples.
2. Zéro dépendance pour l'utilisateur final.

--
## Comparaison de eds avec les outils leaders

_eds est un outil nouveau — ceux-ci sont des outils éprouvés et largement adoptés. Voici un regard honnête sur la place d'eds et là où il n'arrive pas encore._

**Où eds s'inscrit :** une CLI légère, sans dépendances, pour les équipes sur PostgreSQL qui veulent la sécurité de type Flyway (transactions, checksums, verrous) sans JVM ni tier payant — pas adapté si vous avez besoin du multi-base de données, si vous êtes déjà profondément dans Atlas/Flyway, ou si vous construisez une app Elixir où Ecto est le choix naturel.

### Coût, collecte de données et licence

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| Coût | ✅ (gratuit, pas de tier payant — toutes les fonctionnalités incluses) | ⚠️ (noyau gratuit, mais rollback/dry-run nécessitent Teams/Enterprise payant) | ✅ (gratuit, pas de tier payant) | ⚠️ (CLI gratuite, mais fonctionnalités avancées derrière Atlas Cloud payant) | ✅ (gratuit, pas de tier payant) |
| Collecte de données d'utilisation | ✅ (aucune — eds n'envoie rien nulle part) | ⚠️ (télémétrie activée par défaut, opt-out via variable d'environnement — [Docs Redgate](https://documentation.red-gate.com/fd/redgate-disable-telemetry-environment-variable-277579301.html)) | ✅ (aucune télémétrie trouvée dans leurs docs/repo) | ⚠️ (télémétrie activée par défaut — commandes exécutées, OS, hostname — opt-out via variable d'environnement — [Docs de confidentialité d'Atlas](https://atlasgo.io/cli/data-privacy)) | ✅ (aucune télémétrie trouvée. La bibliothèque `:telemetry` d'Elixir est de l'instrumentation/hooks locale, pas de l'analytics envoyée à l'extérieur) |
| Licence | MIT | Communauté gratuite / Teams payant | MIT | Apache 2.0 (fonctionnalités cloud payantes) | Apache 2.0 |

### Fonctionnalités et maturité

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| Dépendance runtime | ✅ (aucune — binaire unique, inclut ERTS) | ❌ (nécessite une JVM, ou leur CLI qui en embarque une) | ✅ (aucune — binaire Go unique) | ✅ (aucune — binaire Go unique) | ❌ (nécessite Elixir + Erlang/OTP + Mix installés — c'est une bibliothèque, pas un binaire standalone) |
| Support des bases de données | ❌ (PostgreSQL uniquement) | ✅ (PostgreSQL, MySQL, Oracle, et plus) | ✅ (beaucoup) | ✅ (beaucoup) | ✅ (PostgreSQL, MySQL, SQLite, MSSQL, et plus via adapters) |
| Migrations transactionnelles | ✅ (par fichier) | ✅ | ⚠️ (dépend du driver) | ✅ | ✅ |
| Rollback | ✅ (`migrate down`, `.down.sql` écrits à la main) | ❌ (tier Teams/Enterprise uniquement) | ✅ (scripts down écrits à la main) | ✅ (diff inverse calculé automatiquement) | ✅ (`mix ecto.rollback`, `down`/`change` écrits à la main) |
| Détection de drift de checksum | ✅ (bloque par défaut) | ✅ | ❌ | ✅ (via lint) | ❌ (non trouvé dans le core d'Ecto) |
| Verrou de concurrence | ✅ (advisory lock Postgres, toujours actif) | ✅ | ⚠️ (dépend du driver) | ✅ | ⚠️ (table lock par défaut ; advisory lock disponible mais nécessite configuration) |
| Dry-run / preview | ✅ | ❌ (Enterprise uniquement) | ❌ | ✅ (`migrate lint`) | ⚠️ (`mix ecto.migrations` affiche l'état en attente, pas une vraie preview SQL) |
| Sortie JSON pour CI | ✅ | ⚠️ (limitée) | ❌ | ✅ | ❌ (la sortie standard des tâches Mix est textuelle) |
| Taille approximative du binaire/téléchargement | ~40–60 Mo* (embarque le runtime Erlang) | ~100+ Mo (embarque un JRE) | ~10–20 Mo (binaire Go natif) | ~15–25 Mo (binaire Go natif) | N/A (bibliothèque, pas un binaire distribué) |
| Maturité | ❌ (nouveau) | ✅ (10+ ans, largement adopté) | ✅ (10+ ans, largement adopté) | ⚠️ (plus récent, en forte croissance) | ✅ (au cœur de l'écosystème Elixir/Phoenix depuis 2015) |

\* Les tailles sont approximatives et varient entre les releases — vérifiez avec `ls -lh` sur votre binaire `eds` téléchargé et sur la page de release la plus récente de chaque outil pour obtenir les chiffres exacts actuels.   
-- 
## Sécurité

<!-- CHECKSUMS-START -->
### 🔒 Sommes de contrôle SHA256 de la version v0.9.1

```
701f6cc72d8875d92347fed3655c1f07589ac9583a3d675de956a011c4ebd65d  eds-linux-x86_64
f42f6666ccad20bf75bfdfa32fc1f4a75227a31e13156202b11a9379ada3268b  eds-macos-arm64
21821a2e9a0eb41481aa6274df84ecc3d4d6fe04cfa1841f720733a91c33d0f1  eds-windows-x86_64
```
<!-- CHECKSUMS-END -->

Pour les problèmes de sécurité, veuillez contacter : [seyed@swiftter.com]

## 🖥️ Utilisation

**Installation :**
```bash
curl -fsSL https://raw.githubusercontent.com/seyed/erl_data_shift/main/scripts/install.sh | bash
```

Ou téléchargement manuel : récupérez le binaire pour votre système d'exploitation depuis les [Releases](../../releases), puis exécutez `chmod +x eds`.

**Configuration :**
```bash
eds init          # échafaude le dossier migrations/ et .env.example dans le répertoire courant
# éditez .env.example, remplissez avec les vraies valeurs PostgreSQL, sauvegardez sous .env   
```

## Commandes

| Commande | Description |
|---|---|
| `con_check` | Teste la connectivité PostgreSQL en utilisant vos identifiants `.env`. |
| `stat` | Affiche les noms des tables, le nombre de lignes et la taille de stockage, du plus grand au plus petit. |
| `history` | Affiche les migrations appliquées — temps écoulé depuis l'application, auteur de l'application/annulation, et vérification de dérive entre local et base de données. |
| `migrate` | Exécute tous les fichiers `.sql` en attente depuis `./migrations` de manière transactionnelle. Refuse de s'exécuter si une migration déjà appliquée a été modifiée (dérive de somme de contrôle). |
| `migrate force` | Identique à `migrate`, mais contourne la vérification de dérive de somme de contrôle. À utiliser délibérément, pas par défaut. |
| `migrate dry-run` | Liste les migrations en attente sans les appliquer. |
| `migrate down` | Annule (rollback) la migration appliquée la plus récente. |
| `migrate -f <path>` | Identique à `migrate`, mais pointe vers un répertoire de migrations personnalisé. |
| `new <name>` | Génère une nouvelle paire de fichiers de migration (up + down) numérotés. |
| `validate` | Exécute un test des migrations en attente dans une transaction annulée pour détecter les erreurs tôt. |
| `verify` | Vérifie que les fichiers de migration appliqués n'ont pas été modifiés depuis leur exécution (dérive de somme de contrôle). |
| `init` | Génère le dossier `migrations/` et le fichier `.env.example` dans le répertoire courant. |
| `--version` | Affiche la version de `eds`. |
| `--help` / `-h` | Affiche ce message d'aide. |   

## 🔬 Tests

<!-- COVERAGE-START -->
### 🧪 Couverture des tests — Total: 91%

[📊 Voir le rapport de couverture interactif ligne par ligne](https://seyed.github.io/erl_data_shift/)

| Module | Couverture |
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
