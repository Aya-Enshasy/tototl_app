import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/localization/app_language.dart';
import '../../shared/services/legal_identity_service.dart';

/// Separate queue from Pilot/Company *account approval*.
class AdminLegalIdentityScreen extends StatefulWidget {
  const AdminLegalIdentityScreen({super.key});
  @override
  State<AdminLegalIdentityScreen> createState() => _AdminLegalIdentityScreenState();
}

class _AdminLegalIdentityScreenState extends State<AdminLegalIdentityScreen> {
  final service = LegalIdentityService(ApiClient());
  List<Map<String, dynamic>> items = [];
  bool loading = true;
  int? busyId;
  String? error;

  String tr(String en, String ar) => AppLanguage.locale.value.languageCode == 'ar' ? ar : en;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final list = await service.pending();
      if (mounted) setState(() => items = list);
    } catch (e) {
      if (mounted) setState(() => error = 'Could not load legal identities. ${e.runtimeType}');
    } finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _decide(int id, {required bool approve}) async {
    if (busyId != null || id <= 0) return;
    var reason = '';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(approve ? tr('Verify legal identity?', 'اعتماد الهوية القانونية؟')
          : tr('Reject legal identity?', 'رفض الهوية القانونية؟')),
      content: approve ? Text(tr('Only approve documents that were actually checked.', 'اعتمدي المستندات بعد التحقق منها فعليًا.'))
        : TextField(maxLength: 1000, minLines: 3, maxLines: 5,
          onChanged: (s) => reason = s,
          decoration: InputDecoration(hintText: tr('Reason (at least 10 characters)', 'سبب الرفض (10 أحرف على الأقل)'))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel', 'إلغاء'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(approve ? tr('Verify', 'اعتماد') : tr('Reject', 'رفض')))],
    ));
    if (ok != true || !mounted) return;
    if (!approve && reason.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Provide a reason of at least 10 characters.', 'اكتبي سببًا لا يقل عن 10 أحرف.'))));
      return;
    }
    setState(() => busyId = id);
    try {
      if (approve) { await service.verify(id); }
      else { await service.reject(id, reason); }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve ? tr('Identity verified.', 'تم اعتماد الهوية.') : tr('Identity rejected.', 'تم رفض الهوية.'))));
        await _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('Action failed', 'فشلت العملية')}: $e')));
    } finally { if (mounted) setState(() => busyId = null); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(tr('Legal identity approvals', 'اعتماد الهويات القانونية')),
      actions: [IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh))]),
      body: loading && items.isEmpty ? const Center(child: CircularProgressIndicator())
        : error != null && items.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(error!), TextButton(onPressed: _load, child: Text(tr('Retry', 'إعادة المحاولة')))]))
        : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(14), children: [
            if (items.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Text(tr('No identities are waiting for review.', 'لا يوجد طلبات تحقق منتظرة.'))),
            for (final item in items) Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['legal_name']?.toString() ?? 'Unknown', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('ID ${item['id']} · ${item['entity_kind'] ?? ''} · ${item['country'] ?? ''}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 5),
                Text(tr('Check submitted documents via secure admin access before approving.',
                  'افحصي المستندات من خلال وصول الأدمن الآمن قبل الاعتماد.'), style: const TextStyle(fontSize: 11)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: busyId == null ? () => _decide(int.tryParse(item['id']?.toString() ?? '') ?? 0, approve: false) : null,
                    child: Text(tr('Reject', 'رفض')))),
                  const SizedBox(width: 9),
                  Expanded(child: FilledButton(onPressed: busyId == null ? () => _decide(int.tryParse(item['id']?.toString() ?? '') ?? 0, approve: true) : null,
                    child: Text(tr('Verify', 'اعتماد')))),
                ]),
              ],
            ))),
          ])),
    );
  }
}
