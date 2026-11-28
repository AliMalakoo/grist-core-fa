# نقاط اتصال لایهٔ فارسی به grist-core

هر فایل این مخزن یا **جدید** است (به‌تنهایی اضافه می‌شود، هیچ رفتار upstream را عوض نمی‌کند) یا روی
فایل موجود upstream یک **hook** کوچک دارد. فهرست دقیق فایل‌ها در `patch/files.txt` است
(`added-files.txt` برای فایل‌های نو و `modified-files.txt` برای فایل‌های upstreamیِ دست‌خورده)؛
برای پیداکردن هر hook در نسخهٔ جدید به نام نماد grep کنید نه شمارهٔ خط:

```bash
cd work/grist-core
grep -rn "jalali\|Jalali\|languageDir\|grist-rtl\|rtlPlacement" app/common/ValueFormatter.ts app/client/models/DocModel.ts \
  app/client/lib/localization.ts app/server/lib/sendAppPage.ts app/common/parseDate.ts app/client/ui2018/menus.ts
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

## ۸. نمای Calendar — دو موتور پشت `CalendarWidget`

`CalendarView.init()` با `shouldUseJalali()` بین دو موتور انتخاب می‌کند:

- **فارسی/جلالی** → `app/client/components/JalaliCalendar.ts`: یک engine سفارشی راست‌به‌چپ
  (grid خود Grist، بدون Toast UI). نمای ماه یک ماه شمسی واقعی است (۶ ردیفِ شنبه‌اول، شنبه در
  ستون راست و جمعه آخر ستون چپ)؛ ارقام و نام ماه‌ها فارسی (`آذر ۱۴۰۵`)، نمای هفته ستون‌های
  شنبه..جمعه با فهرست رویدادها (تمام‌روزه اول)، نمای روز تک‌ستونی. اینترفیس همان
  `CalendarWidget` است که متغیر CalendarWrapper هم دارد؛ رندرکننده (`CalendarRenderer`) و
  `CalendarSource` هیچ چیزی از Toast UI نمی‌خواهند.
- **بقیهٔ زبان‌ها** → `CalendarWrapper.ts` (Toast UI) بدون تغییر در رفتار: شنبه‌اول برای fa/ar
  از `getLocaleWeekStart()`، نام‌های روز و ارقام محلی در تایتل و هدرها (`_gridTemplates`)، و
  جهت toolbar در RTL با `margin-inline-start` و جابه‌جایی آیکون‌های prev/next در
  `CalendarView._buildDom`.

ذخیره‌سازی همچنان Gregorian/unix ثانیه‌ای است؛ تبدیل فقط در لایهٔ نمایش است. موتور جلالی
drag/resize ندارد؛ ساخت رویداد با دو-کلیک (ماه: تمام‌روزه، غیرماه: ۹ تا ۱۰ صبح) و ویرایش با
Double-click روی خود رویداد (Record Card).

> **Rationale:** TUI نمی‌تواند ماتریس ماه شمسی را چاپ کند (هفته‌های یک ماه شمسی با هیچ ماه
> میلادی نمی‌خوانند)، برای همین grid را خودمان کشیدیم؛ اما داده و چرخهٔ نوشتن همان قبلی است.
>
> **Check:** در سند با `lang=fa` یک Calendar باز کنید؛ عنوان «آذر ۱۴۰۵»، شنبه ستون راست، جمعه
> ستون چپ. `tsc -b app/client` و build باید سبز بماند. تست nbrowser موجود
> (`test/nbrowser/CalendarView.ts`) فقط مسیر انگلیسی (TUI) را می‌پوشاند.

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

## ۱۰. منوها و پاپ‌آپ‌های شناور در RTL + حدس نوع ستون با ارقام فارسی

- `app/client/lib/rtlPlacement.ts` (جدید): popper v1 به `start/end` و `left/right` می‌چسبد و
  جهت را نمی‌فهمد؛ `rtlPlacement()` آن‌ها را آینه می‌کند (`bottom-start` → `bottom-end`)، و
  `rtlSetPopupToCreateDom`/`rtlSetPopupToFunc` همان آینه را یک‌بار روی گزینه‌ها اعمال می‌کنند.
- `app/client/ui2018/menus.ts`: `menu()`،`submenu` (از راست به چپ باز می‌شود)،`inputMenu` و
  `select()` همین آینه را یک‌بار می‌کنند؛ و `defaultMenuOptions` خود popweasel در اول ماژول
  یک‌بار آینه می‌شود تا select/autocompleteهایی که placement صریح نمی‌گیرند هم از راست باز شوند
  (با guard تا دوبار آینه نشود). استایل‌های منو به `inset-inline-*` تبدیل شد.
- بقیهٔ call siteها (`PageWidgetPicker`, `RenameDocModal`, `NotifyUI`, `TriggerFormulas`,
  `ColorSelect`, `ColumnTitle`, `searchDropdown`, `GridView`, `FormView`, `OnBoardingPopups`,
  `autocomplete`, `tooltips`) هم به همین مسیرهای یک‌بار-آینه منتقل شدند؛ `tooltips.ts` نمونه‌ای
  بود که دوبار آینه می‌شد و اصلاح شد.
- `app/common/ValueGuesser.ts`: در سند با locale فارسی، حدس «تاریخ/زمان» اول جلالی را می‌فهمد
  (`guessJalaliDateFormat` با اولویت قالب day-first/year-first؛ ارقام فارسی و bidi-mark قبل از
  حدس با momentify نرمال می‌شوند)، تست برابریِ formatter هم با ارقام لاتین مقایسه می‌کند.
  اعداد فارسی (`۱۲۳۴٫۵`) هم دیگر به‌خاطر نگاشت اصلاحی زودهنگام رد نمی‌شوند.
- `app/common/jalali.ts`: باگ «جداکنندهٔ بین تاریخ و زمان» در `formatJalaliMoment` رفع شد
  (مثلاً `۱۴۰۵/۰۹/۰۶ ۱۴:۳۰` قبلاً `۱۴۰۵/۰۹/۰۶۱۴:۳۰` رندر می‌شد)؛ تست‌ها در `test/common/jalali.ts`.
- `app/client/lib/koDomScrolly.js` (اصلاحِ فایل بالادستی): گزینهٔ `paddingLeft` به پهنه‌ٔ
  اسکرول افزوده شد؛ `GridView.ts` در چیدمان RTL این padding را به‌جای سمت راست به سمت چپ می‌دهد
  تا ستون آخر به لبهٔ جریان (`--gridview-header-height` انتهایی) برسد.
- کلیدهای جهت‌نما در RTL بومی‌سازی شدند (پیمایش با جهت دیداریِ صفحه):
  `Cursor.ts` (`cursorLeft`/`cursorRight` بر پایهٔ `hArrowSign()`)، overrideهای مشابه در
  `GridView.ts` (به‌همراه `scrollPaneLeft/Right` در لبهٔ جریان)، `_shiftSelect` و
  `_shiftSelectUntilFirstOrLastNonEmptyCell` (جهت `left`/`right` جابه‌جا می‌شود)،
  `Forms/FormView.ts` (`cursorLeft`/`cursorRight` به `nextField`/`prevField` نگاشت می‌شوند)،
  `ariaTabs.ts` (چرخهٔ تب‌ها)، `OnBoardingPopups.ts` (قدم‌های پرسش‌نما)، `TokenField.ts`
  (bindings پیش/پس)، `AttachmentsEditor.ts` (افقی)، `DetailView.ts` (آیکون‌های دکمهٔ قبل/بعد).
  کلیدهای Tab/Shift+Tab و Home/End (ترتیب خواندن) و کلیدهای عمودی تغییر نکردند.
- `Rtl.css`: آینه‌سازی ماسکِ ellipsis در markdown، فاصله‌گذاریِ شماره‌ٔ اعتبارسنجی و
  `mod-add-column`، حاشیهٔ `info_toggle_icon`، جهتِ `linked_dst::before` (◀) و یک بلوک
  `@media print` برای `.print-widget` (حاشیه و padding ردیف‌شمارها در چاپ RTL).
- **وضعیت:** کامپایل (`tsc --noEmit`)، bundle توسعه‌ای و `test:common` سبز (۸۷۶ پاس)؛
  round-trip تازه→overlay→مقایسهٔ بایت به‌بایت تمیز است. اما **در مرورگر کلیک نشده** —
  منوها/پاپ‌آپ‌ها، گرید RTL و کلیدهای جدید باید دستی بررسی شوند. کلیدهای جهت‌نمای popweasel
  در زیر-منو عمداً هاردکد باقی ماندند (ArrowRight باز می‌کند / ArrowLeft می‌بندد)؛ در RTL
  بومی‌سازی نشدند چون grainjs به listenerهای هم‌عنصر `stopPropagation` نمی‌زند و مرتب‌سازی
  قابل‌اعتماد نیست؛ تا کردن صحیح آن به‌جای آینهٔ کامل، کلیدهای همانند LTR را نگه می‌دارد.

## ۱۱. فرمول‌ها و مقایسهٔ فیلدهای تاریخ جلالی (`sandbox/grist`)

فیلدهای Date/DateTime جلالی همان ستون‌های تاریخ معمولیِ Grist هستند و مقدارشان میلادیِ
(ثانیه‌های یونیکس) ذخیره می‌شود؛ جلالی فقط یک لایهٔ نمایش است. بنابراین **بین فیلدها** همه‌چیز
بدون هیچ تغییر دیگری کار می‌کند — ترتیبِ دو تاریخ در تقویم شمسی دقیقاً با ترتیب میلادی یکی است:

- `$A < $B`، `$A > TODAY()`، `DATEDIF($A, $B, "D")`، تفریق تاریخ‌ها؛ DATEDIF و سایر توابع
  تاریخِ Python روی اشیای `date`/`datetime` اجرا می‌شوند؛ خطای «unorderable types» فقط برای
  مقایسهٔ Date با Text رخ می‌دهد (رفتار upstream).
- نتیجهٔ فرمولی که تاریخ برمی‌گرداند در ستونی با ویدجت جلالی، جلالی نمایش داده می‌شود.
- منوی «Date helpers» (گروه DateAndTime در `GridViewMenusDateHelpers.ts`) همان DATEDIF را
  می‌سازد و روی فیلدهای جلالی هم درست است.

آنچه **کار نمی‌کرد** (و با این لایه اصلاح شد): لیترال‌های تاریخ داخلِ فرمول. مثلاً
`DATEDIF("۱۴۰۳/۰۱/۰۱", TODAY(), "D")` قبلاً `۱۴۰۳` را به‌عنوان *سال میلادی ۱۴۰۳* می‌خواند
(بی‌صدا، بدون خطا) یا با ارقام فارسی خطای parse می‌داد. حالا:

- `sandbox/grist/jalali.py` (جدید): همتای Pythonِ `app/common/jalali.ts` — همان الگوریتم
  ۳۳‌ساله (BREAKS) و همان قانون locale (`JALALI_LANGS`)، همان پنجرهٔ plausibility (۱۲۰۰–۱۵۰۰)
  و همان تعویض خودکار ماه/روز. تست تفاضلی با TS روی ~۲۲٬۰۰۰ روز نمونه و round-trip کامل، صفر
  مغایرت. `parse_jalali_string` همان شکل‌های ورودی (ارقام فارسی/عربی/fullwidth، اسامی ماه شمسی
  فارسی/انگلیسیِ کوتاه و کامل با نرمال‌سازی الف/ی/ک/ة، جداکننده‌های bidi، پسوند جلالی، زمان
  انتهایی، و نهایتاً null برای تاریخ‌های میلادیِ سال >۱۵۰۰) را می‌پذیرد.
- `sandbox/grist/functions/date.py` (تغییر): `_make_datetime`/`_make_date`/`DATEVALUE` قبل از
  dateutil، اگر سند روی تقویم شمسی باشد (`documentSettings.locale` فارسی/دری/… — همان چیزی که
  کلاینت می‌خواند)، رشته را Jalali می‌خوانند؛ در سند انگلیسی/میلادی رفتار بی‌تغییر می‌ماند.
  ارقام فارسی هم به‌صورت طبیعی (چون Python و dateutil با \d یونیکد کار می‌کنند) parse می‌شدند —
  مشکل فقط تقویم بود، که حل شد.
- عمداً **تغییر نکرد**: آرگومان‌های عددی `DATE()`, `EDATE()`, `EOMONTH()` و … میلادی می‌مانند
  (تغییر معنای آن‌ها، نتایجِ موجودِ سندهای فارسی را بی‌صدا جابه‌جا می‌کرد). برای لیترال شمسی
  داخل فرمول بنویسید `DATEVALUE("۱۴۰۳/۰۵/۱۲")` یا به ستون اشاره کنید، نه `DATE(1403, 5, 12)`.
- تست‌ها: `sandbox/grist/functions/test_jalali_date.py` (۱۶ تست؛ تبدیل، parse، لیترال در
  فرمول با monkeypatchِ `doc_uses_jalali`، و یک تست engine-level روی ستون‌های Date فرمولی).
  سوئیت کامل `python sandbox/grist/runtests.py` = ۷۴۶ تست سبز (۲ skipped از قبل).

**محدودیت باقی‌مانده:** `_get_global_tz`/`doc_uses_jalali` در زمان اجرا از DocInfo خوانده می‌شوند؛
اگر locale سند در وسط جلسه تغییر کند، فرمول‌های در حال اجرا تا re-eval شدنِ DocInfo همان تقویم
قبلی را می‌بینند (همان رفتار timezone در upstream). و import/paste هنوز از همان محدودیت
مستند (`parseDateStrict` پرچم per-column جلالی را نمی‌گیرد) تبعیت می‌کنند.

## ۱۲. دکمهٔ «کارت رکورد» کنار هر ردیف (GridView)

کنار هر ردیف در گرید یک دکمهٔ کوچک با آیکون `ExpandArrows` (Font Awesome Free 7.3.1، «expand»,
CC BY 4.0 — attribution در خودِ فایل SVG) قرار گرفت؛ کلیک روی آن همان Record Card سند را برای
**همان رکورد** باز می‌کند (همان مسیر `viewAsCard`: `{ colRef, rowId, sectionId, recordCard: true }`).

- `app/client/components/BaseView.ts`: `viewRecordAsCard(rowId)` اضافه شد؛ `viewSelectedRecordAsCard()`
  حالا از آن استفاده می‌کند (رفتار قبلی بدون تغییر).
- `app/client/components/GridView.ts`: دکمه در `.gridview_data_row_num` ساخته می‌شود؛
  ردیف «جدید» (`_isAddRow`) دکمه نمی‌گیرد و دکمه در `dom.maybe` با سه شرط واکنشی پنهان می‌شود:
  `rowNumbers !== "hidden"`، `!isTableRecordCardDisabled` و `!isVirtual` (همان منطقی که اقدام
  «نمایش به‌صورت کارت» در منوی ردیف با `ariaDisabled` دارد). `mousedown`/`click` را
  stopPropagation می‌کند تا drag-select ردیف و context menu gutter فعال نشوند. ردیف‌شمارنده
  (`ROW_NUMBER_WIDTH`) از ۵۲ به ۷۲ پیکسل رفت تا دکمه و شمارهٔ ردیف و علامت انتخاب هم‌پوشانی نداشته
  باشند (همهٔ offsetهای sticky/frozen از `--row-num-width` می‌آیند، پس به‌صورت خودکار هماهنگ شدند).
- موقعیت: `left: 2px` (لبهٔ جریانٔ آغاز؛ در RTL با Rtl.css به `right: 2px` مهاجرت می‌کند)، عمودی وسط،
  ۱۸×۱۸ پیکسل. شمارهٔ ردیف در وسط می‌ماند، منوی ردیف (`menu_toggle`) در گوشهٔ روبروی دکمه است،
  و `z-index` دکمه (۲۱) از gutter (۲۰) بالاتر است. انتخاب ردیف کل gutter را رنگی می‌کند
  (`.gridview_data_row_num.selected`)، پس با دکمه تداخل بصری ندارد.
- ترجمه: کلید `"View record as card"` به `en.client.json` و `fa.client.json` (گروه `GridView`)
  اضافه شد. در چاپ پنهان است (`@media print { .record_card_toggle { display: none } }`).
- آیکون جدید: `static/ui-icons/UI/ExpandArrows.svg`؛ `yarn generate:icons` خروجی `icons.css` و
  `IconList.ts` را بازساخت (Diff بسیار کوچک). آیکون "Expand" موجود (فلش رو به پایین) دست‌نخورده ماند.
- **وضعیت:** tsc/webpack/bundle.css سبز؛ test:common سبز (۸۷۶)؛ راستی‌آزمایی مرورگری دستی نشده —
  جایگیری دکمه و clip شدن گوشه‌ها باید روی :8484 دیده شود.

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
