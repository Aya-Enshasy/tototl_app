import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../pilot/shared/pilot_data.dart';
import 'mission_tracking_screen.dart';
import 'operation_store.dart';

class CompanyOfferScreen extends StatefulWidget {
  const CompanyOfferScreen({super.key, required this.application});
  final PilotApplication application;
  @override
  State<CompanyOfferScreen> createState() => _CompanyOfferScreenState();
}

class _CompanyOfferScreenState extends State<CompanyOfferScreen> {
  final _date = TextEditingController(text: '2026-08-14');
  final _hours = TextEditingController(text: '8');
  final _amount = TextEditingController(text: '850');
  @override
  void dispose() {
    _date.dispose();
    _hours.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              const Expanded(
                child: Text(
                  'Create Offer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            widget.application.pilot.name,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.application.job.title,
            style: const TextStyle(color: AppColors.grey, fontSize: 13.5),
          ),
          const SizedBox(height: 24),
          _label('Mission date'),
          _field(_date, 'YYYY-MM-DD'),
          _label('Mission hours'),
          _field(_hours, '8', type: TextInputType.number),
          _label('Agreed amount (USD)'),
          _field(_amount, '850', type: TextInputType.number),
          const SizedBox(height: 22),
          const Text(
            'The amount is held securely after the pilot accepts and is released only after work confirmation.',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _send,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Send Offer',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  void _send() {
    final amount = double.tryParse(_amount.text);
    final hours = int.tryParse(_hours.text);
    if (amount == null || hours == null || _date.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a valid date, duration, and amount.'),
        ),
      );
      return;
    }
    final mission = OperationStore.instance.sendOffer(
      widget.application,
      date: _date.text.trim(),
      hours: hours,
      amount: amount,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            MissionTrackingScreen(mission: mission, isCompany: true),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 17, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.navy,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType type = TextInputType.text,
  }) => TextField(
    controller: controller,
    keyboardType: type,
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
    ),
  );
}
