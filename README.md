# grist-core fa — لایهٔ فارسی گریست (Jalali + RTL + ترجمه)

این مخزن **انشعاب (fork) کامل grist-core نیست**. فقط فایل‌هایی را نگه می‌دارد که برای فارسی‌سازی
لازمند — تقویم جلالی، چیدمان راست‌به‌چپ، ویرایشگر تاریخ جلالی، و کاتالوگ ترجمهٔ `fa` (که
grist-core از Weblate دارد و ما گسترشش می‌دهیم) — به‌همراه
اسکریپت‌هایی که همین لایه را روی **آخرین نسخهٔ خودِ grist-core** سوار می‌کنند.

وقتی upstream یک فایل را تغییر دهد، اسکریپت‌ها آن فایل را از نسخهٔ شما نمی‌گیرند؛ تغییر upstream
می‌ماند و تغییرات ما با ادغام سه‌طرفه روی آن سوار می‌شود. فقط وقتی واقعاً در یک محل درگیری پیش
بیاید، همان یک فایل گزارش می‌شود — بقیه دست‌نخورده می‌مانند.

| مسیر | توضیح |
| --- | --- |
| `overlay/` | ۱۹ فایل لایهٔ فارسی، در همان مسیر داخل مخزن grist-core (۵ جدید + ۱۴ دست‌خورده) |
| `patch/fa-modified.patch` | diff همان ۱۴ فایل دست‌خورده؛ ۵ فایل جدید کپی می‌شوند، نه ادغام |
| `patch/files.txt` + `added/modified` | فهرست فایل‌ها؛ اسکریپت‌ها از همین فهرست کار می‌کنند |
| `UPSTREAM.lock` | نسخه‌ای که این لایه روی آن ساخته/آزمایش شده (`v1.7.22`) |
| `bin/checkout.sh` | grist-core را در نسخهٔ خواسته‌شده می‌گیرد و لایه را سوار می‌کند |
| `bin/update.sh` | همان کار برای یک تگ جدید + گزارش اینکه upstream چه چیزهایی را عوض کرده |
| `bin/verify.sh` | بررسی یک‌به‌ید بودن فایل‌ها با overlay |
| `bin/rerecord.sh` | بعد از ادغام موفق، overlay و patch این مخزن را به‌روز می‌کند |
| `docs/UPSTREAM.md` | فهرست نقاط اتصال به upstream و نحوهٔ بررسی آن‌ها |
| `docs/GITHUB-SETUP.md` | ساخت مخزن خصوصی، ریموت‌ها، و آزمون خودکار هفتگی |
| `.github/workflows/fa-verify.yml` | آزمون خودکار «آیا لایه هنوز روی آخرین upstream می‌نشیند؟» |

## نصب از این مخزن

```bash
git clone <آدرسِ این مخزن> grist-core-fa
cd grist-core-fa
bin/checkout.sh                  # grist-core را در work/grist-core می‌سازد و لایه را سوار می‌کند
cd work/grist-core
yarn install
yarn run build                   # tsc + webpack + translations
yarn run dev                     # http://localhost:8484
```

نکتهٔ محیطی: `app/common/version.ts` یک فایل تولیدی و gitignored است؛ اگر build از نبود آن شکایت
کرد بسازیدش:

```bash
echo 'export const VERSION: string = "grist-core-fa";' > work/grist-core/app/common/version.ts
```

## با یک نسخهٔ جدید از grist-core به‌روز کردن

`bin/update.sh` کار را انتخاب می‌کند: اگر upstream هیچ‌کدام از ۱۴ فایل دست‌خوردهٔ ما را لمس نکرده
باشد، لایه را کپی می‌کند (بدون ادغام، بدون patch)؛ اگر لمس کرده باشد، patch را سه‌طرفه ادغام
می‌کند و فقط محل‌های واقعاً متعارض را گزارش می‌دهد.

```bash
git fetch --tags
bin/update.sh v1.7.30             # یا: bin/update.sh            ( newest tag = sort -V )
bin/verify.sh work/grist-core merge
cd work/grist-core && yarn install && yarn run build
```

نمایش خروجی `bin/verify.sh` سه حالت است: `ok` (عیناً overlay ما)، `merged` (همه‌چیز ما + تغییر
بالادستی کنار هم)، `DIFFERS`/`MISSING` (این را باید دستی ببینید).

### اگر درگیری گزارش شد

اسکریپت عمداً مخزن را نیمه‌کاره ول نمی‌کند؛ `git apply --3way` در فایل‌های متعارض نشانگر
`<<<<<<<` می‌گذارد و با کد خروج ۲ تمام می‌شود. فهرست همان فایل‌ها را خود git می‌دهد:

