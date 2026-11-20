# TOTOTL — المطلوب من Backend/Web فقط

**المصدر:** سجل تشغيل Android بتاريخ 14 نوفمبر 2026 (قبل آخر إصلاحات Flutter)، وتوثيق Phase 4 API. هذه أرقام من تشغيل سابق، وليست فحصًا مباشرًا جديدًا للسيرفر.

## 1) أخطاء HTTP التي ظهرت بالفعل — للتحقيق عند عبدالله

| Request | الإخفاقات المرصودة | تفصيل مختصر |
|---|---:|---|
| `GET /api/v1/company/contracts` | 47 | 27×429، 9×503، 10×timeout، وواحد آخر |
| `GET /api/v1/company/job-postings/{id}` | 36 | 30×429، 2×503، 4×timeout |
| `GET /api/v1/company/job-postings/{id}/applicants` | 26 | 22×429، 1×503، 3×timeout |
| `GET /api/v1/company/pilots/{id}/drones` | 20 | 18×429، 2×503 |
| `GET /api/v1/company/pilots/{id}` | 19 | 18×429، 1×503 |
| `GET /api/v1/company/dashboard` | 18 | 7×503، 11×timeout |
| `GET /api/v1/company/applicants` | 14 | 4×429، 5×503، 5×timeout |
| `GET /api/v1/companies/{id}/reviews` | 5 | 2×429، 2×503، 1×401؛ يجب تدقيق جلسة المستخدم بالـ401 |
| `GET /api/v1/pilot-licenses` | 1 | 503 رغم وجود تراخيص في حساب المستخدم |
| `POST /api/v1/auth/logout` | 2 | 503 و502 |
| `GET /api/v1/jobs/{id}` | 4 | 503 |
| `POST /api/v1/company/job-postings/{id}/applicants/{id}/contract` | 6 | 3×429، 1×503، 2×422 بعد إنشاء سابق لنفس الطلب؛ لا نفترض أن 422 خلل سيرفر بحد ذاته |

**أمثلة ذات Request ID من اللوج** (للربط مع Cloudflare/Laravel):
- `GET /api/v1/company/dashboard` — `503` — `a5a680d30882b776-ZDM`، وفشل timeout آخر بعد نحو 19.4 ثانية.
- `GET /api/v1/company/contracts` — `429` — `a5a681841fdc6d23-ZDM`.
- `GET /api/v1/pilot-licenses` — `503` — `a5a68a8928aeafa7-ZDM`.
- `POST /api/v1/auth/logout` — `502` — `a5a6bf36ba685daa-ZDM`.
- `POST /api/v1/company/job-postings/19/applicants/11/contract` — **نجح 201** مرة (#46)، ثم ظهر 429/503/422 في محاولات لاحقة (#208/#209/#210). المطلوب منع إنشاء مكرر وإرجاع العقد المرتبط بالطلب.

**المطلوب:** تحليل Cloudflare WAF/rate limits وLaravel/DB والاستضافة، ثم توفير استجابات JSON و`Retry-After` معقول، وربط كل خطأ بـRequest ID. وقد تم بالفعل تخفيف الطلبات المتزامنة في Flutter، لكن ذلك لا يحل 503 من الخادم.

**ليس خطأ سيرفر بالضرورة:** `GET /company/contracts/{id}/location` حين لا يوجد موقع بعد قد يعيد 404 منطقيًا، و422 بعد إنشاء عقد سابق قد يكون منع تكرار صحيحًا. لا ترسل هذه كأخطاء قبل فحص أسبابها.

## 2) ما يلزم من API لاستكمال رحلة العقد المطلوبة

**مدعوم حاليًا في التوثيق:**
1. الشركة تنشئ عقدًا من طلب مقبول: `POST /v1/company/job-postings/{jobPosting}/applicants/{jobApplication}/contract` → `pending`.
2. الطيار يوافق: `POST /v1/contracts/{contract}/accept` → `accepted`.
3. الشركة تموّل: `POST /v1/company/contracts/{contract}/fund` → `active`، **لكن بوابة الدفع stub تجريبية، دون تحصيل حقيقي أو بيانات بطاقة**.
4. الشركة تحدد الموقع: `PUT /v1/company/contracts/{contract}/location`.
5. الطيار يبدأ: `POST /v1/contracts/{contract}/start-work` → `in_progress`.
6. الطيار يرفع تسليمًا: `POST /v1/contracts/{contract}/submissions`.
7. الشركة توافق أو تطلب تعديلًا: `POST /v1/company/contracts/{contract}/submissions/{submission}/approve` أو `request-revision`؛ الموافقة النهائية تكمل العقد.
8. التقييمات بعد `completed`.

**فجوات مطلوبة حسب مسار العمل الجديد (ليست أخطاء قائمة):**
- **Stripe الحقيقي:** Backend يجهّز PaymentIntent/Checkout، webhook موثق ويمنع التزوير/التكرار، ويربط التمويل الناجح بحالة العقد؛ عند الحاجة لتحويلات للطيار يتطلب Stripe Connect/مزوّد دفع مناسب. لا تُحدث `funded` بناءً على نجاح واجهة Flutter وحدها.
- **Start Work من الطرفين:** يوجد في التوثيق زر/Endpoint بدء العمل للطيار فقط. مطلوب إجراء مستقل لتأكيد الشركة بدء العمل، وحالة تتأكد من موافقة الاثنين قبل الانتقال إذا كان شرطًا ملزمًا.
- **وثيقة إنهاء نهائية وتوقيع الطيار:** غير موجودة. `POST /company/contracts/{contract}/terminate` مخصص لإيقاف عقد **أثناء التنفيذ** (InProgress) وليس لإنهائه بنجاح. مطلوب نموذج إنهاء/اعتماد ختامي وتوقيع الطيار ومسارات موافقة قبل الصرف إذا هذا التسلسل المعتمد.
- **صرف الأموال:** التأكد من سجل دفع موثوق وحالة `released`/payout حقيقية بعد استيفاء الشروط، وعدم صرف وهمي لمجرد اكتمال عقد في الـUI.
- **منع التكرار:** جلب عقد الشركة مباشرة بواسطة `application_id`، مع قيد فريد أو idempotency key لإنشاء عقد واحد لكل طلب.

**ملاحظة:** لم يظهر في اللوج تنفيذ لمسار `POST /company/contracts/{id}/fund` ولا مسار Stripe؛ لا يوجد دليل من اللوج على فشلهما. هذه فجوة تشغيل/تكامل موثقة، وليست خطأ HTTP مرصودًا.

**خارج هذه الرسالة عمدًا:** Firebase Chat والإشعارات؛ لا نعدّها عيوبًا في Backend بناءً على طلب صاحبة المشروع.
