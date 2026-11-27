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
| `bin/docker-build.sh` | ایمیج داکر را با **داکرفایل خودِ grist-core** می‌سازد (توصیه‌شده) |
| `docker-compose.yml` | اجرای ایمیج با volume برای داده؛ `docker compose up -d` |
| `docs/DOCKER.md` | همهٔ جزئیات داکر: رم، volume، آپدیت، GHCR، محدودیت‌ها |
| `docs/UPSTREAM.md` | فهرست نقاط اتصال به upstream و نحوهٔ بررسی آن‌ها |
| `docs/GITHUB-SETUP.md` | ساخت مخزن خصوصی، ریموت‌ها، و آزمون خودکار هفتگی |
| `.github/workflows/fa-verify.yml` | آزمون خودکار «آیا لایه هنوز روی آخرین upstream می‌نشیند؟» |
| `.github/workflows/fa-docker.yml` | ایمیج را واقعاً می‌سازد و چک می‌کند لایه داخلش هست و سرور بالا می‌آید |

## نصب با داکر (کم‌دردسرترین راه)

سه خط، همین:

```bash
git clone https://github.com/AliMalakoo/grist-core-fa.git
cd grist-core-fa && ./bin/docker-build.sh      # merge + docker build (بار اول ۱۰-۲۰ دقیقه)
docker compose up -d                           # http://localhost:8484
```

`bin/docker-build.sh` داکرفایل نمی‌نویسد: درخت merge‌شده را به **داکرفایل رسمی خودِ grist-core**
می‌دهد، پس پایتون فرمول‌ها، سندباکس، `/persist` و بقیه دقیقاً نسخهٔ بالادستی است و لایهٔ فارسی از
همان `COPY app` و `COPY assets` وارد می‌شود. ایمیج نسخهٔ community است (مثل `gristlabs/grist-oss`)؛
`ext/` توخالی‌ای که اسکریپت می‌سازد همان چیزی است که بالادستی هم در CI خودش می‌سازد — توضیح در
`docs/DOCKER.md`.

کلید ورود پنل `/admin` بار اول در لاگ چاپ می‌شود (`docker compose logs grist | grep -i "boot key"`)،
یا خودتان از اول تعیینش کنید:

```bash
export GRIST_SESSION_SECRET="$(openssl rand -base64 24)"
export GRIST_BOOT_KEY='یک-رشته-بلند'
docker compose up -d
```

آپدیت بعدی: `git pull && ./bin/docker-build.sh v1.7.30 && docker compose up -d` (بیلد با
`docker compose build` انجام نمی‌شود؛ `build:` عمدتاً در compose نیست).
جزئیات، نیاز رم، پشتیبان‌گیری و انتقال ایمیج به GHCR: `docs/DOCKER.md`.

## نصب از منبع (اگر داکر نمی‌خواهید)

پیش‌نیازها: **Node.js 22** (`.nvmrc` همین را می‌گوید؛ ۲۰ هم می‌شود)، **yarn 1.22** (با
`corepack enable` درمی‌آید)، **git**، و **python3 + venv** (برای اجرای فرمول‌ها). روی ویندوز همهٔ
این دستور را در WSL بزنید (اسکریپت‌ها bash هستند).

```bash
# ۱) لایهٔ فارسی (مخزن خصوصی است: با SSH یا با token)
git clone git@github.com:AliMalakoo/grist-core-fa.git
cd grist-core-fa
chmod +x bin/*.sh          # فقط اگر به‌جای clone، ZIP دانلود کرده‌اید (ZIP بیت اجرا نگه نمی‌دارد)

# ۲) grist-core را در نسخهٔ قفل‌شده بگیر و لایه را سوار کن
./bin/checkout.sh          # -> work/grist-core، خروجی: ۱۹ خط ok
cd work/grist-core

# ۳) نصب و build (همان چهار خطِ رسمی خودِ grist-core، با yarn)
yarn run set-community-edition    # وگرنه yarn install افزونه‌های نسخهٔ full را دانلود می‌کند
yarn run install:python           # sandbox_venv3 برای فرمول‌های پایتون
yarn run build                    # sanitize_translations + tsc + webpack (چند دقیقه)
yarn start                        # http://localhost:8484
```