```bash
cd work/grist-core
git ls-files -u | awk '{print $4}' | sort -u          # کدام فایل‌ها درگیرند
git diff --diff-filter=U --stat
# همان‌جا در نشانگرهای <<<<<<< <<<<<<< >>>>>>> دست‌ورزی کنید، معمولاً ۱ تا ۳ فایل
bin/verify.sh work/grist-core merge && yarn run build
bin/rerecord.sh work/grist-core                        # overlay + patch + UPSTREAM.lock را بنویسد
```

اگر ترجیح می‌دهید تغییر بالادستی را فعلاً نادیده بگیرید (مثلاً برای یک build اضطراری):
`MODE=clobber bin/apply-overlay.sh work/grist-core`. ولی patch بازنویسی‌نشده می‌ماند، پس بعداً
ادغام را دوباره انجام دهید.

برای نصب معمول (نه update) `bin/checkout.sh <ref>` پیش‌فرض `MODE=clobber` است — همیشه می‌نشیند،
چون فایل‌های ما را کپی می‌کند. برای دیدنِ درگیری‌ها `MODE=merge bin/checkout.sh <ref>`.

## ساخت مخزن خصوصی روی گیت‌هاب

```bash
# ابزار گیت‌هاب (a): با gh
gh auth login
cd /home/user/grist-core-fa
git init -b fa && git add -A && git commit -m "لایهٔ فارسی grist-core: جلالی، RTL، کاتالوگ fa"
gh repo create grist-core-fa --private --source . --remote origin --push

# دستی (b): وب
# 1. New repository → name: grist-core-fa → Private → Create (بدون README)
# 2. git init -b fa && git add -A && git commit -m "..."
#    git remote add origin git@github.com:<کاربر>/grist-core-fa.git
#    git push -u origin fa
# 3. Settings → Branches: `fa` را default کنید؛ در Settings → Actions اجازهٔ cron بدهید.
```

اسکریپت‌ها `UPSTREAM_URL` را از محیط می‌پذیرند، پس می‌توانید اول با یک آینهٔ محلی همه‌چیز را
آزمایش کنید:

```bash
git clone --mirror https://github.com/gristlabs/grist-core.git /tmp/grist-mirror
UPSTREAM_URL=/tmp/grist-mirror WORK_DIR=/tmp/grist-test bin/checkout.sh v1.7.22
```

## مرزها (چیزی که این لایه انجام نمی‌دهد)

- ذخیرهٔ داده همان **میلادیِ UTC** است؛ جلالی فقط نمایش و ورودی است. تاریخ‌های متنی داخل
  `RichText`/توضیحات ترجمه یا تبدیل نمی‌شوند.
- آرایهٔ ستون‌های `GridView` عمداً آینه نشده؛ `Rtl.css` فقط روی سلکتورهای پایدار کار می‌کند نه
  هندسهٔ محاسبه‌شدهٔ گرید (`.grid_view_data` و ردهٔ اسکرول جهتشان `ltr` می‌ماند).
- ترجمهٔ `fa` کلمات کلیدی‌اش با `en` یکی است (۱۹۵ گروه / ۱۴۵۸ کلید client و ۱۳ کلید server)؛
  اگر نسخهٔ جدید upstream کلید تازه‌ای اضافه کند، آن کلید در `fa` خالی می‌ماند و UI انگلیسی نشان
  می‌دهد — `yarn run translations` و سپس `node buildtools/sanitize_translations.js`.
- صفحه‌های `static/*.html` به‌جز `static/app.html` هنوز `<html>` بدون `lang`/`dir` دارند (مستقل از
  این لایه است؛ `index.js` هم template خود را بر اساس `gristConfig.singlePage` انتخاب می‌کند).
- تقویم سه‌ماههٔ Month view شمارهٔ روز جلالی ندارد؛ فقط هدر جلالی و شروع هفته شنبه.

## وضعیت آزمون

`overlay/test/common/jalali.ts` (۳۰ آزمون) در `npm run test:common` می‌آید. در محیط توسعهٔ این
بسته اجرا و سبز شده: `tsc --build tsconfig-prod.json` (rc=0)، build کامل webpack،
`mocha _build/test/common/jalali.js` (۳۰ passing)،
`mocha _build/test/common/{parseDate,ValueFormatter,RelativeDates}.js`
و `_build/test/server/lib/{sendAppPage,ServerLocale}.js` (با هم ۳۲ passing)، و دو harness jsdom
برای `JalaliDatePicker` (۱۶ بررسی DOM) و `LanguageDirection` (۱۵ حالت زبان).
