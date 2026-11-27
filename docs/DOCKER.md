# نصب با داکر (کوتاه‌ترین راه)

## چرا این روش «جعلی» نیست

ما یک ایمیج از صفر نمی‌نویسیم. `bin/docker-build.sh` فقط این کار را می‌کند:

1. `bin/checkout.sh` → یک grist-core تمیز در نسخهٔ قفل‌شده + ۱۹ فایل لایهٔ فارسی رویش.
2. یک `ext/` خالی ساختن (پایین‌تر توضیح).
3. `docker build work/grist-core` → **همان داکرفایل خودِ grist-core** را اجرا می‌کند.

یعنی چند-مرحله‌ایِ بالادستی دست‌نخورده می‌ماند: `node:22-trixie` برای بیلد، `yarn run build:prod`
(که `sanitize_translations.js` + `tsc` + `webpack` + `cat … > static/bundle.css` است)، پایتون ۳.۱۱ با
`requirements.txt` برای فرمول‌ها، سندباکس gVisor، کاربر `grist` برای کاهش سطح دسترسی،
`EXPOSE 8484`، و `ENTRYPOINT ./sandbox/docker_entrypoint.sh` + `CMD ./sandbox/run.sh`. فایل‌های ما
از همان `COPY app /grist/app` و `COPY assets /grist/assets` وارد می‌شوند — پس هیچ مسیر تازه‌ای در
ایمیج اختراع نشده که با آپدیت بالادستی بشکند.

## `ext` — چیزی که اولین بیلد را می‌شکست

داکرفایل بالادستی با `FROM scratch AS ext` شروع می‌شود و بعد `COPY --from=ext / /grist/ext` را دارد.
خودِ grist-core در `.github/workflows/docker.yml` همیشه این context را ردیف می‌کند
(`build-contexts: ext=ext`) و برای ایمیج فقط-آزاد، دقیقاً قبلش این را می‌زند:

```
# grist-oss does not bundle ext/ but the `ext=ext` build-context requires it.
mkdir ext && touch ext/dummy
```

بنابراین `bin/docker-build.sh` و CI همین کار را می‌کنند. نتیجه: ایمیج **نسخهٔ community** است
(مثل `gristlabs/grist-oss`), یعنی هیچ کد غیرمتن‌بازِ نسخهٔ کامل داخلش نیست — که برای ما درست‌ترین
انتخاب است، چون `ext/` در `.gitignore` خودِ grist-core هم هست. `Rtl.css` به `ext/` ربطی ندارد؛
CSS از `app/client/ui/` در همان `cat app/client/*/*.css` می‌آید.

اگر `ext/` واقعی (محصول `yarn install` نسخهٔ کامل) را در درخت بیلد بگذارید، همان اسکریپت آن را
به‌جای dummy داخل ایمیج می‌برد — ولی توجه کنید که `bin/checkout.sh` قبلش `git clean -ffd` می‌زند و
`ext/` و `node_modules` را پاک می‌کند.

## نصب

```bash
git clone https://github.com/AliMalakoo/grist-core-fa.git
cd grist-core-fa
./bin/docker-build.sh          # ~۱۵ تا ۳۰ دقیقه بار اول
docker compose up -d
```

بعد <http://localhost:8484> را باز کنید. بار اول صفحهٔ Quick setup می‌آید و در لاگ یک کلید ورود
چاپ می‌شود؛ یا خودتان از اول کلید را تعیین کنید (قبل از `up`):

```bash
export GRIST_BOOT_KEY='یک-رشته-بلند'      # همان چیزی که در /admin وارد می‌کنید
export GRIST_SESSION_SECRET="$(openssl rand -base64 24)"
docker compose up -d
```

## چیزهایی که باید بدانید

