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

-- 
## Perbandingan eds dengan tools utama

_eds adalah tool baru — yang berikut ini adalah tools yang sudah mapan dan banyak diadopsi. Berikut pandangan jujur tentang di mana eds cocok dan di mana ia (belum) mampu._

**Di mana eds cocok:** CLI kecil tanpa dependensi, untuk tim yang menggunakan PostgreSQL dan ingin keamanan ala Flyway (transaksi, checksum, locking) tanpa JVM atau tier berbayar — tidak cocok jika Anda butuh dukungan multi-database, jika Anda sudah dalam ekosistem Atlas/Flyway, atau jika Anda membangun aplikasi Elixir di mana Ecto adalah pilihan alami.

### Biaya, pengumpulan data, dan lisensi

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| Biaya | ✅ (gratis, tanpa tier berbayar — semua fitur termasuk) | ⚠️ (inti gratis, tapi rollback/dry-run memerlukan Teams/Enterprise berbayar) | ✅ (gratis, tanpa tier berbayar) | ⚠️ (CLI gratis, tapi fitur lanjutan di balik Atlas Cloud berbayar) | ✅ (gratis, tanpa tier berbayar) |
| Pengumpulan data penggunaan | ✅ (tidak ada — eds tidak mengirim apa pun ke mana pun) | ⚠️ (telemetri aktif secara default, opt-out via variabel lingkungan — [Dokumentasi Redgate](https://documentation.red-gate.com/fd/redgate-disable-telemetry-environment-variable-277579301.html)) | ✅ (tidak ditemukan telemetri di dokumentasi/repo mereka) | ⚠️ (telemetri aktif secara default — perintah yang dijalankan, OS, hostname — opt-out via variabel lingkungan — [Dokumentasi privasi Atlas](https://atlasgo.io/cli/data-privacy)) | ✅ (tidak ditemukan telemetri. Library `:telemetry` Elixir adalah instrumentasi/hooks lokal, bukan analitik yang mengirim data keluar) |
| Lisensi | MIT | Komunitas gratis / Teams berbayar | MIT | Apache 2.0 (fitur cloud berbayar) | Apache 2.0 |

### Fitur dan kematangan

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| Ketergantungan runtime | ✅ (tidak ada — satu binary, memuat ERTS) | ❌ (membutuhkan JVM, atau CLI mereka yang memuat JVM) | ✅ (tidak ada — satu binary Go) | ✅ (tidak ada — satu binary Go) | ❌ (membutuhkan Elixir + Erlang/OTP + Mix terinstal — ini library, bukan binary standalone) |
| Dukungan database | ❌ (hanya PostgreSQL) | ✅ (PostgreSQL, MySQL, Oracle, dan lain-lain) | ✅ (banyak) | ✅ (banyak) | ✅ (PostgreSQL, MySQL, SQLite, MSSQL, dan lain-lain via adapter) |
| Migrasi transaksional | ✅ (per file) | ✅ | ⚠️ (tergantung driver) | ✅ | ✅ |
| Rollback | ✅ (`migrate down`, `.down.sql` ditulis manual) | ❌ (hanya tier Teams/Enterprise) | ✅ (skrip down ditulis manual) | ✅ (reverse diff dihitung otomatis) | ✅ (`mix ecto.rollback`, `down`/`change` ditulis manual) |
| Deteksi drift checksum | ✅ (memblokir secara default) | ✅ | ❌ | ✅ (via lint) | ❌ (tidak ditemukan di core Ecto) |
| Lock konkurensi | ✅ (advisory lock Postgres, selalu aktif) | ✅ | ⚠️ (tergantung driver) | ✅ | ⚠️ (table lock secara default; advisory lock tersedia tapi harus dikonfigurasi) |
| Dry-run / preview | ✅ | ❌ (hanya Enterprise) | ❌ | ✅ (`migrate lint`) | ⚠️ (`mix ecto.migrations` menampilkan status tertunda, bukan preview SQL sejati) |
| Output JSON untuk CI | ✅ | ⚠️ (terbatas) | ❌ | ✅ | ❌ (output task Mix standar bersifat tekstual) |
| Ukuran binary/download perkiraan | ~40–60 MB* (memuat runtime Erlang) | ~100+ MB (memuat JRE) | ~10–20 MB (binary Go native) | ~15–25 MB (binary Go native) | N/A (library, bukan binary yang didistribusikan) |
| Kematangan | ❌ (baru) | ✅ (10+ tahun, banyak diadopsi) | ✅ (10+ tahun, banyak diadopsi) | ⚠️ (lebih baru, berkembang pesat) | ✅ (inti ekosistem Elixir/Phoenix sejak 2015) |

\* Angka ukuran bersifat perkiraan dan berubah antar release — periksa dengan `ls -lh` pada binary `eds` yang Anda unduh dan halaman release terbaru masing-masing tool untuk angka yang akurat.   
-- 
## Keamanan

<!-- CHECKSUMS-START -->
### 🔒 Checksum SHA256 untuk Rilis v0.9.1

```
701f6cc72d8875d92347fed3655c1f07589ac9583a3d675de956a011c4ebd65d  eds-linux-x86_64
f42f6666ccad20bf75bfdfa32fc1f4a75227a31e13156202b11a9379ada3268b  eds-macos-arm64
21821a2e9a0eb41481aa6274df84ecc3d4d6fe04cfa1841f720733a91c33d0f1  eds-windows-x86_64
```
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
### 🧪 Cakupan Pengujian — Total: 89%

[📊 Lihat laporan cakupan interaktif baris demi baris](https://seyed.github.io/erl_data_shift/)

| Modul | Cakupan |
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