`yarn start` حالت watch است (همه‌چیز را دوباره build می‌کند و با Ctrl+C می‌بندید). برای اجرای
ساده‌ترِ سروری: `yarn run build:prod` بعد `yarn run start:prod`.

**بار اول:** صفحهٔ «Quick setup» می‌آید و در همان ترمینال یک خط
`BOOT KEY: <رشته‌ی تصادفی>` چاپ می‌شود — همان کلید را بزنید تا اکانت ادمین ساخته شود. اگر خواستید
این مرحله رد شود: `GRIST_IN_SERVICE=true yarn start`.

دو نکته که معمولاً گمراه‌کننده‌اند:
- `app/common/version.ts` را **نسازید**؛ `buildtools/build.sh` خودش آن را از `package.json` و git
  می‌نویسد (تابع `build_version_file`). فقط وقتی لازم است که مستقیم `tsc` اجرا کنید (مثل step
  انتخابی `run_build` در workflow).
- `bin/update.sh` و `bin/checkout.sh` درخت کار را با `git clean -ffd` تمیز می‌کنند؛ اگر داخل
  `work/grist-core` چیز دستی گذاشته‌اید، قبلش بردارید.

## فعال کردن فارسی و جلالی

سه کلید جدا وجود دارد (هرکدام یک کار متفاوت می‌کند):

| چه | کجا | نتیجه |
| --- | --- | --- |
| زبان رابط کاربری | منوی بالا → **Account/Settings → Language → فارسی** (`app/client/ui/AccountPage.ts`) | کل صفحه RTL می‌شود، `<html lang="fa" dir="rtl" data-calendar="jalali">`، و تاریخ‌های رابط جلالی |
| زبان سند | داخل سند → ⚙️ **Document Settings → «زون محلی / Locale»** را روی فارسی (`fa-IR`) بگذارید | سلول‌های تاریخِ آن سند جلالی نمایش داده می‌شوند و ورودی جلالی را می‌پذیرند (`DocModel.ts:213` → `setJalaliDocLocale`) |
| فقط یک ستون | روی سرستونِ Date/DateTime → پیکربندی ویجت → تیک **«تقویم هجری شمسی»** | همان ستون جلالی، مستقل از زبان سند (و با برداشتن تیک، صریحاً میلادی می‌ماند) |

اگر «فارسی» در فهرست زبان‌ها نبود، یعنی `write_static_locales.js` اجرا نشده — یک `yarn run build`
دیگر آن را می‌سازد (فهرست زبان‌ها از `gristConfig.supportedLngs` می‌آید).

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

## مخزن روی گیت‌هاب (ساخته و push شده)

`https://github.com/AliMalakoo/grist-core-fa` — خصوصی، branch پیش‌فرض `fa`. روی ماشین تازه:

```bash
git clone git@github.com:AliMalakoo/grist-core-fa.git && cd grist-core-fa
bin/checkout.sh && cd work/grist-core && yarn install && yarn run build
```

دستورات ساخت دوباره (اگر روزی مخزن را از نو خواستید بسازید):

```bash
# ابزار گیت‌هاب (a): با gh
gh auth login
cd <مسیر این پوشه>
git init -b fa && git add -A && git commit -m "لایهٔ فارسی grist-core: جلالی، RTL، کاتالوگ fa"
gh repo create grist-core-fa --private --source . --remote origin --push

# دستی (b): وب
# 1. New repository → name: grist-core-fa → Private → Create (بدون README؛ وگرنه تاریخچهٔ ما
#    روی یک mainِ بی‌ربط می‌نشیند و باید merge یا force کنید)
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
