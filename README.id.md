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
🇮🇩 Bahasa Indonesia* | [🇬🇧 English](README.md) | [🇯🇵 日本語](README.ja.md) | [🇨🇳 中文](README.zh.md) | [🇮🇱 עברית](README.he.md) | [🇸🇦 العربية](README.ar.md) | [🇫🇷 Français](README.fr.md) | [🇩🇪 Deutsch](README.de.md) | [🇳🇴 Norsk](README.no.md) | [🇸🇪 Svenska](README.sv.md) | [🇹🇷 Türkçe](README.tr.md) | [🇲🇾 Bahasa Melayu](README.ms.md) | [🇪🇸 Español](README.es.md)   

**erl_data_shift – CLI migrasi Postgres mandiri**


[![CI](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml/badge.svg)](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml)
[![Sous licence MIT](https://img.shields.io/github/license/seyed/erl_data_shift)](LICENSE)
[![Dernière version](https://img.shields.io/github/v/release/seyed/erl_data_shift)](https://github.com/seyed/erl_data_shift/releases)
![macOS](https://img.shields.io/badge/macOS-supported-success)
![Linux](https://img.shields.io/badge/Linux-supported-success)
![Windows](https://img.shields.io/badge/Windows-supported-success)
![Erlang/OTP](https://img.shields.io/badge/OTP-27%2B-blue)
![Les PR sont les bienvenues](https://img.shields.io/badge/PRs-welcome-brightgreen)

* Perhatikan bahwa dokumen ini adalah terjemahan mesin. Jika Anda menggunakan bahasa ini sebagai bahasa ibu, silakan kirim versi README Anda melalui pull request.

## ⚠️ Penafian
```
╔══════════════════════════════════════════════════════════════╗
║          GUNAKAN DENGAN RISIKO ANDA SENDIRI                  ║
╚══════════════════════════════════════════════════════════════╝
```
**Perangkat lunak ini (Alat) adalah utilitas migrasi data open source yang disediakan "APA ADANYA,"** tanpa jaminan apa pun, baik tersurat maupun tersirat, termasuk tetapi tidak terbatas pada jaminan kelayakan dagang, kesesuaian untuk tujuan tertentu, dan tidak melanggar.

**Tanggung Jawab Pengguna:**
- Anda sepenuhnya bertanggung jawab untuk **mencadangkan data Anda** sebelum menjalankan migrasi apa pun.
- Anda sepenuhnya bertanggung jawab untuk menguji Alat ini di lingkungan non-produksi sebelum menggunakannya pada data langsung.
- Penulis dan kontributor Alat ini **tidak dapat dituntut pertanggungjawaban** atas kehilangan data, korupsi, gangguan layanan, atau kerusakan langsung, tidak langsung, insidental, atau konsekuensial apa pun yang timbul dari penggunaan atau ketidakmampuan menggunakan perangkat lunak ini.

Dengan menggunakan Alat ini, Anda mengakui bahwa Anda telah membaca, memahami, dan menyetujui ketentuan-ketentuan ini. Jika Anda tidak setuju, jangan gunakan perangkat lunak ini.

---
## 🎯 Tujuan dan Sasaran

**Tujuan.** CLI lintas platform untuk migrasi PostgreSQL.

**Sasaran**

1. Membangun, menjalankan, dan memverifikasi perubahan skema basis data melalui perintah sederhana.
2. Nol dependensi bagi pengguna akhir.

## Perbandingan eds dengan pemain besar

_eds masih baru — ini adalah alat-alat mapan yang diadopsi secara luas. Berikut adalah pandangan jujur tentang di mana eds cocok dan di mana ia belum._

**Di mana eds cocok:** CLI kecil, bebas dependensi untuk tim di Postgres yang menginginkan keamanan gaya Flyway (transaksi, checksum, penguncian) tanpa JVM atau tier berbayar — tidak cocok jika Anda memerlukan dukungan multi-database atau sudah mendalam dalam setup Atlas/Flyway.

### Biaya, data, dan lisensi

| | **eds** | Flyway | golang-migrate | Atlas |
|---|---|---|---|---|
| Biaya | ✅ (gratis, tanpa tier berbayar — semua fitur termasuk) | ⚠️ (inti gratis, tetapi rollback/dry-run memerlukan Teams/Enterprise berbayar) | ✅ (gratis, tanpa tier berbayar) | ⚠️ (CLI gratis, tetapi fitur lanjutan dikunci di belakang Atlas Cloud berbayar) |
| Pengumpulan data penggunaan | ✅ (tidak ada — eds tidak mengirim apa pun ke mana pun) | ⚠️ (telemetri aktif secara default, opt-out via variabel lingkungan — [dokumentasi Redgate](https://documentation.red-gate.com/fd/redgate-disable-telemetry-environment-variable-277579301.html)) | ✅ (tidak ditemukan telemetri dalam dokumentasi/repo mereka) | ⚠️ (telemetri aktif secara default — perintah yang dijalankan, OS, nama host — opt-out via variabel lingkungan — [dokumentasi privasi Atlas sendiri](https://atlasgo.io/cli/data-privacy)) |
| Lisensi | MIT | Community gratis / Teams berbayar | MIT | Apache 2.0 (fitur cloud berbayar) |

### Fitur dan kematangan

| | **eds** | Flyway | golang-migrate | Atlas |
|---|---|---|---|---|
| Dependensi runtime | ✅ (tidak ada — satu biner, memuat ERTS) | ❌ (memerlukan JVM, atau CLI mereka yang memuat satu) | ✅ (tidak ada — satu biner Go) | ✅ (tidak ada — satu biner Go) |
| Dukungan basis data | ❌ (hanya PostgreSQL) | ✅ (PostgreSQL, MySQL, Oracle, dan lainnya) | ✅ (banyak) | ✅ (banyak) |
| Migrasi transaksional | ✅ (per file) | ✅ | ⚠️ (tergantung driver) | ✅ |
| Rollback | ✅ (`migrate down`, `.down.sql` tulisan tangan) | ❌ (hanya tier Teams/Enterprise) | ✅ (skrip down tulisan tangan) | ✅ (reverse diff dihitung otomatis) |
| Deteksi drift checksum | ✅ (memblokir secara default) | ✅ | ❌ | ✅ (via lint) |
| Kunci konkurensi | ✅ (kunci nasihat Postgres) | ✅ | ⚠️ (tergantung driver) | ✅ |
| Dry-run / pratinjau | ✅ | ❌ (hanya Enterprise) | ❌ | ✅ (`migrate lint`) |
| Output JSON untuk CI | ✅ | ⚠️ (terbatas) | ❌ | ✅ |
| Ukuran biner/unduhan perkiraan | ~40–60 MB* (memuat runtime Erlang) | ~100+ MB (memuat JRE) | ~10–20 MB (biner Go native) | ~15–25 MB (biner Go native) |
| Kematangan | ❌ (baru) | ✅ (10+ tahun, diadopsi luas) | ✅ (10+ tahun, diadopsi luas) | ⚠️ (lebih baru, berkembang pesat) |

\* Angka ukuran bersifat perkiraan dan berubah antar rilis — periksa `ls -lh` pada biner `eds` yang Anda unduh dan halaman rilis terbaru setiap alat untuk angka saat ini yang tepat, bukan mengandalkan tabel ini.   

## Keamanan

<!-- CHECKSUMS-START -->
<!-- CHECKSUMS-END -->

Untuk masalah keamanan, silakan hubungi: [seyed@swiftter.com]

## 🖥️ Penggunaan

**Instalasi:**
```bash
curl -fsSL https://raw.githubusercontent.com/seyed/erl_data_shift/main/scripts/install.sh | bash
```

Atau unduh secara manual: ambil biner untuk OS Anda dari [Rilis](../../releases), kemudian `chmod +x eds`.

**Pengaturan:**
```bash
eds init          # membuat kerangka migrations/ dan .env.example di direktori saat ini
# edit .env.example, isi nilai Postgres yang sebenarnya, simpan sebagai .env
```

## Perintah

| Perintah | Deskripsi |
|---|---|
| `con_check` | Menguji konektivitas Postgres menggunakan kredensial `.env` Anda. |
| `stat` | Menampilkan nama tabel, jumlah baris, dan ukuran penyimpanan, terbesar terlebih dahulu. |
| `history` | Menampilkan migrasi yang telah diterapkan — waktu sejak penerapan, siapa yang menerapkan/memulihkan masing-masing, dan pemeriksaan drift lokal/DB. |
| `migrate` | Menjalankan semua file `.sql` yang tertunda dari `./migrations` secara transaksional. Menolak jika migrasi yang sudah diterapkan telah diedit (drift checksum). |
| `migrate force` | Sama seperti migrate, tetapi melewati pemeriksaan drift checksum. Gunakan secara sengaja, bukan secara default. |
| `migrate dry-run` | Mendaftar migrasi yang tertunda tanpa menerapkannya. |
| `migrate down` | Memulihkan migrasi yang diterapkan terakhir. |
| `migrate -f <path>` | Sama seperti `migrate`, tetapi menunjuk ke direktori migrasi kustom. |
| `new <name>` | Membuat pasangan file migrasi up+down bernomor baru. |
| `validate` | Menjalankan uji migrasi yang tertunda dalam transaksi yang dibatalkan untuk menangkap error lebih awal. |
| `verify` | Memeriksa bahwa file migrasi yang diterapkan tidak telah diedit sejak dijalankan (drift checksum). |
| `init` | Membuat kerangka `migrations/` dan `.env.example` di direktori saat ini. |
| `--version` | Mencetak versi `eds`. |
| `--help` / `-h` | Menampilkan pesan bantuan ini. |

## 🔬 Pengujian   


<!-- COVERAGE-START -->
### 🧪 Cakupan Pengujian — Total: 92%

[📊 Lihat laporan cakupan interaktif baris demi baris](https://seyed.github.io/erl_data_shift/)

| Modul | Cakupan |
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