# نقاط اتصال لایهٔ فارسی به grist-core

هر فایل این مخزن یا **جدید** است (به‌تنهایی اضافه می‌شود، هیچ رفتار upstream را عوض نمی‌کند) یا روی
فایل موجود upstream یک **hook** کوچک دارد. پنج فایل، کامل جدیدند:

```
app/common/jalali.ts              app/common/LanguageDirection.ts
app/client/ui/JalaliDatePicker.ts app/client/ui/Rtl.css
test/common/jalali.ts
```

بقیه (۱۴ فایل) دست‌خورده‌اند و hookهایشان در زیر آمده — این تنها چیزی است که باید بعد از هر
update بازبینی شود. برای پیداکردن هر hook در نسخهٔ جدید به نام نماد grep کنید نه شمارهٔ خط:

```bash
cd work/grist-core
grep -rn "jalali\|Jalali\|languageDir\|grist-rtl" app/common/ValueFormatter.ts app/client/models/DocModel.ts \
  app/client/lib/localization.ts app/server/lib/sendAppPage.ts app/common/parseDate.ts
```

## ۱. `app/common/ValueFormatter.ts` — نمایش

hook: در `DateFormatter`، `shouldUseJalali(widgetOpts.jalali, docSettings.locale)` تعیین می‌کند و
`formatJalaliMoment` قبل از moment اجرا می‌شود. interface محلی `JalaliDateFormatOptions` فقط
`jalali?: boolean` را به `DateFormatOptions` اضافه می‌کند.

> **Rationale:** مقدار ذخیره‌شده دست نمی‌خورد؛ فقط رشتهٔ خروجی جلالی می‌شود، برای اینکه export،
> filter و sort همان دادهٔ میلادیِ همه‌جا-قابل-فهم بمانند.
>
> **Check:** با `jalali` خاموش، خروجی `DateFormatter` باید بایت‌به‌بایت مثل قبل باشد
> (`mocha _build/test/common/ValueFormatter.js`).

## ۲. `app/client/models/DocModel.ts` — locale سند

hook: `setJalaliDocLocale(docLocale())` هنگام load و در یک `subscribe` روی تغییر locale.

> **Rationale:** کد مشترک (formatterها) نباید به مدل کلاینت وابسته شود؛ تابع یک setter جهانی است.
>
> **Check:** اگر upstream `docSettings.locale` را جابه‌جا کند، subscribe باید جابه‌جایی را ببیند و
> سند همچنان جلالی بماند.

## ۳. `app/client/lib/localization.ts` — زبان UI

hook: در `applyLanguageToDocument` مقدار `languageDir(lng)` روی `dir` و کلاس `grist-rtl`، و
`data-calendar="jalali|gregorian"` روی `<html>`؛ `setJalaliUiLangOverride(lng)` هم همین‌جا.

> **Rationale:** `<html dir/lang>` تنها جایی است که CSS، کد مشترک و صفحه‌های استاتیک همه به آن
> دسترسی دارند. override لازم است چون attribute جدید هنوز نوشته نشده وقتی formatterها اجرا می‌شوند.
>
> **Check:** با زبان عبری/عربی باید `dir="rtl"` و `data-calendar="gregorian"` بیاید (تقویم جلالی
> نه)، با `fa` هر دو.

## ۴. `app/server/lib/sendAppPage.ts` — همان attr سمت سرور

hook: تابع exported `getLanguageAttributes(req, config)` (خط ~۲۷۵ در فایل ما) که `lang`, `dir`,
`data-calendar` را می‌سازد و در `static/app.html` با `<%~ languageAttributes %>` تزریق می‌شود.

> **Rationale:** قبل از رسیدن JS کلاینت باید `dir` درست روی `<html>` نشسته باشد تا یک frame با
> چیدمان LTR flashed نشود. تابع export شده تا تست مستقیم شود.
>
> **Check:** `mocha _build/test/server/lib/sendAppPage.js` (۶ حالت en/fa/iw/ar/de + fallback). اگر
> upstream امضای `getActiveLocale` را عوض کرد، `getLanguageAttributes` تنها نقطهٔ نیازمند ویرایش
> است و باید همان ۶ حالت را دوباره دید.
>
> **Known upstream gap:** `app/server/lib/index.js:226` صفحهٔ index را بر اساس
> `gristConfig.singlePage` انتخاب می‌کند و `static/form.html`، `error.html`،
> `custom-widget.html`، `apiconsole.html` هنوز `<html>` بدون attr دارند. برای فرم‌های لاگین/اشتراک
> این یعنی LTR؛ اصلاحش یک patch جداست، نه بخشی از این لایه.

