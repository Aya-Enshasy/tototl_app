# TOTOTL — تحسين متابعة Stripe للعقد 12

## ما يثبته اللوج

- `GET /company/contracts/12` نجح بـHTTP 200.
- `GET /company/payments` ثم `GET /company/contracts/12/collect/2` ثم `GET /company/payments` مرة ثانية: أربعة طلبات متسلسلة للفحص الواحد.
- نهاية الفحص كانت `contractState=accepted`, `funded=false`, ولم يظهر في السجل رابط Checkout جديد.
- `NAV POP` يشير إلى إغلاق شاشة التمويل، وليس دليلًا بحد ذاته على Crash أو قتل التطبيق.

## التغيير في Flutter

1. كل دورة فحص تقرأ العقد، ثم `GET /collect/{attempt}` **فقط** إن احتاجت حالة المحاولة أو رابطها؛ لا تعيد قائمة مدفوعات الشركة مرتين عند كل تحديث.
2. يتوقف الفحص الدوري بعد 6 جولات، بفاصل 40 ثانية بين الجولات، بدل إغراق الـAPI بطلبات لا تنتهي. الفحص اليدوي يبقى متاحًا.
3. لا يفحص التطبيق تلقائيًا أثناء وجود صفحة Stripe مفتوحة.
4. عندما يعطي السيرفر حالة عقد ممولة يعود لتفاصيل العقد. الرجوع أو وصول صفحة `Payment submitted` **لا يعني** تمويلًا ناجحًا.
5. يتم فحص رابط Checkout إن جاء من بيانات محاولة التحصيل، ويُفتح تلقائيًا إن كان صالحًا.
6. أضيف Log باسم `[TOTOTL][PAYMENT][ROUTE_CLOSE]` لتمييز الإغلاق التلقائي بسبب التمويل عن زر الرجوع.

## ما لا يمكن حله من Flutter وحده

وجود Attempt رقم 2 بحالة `pending` دون رابط Checkout كامل في ردود API أو في كاش نفس حساب الشركة لا يكفي لفتح Stripe. إنشاء رابط من رقم المحاولة أو إعادة `POST /fund` يعرض الشركة لمحاولة مكررة. لا تغيّر Flutter حالة العقد إلى `active` محليًا.

## التحقق على Windows

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test test/stripe_attempt_status_polling_test.dart
flutter test
flutter run
```

> لم يتوفر Flutter SDK داخل بيئة إعداد هذا الأرشيف، لذا فحوصات Flutter والبناء والتجربة الحقيقية على الجهاز لم تُنفّذ هنا.
