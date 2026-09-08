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

## eds'in büyüklerle karşılaştırması

_eds yenidir — bunlar yerleşik, yaygın olarak benimsenmiş araçlardır. eds'in nerede yer aldığı ve (henüz) yer almadığı yerler hakkında dürüst bir bakış._

**eds'in yer aldığı alan:** Postgres kullanan ekipler için Flyway benzeri güvenlik (işlemler, özet kontrolleri, kilitlenme) sunan, JVM veya ücretli tier gerektirmeyen küçük, bağımsız bir CLI — çoklu veritabanı desteğine ihtiyacınız varsa veya zaten Atlas/Flyway kurulumunun derinindeyseniz uygun değildir.

### Maliyet, veri ve lisanslama

| | **eds** | Flyway | golang-migrate | Atlas |
|---|---|---|---|---|
| Maliyet | ✅ (ücretsiz, ücretli tier yok — tüm özellikler dahil) | ⚠️ (ücretsiz çekirdek, ancak geri alma/dry-run ücretli Teams/Enterprise gerektirir) | ✅ (ücretsiz, ücretli tier yok) | ⚠️ (ücretsiz CLI, ancak gelişmiş özellikler ücretli Atlas Cloud'un arkasında) |
| Kullanım veri toplama | ✅ (yok — eds hiçbir yere hiçbir şey göndermez) | ⚠️ (telemetri varsayılan olarak açık, ortam değişkeni ile opt-out — [Redgate belgeleri](https://documentation.red-gate.com/fd/redgate-disable-telemetry-environment-variable-277579301.html)) | ✅ (belgeleri/repo'larında telemetri bulunamadı) | ⚠️ (telemetri varsayılan olarak açık — çalıştırılan komutlar, OS, ana makine adı — ortam değişkeni ile opt-out — [Atlas'ın kendi gizlilik belgeleri](https://atlasgo.io/cli/data-privacy)) |
| Lisans | MIT | Community ücretsiz / Teams ücretli | MIT | Apache 2.0 (ücretli bulut özellikleri) |

### Özellikler ve olgunluk

| | **eds** | Flyway | golang-migrate | Atlas |
|---|---|---|---|---|
| Çalışma zamanı bağımlılığı | ✅ (yok — tek ikili dosya, ERTS içerir) | ❌ (JVM gerektirir veya JVM içeren CLI'ları) | ✅ (yok — tek Go ikilisi) | ✅ (yok — tek Go ikilisi) |
| Veritabanı desteği | ❌ (yalnızca PostgreSQL) | ✅ (PostgreSQL, MySQL, Oracle ve daha fazlası) | ✅ (birçok) | ✅ (birçok) |
| İşlemsel migrasyonlar | ✅ (dosya başına) | ✅ | ⚠️ (sürücüye bağlı) | ✅ |
| Geri alma | ✅ (`migrate down`, elle yazılmış `.down.sql`) | ❌ (yalnızca Teams/Enterprise tier) | ✅ (elle yazılmış down betikleri) | ✅ (otomatik hesaplanan ters diff) |
| Özet sapma algılama | ✅ (varsayılan olarak engeller) | ✅ | ❌ | ✅ (lint ile) |
| Eşzamanlı kilit | ✅ (Postgres danışman kilit) | ✅ | ⚠️ (sürücüye bağlı) | ✅ |
| Dry-run / önizleme | ✅ | ❌ (yalnızca Enterprise) | ❌ | ✅ (`migrate lint`) |
| CI için JSON çıktısı | ✅ | ⚠️ (sınırlı) | ❌ | ✅ |
| Yaklaşık ikili/indirme boyutu | ~40–60 MB* (Erlang çalışma zamanı içerir) | ~100+ MB (JRE içerir) | ~10–20 MB (yerel Go ikilisi) | ~15–25 MB (yerel Go ikilisi) |
| Olgunluk | ❌ (yeni) | ✅ (10+ yıl, yaygın benimsenmiş) | ✅ (10+ yıl, yaygın benimsenmiş) | ⚠️ (daha yeni, hızlı büyüyen) |

\* Boyut rakamları yaklaşık olup sürümler arasında değişir — bu tableye güvenmek yerine, kendi indirdiğiniz `eds` ikilisi için `ls -lh` komutunu ve her aracın en son sürüm sayfasını kontrol edin.   

## Güvenlik

<!-- CHECKSUMS-START -->
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
### 🧪 Test Kapsamı — Toplam: 92%

[📊 Etkileşimli satır satır kapsam raporunu görüntüle](https://seyed.github.io/erl_data_shift/)

| Modül | Kapsam |
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