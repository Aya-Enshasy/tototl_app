# TOTOTL INTGRX — تقرير تدقيق الإشعارات والتوجيه (14 نوفمبر 2026)

## الملخص
تم إصلاح ربط الجرس وواجهة قائمة إشعارات المرحلة الرابعة، وإضافة تهيئة استقبال Firebase Cloud Messaging والتعامل مع الضغط على Push لدى وجود مُرسِل موثوق. **هذه حزمة مرشحة للاختبار، لا إثبات نجاح FCM الحقيقي**: توثيق عبدالله المرفق يصرح أن Laravel ينشئ إشعارات قاعدة البيانات فقط ولا يرسل Push إلى FCM.

## ما تغيّر بالفعل في Flutter
- جرس Pilot Home وCompany Home أصبح يفتح `features/notifications/screens/notifications_screen.dart` بدل الشاشة الوهمية الثابتة. أبقينا الملف القديم كغلاف يفتح الشاشة الحقيقية لتجنّب كسر أي مرجع سابق.
- تمت إضافة مدخل Notifications للأدمن، يعمل من نفس GET `/notifications` بحسب التوكن (الـAPI لا يتطلب endpoint منفصل حسب الدور).
- عداد الجرس يستخدم `data.unread_count` من الـAPI؛ لا يعرض نقطة ثابتة على أنها إشعار جديد. التحديث عند دخول الحساب، الرجوع لصندوق الإشعارات، فتح التطبيق من الخلفية، وعند وصول Push فعلي، مع حد تقريبي بين الاستدعاءات غير الإجبارية 45 ثانية لتخفيف خطر 429.
- `GET /notifications` + `?unread=1`, الترقيم، `POST /notifications/{uuid}/read`, `POST /notifications/read-all` في الخدمة الموجودة. الإشعارات تحدد كمقروءة دون تعليق التنقل على بطء الشبكة، وتنعكس القراءة على الشارة عند تأكيد السيرفر.
- تجهيز مستقبل FCM في التطبيق المفتوح (`onMessage` مع SnackBar قابل للنقر)، بالخلفية (`onMessageOpenedApp`)، وعند بدء التطبيق من إشعار بعد إغلاقه (`getInitialMessage`). مع `onBackgroundMessage` بنقطة دخول آمنة لا تحاول فتح واجهة من isolate خلفي.
- عند الضغط على Push، ينتظر التطبيق حتى يوجد حساب موثّق؛ ويسقط الضغطات بعد تسجيل الخروج. التسجيل والخروج يمسحان عداد الإشعارات الخاص بالحساب السابق محليًا.
- تحديث FCM Token: لا يطبع قيمة التوكن السرية في الـlogs، ويحتفظ بالمستمع حتى إذا تأخر توليد التوكن.
- Android: إضافة `POST_NOTIFICATIONS`، والتحقق من أن google-services.json يطابق applicationId. iOS: إضافة `UIBackgroundModes` لقناة remote-notification؛ **لكن إعداد iOS ما زال ناقصًا**.
- إضافة 4 اختبارات لمنطق نموذج الإشعار وأنواع المرحلة الرابعة وتحليل FCM data وUUID؛ لم تُشغّل لاختفاء Flutter SDK في بيئة المراجعة.

## مسارات الضغط من الأحداث الـ10 الموثقة

| type | related_type | انتقال Flutter |
|---|---|---|
| account_status_changed | user | ملف البايلوت أو الشركة (الأدمن: رسالة حالة) |
| application_received | job_application | قائمة طلبات الشركة (المعرف هو رقم الطلب، وليس رقم الوظيفة) |
| application_status_changed | job_application | البايلوت: تفاصيل طلبه بالـID؛ الشركة: قائمة الطلبات |
| contract_created | contract | البايلوت: تفاصيل العقد بالـID |
| contract_status_changed | contract | تفاصيل العقد للدور المعني بالـID |
| work_submitted | contract_submission | عقود الشركة؛ تفاصيل العقد مباشرة فقط إذا توافر `contract_id` إضافي |
| work_reviewed | contract_submission | عقود البايلوت؛ تفاصيل العقد مباشرة فقط إذا توافر `contract_id` إضافي |
| payment_status_changed | payment | تاريخ المدفوعات، مع فلتر العقد إذا أُرسل `contract_id` |
| subscription_status_changed | user_subscription | مركز الاشتراكات |
| review_received | review | تقييمات الحساب؛ استرجاع profile ID من API عند غيابه محليًا |

مهم: `related_id` في work_submitted/work_reviewed هو **submission ID**، وليس contract ID. لا يجوز تحويله مباشرة إلى `/contracts/{id}`. وبالمثل `related_id` في application_received هو **application ID**. لتحويلها إلى الشاشة الدقيقة دون بحث طويل نحتاج `contract_id` أو `job_posting_id` إضافيًا بالـpayload، أو endpoint يعيد كائن العلاقة مع المعرّفات الأب.

