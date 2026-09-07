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

## השוואה עם כלים מרכזיים

_eds הוא חדש — אלה הם כלים מבוססים ונפוצים. הנה מבט כנה על היכן eds מתאים והיכן שהוא עדיין לא מתאים._

**היכן eds מתאים:** CLI קטן וללא תלויות, למצוות שעובדות עם Postgres ומחפשות בטיחות ברמת Flyway (תהליכים, בדיקות סכום, נעילה) ללא JVM או תוכנית מנומקת — לא מתאים אם אתה צריך תמיכה במספר בסיסי נתונים או שאתה כבר עמוק בהגדרת Atlas/Flyway.

| | **eds** | Flyway | golang-migrate | Atlas |
|---|---|---|---|---|
| עלות | ✅ (חינמי, ללא תוכנית מנומקת — כל הפיצ'רים כלולים) | ⚠️ (ליבה חינמית, אך החזרה/ריצה יבשה דורשים Teams/Enterprise בתשלום) | ✅ (חינמי, ללא תוכנית מנומקת) | ⚠️ (CLI חינמי, אך פיצ'רים מתקדמים מאחורי Atlas Cloud בתשלום) |
| איסוף נתוני שימוש | ✅ (אין — eds לא שולח כלום לשום מקום) | ⚠️ (טלמטריה מופעלת כברירת מחדל, ניתן להשבתה דרך משתנה סביבה — [תיעוד Redgate](https://documentation.red-gate.com/fd/redgate-disable-telemetry-environment-variable-277579301.html)) | ✅ (לא נמצאה טלמטריה בתיעוד/מאגר שלהם) | ⚠️ (טלמטריה מופעלת כברירת מחדל — פקודות שרוצו, מערכת הפעלה, שם מחשב — ניתן להשבתה דרך משתנה סביבה — [תיעוד הפרטיות של Atlas](https://atlasgo.io/cli/data-privacy)) |
| רישיון | MIT | קהילה חינמי / Teams בתשלום | MIT | Apache 2.0 (פיצ'רי ענן בתשלום) |

### פיצ'רים ובשלות

| | **eds** | Flyway | golang-migrate | Atlas |
|---|---|---|---|---|
| תלות ריצה | ✅ (אין — קובץ בינארי יחיד, כולל ERTS) | ❌ (דורש JVM, או CLI שלהם שכולל אחד) | ✅ (אין — קובץ בינארי Go יחיד) | ✅ (אין — קובץ בינארי Go יחיד) |
| תמיכת בסיסי נתונים | ❌ (PostgreSQL בלבד) | ✅ (PostgreSQL, MySQL, Oracle ועוד) | ✅ (רבים) | ✅ (רבים) |
| העברות תהליכיות | ✅ (לפי קובץ) | ✅ | ⚠️ (תלוי בדרייבר) | ✅ |
| החזרה (Rollback) | ✅ (`migrate down`, `.down.sql` כתוב ידנית) | ❌ (רק ברמת Teams/Enterprise) | ✅ (סקריפטי down כתובים ידנית) | ✅ (חישוב אוטומטי של diff הפוך) |
| זיהוי סטיית בדיקת סכום | ✅ (חסום כברירת מחדל) | ✅ | ❌ | ✅ (דרך lint) |
| נעילת מקבילות | ✅ (נעילת ייעוץ של Postgres) | ✅ | ⚠️ (תלוי בדרייבר) | ✅ |
| ריצה יבשה / תצוגה מקדימה | ✅ | ❌ (רק Enterprise) | ❌ | ✅ (`migrate lint`) |
| פלט JSON ל-CI | ✅ | ⚠️ (מגביל) | ❌ | ✅ |
| גודל בינארי/הורדה (קירוב) | ~40–60 MB* (כולל ריצת Erlang) | ~100+ MB (כולל JRE) | ~10–20 MB (בינארי Go נייטיבי) | ~15–25 MB (בינארי Go נייטיבי) |
| בשלות | ❌ (חדש) | ✅ (מעל 10 שנים, נפוץ מאוד) | ✅ (מעל 10 שנים, נפוץ מאוד) | ⚠️ (חדש יחסית, צומח מהר) |

\* מספרי הגודל הם קירוביים ומשתנים בין גרסאות — בדוק עם `ls -lh` על קובץ ה-`eds` שהורדת ועל דף הרilase האחרון של כל כלי למספרים מדויקים.

---
## אבטחה   
<!-- CHECKSUMS-START -->
### 🔒 סכומי ביקורת SHA256 עבור גרסה v0.8.9

```
da04b5dcd5a146f4231e99e429335c7f82ac39e2e3a9e05abff7578222ed8729  eds-linux-x86_64
4940f53560beac56cca6aa454caf1ef8911b891e44678b13ac4ce3e748aad7a0  eds-macos-arm64
8e95964c4595df3aa2b52571aab5f64248a82eaf8798e37fa7765456332b04cc  eds-windows-x86_64
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
### 🧪 כיסוי בדיקות — סה"כ: 92%

[📊 צפה בדוח כיסוי אינטראקטיבי](https://seyed.github.io/erl_data_shift/)

<table dir="rtl" align="right">
<tr><th>כיסוי</th><th>מודול</th></tr>
<tr><td>✅ 100%</td><td>erl_data_shift_bench</td></tr>
<tr><td>✅ 100%</td><td>erl_data_shift_json</td></tr>
<tr><td>✅ 96%</td><td>erl_data_shift_migrations</td></tr>
<tr><td>✅ 94%</td><td>erl_data_shift_env</td></tr>
<tr><td>✅ 93%</td><td>erl_data_shift_app</td></tr>
<tr><td>✅ 93%</td><td>erl_data_shift_db</td></tr>
<tr><td>✅ 92%</td><td>erl_data_shift_migrator</td></tr>
<tr><td>✅ 82%</td><td>erl_data_shift_scaffold</td></tr>
<tr><td>✅ 80%</td><td>erl_data_shift_init</td></tr>
</table>
<!-- COVERAGE-END -->