| موضوع | توضیح |
| --- | --- |
| رم | مرحلهٔ `tsc` در بیلد، ~۴ گیگ رم آزاد می‌خواهد (روی ۲ گیگ، پروسه کشیده/کشته می‌شود — در همین سندباکس تجربه شد). اگر سرورتان کوچک است، ایمیج را روی لپ‌تاپ بسازید و با `docker save` / `docker load` منتقل کنید. |
| داده | همه‌چیز در volume `grist-fa-persist` است: `/persist/docs` و `/persist/home.sqlite3` (متغیرهای `GRIST_DATA_DIR`/`GRIST_INST_DIR`/`TYPEORM_DATABASE` را خودِ داکرفایل بالادستی ست کرده). پشتیبان‌گیری = گرفتن همان volume. |
| `GRIST_SESSION_SECRET` | در `docker-compose.yml` روی `change-me-please` است؛ عوضش کنید. اگر ست نشود، grist-core یک مقدار پیش‌فرض دارد (`app/server/lib/ICreate.ts:201`) که برای محیط واقعی قابل اتکا نیست. |
| بیلد با compose | عمدتاً در `docker-compose.yml` بخش `build:` ندارد: بیلد باید `ext` context را بگیرد و آن کار `bin/docker-build.sh` است. `docker compose up -d --build` نخواهد ساخت. |
| آپدیت | `git pull && ./bin/docker-build.sh v1.7.30 && docker compose up -d`. اگر بالادستی فایل‌های ما را لمس کرده باشد، `docker-build.sh` اول merge را تمیز رد می‌کند و درگیری را نشان می‌دهد — قبل از build. |
| ایمیجِ تازه نیست | `docker compose up -d` همان ایمیج `grist-core-fa:latest` را اجرا می‌کند؛ تا `docker-build.sh` را نزده‌اید، تغییری نمی‌بینید. |
| پورت | ۸۴۸۴ پیش‌فرض است. برای پورت دیگر سرور هم باید همان پورت را گوش بدهد: در compose «`ports: ["9999:9999"]`» را در کنار «`environment: {PORT: "9999"}`» بگذارید (بالادستی `PORT` را می‌خواند — `stubs/app/server/server.ts:53`). |
| رجیستری | هیچ image عمومی ساخته نمی‌شود؛ build محلی است. اگر خواستید روی GHCR بفرستید: `IMAGE=ghcr.io/AliMalakoo/grist-fa:1.0 ./bin/docker-build.sh && docker push ghcr.io/AliMalakoo/grist-fa:1.0` (لازم: `docker login ghcr.io` با token دارای `write:packages`). |

## تست سریع

```bash
curl -fs http://localhost:8484/status | grep -o alive          # "alive"
curl -sL -H 'Accept-Language: fa' http://localhost:8484/ | grep -o "<html[^>]*>"
```

ایک `status` مرجع بهتری از `/` است: `test/test_under_docker.sh` خودِ grist-core هم دقیقاً همین را
می‌زند و توضیح می‌دهد که سرور پورت را زودتر باز می‌کند و تا آماده شدن به `/status` جواب ۵۰۳
«starting» می‌دهد.

این‌ها را `.github/workflows/fa-docker.yml` هم داخل ایمیج چک می‌کند (بدون نیاز به لاگین):
وجود `_build/app/common/jalali.js`، `grep html[dir="rtl"]` در `/grist/static/bundle.css`،
`assets/locales/fa.client.json`، و اجرای واقعی `gregorianToJalali(2026,11,27)` با کدی که در
پروداکشن داخل کانتینر اجرا می‌شود.

## قرمز شدن fa-docker یعنی چه

استپ‌های این workflow دو دسته‌اند: «Merge…»، «Prepare the ext build-context»، «Build the image»،
«The layer is inside the image»، «The conversion works inside the image»، «The server boots and
answers» — این‌ها **تست**‌اند و اگر قرمز شوند یعنی واقعاً مشکلی هست (اولین شکستِ ۳۵۵۲f7f نبودِ
`ext` context بود؛ build رد نشد، همان أولین COPY مرده بود). آخرین استپ «Tear down…» با
`if: always()` و `|| true` است و **هیچ‌وقت** شغل را قرمز نمی‌کند: یک بار `docker rm -f g` در انتهای
استپ تست، بعد از اینکه همهٔ assertها پاس شده بودند، با کد ۱۲۵ شکست و کل run را قرمز کرد.

## چیزی که ایمیج حل نمی‌کند

- زبان رابط و «زون محلی» سند را باید خودتان انتخاب کنید (`docs/UPSTREAM.md` و بخش «فعال کردن
  فارسی و جلالی» در README): ایمیج فقط *می‌تواند* فارسی باشد، تصمیم با کاربر است.
- صفحه‌های استاتیکِ کنار `app.html` (`static/form.html`، `error.html`، …) هنوز `lang`/`dir` ندارند؛
  برای فرم لاگین/اشتراک باید جدا patch شوند.
- سندباکس فرمول‌ها در داکر با `runsc` بی‌مجوز کار می‌کند (`GVISOR_FLAGS="-unprivileged -ignore-cgroups"`,
  از داکرفایل بالادستی)؛ اگر روی سرور شما کار نکرد، `GRIST_SANDBOX_FLAVOR=pyodide` را امتحان کنید.
