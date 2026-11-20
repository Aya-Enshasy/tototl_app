# TOTOTL — إصلاح محاولات Stripe المعلّقة وكاش البروفايل

## المشكلة الأساسية

السيرفر يرجع: `422 Attempt #2 is still pending on this contract`.
هذه ليست مشكلة في WebView ولا انتهاء Quote، بل محاولة دفع موجودة بالفعل.
يمنع Flutter الآن إعادة `/fund` عشوائيًا لنفس العقد، ويفحص الطلبات
المعلقة عبر `GET /company/payments?status=pending` إذا كانت تفاصيل العقد
لا تعطي حالة الدفع.

إذا كان رابط Stripe محفوظًا على الجهاز أو موجودًا في `payment.client_action.token`
يمكن استكماله. إذا كان الرابط غير متاح من السيرفر ولا من التخزين المحلي،
فلا يمكن اختراعه؛ يحتاج عبدالله إلى توفير Resume Checkout لنفس المحاولة
أو إغلاقها/إلغائها في السيرفر بعد التحقق من بوابة Stripe.

## المسار الصحيح

1. الشركة تفتح عقدًا بحالة accepted، ويُفحص وضع الدفع مسبقًا.
2. إذا لم يوجد دفع معلق، يُطلب Quote مرة واحدة ويُعرض إجمالي الرسوم.
3. بعد التأكيد، `POST /company/contracts/{id}/fund` مع
   `{ "quote_reference": "...", "method": "redirect" }`.
4. إذا رجع `payment.client_action.token` رابط HTTPS من checkout.stripe.com،
   يُفتح WebView مع خيار المتصفح الخارجي.
5. إغلاق WebView أو الرجوع منه **لا يعني الدفع**؛ يظل العقد accepted حتى
   يؤكد Laravel/Webhook استلام الدفعة.
6. عند الرد `Attempt #N is still pending` تحفظ هوية المحاولة محليًا،
   ويظهر رقمها وحالة الدفع وتعليمات الاسترجاع دون إعادة fund.

## البروفايل

يُخزن Snapshot مشفر لبيانات الملف الشخصي ويُفصل حسب user ID.
بعد تسجيل الدخول إلى **نفس الحساب**، تُستعاد بياناته مباشرة ثم
يستمر التحديث بالخلفية. لا يُستعمل الكاش لاتخاذ قرارات صلاحية أو دفع.

## التحقق المطلوب

```powershell
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --debug
```

ثم اختبر السيناريوهات: pending مع رابط؛ pending بلا رابط؛ failed؛ funded؛
ضغط متكرر على Fund؛ switching accounts؛ إعادة فتح البروفايل دون إنترنت.

**تنبيه:** الحزمة لم تجتز تنفيذ Flutter في بيئة الإنشاء هنا لغياب Flutter SDK.
لم نختبر عملية دفع Stripe حقيقية أو إصدار webhook من Laravel.
