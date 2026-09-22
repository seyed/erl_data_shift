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
🇮🇱 עברית*  | [🇬🇧 English](README.md) | [🇯🇵 日本語](README.ja.md) | [🇨🇳 中文](README.zh.md) | [🇸🇦 العربية](README.ar.md) | [🇫🇷 Français](README.fr.md) | [🇩🇪 Deutsch](README.de.md) | [🇳🇴 Norsk](README.no.md) | [🇸🇪 Svenska](README.sv.md) | [🇹🇷 Türkçe](README.tr.md) | [🇲🇾 Bahasa Melayu](README.ms.md) | [🇮🇩 Bahasa Indonesia](README.id.md) | [🇪🇸 Español](README.es.md)   

**ממשק שורת פקודה (CLI) עצמאי להגירת Postgres** 

[![CI](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml/badge.svg)](https://github.com/seyed/erl_data_shift/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/github/license/seyed/erl_data_shift)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/seyed/erl_data_shift)](https://github.com/seyed/erl_data_shift/releases)
![macOS](https://img.shields.io/badge/macOS-supported-success)
![Linux](https://img.shields.io/badge/Linux-supported-success)
![Windows](https://img.shields.io/badge/Windows-supported-success)
![Erlang/OTP](https://img.shields.io/badge/OTP-27%2B-blue)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)
* סליחה: תרגום זה נוצר באמצעות LLM. אם הניסוח אינו טבעי, ניתן לשלוח את הטקסט המלא בעברית ל-seyed@swiftter.com או לשלוח PR למאגר זה!   

## ⚠️ פרט מייחד
                                                                                                     
                                                                                                      
║                   שימוש באחריות המשתמש                                                                                                                       
                                                                                                      
                                                                                                     
                                                                                                  
תוכנה זו (להלן "הכלי") היא כלי העברת נתונים בקוד פתוח המסופק "כמות שהוא", ללא אחריות מכל סוג, מפורשת או מובנת, כולל אך לא רק אחריות לכשירות למכירה, לכשירות למטרה
מסוימת, וללא פלישה לזכויות.

אחריות המשתמש:

*   אתה היחיד האחראי לגיבוי הנתונים שלך לפני הרצת כל העברה.
*   אתה היחיד האחראי לבדיקת הכלי בסביבה שאינה ייצור לפני שימוש בנתונים חיים.
*   המחברים והתורמים של כלי זה לא יישאו באחריות לכל אובדן נתונים, נזק לנתונים, הפסקת שירות, או כל נזק ישיר, עקיף, מקרי או תוצאתי הנובע משימוש בתוכנה זו או מייכולת השימוש בה.
*   באמצעות כלי זה, אתה מאשר שקראת, הבנת והסמכת לתנאים אלה. אם אינך מסכים, אל תשתמש בתוכנה זו.

---
## השוואת eds עם הכלים המובילים

_eds הוא כלי חדש — אלה כליים מוכחים ומקובלים ברחב. הנה מבט כנה על איפה eds מתאים ואיפה הוא עדיין לא מגיע._

**איפה eds מתאים:** CLI קטן ונטול תלויות, עבור צוותים שעובדים על PostgreSQL שרוצים רמת בטיחות בסגנון Flyway (transactions, checksums, locking) ללא JVM או מנוי בתשלום — לא מתאים אם אתם צריכים תמיכה במספר בסיסי נתונים, אם אתם כבר עמוקים ב-Atlas/Flyway, או אם אתם בונים אפליקציית Elixir שבה Ecto היא הבחירה הטבעית.

### עלות, איסוף נתונים ורישיון

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| עלות | ✅ (חינם, ללא מנוי בתשלום — כל התכונות כלולות) | ⚠️ (ליבה חינם, אבל rollback/dry-run דורשים Teams/Enterprise בתשלום) | ✅ (חינם, ללא מנוי בתשלום) | ⚠️ (CLI חינם, אבל תכונות מתקדמות מאחורי Atlas Cloud בתשלום) | ✅ (חינם, ללא מנוי בתשלום) |
| איסוף נתוני שימוש | ✅ (אין — eds לא שולח כלום לשום מקום) | ⚠️ (טלמטריה פעילה כברירת מחדל, אפשר להימנע דרך משתנה סביבה — [מסמכי Redgate](https://documentation.red-gate.com/fd/redgate-disable-telemetry-environment-variable-277579301.html)) | ✅ (לא נמצאה טלמטריה במסמכים/מאגר שלהם) | ⚠️ (טלמטריה פעילה כברירת מחדל — פקודות שרצו, OS, hostname — אפשר להימנע דרך משתנה סביבה — [מסמכי הפרטיות של Atlas](https://atlasgo.io/cli/data-privacy)) | ✅ (לא נמצאה טלמטריה. ספריית `:telemetry` של Elixir היא אינסטרומנטציה/הוקים מקומיים, לא אנליטיקה ששולחת החוצה) |
| רישיון | MIT | קהילה חינם / Teams בתשלום | MIT | Apache 2.0 (תכונות ענן בתשלום) | Apache 2.0 |

### תכונות ובשלות

| | **eds** | Flyway | golang-migrate | Atlas | Ecto |
|---|---|---|---|---|---|
| תלות ב-Runtime | ✅ (אין — בינארי יחיד, כולל ERTS) | ❌ (דורש JVM, או ה-CLI שלהם שכולל אחד) | ✅ (אין — בינארי Go יחיד) | ✅ (אין — בינארי Go יחיד) | ❌ (דורש התקנת Elixir + Erlang/OTP + Mix — זו ספרייה, לא בינארי עצמאי) |
| תמיכה בבסיסי נתונים | ❌ (PostgreSQL בלבד) | ✅ (PostgreSQL, MySQL, Oracle ועוד) | ✅ (הרבה) | ✅ (הרבה) | ✅ (PostgreSQL, MySQL, SQLite, MSSQL ועוד דרך adapters) |
| מיגרציות transaktional | ✅ (לפי קובץ) | ✅ | ⚠️ (תלוי ב-driver) | ✅ | ✅ |
| Rollback | ✅ (`migrate down`, `.down.sql` שנכתבו ידנית) | ❌ (רק Teams/Enterprise) | ✅ (סקריפטי down שנכתבו ידנית) | ✅ (reverse diff שחושב אוטומטית) | ✅ (`mix ecto.rollback`, `down`/`change` שנכתבו ידנית) |
| זיהוי סטיית checksum | ✅ (חסום כברירת מחדל) | ✅ | ❌ | ✅ (דרך lint) | ❌ (לא נמצא בליבת Ecto) |
| נעילת concurrent | ✅ (advisory lock של Postgres, תמיד פעיל) | ✅ | ⚠️ (תלוי ב-driver) | ✅ | ⚠️ (table lock כברירת מחדל; advisory lock זמין אך דורש התאמה) |
| Dry-run / תצוגה מקדימה | ✅ | ❌ (רק Enterprise) | ❌ | ✅ (`migrate lint`) | ⚠️ (`mix ecto.migrations` מציג סטטוס ממתין, לא תצוגת SQL אמיתית) |
| פלט JSON ל-CI | ✅ | ⚠️ (מגובל) | ❌ | ✅ | ❌ (פלט המשימות הסטנדרטי של Mix הוא טקסטואלי) |
| גודל בינארי/הורדה משוער | ~40–60 MB* (כולל Erlang runtime) | ~100+ MB (כולל JRE) | ~10–20 MB (בינארי Go נטייבי) | ~15–25 MB (בינארי Go נטייבי) | N/A (ספרייה, לא בינארי מופץ) |
| בשלות | ❌ (חדש) | ✅ (10+ שנים, מקובל ברחב) | ✅ (10+ שנים, מקובל ברחב) | ⚠️ (חדש יותר, גדל במהירות) | ✅ (ליבת אקו-סיסטם Elixir/Phoenix מאז 2015) |

\* המספרים משוערים ומשתנים בין גרסאות — בדקו עם `ls -lh` על הבינארי של `eds` שהורדתם ועל דף ה-release העדכני ביותר של כל כלי כדי לקבל מספרים מדויקים.   
---
## אבטחה   
<!-- CHECKSUMS-START -->
### 🔒 סכומי ביקורת SHA256 עבור גרסה v0.9.2

```
137375221c5561dcefc23f13f435bff5238206353f928aa7617c26e9e96afb49  eds-linux-x86_64
7ae4aed653b6699458e5e2b5e94f7e8dbd72199eb41896c437576a9b00570722  eds-macos-arm64
f9efc72abc2a8f75bdbe52d3e9972de9115239ecef3a9255e58bb7d2dd3da151  eds-windows-x86_64
```
<!-- CHECKSUMS-END -->

## 🖥️ שימוש

**התקנה:**
```bash
curl -fsSL https://raw.githubusercontent.com/seyed/erl_data_shift/main/scripts/install.sh | bash   
```
או הורדה ידנית: קח את הבינארי למערכת ההפעלה שלך מ-Releases, ואז chmod +x eds.


## הגדרה:
```
eds init          # יוצר את migrations/ ו-.env.example בתיקייה הנוכחית
# ערוך את .env.example, מלא ערכי Postgres אמיתיים, שמור כ-.env
```



## פקודות

| פקודה | תיאור |
|---|---|
| `con_check` | בודק חיבור ל-Postgres באמצעות פרטי הזיהוי מ-`.env`. |
| `stat` | מציג שמות טבלאות, מספר שורות וגודל אחסון, מהגדול לקטן. |
| `history` | מציג העברות שבוצעו — כמה זמן מאז, מי ביצע/החזיר כל אחת, ובדיקת סטייה מקומית/DB. |
| `migrate` | מריץ את כל קבצי ה-`.sql` הממתנים מ-`./migrations` בתהליך. דוחה אם העברה שבוצעה עורכה (סטיית בדיקת סכום). |
| `migrate force` | כמו migrate, אך עוקף את בדיקת סטיית בדיקת הסכום. להשתמש בכוונה, לא כברירת מחדל. |
| `migrate dry-run` | מציג רשימת העברות ממתנות ללא ביצוע. |
| `migrate down` | מחזיר את ההעברה האחרונה שבוצעה. |
| `migrate -f <path>` | כמו `migrate`, אך מצביע על תיקיית העברות מותאמת אישית. |
| `new <name>` | יוצר זוג קבצי העברה up+down עם מספור. |
| `validate` | מריץ את ההעברות הממתנות בתהליך שמוחזר כדי לזהות שגיאות מוקדם. |
| `verify` | בודק שקבצי העברה שבוצעו לא עורכו מאז הרצתם (סטיית בדיקת סכום). |
| `init` | יוצר `migrations/` ו-`.env.example` בתיקייה הנוכחית. |
| `--version` | מציג את גרסת `eds`. |
| `--help` / `-h` | מציג את הודעת העזרה הזו. |

 
<!-- COVERAGE-START -->
### 🧪 כיסוי בדיקות — סה"כ: 89%

[📊 צפה בדוח כיסוי אינטראקטיבי](https://seyed.github.io/erl_data_shift/)

<table dir="rtl" align="right">
<tr><th>כיסוי</th><th>מודול</th></tr>
<tr><td>✅ 100%</td><td>erl_data_shift_bench</td></tr>
<tr><td>✅ 100%</td><td>erl_data_shift_json</td></tr>
<tr><td>✅ 97%</td><td>erl_data_shift_migrations</td></tr>
<tr><td>✅ 94%</td><td>erl_data_shift_env</td></tr>
<tr><td>✅ 93%</td><td>erl_data_shift_db</td></tr>
<tr><td>✅ 93%</td><td>erl_data_shift_migrator</td></tr>
<tr><td>✅ 86%</td><td>erl_data_shift_app</td></tr>
<tr><td>✅ 82%</td><td>erl_data_shift_scaffold</td></tr>
<tr><td>✅ 80%</td><td>erl_data_shift_init</td></tr>
</table>
<!-- COVERAGE-END -->





