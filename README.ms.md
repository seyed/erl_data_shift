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
🇲🇾 Bahasa Melayu* | [🇬🇧 English](README.md) | [🇯🇵 日本語](README.ja.md) | [🇨🇳 中文](README.zh.md) | [🇮🇱 עברית](README.he.md) | [🇸🇦 العربية](README.ar.md) | [🇫🇷 Français](README.fr.md) | [🇩🇪 Deutsch](README.de.md) | [🇳🇴 Norsk](README.no.md) | [🇸🇪 Svenska](README.sv.md) | [🇹🇷 Türkçe](README.tr.md) | [🇮🇩 Bahasa Indonesia](README.id.md) | [🇪🇸 Español](README.es.md)   

**erl_data_shift – CLI migrasi Postgres berdikari**

[![CI](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml/badge.svg)](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml)
[![Sous licence MIT](https://img.shields.io/github/license/seyed/erl_data_shift)](LICENSE)
[![Dernière version](https://img.shields.io/github/v/release/seyed/erl_data_shift)](https://github.com/seyed/erl_data_shift/releases)
![macOS](https://img.shields.io/badge/macOS-supported-success)
![Linux](https://img.shields.io/badge/Linux-supported-success)
![Windows](https://img.shields.io/badge/Windows-supported-success)
![Erlang/OTP](https://img.shields.io/badge/OTP-27%2B-blue)
![Les PR sont les bienvenues](https://img.shields.io/badge/PRs-welcome-brightgreen)

* Sila ambil perhatian bahawa dokumen ini ialah terjemahan mesin. Jika anda menggunakan bahasa ini sebagai bahasa ibunda, sila hantar versi README anda melalui pull request.


## ⚠️ Penafian
```
╔══════════════════════════════════════════════════════════════╗
║            GUNA PADA RISIKO ANDA SENDIRI                     ║
╚══════════════════════════════════════════════════════════════╝
```
**Perisian ini (Alat) ialah utiliti migrasi data sumber terbuka yang disediakan "SEADANYA,"** tanpa jaminan apa jua, sama ada tersurat atau tersirat, termasuk tetapi tidak terhad kepada jaminan kebolehtoranganan, kesesuaian untuk tujuan tertentu, dan tidak melanggar.

**Tanggung Jawab Pengguna:**
- Anda bertanggungjawab sepenuhnya untuk **menyediakan salinan data anda** sebelum menjalankan sebarang migrasi.
- Anda bertanggungjawab sepenuhnya untuk menguji Alat ini dalam persekitaran bukan pengeluaran sebelum menggunakannya pada data langsung.
- Pengarang dan penyumbang Alat ini **tidak boleh dituntut tanggungjawab** bagi sebarang kehilangan data, kerosakan, gangguan perkhidmatan, atau sebarang kerosakan langsung, tidak langsung, kebetulan, atau akibat yang timbul daripada penggunaan atau ketidakupayaan untuk menggunakan perisian ini.

Dengan menggunakan Alat ini, anda mengiktiraf bahawa anda telah membaca, memahami, dan bersetuju dengan terma-terma ini. Jika anda tidak bersetuju, jangan gunakan perisian ini.

---
## 🎯 Matlamat dan Objektif

**Matlamat.** CLI rentas platform untuk migrasi PostgreSQL.

**Objektif**

1. Membina, menjalankan, dan mengesahkan perubahan skema pangkalan data melalui arahan mudah.
2. Sifar kebergantungan untuk pengguna akhir.

-- 
## Perbandingan eds dengan tools utama

_eds ialah tool baharu — yang berikut ialah tools yang sudah mapan dan banyak diadaptasi. Berikut pandangan jujur tentang di mana eds sesuai dan di mana ia (belum) mampu._

**Di mana eds sesuai:** CLI kecil tanpa kebergantungan, untuk pasukan yang menggunakan PostgreSQL dan ingin keselamatan ala Flyway (transaksi, checksum, locking) tanpa JVM atau tier berbayar — tidak sesuai jika anda perlu sokongan multi-database, jika anda sudah mendalam dalam ekosistem Atlas/Flyway, atau jika anda membina aplikasi Elixir di mana Ecto ialah pilihan semula jadi.

### Kos, pengumpulan data, dan lesen

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| Kos | ✅ (percuma, tanpa tier berbayar — semua ciri disertakan) | ⚠️ (teras percuma, tetapi rollback/dry-run memerlukan Teams/Enterprise berbayar) | ✅ (percuma, tanpa tier berbayar) | ⚠️ (CLI percuma, tetapi ciri lanjutan di sebalik Atlas Cloud berbayar) | ✅ (percuma, tanpa tier berbayar) |
| Pengumpulan data penggunaan | ✅ (tiada — eds tidak menghantar apa-apa ke mana-mana) | ⚠️ (telemetri aktif secara lalai, opt-out melalui pemboleh ubah persekitaran — [Dokumentasi Redgate](https://documentation.red-gate.com/fd/redgate-disable-telemetry-environment-variable-277579301.html)) | ✅ (tiada telemetri ditemui dalam dokumentasi/repo mereka) | ⚠️ (telemetri aktif secara lalai — arahan yang dijalankan, OS, hostname — opt-out melalui pemboleh ubah persekitaran — [Dokumentasi privasi Atlas](https://atlasgo.io/cli/data-privacy)) | ✅ (tiada telemetri ditemui. Perpustakaan `:telemetry` Elixir ialah instrumentasi/hooks tempatan, bukan analitik yang menghantar data keluar) |
| Lesen | MIT | Komuniti percuma / Teams berbayar | MIT | Apache 2.0 (ciri cloud berbayar) | Apache 2.0 |

### Ciri dan kematangan

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| Kebergantungan runtime | ✅ (tiada — satu binary, mengandungi ERTS) | ❌ (memerlukan JVM, atau CLI mereka yang mengandungi JVM) | ✅ (tiada — satu binary Go) | ✅ (tiada — satu binary Go) | ❌ (memerlukan Elixir + Erlang/OTP + Mix dipasang — ini perpustakaan, bukan binary berdiri sendiri) |
| Sokongan database | ❌ (PostgreSQL sahaja) | ✅ (PostgreSQL, MySQL, Oracle, dan lain-lain) | ✅ (banyak) | ✅ (banyak) | ✅ (PostgreSQL, MySQL, SQLite, MSSQL, dan lain-lain melalui adapter) |
| Migrasi transaksional | ✅ (per fail) | ✅ | ⚠️ (bergantung pada driver) | ✅ | ✅ |
| Rollback | ✅ (`migrate down`, `.down.sql` ditulis secara manual) | ❌ (tier Teams/Enterprise sahaja) | ✅ (skrip down ditulis secara manual) | ✅ (reverse diff dikira secara automatik) | ✅ (`mix ecto.rollback`, `down`/`change` ditulis secara manual) |
| Pengesanan drift checksum | ✅ (memblok secara lalai) | ✅ | ❌ | ✅ (melalui lint) | ❌ (tiada yang ditemui dalam teras Ecto) |
| Kunci konkurensi | ✅ (advisory lock Postgres, sentiasa aktif) | ✅ | ⚠️ (bergantung pada driver) | ✅ | ⚠️ (table lock secara lalai; advisory lock tersedia tetapi perlu dikonfigurasi) |
| Dry-run / pratonton | ✅ | ❌ (Enterprise sahaja) | ❌ | ✅ (`migrate lint`) | ⚠️ (`mix ecto.migrations` memaparkan status tertangguh, bukan pratonton SQL sebenar) |
| Output JSON untuk CI | ✅ | ⚠️ (terhad) | ❌ | ✅ | ❌ (output tugas Mix piawai bersifat teks) |
| Saiz binary/muat turun anggaran | ~40–60 MB* (mengandungi runtime Erlang) | ~100+ MB (mengandungi JRE) | ~10–20 MB (binary Go asli) | ~15–25 MB (binary Go asli) | N/A (perpustakaan, bukan binary yang diedarkan) |
| Kematangan | ❌ (baharu) | ✅ (10+ tahun, banyak diadaptasi) | ✅ (10+ tahun, banyak diadaptasi) | ⚠️ (lebih baharu, berkembang pesat) | ✅ (teras ekosistem Elixir/Phoenix sejak 2015) |

\* Angka saiz adalah anggaran dan berubah antara rilis — semak dengan `ls -lh` pada binary `eds` yang anda muat turun dan halaman rilis terkini setiap tool untuk angka yang tepat.   
-- 
## Keselamatan

<!-- CHECKSUMS-START -->
### 🔒 Jumlah Semak SHA256 untuk Keluaran v0.9.0

```
be6b4fb705849ea6a39eefb7cb2588ea53ac85fd36e69a7cabe9ca2e82f5d4f6  eds-linux-x86_64
a883258573b3b1c389f90209497861d6eeefcbaef2624bbd50cb2b08a7717923  eds-macos-arm64
c286b463b130481c243dcc9341aa32a1709c0097fd45cdd8dcd6299abff645d9  eds-windows-x86_64
```
<!-- CHECKSUMS-END -->

Untuk isu keselamatan, sila hubungi: [seyed@swiftter.com]

## 🖥️ Penggunaan

**Pemasangan:**
```bash
curl -fsSL https://raw.githubusercontent.com/seyed/erl_data_shift/main/scripts/install.sh | bash
```

Atau muat turun secara manual: dapatkan binari untuk OS anda dari [Rilis](../../releases), kemudian `chmod +x eds`.

**Penetapan:**
```bash
eds init          # membuat kerangka migrations/ dan .env.example dalam direktori semasa
# sunting .env.example, isi nilai Postgres sebenar, simpan sebagai .env
```

## Arahan

| Arahan | Penerangan |
|---|---|
| `con_check` | Menguji konektiviti Postgres menggunakan kelayakan `.env` anda. |
| `stat` | Menunjukkan nama jadual, bilangan baris, dan saiz storan, terbesar dahulu. |
| `history` | Menunjukkan migrasi yang telah diterapkan — masa sejak penerapan, siapa yang menerapkan/memulihkan setiap satu, dan semakan hanyutan tempatan/DB. |
| `migrate` | Menjalankan semua fail `.sql` yang tertangguh dari `./migrations` secara transaksional. Menolak jika migrasi yang telah diterapkan telah disunting (hanyutan jumlah semakan). |
| `migrate force` | Sama seperti migrate, tetapi memintas semakan hanyutan jumlah semakan. Gunakan secara sengaja, bukan secara lalai. |
| `migrate dry-run` | Menyenaraikan migrasi yang tertangguh tanpa menerapkannya. |
| `migrate down` | Memulihkan migrasi yang diterapkan terbaru. |
| `migrate -f <path>` | Sama seperti `migrate`, tetapi menunjuk ke direktori migrasi tersuai. |
| `new <name>` | Membuat pasangan fail migrasi up+down bernombor baharu. |
| `validate` | Menjalankan uji migrasi yang tertangguh dalam transaksi yang dipulihkan untuk menangkap ralat awal. |
| `verify` | Menyemak bahawa fail migrasi yang diterapkan tidak telah disunting sejak ia dijalankan (hanyutan jumlah semakan). |
| `init` | Membuat kerangka `migrations/` dan `.env.example` dalam direktori semasa. |
| `--version` | Mencetak versi `eds`. |
| `--help` / `-h` | Menunjukkan mesej bantuan ini. |

## 🔬 Pengujian   



<!-- COVERAGE-START -->
### 🧪 Liputan Ujian — Jumlah: 91%

[📊 Lihat laporan liputan interaktif baris demi baris](https://seyed.github.io/erl_data_shift/)

| Modul | Liputan |
|---|---|
| ✅ erl_data_shift_bench | 100% |
| ✅ erl_data_shift_json | 100% |
| ✅ erl_data_shift_migrations | 96% |
| ✅ erl_data_shift_env | 94% |
| ✅ erl_data_shift_db | 93% |
| ✅ erl_data_shift_migrator | 93% |
| ✅ erl_data_shift_app | 90% |
| ✅ erl_data_shift_scaffold | 82% |
| ✅ erl_data_shift_init | 80% |
<!-- COVERAGE-END -->
