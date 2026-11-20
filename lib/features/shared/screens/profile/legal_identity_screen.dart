import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/theme/app_colors.dart';
import '../../services/legal_identity_service.dart';

/// Legal signing identity: independent of the existing account approval badge.
/// Submit the multipart registration to the API; only Admin may verify it.
class LegalIdentityScreen extends StatefulWidget {
  const LegalIdentityScreen({super.key});
  @override
  State<LegalIdentityScreen> createState() => _LegalIdentityScreenState();
}

class _LegalIdentityScreenState extends State<LegalIdentityScreen> {
  final service = LegalIdentityService(ApiClient());
  final name = TextEditingController();
  final country = TextEditingController();
  final legalForm = TextEditingController();
  final address = TextEditingController();
  final regValue = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String kind = 'natural';
  String? scheme;
  Map<String, dynamic>? identity;
  Map<String, dynamic> schemes = {};
  List<PlatformFile> attachments = [];
  bool loading = true;
  bool saving = false;
  String? error;

  String tr(String en, String ar, String de) => switch (AppLanguage.locale.value.languageCode) {
    'ar' => ar, 'de' => de, _ => en,
  };

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    name.dispose(); country.dispose(); legalForm.dispose(); address.dispose(); regValue.dispose();
    super.dispose();
  }

  String? _currentStatus() {
    final item = identity;
    if (item == null) return null;
    final verified = item['verified']?.toString().toLowerCase() ?? '';
    if (item['verified_at'] != null || {'1', 'true', 'yes', 'verified'}.contains(verified)) return 'verified';
    if (item['rejection_reason']?.toString().trim().isNotEmpty == true) return 'rejected';
    return 'pending';
  }

  List<Map<String, dynamic>> get availableSchemes {
    final raw = schemes[kind];
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _reload() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await service.getMine();
      if (!mounted) return;
      final raw = data['identity'];
      final item = raw is Map ? Map<String, dynamic>.from(raw) : null;
      final newSchemes = data['schemes'] is Map
          ? Map<String, dynamic>.from(data['schemes'] as Map) : <String, dynamic>{};
      setState(() {
        identity = item;
        schemes = newSchemes;
        if (item != null) {
          name.text = item['legal_name']?.toString() ?? '';
          country.text = item['country']?.toString() ?? '';
          legalForm.text = item['legal_form']?.toString() ?? '';
          address.text = item['registered_address']?.toString() ?? '';
          final incomingKind = item['entity_kind']?.toString();
          if (incomingKind == 'natural' || incomingKind == 'legal') kind = incomingKind!;
        }
        scheme = null;
      });
      if (kDebugMode) debugPrint('[TOTOTL][LEGAL_IDENTITY][GET] status=${_currentStatus() ?? 'not_submitted'}');
    } catch (e) {
      if (mounted) setState(() => error = _safeError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _safeError(Object e) {
    final s = e.toString();
    if (s.contains('429')) return tr('Too many requests. Try shortly.', 'طلبات كثيرة، حاولي بعد قليل.', 'Zu viele Anfragen.');
    if (s.contains('503') || s.contains('502')) return tr('Service temporarily unavailable.', 'الخدمة غير متاحة مؤقتًا.', 'Dienst vorübergehend nicht verfügbar.');
    return s.length > 240 ? s.substring(0, 240) : s;
  }

  Future<void> _chooseFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true, type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || !mounted) return;
    final items = result.files.take(5).toList();
    if (items.any((e) => e.size > 10 * 1024 * 1024)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Each file must be smaller than 10 MB.')));
      return;
    }
    setState(() => attachments = items);
  }

  Future<void> _submit() async {
    if (saving || !(formKey.currentState?.validate() ?? false)) return;
    if (scheme == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Choose a registration type.', 'اختاري نوع الوثيقة.', 'Registrierungsart wählen.'))));
      return;
    }
    setState(() { saving = true; error = null; });
    try {
      await service.submit(
        legalName: name.text, entityKind: kind, country: country.text,
        legalForm: legalForm.text, registeredAddress: address.text,
        registrationScheme: scheme!, registrationValue: regValue.text,
        documents: attachments,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(
        'Sent for Admin verification. Contract acceptance remains locked until approved.',
        'تم الإرسال لمراجعة الأدمن. قبول العقد يبقى مقفولًا حتى الاعتماد.',
        'Zur Überprüfung eingereicht. Vertragsannahme bleibt bis zur Genehmigung gesperrt.',
      ))));
      await _reload();
    } catch (e) {
      if (mounted) setState(() => error = _safeError(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _field(TextEditingController controller, String title, {bool required = false, String? hint}) =>
      Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(
        controller: controller, maxLines: 1, style: const TextStyle(fontSize: 13),
        validator: (v) => required && (v?.trim().isEmpty ?? true) ? tr('Required', 'مطلوب', 'Erforderlich') : null,
        decoration: InputDecoration(labelText: title, hintText: hint, border: const OutlineInputBorder()),
      ));

  @override
  Widget build(BuildContext context) {
    final rtl = AppLanguage.locale.value.languageCode == 'ar';
    final status = _currentStatus();
    return Directionality(textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(title: Text(tr('Legal Identity', 'الهوية القانونية', 'Rechtliche Identität'), style: const TextStyle(fontSize: 16)),
            actions: [IconButton(onPressed: saving ? null : _reload, icon: const Icon(Icons.refresh_rounded))]),
        body: loading && identity == null
          ? const Center(child: CircularProgressIndicator())
          : Form(key: formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
              if (identity != null) Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(status == 'verified' ? tr('Verified', 'تم التحقق', 'Bestätigt')
                    : status == 'rejected' ? tr('Rejected — please correct details', 'مرفوضة — يرجى تصحيح البيانات', 'Abgelehnt')
                    : tr('Pending Admin review', 'بانتظار مراجعة الأدمن', 'Prüfung ausstehend'),
                    style: TextStyle(fontWeight: FontWeight.w800, color: status == 'verified' ? Colors.green : Colors.deepOrange, fontSize: 14)),
                  if (identity!['rejection_reason']?.toString().isNotEmpty == true)
                    Text(identity!['rejection_reason'].toString(), style: const TextStyle(fontSize: 12)),
                ],
              ))),
              if (error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
              Text(tr('Your contract signing identity', 'بيانات الهوية لتوقيع العقد', 'Identität für Vertragsunterzeichnung'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(tr('Account approval and legal verification are separate. Re-submission requires another Admin approval.',
                'اعتماد الحساب والتحقق القانوني خطوتان منفصلتان. تعديل البيانات يحتاج مراجعة جديدة.',
                'Konto- und Identitätsprüfung sind getrennt.'), style: const TextStyle(fontSize: 11.5)),
              const SizedBox(height: 16),
              _field(name, tr('Legal name', 'الاسم القانوني', 'Gesetzlicher Name'), required: true),
              DropdownButtonFormField<String>(value: kind,
                decoration: InputDecoration(labelText: tr('Entity type', 'نوع الكيان', 'Rechtsform'), border: const OutlineInputBorder()),
                items: [DropdownMenuItem(value: 'natural', child: Text(tr('Individual', 'شخص طبيعي', 'Natürliche Person'))),
                  DropdownMenuItem(value: 'legal', child: Text(tr('Company / legal entity', 'شركة / شخص اعتباري', 'Juristische Person')))],
                onChanged: (v) { if (v != null) setState(() { kind = v; scheme = null; }); }),
              const SizedBox(height: 12),
              _field(country, tr('Country ISO code (e.g. PS)', 'رمز الدولة (مثل PS)', 'Ländercode (z. B. PS)'), required: true, hint: 'PS'),
              _field(legalForm, tr('Legal form (optional)', 'الشكل القانوني (اختياري)', 'Rechtsform (optional)')),
              _field(address, tr('Registered address (optional)', 'العنوان المسجل (اختياري)', 'Registrierte Adresse (optional)')),
              if (availableSchemes.isNotEmpty) DropdownButtonFormField<String>(
                value: availableSchemes.any((s) => s['value']?.toString() == scheme) ? scheme : null,
                decoration: InputDecoration(labelText: tr('Registration / ID type', 'نوع الهوية / التسجيل', 'Registrierungsart'), border: const OutlineInputBorder()),
                items: availableSchemes.map((s) => DropdownMenuItem(value: s['value'].toString(),
                  child: Text(s['label']?.toString() ?? s['value'].toString()))).toList(),
                onChanged: (v) => setState(() => scheme = v),
              ) else Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(tr('Registration types unavailable — refresh before submitting.',
                'أنواع الهوية غير متاحة؛ حدّثي الصفحة قبل الإرسال.', 'Registrierungsarten fehlen.'))),
              const SizedBox(height: 12),
              _field(regValue, tr('Registration / document number', 'رقم الوثيقة / التسجيل', 'Dokumentnummer'), required: true),
              OutlinedButton.icon(onPressed: saving ? null : _chooseFiles,
                icon: const Icon(Icons.attach_file_rounded, size: 17),
                label: Text(tr('Attach proof (up to 5 files, 10 MB each)', 'إرفاق المستندات (5 ملفات، 10 ميجا لكل ملف)', 'Nachweise hinzufügen'),
                  style: const TextStyle(fontSize: 12))),
              for (final file in attachments) Text('• ${file.name}', style: const TextStyle(fontSize: 11)),
              const SizedBox(height: 18),
              FilledButton.icon(onPressed: saving || availableSchemes.isEmpty ? null : _submit,
                icon: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.verified_user_outlined),
                label: Text(tr('Submit for verification', 'إرسال للتحقق', 'Zur Überprüfung senden'))),
            ])),
      ),
    );
  }
}
