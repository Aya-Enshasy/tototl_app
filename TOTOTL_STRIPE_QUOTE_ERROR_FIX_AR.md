# TOTOTL — فحص مشاكل Stripe Quote قبل فتح WebView

## السبب الظاهر في الصور

- **HTTP 429** أثناء عرض السعر يعني أن السيرفر/Cloudflare يحدّ من الطلبات. لا توجد بيانات Quote صالحة، وبالتالي لا يمكن إرسال طلب `POST /fund` أو فتح WebView بطريقة آمنة.
- رسالة **Quote expired or was rejected** كانت نصًا ثابتًا لأي `422` حتى لو السبب مختلف. صار التطبيق يعرض رسالة الـBackend الحقيقية (بشكل محدود وآمن) والـRequest ID عند توفره.
- Stripe Checkout المرفق بمثال عبدالله تجريبي `cs_test_`، لكن لا يمكن فتحه إلا بعد نجاح `POST /company/contracts/{contract}/fund` واستلام `payment.client_action.token` لموقع Stripe المعتمد.

## التعديل المطبق

1. تبريد Retry لمدة محددة عند HTTP 429 بدل تكرار POST Quote بسرعة، مع عدّ تنازلي واضح.
2. منع تحميل Quote بشكل متداخل داخل الشاشة نفسها.
3. حفظ آخر Quote صالح ومحدد المدة داخل تخزين مشفر ومرتبط بمعرّف المستخدم والعقد، لتقليل تكرار طلب عروض الأسعار عند إعادة فتح الصفحة.
4. مسار الدفع يظل `Quote -> تأكيد المبلغ -> POST /fund {quote_reference, method: redirect} -> Stripe WebView -> GET حالة العقد`.
5. الرفض 422 يعرض السبب الفعلي إن رجع في `message` أو أخطاء التحقق من السيرفر. لا يَفترض انتهاء العرض بدون دليل.
6. منع إعادة طلب POST /fund تلقائيًا عند خطأ أو انقطاع الرد. لا يُحسب الدفع ناجحًا بدون تأكيد السيرفر.
7. اختبارات Dart لحالات 422 و429 ومنع عرض HTML للسيرفر.

## الاختبار على جهاز المستخدم

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d 192.168.56.102:5555 2>&1 | Tee-Object tototl_stripe_debug.log
```

بعد التحقق من أن العقد Accepted:
- افتحي Fund Contract وانتظري Quote. إذا عاد 429، يجب أن يظهر عداد تأخير Retry.
- إذا عاد 422، سجلي المعلومة `POST /api/v1/company/contracts/{id}/quote` ورسالة الخطأ الحقيقية وRequest ID.
- بعد نجاح Quote تأكدي من عرض الرسوم ثم اضغطي Continue to Stripe checkout.
- بعد نجاح `POST /fund` يجب فتح WebView من `payment.client_action.token`.
- عودة المستخدم من Stripe ليست إثباتًا للدفع؛ انتظري GET للحالة المعتمدة من Laravel.

## حدود الإثبات

لا يتوفر Flutter SDK في بيئة الفحص هنا، فلم يُنفَّذ flutter analyze أو Flutter Build. كما أن نجاح دفع Stripe لم يختبر باستخدام حسابات حقيقية. تم التحقق من سلامة ZIP ووجود جميع مراجع import المحلية فقط. أسباب 429 أو 422 من السيرفر تحتاج سجلات Laravel/Cloudflare حال استمرارها.
