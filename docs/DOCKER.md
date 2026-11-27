# نصب با داکر (کوتاه‌ترین راه)

## چرا این روش «جعلی» نیست

ما یک ایمیج از صفر نمی‌نویسیم. `bin/docker-build.sh` فقط این کار را می‌کند:

1. `bin/checkout.sh` → یک grist-core تمیز در نسخهٔ قفل‌شده + ۱۹ فایل لایهٔ فارسی رویش.
2. `docker build work/grist-core` → **همان داکرفایل خودِ grist-core** را اجرا می‌کند.

یعنی چند-مرحله‌ایِ بالادستی دست‌نخورده می‌ماند: `node:22-trixie` برای بیلد، `yarn run build:prod`
(که `sanitize_translations.js` + `tsc` + `webpack` + `cat … > static/bundle.css` است)، پایتون ۳.۱۱ با
`requirements.txt` برای فرمول‌ها، سندباکس gVisor، کاربر `grist` برای کاهش سطح دسترسی،
`EXPOSE 8484`، و `ENTRYPOINT ./sandbox/docker_entrypoint.sh` + `CMD ./sandbox/run.sh`. فایل‌های ما
از همان `COPY app /grist/app` و `COPY assets /grist/assets` وارد می‌شوند — پس هیچ مسیر تازه‌ای در
ایمیج اختراع نشده که با آپدیت بالادستی بشکند.

## نصب

```bash
git clone https://github.com/AliMalakoo/grist-core-fa.git
cd grist-core-fa
./bin/docker-build.sh                 # ~۱۰ تا ۲۰ دقیقه بار اول
docker compose up -d
```

بعد <http://localhost:8484> را باز کنید. بار اول صفحهٔ Quick setup می‌آید و در لاگ یک کلید ورود
چاپ می‌شود:

```bash
docker compose logs grist | grep -i "boot key"
```

## چیزهایی که باید بدانید

| موضوع | توضیح |
| --- | --- |
| رم | مرحلهٔ `tsc` در بیلد، ~۴ گیگ رم آزاد می‌خواهد (روی ۲ گیگ، پروسه کشیده/کشته می‌شود — در همین سندباکس تجربه شد). اگر سرورتان کوچک است، ایمیج را روی لپ‌تاپ بسازید و با `docker save` / `docker load` منتقل کنید. |
| داده | همه‌چیز در volume `grist-fa-persist` است: `/persist/docs` و `/persist/home.sqlite3` (متغیرهای `GRIST_DATA_DIR`/`GRIST_INST_DIR`/`TYPEORM_DATABASE` را خودِ داکرفایل بالادستی ست کرده). پشتیبان‌گیری = گرفتن همان volume. |
| `GRIST_SESSION_SECRET` | در `docker-compose.yml` روی `change-me-please` است؛ عوضش کنید. اگر ست نشود، grist-core یک مقدار پیش‌فرض دارد (`app/server/lib/ICreate.ts:201`) که برای محیط واقعی قابل اتکا نیست. |
| آپدیت | `git pull && ./bin/docker-build.sh v1.7.30 && docker compose up -d --build`. اگر بالادستی فایل‌های ما را لمس کرده باشد، `docker-build.sh` اول merge را تمیز رد می‌کند و درگیری را نشان می‌دهد — قبل از build. |
| بیلد نکردنِ دوباره | `docker compose up -d` بدون `--build` همان ایمیج قبلی را اجرا می‌کند. |
| پورت | ۸۴۸۴ پیش‌فرض است؛ برای تغییر، هم `ports` و هم (اگر از `docker run` استفاده می‌کنید) `-p` را عوض کنید. |
| رجیستری | هیچ image عمومی ساخته نمی‌شود؛ build محلی است. اگر خواستید روی GHCR بفرستید: `IMAGE=ghcr.io/AliMalakoo/grist-fa:1.0 ./bin/docker-build.sh && docker push $IMAGE` (لازم: `docker login ghcr.io` با token دارای `write:packages`). |

## اگر می‌خواهید HTTP را سریع تست کنید

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8484/          # 200 یا 302
curl -s http://localhost:8484/ | grep -o "<html[^>]*>"                    # باید dir="rtl" و
# data-calendar="jalali" داشته باشد اگر Accept-Language: fa بفرستید:
curl -s -H 'Accept-Language: fa' http://localhost:8484/ | grep -o "<html[^>]*>"
```

(این همان چیزی است که `.github/workflows/fa-docker.yml` هم چک می‌کند، ولی آنجا بدون نیاز به لاگین،
مستقیم داخل ایمیج: وجود `_build/app/common/jalali.js`، وجود `html[dir="rtl"]` در
`/grist/static/bundle.css`، و `assets/locales/fa.client.json`.)

## چیزی که ایمیج حل نمی‌کند

- زبان رابط و «زون محلی» سند را باید خودتان انتخاب کنید (`docs/UPSTREAM.md` و بخش «فعال کردن
  فارسی و جلالی» در README): ایمیج فقط *می‌تواند* فارسی باشد، تصمیم با کاربر است.
- صفحه‌های استاتیکِ کنار `app.html` (`static/form.html`، `error.html`، …) هنوز `lang`/`dir` ندارند؛
  برای فرم لاگین/اشتراک باید جدا patch شوند.
- سندباکس فرمول‌ها در داکر با `runsc` بی‌مجوز کار می‌کند (`GVISOR_FLAGS="-unprivileged -ignore-cgroups"`,
  از داکرفایل بالادستی)؛ اگر روی سرور شما کار نکرد، `GRIST_SANDBOX_FLAVOR=pyodide` را امتحان کنید.
