import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/localization/app_language.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/company_job_controller.dart';
import '../../models/company_contract_model.dart';
import '../../models/company_create_contract_request.dart';
import '../../models/company_job_application_model.dart';
import '../../services/company_job_service.dart';

class CreateCompanyContractScreen extends StatefulWidget {
  const CreateCompanyContractScreen({
    super.key,
    required this.jobId,
    required this.application,
  });

  final int jobId;
  final CompanyJobApplicationModel application;

  @override
  State<CreateCompanyContractScreen> createState() =>
      _CreateCompanyContractScreenState();
}

class _CreateCompanyContractScreenState
    extends State<CreateCompanyContractScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final CompanyJobController _controller;
  late final TextEditingController _amountController;
  late final TextEditingController _currencyController;
  late final TextEditingController _termsController;

  String _paymentType = 'fixed';
  late DateTime _startDate;
  DateTime? _endDate;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    _controller = CompanyJobController(
      CompanyJobService(ApiClient()),
    );

    _amountController = TextEditingController();
    _currencyController = TextEditingController(text: 'USD');
    _termsController = TextEditingController();

    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _currencyController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _ContractBackground(),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      children: [
                        _hero(),
                        const SizedBox(height: 12),
                        _pilotSummary(),
                        const SizedBox(height: 12),
                        _contractValueSection(),
                        const SizedBox(height: 12),
                        _scheduleSection(),
                        const SizedBox(height: 12),
                        _termsSection(),
                        const SizedBox(height: 12),
                        _reviewNotice(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_submitting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.08),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.blue,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Creating contract...',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _bottomAction(),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 7, 10, 5),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _submitting ? null : () => Navigator.of(context).pop(),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 17,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              AppLanguage.text('Create Contract'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 44, height: 44),
        ],
      ),
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF102A3A),
            Color(0xFF0D4757),
            Color(0xFF0D8AA5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'PHASE 3 · CONTRACT',
              style: TextStyle(
                color: Color(0xFF83E2C4),
                fontSize: 10.2,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Set the final mission agreement',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'The contract will be sent to the selected pilot and starts in Pending status.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.70),
              fontSize: 11.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(
                icon: Icons.work_outline_rounded,
                text: 'Job #${widget.jobId}',
              ),
              _HeroPill(
                icon: Icons.assignment_outlined,
                text: 'Application #${widget.application.id}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pilotSummary() {
    final pilot = widget.application.pilotProfile;
    final name = pilot?.displayName ??
        'Pilot #${widget.application.pilotProfileId}';
    final location = pilot?.location.trim() ?? '';
    final drone = widget.application.drone;

    return _section(
      title: AppLanguage.text('Selected Pilot'),
      icon: Icons.person_outline_rounded,
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.blueBg,
            foregroundImage: pilot?.profilePhoto.trim().isNotEmpty == true
                ? NetworkImage(pilot!.profilePhoto.trim())
                : null,
            child: pilot?.profilePhoto.trim().isNotEmpty == true
                ? null
                : Text(
                    _initials(name),
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 13.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (pilot?.verified == true) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: AppColors.green,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (location.isNotEmpty) location,
                    if (drone != null) drone.displayName,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 10.8,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contractValueSection() {
    return _section(
      title: AppLanguage.text('Contract Value'),
      icon: Icons.payments_outlined,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: _inputDecoration(
                    label: 'Amount',
                    hint: 'e.g. 1500',
                    icon: Icons.attach_money_rounded,
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null) return 'Enter a valid amount.';
                    if (amount <= 0) return 'Amount must be greater than 0.';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _currencyController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 3,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: _inputDecoration(
                    label: 'Currency',
                    hint: 'USD',
                    icon: Icons.currency_exchange_rounded,
                    counterText: '',
                  ),
                  validator: (value) {
                    final currency = value?.trim() ?? '';
                    if (currency.length != 3) {
                      return 'Use 3 letters.';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          DropdownButtonFormField<String>(
            value: _paymentType,
            decoration: _inputDecoration(
              label: 'Payment Type',
              icon: Icons.account_balance_wallet_outlined,
            ),
            items: const [
              DropdownMenuItem(
                value: 'fixed',
                child: Text('Fixed'),
              ),
              DropdownMenuItem(
                value: 'hourly',
                child: Text('Hourly'),
              ),
              DropdownMenuItem(
                value: 'daily',
                child: Text('Daily'),
              ),
            ],
            onChanged: _submitting
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _paymentType = value);
                  },
          ),
        ],
      ),
    );
  }

  Widget _scheduleSection() {
    return _section(
      title: AppLanguage.text('Work Schedule'),
      icon: Icons.calendar_month_outlined,
      child: Column(
        children: [
          _DateField(
            label: 'Start date',
            value: _startDate,
            requiredField: true,
            onTap: _submitting ? null : _pickStartDate,
          ),
          const SizedBox(height: 10),
          _DateField(
            label: 'End date',
            value: _endDate,
            requiredField: false,
            onTap: _submitting ? null : _pickEndDate,
            onClear: _endDate == null || _submitting
                ? null
                : () => setState(() => _endDate = null),
          ),
          if (_endDate != null && _endDate!.isBefore(_startDate)) ...[
            const SizedBox(height: 9),
            const _InlineWarning(
              text: 'End date cannot be before the start date.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _termsSection() {
    return _section(
      title: AppLanguage.text('Terms & Conditions'),
      icon: Icons.description_outlined,
      child: TextFormField(
        controller: _termsController,
        minLines: 6,
        maxLines: 10,
        maxLength: 5000,
        textCapitalization: TextCapitalization.sentences,
        decoration: _inputDecoration(
          label: 'Terms',
          hint:
              'Add mission scope, deliverables, responsibilities, timing, or any agreed conditions...',
          icon: Icons.notes_rounded,
        ),
      ),
    );
  }

  Widget _reviewNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orangeBg.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.orange.withOpacity(0.12),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.orange,
            size: 18,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'After creation, the contract is Pending and waits for the pilot to Accept or Reject it. The company can edit contract terms only while it is still Pending.',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 10.9,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.022),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.blueBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppColors.blue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
    String? counterText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      counterText: counterText,
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color: AppColors.blue,
              size: 18,
            ),
      filled: true,
      fillColor: AppColors.bg,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 14,
      ),
      labelStyle: const TextStyle(
        color: AppColors.grey,
        fontSize: 11.5,
      ),
      hintStyle: TextStyle(
        color: AppColors.grey.withOpacity(0.7),
        fontSize: 11.3,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.blue,
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.red),
      ),
    );
  }

  Widget _bottomAction() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.cardBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: AppColors.blue,
            disabledBackgroundColor: AppColors.grey.withOpacity(0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          icon: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.draw_outlined,
                  size: 18,
                ),
          label: Text(
            AppLanguage.text('Create Contract'),
            style: const TextStyle(
              fontSize: 12.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _startDate = DateTime(picked.year, picked.month, picked.day);
      if (_endDate != null && _endDate!.isBefore(_startDate)) {
        _endDate = null;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final initial = _endDate ?? _startDate.add(const Duration(days: 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(_startDate) ? _startDate : initial,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _endDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!widget.application.isAccepted) {
      _showSnack(
        'Only an accepted application can be used to create a contract.',
        isError: true,
      );
      return;
    }

    if (_formKey.currentState?.validate() != true) return;

    if (_endDate != null && _endDate!.isBefore(_startDate)) {
      _showSnack(
        'End date cannot be before the start date.',
        isError: true,
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    final request = CompanyCreateContractRequest(
      amount: amount,
      currency: _currencyController.text.trim().toUpperCase(),
      paymentType: _paymentType,
      startDate: _startDate,
      endDate: _endDate,
      terms: _termsController.text.trim(),
    );

    final confirmed = await _confirmCreate(request);
    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);

    final contract = await _controller.createContract(
      jobId: widget.jobId,
      applicationId: widget.application.id,
      request: request,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (contract == null) {
      _showSnack(
        _controller.contractErrorMessage ?? 'Unable to create contract.',
        isError: true,
      );
      return;
    }

    _showSnack('Contract created successfully.');
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    Navigator.of(context).pop<CompanyContractModel>(contract);
  }

  Future<bool?> _confirmCreate(
    CompanyCreateContractRequest request,
  ) {
    final amount = request.amount == request.amount.roundToDouble()
        ? request.amount.toStringAsFixed(0)
        : request.amount.toStringAsFixed(2);

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: const Row(
            children: [
              Icon(
                Icons.handshake_outlined,
                color: AppColors.green,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Create this contract?',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            '$amount ${request.currency.toUpperCase()} · ${_pretty(request.paymentType)} · Start ${_formatDate(request.startDate)}\n\nThe pilot will receive this contract in Pending status for review.',
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLanguage.text('Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
              ),
              child: Text(AppLanguage.text('Create Contract')),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red.shade700 : AppColors.navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
          content: Text(
            message,
            style: const TextStyle(fontSize: 11.5),
          ),
        ),
      );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.requiredField,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final bool requiredField;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.blue,
                size: 17,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requiredField ? '$label *' : '$label (optional)',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value == null ? 'Not set' : _formatDate(value!),
                      style: TextStyle(
                        color: value == null ? AppColors.grey : AppColors.navy,
                        fontSize: 12.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  tooltip: 'Clear date',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 17,
                    color: AppColors.grey,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.grey,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white70,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: AppColors.red,
          size: 15,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.red,
              fontSize: 10.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContractBackground extends StatelessWidget {
  const _ContractBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.blue.withOpacity(0.09),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -140,
          left: -130,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.green.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String _pretty(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return '';

  return clean
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) =>
            '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) return 'P#';
  if (parts.length == 1) {
    final text = parts.first;
    return text.length <= 2
        ? text.toUpperCase()
        : text.substring(0, 2).toUpperCase();
  }

  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