## ۵. `app/common/parseDate.ts` — ورودی

hook: `ParseOptions.jalali?: boolean` و تابع `fromJalali()` که در ابتدای مسیر parse کوتاه‌کرد
(«hand-off») می‌کند؛ `dateFormatOptions()` و `timeFormatOptions()` هم export شده‌اند تا
`jalali.ts` همان فهرست را به‌جا استفاده کند.

> **Rationale:** ورودی جلالی به میلادیِ همان‌روز تبدیل می‌شود و بعد به parser معمولی سپرده می‌شود؛
> پس هیچ قاعدهٔ parsing موجودی تغییر نمی‌کند و رفتار برای بقیهٔ زبان‌ها دقیقاً قبلی است.
>
> **Check:** اگر upstream به `dateFormatOptions` شکلی با فاصلهٔ متفاوت اضافه کرد، `splitDateFormat`
> و الگوی regex در `jalali.ts` باید همان را قبول کند. تست: `mocha _build/test/common/parseDate.js`.
>
> **Rationale (exportها):** این دو تابع `export` شده‌اند و این تنها تغییر امضای یک فایل upstream
> است. اگر upstream آن‌ها را جابه‌جا یا حذف کرد، `jalali.ts` باید فرمت‌ها را در خود کپی کند.
>
> **Limitation (آگاهانه):** `parseDateStrict()` — که مسیر paste و `parseDateTime()` از آن رد می‌شوند
> — پرچم `jalali` نمی‌گیرد و فقط به locale سند نگاه می‌کند؛ یعنی در سند انگلیسی، ستونی با تیک
> «تقویم جلالی» هنگام paste رشتهٔ جلالی را میلادی می‌خواند. تایپ دستی در سلول (`parseDate`) پرچم
> ستون را رعایت می‌کند.
>
> **Time-of-day:** `jalaliDateStringToGregorian()` زمان انتهایی رشته را در خروجی نگه می‌دارد
> ("1405-09-06 14:30" → "2026-11-27 14:30")، دقیقاً مثل ورودی میلادی. اگر افتد، `parseDateStrict`
> همان رشتهٔ date-only را می‌پسندد و `parseDateTime` هرگز نوبتش را نمی‌بیند — زمان بی‌صدا دور
> ریخته می‌شود. علائم bidi (LRM/RLM/RLE…) هم پاک می‌شوند، وگرنه یک کپی از چت زمان را گم می‌کند.
> تست: «should hand a time typed with the date on to the ordinary parser».

## ۶. `app/common/WidgetOptions.ts` + `app/client/widgets/UserType.ts` — گزینهٔ ویجت

hook: `jalali?: boolean` در `WidgetOptions`؛ `jalali: null` در `options` هر دو ویجت `Date` و
`DateTime` (`UserType.ts` خطوط ~۱۶۹ و ~۱۸۹).

> **Rationale:** هر option جدید **باید** در `UserType.ts` اعلام شود، وگرنه `ViewFieldConfig.disabled()`
> کنترلش را برای همیشه غیرفعال می‌سازد. مقدار `null` یعنی «پیش‌فرضِ سند».
>
> **Check:** تیک «تقویم جلالی» در پنل پیکربندی باید clickable باشد؛ ذخیرهٔ `false` هم باید
> بنویسد (نه `null`)، چون `modelUtil.setSaveValue` روی مقدار برابر no-op است.

## ۷. `app/client/widgets/DateTextBox.js` + `DateEditor.ts` + `DateTimeEditor.ts` — ویرایشگر

hook: سلول `DateTextBox` یک `buildJalaliConfigDom()` با `kf.checkbox(this.jalaliToggle, ...)` اضافه
می‌کند (کلاس‌های `jjp-toggle-label/hint` در `Rtl.css`); `DateEditor` در مسیر bootstrap-datepicker
دست‌نخورده مانده و `this.jalali` را به `DateTimeEditor` پاس می‌دهد؛ وقتی جلالی روشن است
`JalaliDatePicker` جای datepicker را می‌گیرد (`_attachJalaliPicker`).

