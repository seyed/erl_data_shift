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

## Perbandingan eds dengan pemain utama

_eds adalah baharu — ini adalah alat yang mapan dan diterima secara meluas. Berikut adalah pandangan jujur tentang di mana eds sesuai dan di mana ia belum._

**Di mana eds sesuai:** CLI kecil, bebas kebergantungan untuk pasukan pada Postgres yang ingin keselamatan gaya Flyway (transaksi, jumlah semakan, penguncian) tanpa JVM atau tier berbayar — tidak sesuai jika anda memerlukan sokongan pelbagai pangkalan data atau sudah mendalam dalam persediaan Atlas/Flyway.

### Kos, data, dan lesen

| | **eds** | Flyway | golang-migrate | Atlas |
|---|---|---|---|---|
| Kos | ✅ (percuma, tiada tier berbayar — semua ciri termasuk) | ⚠️ (teras percuma, tetapi pengunduran/dry-run memerlukan Teams/Enterprise berbayar) | ✅ (percuma, tiada tier berbayar) | ⚠️ (CLI percuma, tetapi ciri lanjutan dikunci di belakang Atlas Cloud berbayar) |
| Pengumpulan data penggunaan | ✅ (tiada — eds tidak menghantar apa-apa ke mana-mana) | ⚠️ (telemetri aktif secara lalai, opt-out melalui pemboleh ubah persekitaran — [dokumen Redgate](https://documentation.red-gate.com/fd/redgate-disable-telemetry-environment-variable-277579301.html)) | ✅ (tiada telemetri ditemui dalam dokumen/repo mereka) | ⚠️ (telemetri aktif secara lalai — arahan dijalankan, OS, nama hos — opt-out melalui pemboleh ubah persekitaran — [dokumen privasi Atlas sendiri](https://atlasgo.io/cli/data-privacy)) |
| Lesen | MIT | Community percuma / Teams berbayar | MIT | Apache 2.0 (ciri awan berbayar) |

### Ciri-ciri dan kematangan

| | **eds** | Flyway | golang-migrate | Atlas |
|---|---|---|---|---|
| Kebergantungan runtime | ✅ (tiada — satu binari, mengandungi ERTS) | ❌ (memerlukan JVM, atau CLI mereka yang mengandungi satu) | ✅ (tiada — satu binari Go) | ✅ (tiada — satu binari Go) |
| Sokongan pangkalan data | ❌ (PostgreSQL sahaja) | ✅ (PostgreSQL, MySQL, Oracle, dan lain-lain) | ✅ (banyak) | ✅ (banyak) |
| Migrasi transaksional | ✅ (per fail) | ✅ | ⚠️ (bergantung pada pemacu) | ✅ |
| Pengunduran | ✅ (`migrate down`, `.down.sql` tulisan tangan) | ❌ (tier Teams/Enterprise sahaja) | ✅ (skrip down tulisan tangan) | ✅ (beza songsang dikira secara automatik) |
| Pengesanan hanyutan jumlah semakan | ✅ (memblok secara lalai) | ✅ | ❌ | ✅ (melalui lint) |
| Kunci serentak | ✅ (kunci nasihat Postgres) | ✅ | ⚠️ (bergantung pada pemacu) | ✅ |
| Dry-run / pratonton | ✅ | ❌ (Enterprise sahaja) | ❌ | ✅ (`migrate lint`) |
| Output JSON untuk CI | ✅ | ⚠️ (terhad) | ❌ | ✅ |
| Saiz binari/muat turun anggaran | ~40–60 MB* (mengandungi runtime Erlang) | ~100+ MB (mengandungi JRE) | ~10–20 MB (binari Go asli) | ~15–25 MB (binari Go asli) |
| Kematangan | ❌ (baharu) | ✅ (10+ tahun, diterima secara meluas) | ✅ (10+ tahun, diterima secara meluas) | ⚠️ (lebih baharu, berkembang pesat) |

\* Angka saiz adalah anggaran dan berubah antara edisi — semak `ls -lh` pada binari `eds` anda sendiri yang dimuat turun dan halaman edisi terkini setiap alat untuk angka semasa yang tepat, bukan bergantung pada jadual ini.   

## Keselamatan

<!-- CHECKSUMS-START -->
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
### 🧪 Liputan Ujian — Jumlah: 92%

[📊 Lihat laporan liputan interaktif baris demi baris](https://seyed.github.io/erl_data_shift/)

| Modul | Liputan |
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