# TOTOTL INTGRX — API Update Integration (16 November 2026)

## نطاق النسخة
قاعدة العمل: TOTOTL_STRIPE_DEMO_INTEGRATED_2026-11-14.zip + إصلاح LEGAL_IDENTITY_NOT_VERIFIED المرسل لاحقًا. تم الاحتفاظ بتعديلات الدرونات التسع، الترجمة، الإشعارات، العقود والكاش من النسخ السابقة. التعديلات مبنية على الملف `Last Update TOTOTL INTGRX API.json` الذي أرسله المستخدم.

## التغييرات المضافة
1. **Legal Identity:** API GET/POST ومراسلة `multipart/form-data` للحقول `legal_name`, `entity_kind`, `country`, `registrations[0][scheme]`, `registrations[0][value]`, و`documents[n]`. شاشة جديدة من الإعدادات لكلا الدورين، مع القيم الخاصة بأنواع التسجيل من السيرفر، ورفض إرسال نموذج ناقص؛ النموذج يرسل طلب مراجعة ولا يدّعي توثيق الهوية.
2. **Admin:** شاشة مراجعة الهويات المنتظرة، وأزرار verify/reject (سبب الرفض 10–1000 حرف) منفصلة عن اعتماد الحساب العادي. يجب أن يراجع الأدمن المستندات قبل الموافقة.
3. **Accept Contract:** كود 422 `LEGAL_IDENTITY_NOT_VERIFIED` لا يؤدي لإعادة إرسال POST أو انتظار ستة GET؛ يظهر حوارًا يفتح شاشة الهوية.
4. **Funding:** شاشة الدفع تعتمد POST Quote مع عرض المبلغ الحقيقي والرسوم وإجمالي التحصيل، ثم POST Collect بمفتاح quote_reference من السيرفر. GET Collection Status متاح عندما يعود attempt_id. لا تُعتبر استجابة Collect دفعًا ناجحًا، ولا تتحول حالة العقد محليًا إلى Active دون تأكيد Backend.
5. **Demo:** التمويل القديم `/fund` موجود فقط خلف اختيار صريح في وضع Debug؛ لا يتم عرضه كدفع حقيقي افتراضيًا. لا توجد معالجة لبطاقات الائتمان محليًا.
6. **Contract duplicate:** لا يتم حذف العقد المعروف من الكاش إذا فشل طلب تحقق. عند فشل create POST واحتمال فقد استجابته يجري التطبيق GET واحدًا لمحاولة معرفة عقد موجود، دون إعادة POST تلقائي. نقل زر إنشاء إلى تفاصيل العقد المعروف. يحتاج منع التكرار النهائي قيد unique على السيرفر.
7. **Cancel:** السبب أصبح إلزاميًا ويُرسل عبر JSON، بما يوافق `CancelContractRequest` الجديد.
8. **Logging:** أُزيلت طباعة تفاصيل طلب/رد إنشاء العقد بالكامل. سجلات Debug تتضمن المسار والرموز وحالة HTTP بلا Tokens أو بيانات بطاقة.
9. اختبار إضافي لمطابقة مسارات الـAPI وللحالات التي تسمح بالتمويل.

## ما **لم** يتم إثباته أو تنفيذه
- لم يتوفر Flutter SDK في بيئة التعديل، لذلك **لم يتم تشغيل flutter analyze أو flutter test أو APK Build** هنا. فحوصات imports وZIP ثابتة وليست بديلًا عن Build.
- تحقق KYC/Legal Identity يتوقف على اعتماد الأدمن وفق قواعد Laravel الفعلية. حساب العقد #12 لن يتحول إلى verified بمجرد إرسال الهوية.
- Stripe SDK/PaymentSheet/3DS غير موثق بشكل كافٍ في OpenAPI. رد `collect` موثق بـ`data: []` ولا يضمن وجود attempt_id أو client_secret. لذلك تركت تجربة الدفع الحقيقية مشروطة بتحديث العقد من السيرفر؛ لا يوجد حفظ لبطاقات أو تأكيد دفع وهمي.
- الموافقة الثانية من الشركة على بدء العمل، والتوقيع النهائي بعد تسليم العمل، وصرف مبالغ حقيقية ليست مسارات مثبتة في Swagger الجديد. لا تُستبدل بـ `terminate` لأن دلالته إنهاء مبكر.
- أخطاء Cloudflare 429 وGateway 502/503 والـTimeout تحتاج اختبار تشغيل جديد بعد تغييرات عبدالله؛ لا يمكن إثبات حلها من توثيق OpenAPI.
- متغيرات الحالة والمراحل في Flutter يجب اختبارها بحساب Company وآخر Pilot، على Debug وRelease؛ وجود زر في واجهة أحدهما لا يثبت تحديث الآخر.

## اختبار القبول على جهاز Windows
```powershell
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --debug
flutter build apk --release
flutter run -d 192.168.56.102:5555 2>&1 | Tee-Object -FilePath tototl_debug_new.log
```

سيناريو الاختبار: حساب طيار بدون هوية → تظهر رسالة واضحة عند Accept → يرسل الهوية → الأدمن يعتمدها → Accept ينجح → الشركة تفتح نفس العقد ولا تستطيع إنشاء عقد مكرر → Quote يعرض الرسوم → Collect (أو التمويل التجريبي للاختبار) → يتم عرض **pending** حتى يؤكد السيرفر → Active → الموقع → Start Work من الطيار → Submitted Files → Review → Completed → Ratings.

*للتسليم الإنتاجي الحقيقي يلزم تفعيل مزود الدفع وتوثيق تدفق Collection Response وإثبات استقرار السيرفر. لا تضع أي مفاتيح Stripe السرية أو بيانات بطاقات ضمن تطبيق Flutter.*
