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

## Comment eds se compare aux poids lourds

_eds est nouveau — ce sont des outils établis et largement adoptés. Voici un regard honnête sur où eds se situe et où il ne se situe pas (encore)._

**Où eds se situe :** une petite CLI sans dépendance pour les équipes sur PostgreSQL qui veulent la sécurité de style Flyway (transactions, sommes de contrôle, verrouillage) sans JVM ni version payante — ne convient pas si vous avez besoin d'un support multi-bases de données ou si vous êtes déjà profondément intégré dans un écosystème Atlas/Flyway.   

### Coût, données et licence

| | **eds** | Flyway | golang-migrate | Atlas |
|---|---|---|---|---|
| Coût | ✅ (gratuit, pas d'offre payante — toutes les fonctionnalités incluses) | ⚠️ (cœur gratuit, mais rollback/dry-run nécessitent les offres Teams/Enterprise payantes) | ✅ (gratuit, pas d'offre payante) | ⚠️ (CLI gratuit, mais fonctionnalités avancées bloquées derrière Atlas Cloud payant) |
| Collecte de données d'utilisation | ✅ (aucune — eds n'envoie rien nulle part) | ⚠️ (télémétrie activée par défaut, désactivable via variable d'environnement — [docs Redgate](https://documentation.red-gate.com/fd/redgate-disable-telemetry-environment-variable-277579301.html)) | ✅ (aucune télémétrie trouvée dans leur docs/dépôt) | ⚠️ (télémétrie activée par défaut — commandes exécutées, OS, nom d'hôte — désactivable via variable d'environnement — [docs de confidentialité d'Atlas](https://atlasgo.io/cli/data-privacy)) |
| Licence | MIT | Communauté gratuite / Teams payant | MIT | Apache 2.0 (fonctionnalités cloud payantes) |   

### Fonctionnalités et maturité

| | **eds** | Flyway | golang-migrate | Atlas |
|---|---|---|---|---|
| Dépendance d'exécution | ✅ (aucune — binaire unique, inclut ERTS) | ❌ (nécessite une JVM, ou leur CLI qui en inclut une) | ✅ (aucune — binaire Go unique) | ✅ (aucune — binaire Go unique) |
| Support de bases de données | ❌ (PostgreSQL uniquement) | ✅ (PostgreSQL, MySQL, Oracle, et plus) | ✅ (nombreuses) | ✅ (nombreuses) |
| Migrations transactionnelles | ✅ (par fichier) | ✅ | ⚠️ (dépend du pilote) | ✅ |
| Rollback (retour arrière) | ✅ (`migrate down`, fichiers `.down.sql` écrits à la main) | ❌ (uniquement dans les offres Teams/Enterprise) | ✅ (scripts de retour arrière écrits à la main) | ✅ (diff inverse calculé automatiquement) |
| Détection de dérive de somme de contrôle | ✅ (bloque par défaut) | ✅ | ❌ | ✅ (via lint) |
| Verrou de concurrence | ✅ (verrou conseil PostgreSQL) | ✅ | ⚠️ (dépend du pilote) | ✅ |
| Simulation / Aperçu (Dry-run) | ✅ | ❌ (uniquement Enterprise) | ❌ | ✅ (`migrate lint`) |
| Sortie JSON pour CI | ✅ | ⚠️ (limitée) | ❌ | ✅ |
| Taille approximative du binaire/téléchargement | ~40–60 Mo* (inclut le runtime Erlang) | ~100+ Mo (inclut un JRE) | ~10–20 Mo (binaire Go natif) | ~15–25 Mo (binaire Go natif) |
| Maturité | ❌ (nouveau) | ✅ (10+ ans, largement adopté) | ✅ (10+ ans, largement adopté) | ⚠️ (plus récent, croissance rapide) |

\* Les tailles sont approximatives et changent entre les versions — vérifiez avec `ls -lh` sur votre propre binaire `eds` téléchargé et sur la page de dernière version de chaque outil pour les chiffres exacts actuels plutôt que de vous fier à ce tableau.   

## Sécurité

<!-- CHECKSUMS-START -->
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
### 🧪 Couverture des tests — Total: 92%

[📊 Voir le rapport de couverture interactif ligne par ligne](https://seyed.github.io/erl_data_shift/)

| Module | Couverture |
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