## نواقص خارج تحكم Flutter — مهمة قبل إطلاق Push حقيقي
1. **Laravel لا يرسل FCM Push حاليًا حسب توثيق المرحلة الرابعة**. يلزم Firebase Admin SDK أو FCM HTTP v1 من بيئة السيرفر فقط، مع Queue لتوصيل الإشعارات للمستلمين عند إنشائها في قاعدة البيانات. لا تُوضع مفاتيح Service Account في تطبيق الموبايل.
2. على السيرفر حفظ FCM Token لكل جهاز/مستخدم، التعامل مع حالات Unregistered/Invalid، ومنع تسريب إشعارات حساب قديم بعد Logout؛ الأفضل توفير endpoint لإلغاء تسجيل الجهاز عند الخروج.
3. Endpoint `/fcm-token/refresh` يتطلب `old_token` و`token`؛ عندما يظهر توكن لأول مرة **بعد** تسجيل الدخول ولا يوجد `old_token`، لا يوجد في التوثيق endpoint مستقل لتسجيله. يلزم مسار register/upsert token للمستخدم الحالي. في تسجيل الدخول العادي يُرسل `fcm_token` بالفعل.
4. لضمان فتح تفاصيل تسليم العمل مباشرة أضيفوا `contract_id` في إشعارات submission. ولتفاصيل متقدّم لدى الشركة أضيفوا `job_posting_id` بجانب `related_id` الخاص بالتقديم، أو endpoint lookup مناسب؛ حاليًا الشاشة تفتح القسم الصحيح لا كائنًا بمعرّف خاطئ.
5. شاشة Notification Preferences الحالية تخزّن الخيارات محليًا **لكن لا يوجد API لتطبيقها على الإرسال أو التخزين**؛ وخيار تنبيهات الرسائل ليس من أنواع إشعارات المرحلة الرابعة المذكورة. يلزم تحديد المتطلبات وتطبيقها على السيرفر. لا يجوز الإيحاء بأن إيقاف toggle يمنع Push من السيرفر.
6. ملف `ios/Runner/GoogleService-Info.plist` غير موجود، وكذلك يلزم ضبط APNs Push Notifications capability، مفتاح Apple APNs في Firebase Console وتوقيع iOS. لا يمكن تأكيد دعم Push على iOS من الحزمة الحالية.
7. يحتاج تأكيد Cloudflare وLaravel أثناء تشغيل حقيقي لتجنب 429 و500 و503. شاشة Flutter لا تعالج توقف الخادم.

### نموذج FCM مرسل من Backend (قِيَم data كلها Strings)
```json
{
  "notification": {
    "title": "New contract",
    "body": "A company has offered you a contract"
  },
  "data": {
    "notification_id": "90b8c74e-5973-4eb1-ac17-6d2bb0ffcc1f",
    "type": "contract_created",
    "related_type": "contract",
    "related_id": "19"
  }
}
```
هذا **مثال للحمولة** لا يُرسل من الموبايل. المرسل المسؤول عن هذه الحمولة هو خادم موثوق.

## التحقق الذي أُجري
- فحص مسارات 1258 import في ملفات Dart: **0 مراجع داخلية مفقودة**.
- فحص توازن الأقواس والنصوص في كل ملفات Dart المتغيّرة: **لم تُرصد تعارضات نصية**.
- `ios/Runner/Info.plist` قابل للقراءة كـPlist؛ وAndroid Manifest يحتوي POST_NOTIFICATIONS.
- فحص وجود إعداد Android Firebase ومطابقة معرف الحزمة فقط؛ لم يُجر اتصال بفirebase أو طلب فعلي للـAPI.
- **لم يتم تشغيل Flutter SDK أو `flutter analyze`, `flutter test`, `flutter build` على الجهاز في هذه البيئة.** لا يُعد الفحص النصي بديلًا عن البناء.

## سيناريوهات اختبار القبول على جهاز Android
1. سجلي دخول Pilot، تأكدي أن الجرس يفتح قائمة API حقيقية، ثم افتحي إشعار حالة طلب، وعودي لمراجعة العداد والمقروء.
2. سجلي دخول Company، جرّبي إشعار تقديم، تغيير حالة العقد، والتسليم الجديد؛ يجب فتح أقسام الشركة لا أقسام البايلوت.
3. سجلي دخول Admin، افتحي صندوق الإشعارات من رأس صفحة الأدمن.
4. جرّبي `Mark all as read` والفلتر Unread والتحميل على أكثر من صفحة مع بطء الشبكة؛ لا يظهر No Data قبل انتهاء أول جلب.
5. أرسلي رسالة اختبار FCM إلى جهازك من Firebase Console الخاص بمشروعك (لا تشاركي التوكن هنا). تحققي من app foreground؛ ثم background؛ ثم terminated مع ضغط الإشعار.
6. للـDeep Link، استخدمي نفس مفاتيح `data` في المثال أعلاه مع `related_id` حقيقي ومصرّح لهذا المستخدم.
7. سجلي خروجًا ثم ادخلي حسابًا مختلفًا. لا يجب إبقاء عداد الحساب القديم أو فتح إشعاره داخل الحساب الجديد.
8. إذا فشل أي طلب، سجلي URI وHTTP status وContent-Type وتاريخ الاختبار؛ لا ترسلي التوكن أو كلمات المرور في اللوج.

أوامر فحص الجهاز:
```powershell
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --debug
```

الخلاصة: **واجهة الإشعارات والـrouting أصبحت مرشحة للاختبار؛ أما Push التلقائي الكامل فلا يصح اعتباره منجزًا حتى يُنشَّط إرسال FCM من Laravel ويُجرّب على جهاز حقيقي.**