> **Rationale:** `kf.toggle` در `app/client/lib/koForm.js` وجود ندارد (checkbox در خط ~۲۰۳)؛ برای
> همین `kf.checkbox`. مسیر bootstrap فقط **دکمهٔ جلالی** را پنهان می‌کند، خود widget را نه — تا اگر
> `shouldUseJalali` false شد همان رفتار قبلی برگردد.
>
> **Check:** `mocha _build/test/client/widgets/DateEditor.js` و `DateParser.js` باید سبز بماند. اگر
> upstream `dateOptions` را عوض کرد، `jalaliFormatOptions()` در `jalali.ts` تنها جایی است که
> مپینگ `monthNames/weekdayNames` را نگه می‌دارد.

## ۸. `app/client/components/CalendarWrapper.ts` — Month/Year view

hook: در `getFullOptions()` — `weekStart: "sat"` (MomentJS شمارهٔ روز هفتفه را می‌گیرد) و
`getTitleLocale()` که برای فارسی `fa` برمی‌گرداند.

> **Rationale:** Intl برای `fa` تقویم جلالی را در Month view هم تحمیل می‌کند؛ اینجا همان locale را
> نگه می‌داریم و شروع هفته را صحیح می‌کنیم. شمارهٔ روز جلالی در سلول‌ها **نشان داده نمی‌شود** —
> این یک مرز آگاهانه است، نه فراموشی.
>
> **Check:** `mocha _build/test/client/components/CalendarSection.js`.

## ۹. `assets/locales/fa.{client,server}.json` + تست‌ها — ترجمه

این دو فایل **ساختهٔ ما نیستند**: grist-core آن‌ها را از Weblate می‌گیرد. کاری که ما می‌کنیم
پرکردن/درست‌کردن همان کلیدهاست — `fa.client.json` ۱۹۵ گروه و ۱۴۵۸ کلید، `fa.server.json` ۱۳ کلید،
هیچ کلید تازه‌ای اختراع نشده و نام کلیدها بایت‌به‌بایت مثل `en` است (فاصله‌های انتهایی و `{{- x }}`
معنا دارند).

> **Rationale:** اگر کلیدی را که upstream می‌فرستد عوضی بنویسیم، `sanitize_translations.js` رد
> می‌کند یا UI آن رشته را انگلیسی نشان می‌دهد؛ پس فهرست کلیدها از upstream می‌آید نه از ما.
>
> **Check:** `node buildtools/sanitize_translations.js` باید rc=0 بدهد، و اگر نسخهٔ جدید کلید تازه‌ای
> به `en.client.json` اضافه کرد، `fa.client.json` باید همان کلید را (ترجمه‌نشده) بگیرد — اسنیپت
> پایین همین صفحه آن را می‌شمارد. `test/server/lib/sendAppPage.ts` هم افزوده شده تا
> `lang`/`dir`/`data-calendar` سمت سرور بدون مرورگر آزمایش شود.

## قبل از هر انتشار، این فهرست را ببینید

```bash
cd work/grist-core
node buildtools/sanitize_translations.js                       # rc=0
node buildtools/write_static_locales.js assets/locales ext/assets/locales
yarn run test:common
yarn run lint
grep -c 'html\[dir="rtl"\]' app/client/ui/Rtl.css            # ۱۱۰ قاعده؛ نباید صفر شود
grep -rn 'grid_view_data\|\.column_names' app/client/ui/Rtl.css | head -3   # هندسهٔ گرید آینه نشده
python3 - <<'PY'
import json
en=json.load(open('assets/locales/en.client.json')); fa=json.load(open('assets/locales/fa.client.json'))
new=[k for g in en for k in en[g] if g in fa and k not in fa[g]]
gone=[k for g in fa for k in fa[g] if g in en and k not in en[g]]
print('groups missing from fa:', len([g for g in en if g not in fa]))
print('keys to translate:', len(new), '| stale keys:', len(gone))
PY
```

`keys to translate` باید صفر باشد؛ اگر نبود، کلیدهای تازه را از `en.client.json` **عیناً** کپی کنید
(فاصله‌های انتهایی و `{{- x }}` معنا دارند) و بعد `sanitize_translations.js` را دوباره اجرا کنید.
