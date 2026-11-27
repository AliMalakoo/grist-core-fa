# این مخزن را خصوصی روی گیت‌هاب منتشر کردن

هدف: یک مخزن **خصوصی** که (۱) با `git clone` + `bin/checkout.sh` یک grist-core کامل و قابل build
بدهد، (۲) فقط لایهٔ فارسی را نگه دارد، (۳) با `bin/update.sh` پشت آخرین release خودِ grist-core
برود بدون اینکه تغییرات بالادستی دور ریخته شوند.

## ۱) ساخت مخزن

`gh` روی این ماشین نصب نیست (فقط `/usr/bin/git` هست) و هیچ credentialی هم تنظیم نشده؛ پس مخزن را
یا خودتان بسازید یا یک token بدهید تا من بفرستم.

**با وب (ساده‌ترین):**
1. `github.com/new` → Repository name: `grist-core-fa` → **Private** → تیک «Add a README» را
   **بردارید** (ما README خودمان را commit می‌کنیم) → Create repository.
2. در این پوشه:

```bash
cd /home/user/grist-core-fa
git init -b fa
git add -A
git commit -m "لایهٔ فارسی grist-core: تقویم جلالی، RTL، کاتالوگ fa"
git remote add origin git@github.com:<کاربر>/grist-core-fa.git     # یا https
git push -u origin fa
```

3. `Settings → Branches → Add branch protection` روی `fa` (اختیاری، ولی mergeهای خودکار را
   کنترل‌شده می‌کند). `Settings → Actions → General` را چک کنید که cron مجاز باشد.

**با gh (اگر نصب کردید):**

```bash
sudo apt-get install -y gh          # یا: https://cli.github.com
gh auth login --scopes repo,workflow
cd /home/user/grist-core-fa
git init -b fa && git add -A && git commit -m "لایهٔ فارسی grist-core"
gh repo create grist-core-fa --private --source . --remote origin --push
```

**با token (برای یک‌بار ارسال از همین‌جا):** token با اسکوپ `repo` (fine-grained: Contents: Read and
write) کافی است:

```bash
git push "https://x-access-token:$GITHUB_TOKEN@github.com/<کاربر>/grist-core-fa.git" fa:fa
```

token را در چت نگذارید اگر لازم نیست؛ می‌توانید فقط برای یک پیام بگذاریدش و بعد در گیت‌هاب
revoke کنید.

## ۲) دو ریموت را جدایی نگه دارید

`origin` = این مخزن (لایهٔ فارسی)؛ `upstream` = gristlabs/grist-core. اسکریپت‌ها `upstream` را از
`UPSTREAM.lock` می‌خوانند، پس لازم نیست جابه‌جایشان کنید:

```bash
git remote -v
# origin    git@github.com:<کاربر>/grist-core-fa.git (fetch/push)
git -C work/grist-core remote -v
# origin    https://github.com/gristlabs/grist-core.git (fetch/push)   <-- چوب‌پنبه‌ای است، دست نزنید
```

`work/` در `.gitignore` است: نسخهٔ merge‌شدهٔ grist-core هرگز commit نمی‌شود. اگر جایی خواستید
کل درخت merge‌شده را هم روی یک branch نگه دارید (مثلاً برای build کردن روی سرور)، این‌طور:

```bash
cd work/grist-core && git push --force <remote-for-build> fa:fa-build
```

## ۳) چرخهٔ update (ماهی یک‌بار کافی است)

```bash
git fetch --tags
bin/update.sh                              # newest v* tag را خودش انتخاب می‌کند
bin/verify.sh work/grist-core merge
cd work/grist-core && yarn install && yarn run build && npm run test:common
node buildtools/sanitize_translations.js   # کلیدهای تازهٔ en را در fa کنترل کنید
bin/rerecord.sh work/grist-core            # overlay + patch + UPSTREAM.lock
git add -A && git commit -m "rebase Persian layer on v1.7.30"
git push
```

`bin/rerecord.sh` را بعد از هر update که **merge** لازم داشته باشد حتماً اجرا کنید؛ اگر overlay
بازنویسی نشود، دفعهٔ بعد patch کهنه با base جدید درگیر می‌شود و درگیری‌های ساختگی می‌بینید.

## ۴) آزمون خودکار

`.github/workflows/fa-verify.yml` هر دوشنبه `bin/update.sh` را روی newest tag اجرا می‌کند و اگر
patch سه‌طرفه ننشیند، قرمز می‌شود (بدون `yarn install`، پس ارزان است). از «Run workflow» می‌توانید
`upstream_ref` را دستی بدهید و `run_build` را روشن کنید تا `tsc --build tsconfig-prod.json` روی
درخت merge‌شده هم اجرا شود.

این مخزن برای build به `app/common/version.ts` نیاز دارد که تولیدی و gitignored است؛ اسکریپت‌ها
دست به آن نمی‌زنند، ولی اگر build گفت `Cannot find module 'app/common/version'`:

```bash
echo 'export const VERSION: string = "grist-core-fa";' > work/grist-core/app/common/version.ts
```

## ۵) چیزی که عمداً این‌جا نیست

- فایل‌های `work/*`، `node_modules`، `_build` — build‌شدنی‌اند، نه منبع.
- هیچ فایل build یا script از upstream در overlay نیست؛ `buildtools/`، `package.json` و
  `tsconfig*.json` همان‌طور که grist-core می‌دهد می‌مانند. تنها استثنای سمت سرور
  `overlay/app/server/lib/sendAppPage.ts` است.
- صفحه‌های استاتیکی که از این لایه بیرون‌اند (`static/form.html`، `error.html`،
  `custom-widget.html`، `apiconsole.html`) هنوز `<html>` بدون `lang`/`dir` دارند؛ `static/app.html`
  دارد. برای فرم لاگین/اشتراک، اصلاحش یک patch جداست — `docs/UPSTREAM.md` بند ۴.
