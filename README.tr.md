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
🇹🇷 Türkçe* | [🇬🇧 English](README.md) | [🇯🇵 日本語](README.ja.md) | [🇨🇳 中文](README.zh.md) | [🇮🇱 עברית](README.he.md) | [🇸🇦 العربية](README.ar.md) | [🇫🇷 Français](README.fr.md) | [🇩🇪 Deutsch](README.de.md) | [🇳🇴 Norsk](README.no.md) | [🇸🇪 Svenska](README.sv.md) | [🇲🇾 Bahasa Melayu](README.ms.md) | [🇮🇩 Bahasa Indonesia](README.id.md) | [🇪🇸 Español](README.es.md)   

**erl_data_shift – Bağımsız bir Postgres migrasyon CLI'si**

[![CI](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml/badge.svg)](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml)
[![Sous licence MIT](https://img.shields.io/github/license/seyed/erl_data_shift)](LICENSE)
[![Dernière version](https://img.shields.io/github/v/release/seyed/erl_data_shift)](https://github.com/seyed/erl_data_shift/releases)
![macOS](https://img.shields.io/badge/macOS-supported-success)
![Linux](https://img.shields.io/badge/Linux-supported-success)
![Windows](https://img.shields.io/badge/Windows-supported-success)
![Erlang/OTP](https://img.shields.io/badge/OTP-27%2B-blue)
![Les PR sont les bienvenues](https://img.shields.io/badge/PRs-welcome-brightgreen)

* Bu belgenin bir makine çevirisi olduğunu lütfen not edin. Bu dili ana dil olarak kullanıyorsanız, README sürümünüzü lütfen pull request ile gönderin.


## ⚠️ Yasal Uyarı
```
╔══════════════════════════════════════════════════════════════╗
║               KULLANIM SİZİN RİSKİNİZDE                      ║
╚══════════════════════════════════════════════════════════════╝
```
**Bu yazılım (Araç), "OLDUĞU GİBİ" sağlanan açık kaynak bir veri migrasyon aracıdır;** hiçbir tür açık veya örtülü garanti verilmez, bunlar arasında sınırlı olmamak kaydıyla ticarete elverişlilik, belirli bir amaç için uygunluk ve ihlal etmeme garantileri dahildir.

**Kullanıcı Sorumluluğu:**
- Herhangi bir migrasyon çalıştırmadan önce **verilerinizi yedeklemekten** yalnızca siz sorumlusunuz.
- Bu Aracı canlı verilerde kullanmadan önce üretim dışı bir ortamda test etmenizden yalnızca siz sorumlusunuz.
- Bu Aracın yazarları ve katkıda bulunanlar, bu yazılımın kullanımı veya kullanılamamasından kaynaklanan herhangi bir veri kaybı, bozulma, hizmet kesintisi veya doğrudan, dolaylı, tesadüfi veya sonuç hasarlarından **sorumlu tutulamaz**.

Bu Aracı kullanarak, bu koşulları okuduğunuzu, anladığınızı ve kabul ettiğinizi beyan edersiniz. Kabul etmiyorsanız, bu yazılımı kullanmayın.

---
## 🎯 Amaç ve Hedefler

**Amaç.** PostgreSQL migrasyonları için platformlar arası bir komut satırı aracı.

**Hedefler**

1. Veritabanı şema değişikliklerini basit komutlarla oluşturma, çalıştırma ve doğrulama.
2. Son kullanıcı için sıfır bağımlılık.

-- 
## eds'in önde gelen araçlarla karşılaştırması

_eds yeni bir araç — aşağıdakiler olgun ve yaygın olarak benimsenmiş araçlardır. eds'in nerede uygun olduğu ve (henüz) olmadığı konusunda dürüst bir bakış._

**eds'in uygun olduğu yer:** PostgreSQL kullanan ve JVM veya ücretli katman olmadan Flyway tarzı güvenlik (işlemler, checksum, kilit) isteyen ekipler için küçük, bağımlılıksız bir CLI — çoklu veritabanı desteğine ihtiyacınız varsa, zaten Atlas/Flyway ekosisteminde derinleştiyseniz veya Ecto'nun doğal seçim olduğu bir Elixir uygulaması geliştiriyorsanız uygun değildir.

### Maliyet, veri toplama ve lisans

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| Maliyet | ✅ (ücretsiz, ücretli katman yok — tüm özellikler dahil) | ⚠️ (çekirdek ücretsiz, ancak rollback/dry-run ücretli Teams/Enterprise gerektirir) | ✅ (ücretsiz, ücretli katman yok) | ⚠️ (CLI ücretsiz, ancak gelişmiş özellikler ücretli Atlas Cloud arkasında) | ✅ (ücretsiz, ücretli katman yok) |
| Kullanım veri toplama | ✅ (yok — eds hiçbir yere hiçbir şey göndermez) | ⚠️ (telemetri varsayılan olarak etkin, ortam değişkeni ile devre dışı bırakılabilir — [Redgate belgeleri](https://documentation.red-gate.com/fd/redgate-disable-telemetry-environment-variable-277579301.html)) | ✅ (belgeleri/repo'larında telemetri bulunamadı) | ⚠️ (telemetri varsayılan olarak etkin — çalıştırılan komutlar, OS, hostname — ortam değişkeni ile devre dışı bırakılabilir — [Atlas gizlilik belgeleri](https://atlasgo.io/cli/data-privacy)) | ✅ (telemetri bulunamadı. Elixir'in `:telemetry` kütüphanesi yerel enstrümantasyon/hooks'tur, dışarıya veri gönderen analitik değildir) |
| Lisans | MIT | Topluluk ücretsiz / Teams ücretli | MIT | Apache 2.0 (ücretli bulut özellikleri) | Apache 2.0 |

### Özellikler ve olgunluk

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| Runtime bağımlılığı | ✅ (yok — tek binary, ERTS'i barındırır) | ❌ (JVM gerektirir, veya JVM barındıran CLI'ları) | ✅ (yok — tek Go binary) | ✅ (yok — tek Go binary) | ❌ (Elixir + Erlang/OTP + Mix kurulu olmalı — bir kütüphane, bağımsız binary değil) |
| Veritabanı desteği | ❌ (yalnızca PostgreSQL) | ✅ (PostgreSQL, MySQL, Oracle ve daha fazlası) | ✅ (çok fazla) | ✅ (çok fazla) | ✅ (PostgreSQL, MySQL, SQLite, MSSQL ve daha fazlası adapter'larla) |
| İşlem tabanlı migrasyonlar | ✅ (dosya başına) | ✅ | ⚠️ (sürücüye bağlı) | ✅ | ✅ |
| Rollback | ✅ (`migrate down`, elle yazılmış `.down.sql`) | ❌ (yalnızca Teams/Enterprise) | ✅ (elle yazılmış down script'leri) | ✅ (otomatik hesaplanan reverse diff) | ✅ (`mix ecto.rollback`, elle yazılmış `down`/`change`) |
| Checksum drift algılama | ✅ (varsayılan olarak engeller) | ✅ | ❌ | ✅ (lint ile) | ❌ (Ecto çekirdeğinde bulunamadı) |
| Eşzamanlı kilit | ✅ (Postgres advisory lock, her zaman etkin) | ✅ | ⚠️ (sürücüye bağlı) | ✅ | ⚠️ (varsayılan olarak table lock; advisory lock mevcut ancak yapılandırma gerektirir) |
| Dry-run / önizleme | ✅ | ❌ (yalnızca Enterprise) | ❌ | ✅ (`migrate lint`) | ⚠️ (`mix ecto.migrations` bekleyen durumu gösterir, gerçek bir SQL önizlemesi değildir) |
| CI için JSON çıktı | ✅ | ⚠️ (sınırlı) | ❌ | ✅ | ❌ (standart Mix task çıktısı metinsel) |
| Yaklaşık binary/indirme boyutu | ~40–60 MB* (Erlang runtime'ı barındırır) | ~100+ MB (JRE barındırır) | ~10–20 MB (yerel Go binary) | ~15–25 MB (yerel Go binary) | N/A (kütüphane, dağıtılan binary değil) |
| Olgunluk | ❌ (yeni) | ✅ (10+ yıl, yaygın benimsenmiş) | ✅ (10+ yıl, yaygın benimsenmiş) | ⚠️ (daha yeni, hızlı büyüyor) | ✅ (2015'ten beri Elixir/Phoenix ekosisteminin çekirdeği) |

\* Boyut değerleri yaklaşık olup sürümler arasında değişir — kesin güncel sayılar için indirilen `eds` binary'sine `ls -lh` uygulayın ve her aracın en güncel sürüm sayfasını kontrol edin.   
-- 
## Güvenlik

<!-- CHECKSUMS-START -->
### 🔒 v0.9.1 Sürümü SHA256 Sağlama Toplamları

```
701f6cc72d8875d92347fed3655c1f07589ac9583a3d675de956a011c4ebd65d  eds-linux-x86_64
f42f6666ccad20bf75bfdfa32fc1f4a75227a31e13156202b11a9379ada3268b  eds-macos-arm64
21821a2e9a0eb41481aa6274df84ecc3d4d6fe04cfa1841f720733a91c33d0f1  eds-windows-x86_64
```
<!-- CHECKSUMS-END -->

Güvenlik sorunları için lütfen şunu arayın: [seyed@swiftter.com]

## 🖥️ Kullanım

**Kurulum:**
```bash
curl -fsSL https://raw.githubusercontent.com/seyed/erl_data_shift/main/scripts/install.sh | bash
```

Veya manuel olarak indirin: işletim sisteminiz için ikili dosyayı [Sürümler](../../releases) sayfasından alın, ardından `chmod +x eds` uygulayın.

**Kurulum:**
```bash
eds init          # mevcut dizinde migrations/ ve .env.example oluşturur
# .env.example dosyasını düzenleyin, gerçek Postgres değerlerini girin, .env olarak kaydedin
```

## Komutlar

| Komut | Açıklama |
|---|---|
| `con_check` | `.env` kimlik bilgilerinizi kullanarak Postgres bağlantısını test eder. |
| `stat` | Tablo adlarını, satır sayılarını ve depolama boyutunu, en büyükten başlayarak gösterir. |
| `history` | Uygulanan migrasyonları gösterir — uygulama süresi, her birini uygulayan/geri alan kişi ve yerel/DB sapma kontrolü. |
| `migrate` | `./migrations` dizinindeki tüm bekleyen `.sql` dosyalarını işlemsel olarak çalıştırır. Zaten uygulanmış bir migrasyonun düzenlenmiş olması durumunda reddeder (özet sapması). |
| `migrate force` | migrate ile aynı, ancak özet sapma kontrolünü atlar. Bilinçli olarak kullanın, varsayılan olarak değil. |
| `migrate dry-run` | Bekleyen migrasyonları uygulamadan listeler. |
| `migrate down` | En son uygulanmış migrasyonu geri alır. |
| `migrate -f <path>` | `migrate` ile aynı, ancak özel bir migrasyon dizinine yönlendirir. |
| `new <name>` | Yeni numaralı up+down migrasyon dosyası çifti oluşturur. |
| `validate` | Bekleyen migrasyonları geri alınmış bir işlemde test ederek hataları erken yakalar. |
| `verify` | Uygulanan migrasyon dosyalarının çalıştırılmalarından sonra düzenlenip düzenlenmediğini kontrol eder (özet sapması). |
| `init` | Mevcut dizinde `migrations/` ve `.env.example` oluşturur. |
| `--version` | `eds` sürümünü yazdırır. |
| `--help` / `-h` | Bu yardım mesajını gösterir. |

## 🔬 Test   

<!-- COVERAGE-START -->
### 🧪 Test Kapsamı — Toplam: 89%

[📊 Etkileşimli satır satır kapsam raporunu görüntüle](https://seyed.github.io/erl_data_shift/)

| Modül | Kapsam |
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
