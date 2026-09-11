import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';

import '../../controllers/company_job_controller.dart';
import '../../models/company_job_posting_model.dart';
import '../../models/company_update_job_request.dart';
import '../../services/company_job_service.dart';

class EditCompanyJobScreen extends StatefulWidget {
  const EditCompanyJobScreen({
    super.key,
    required this.job,
  });

  final CompanyJobPostingModel job;

  @override
  State<EditCompanyJobScreen> createState() =>
      _EditCompanyJobScreenState();
}

class _EditCompanyJobScreenState extends State<EditCompanyJobScreen> {
  late final CompanyJobController _controller;

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _country;
  late final TextEditingController _state;
  late final TextEditingController _city;
  late final TextEditingController _region;
  late final TextEditingController _paymentMin;
  late final TextEditingController _paymentMax;
  late final TextEditingController _requirementsNotes;

  final _customDroneLength = TextEditingController();
  final _customDroneWidth = TextEditingController();
  final _customDroneHeight = TextEditingController();
  final _customDroneWeight = TextEditingController();

  String? _serviceCategory;
  String _paymentType = 'fixed';
  String? _droneSize;
  String? _existingCustomDroneSize;
  String? _requiredExperience;

  final Set<String> _requiredCapabilities = {};
  final Set<String> _requiredCertifications = {};

  bool _trainingSafetyRequired = false;
  bool _ndaRequired = false;

  DateTime? _startDate;
  DateTime? _endDate;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final job = widget.job;

    _controller = CompanyJobController(
      CompanyJobService(ApiClient()),
    );

    _title = TextEditingController(text: job.title);
    _description = TextEditingController(text: job.description);
    _country = TextEditingController(text: job.country);
    _state = TextEditingController(text: job.state);
    _city = TextEditingController(text: job.city);
    _region = TextEditingController(text: job.region);
    _paymentMin = TextEditingController(
      text: _numberText(job.paymentMin),
    );
    _paymentMax = TextEditingController(
      text: _numberText(job.paymentMax),
    );
    _requirementsNotes =
        TextEditingController(text: job.requirementsNotes);

    _serviceCategory =
    job.serviceCategory.isEmpty ? null : job.serviceCategory;

    _paymentType =
    job.paymentType.isEmpty ? 'fixed' : job.paymentType;

    _configureDroneSize(job.droneSize);

    _requiredExperience = job.requiredExperience.isEmpty
        ? null
        : job.requiredExperience;

    _requiredCapabilities.addAll(job.requiredCapabilities);
    _requiredCertifications.addAll(job.requiredCertifications);

    _trainingSafetyRequired = job.trainingSafetyRequired;
    _ndaRequired = job.ndaRequired;

    _startDate = job.startDate;
    _endDate = job.endDate;
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _description,
      _country,
      _state,
      _city,
      _region,
      _paymentMin,
      _paymentMax,
      _requirementsNotes,
      _customDroneLength,
      _customDroneWidth,
      _customDroneHeight,
      _customDroneWeight,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }

  // ==========================================================================
  // SAVE
  // ==========================================================================

  Future<void> _save() async {
    if (_saving) return;

    if (_title.text.trim().isEmpty ||
        _description.text.trim().isEmpty ||
        _country.text.trim().isEmpty ||
        _startDate == null ||
        _endDate == null) {
      _showSnack(
        'Please complete the required fields.',
        isError: true,
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      _showSnack(
        'End date cannot be before start date.',
        isError: true,
      );
      return;
    }

    if (!_validCustomDroneSize()) {
      _showSnack(
        'For a custom drone size, enter at least length and width.',
        isError: true,
      );
      return;
    }

    double? min;
    double? max;

    if (_paymentType != 'negotiable') {
      min = double.tryParse(_paymentMin.text.trim());

      if (min == null || min < 0) {
        _showSnack(
          'Enter a valid minimum payment.',
          isError: true,
        );
        return;
      }

      final maxText = _paymentMax.text.trim();

      if (maxText.isNotEmpty) {
        max = double.tryParse(maxText);

        if (max == null || max < min) {
          _showSnack(
            'Maximum payment must be greater than or equal to minimum payment.',
            isError: true,
          );
          return;
        }
      }
    }

    final request = CompanyUpdateJobRequest(
      title: _title.text.trim(),
      serviceCategory: _emptyToNull(_serviceCategory),
      description: _description.text.trim(),
      country: _country.text.trim(),
      state: _emptyToNull(_state.text),
      city: _emptyToNull(_city.text),
      region: _emptyToNull(_region.text),
      startDate: _startDate!,
      endDate: _endDate!,
      paymentType: _paymentType,
      paymentMin: min,
      paymentMax: max,
      requiredCapabilities: _requiredCapabilities.toList(),
      requiredExperience: _emptyToNull(_requiredExperience),
      requiredCertifications: _requiredCertifications.toList(),
      droneSize: _droneSizePayload(),
      trainingSafetyRequired: _trainingSafetyRequired,
      ndaRequired: _ndaRequired,
      requirementsNotes: _emptyToNull(_requirementsNotes.text),
    );

    setState(() => _saving = true);

    final updated = await _controller.updateJob(
      widget.job.id,
      request,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (updated == null) {
      _showSnack(
        _controller.errorMessage ?? 'Unable to update job.',
        isError: true,
      );
      return;
    }

    _showSnack('Job updated successfully.');

    await Future<void>.delayed(
      const Duration(milliseconds: 250),
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  // ==========================================================================
  // DATE
  // ==========================================================================

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final initial = _startDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() {
      _startDate = picked;

      if (_endDate != null && _endDate!.isBefore(picked)) {
        _endDate = null;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final first = _startDate ?? DateTime(now.year - 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? first,
      firstDate: first,
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;
    setState(() => _endDate = picked);
  }

  // ==========================================================================
  // DRONE SIZE
  // ==========================================================================

  void _configureDroneSize(String rawValue) {
    final raw = rawValue.trim();

    if (raw.isEmpty) {
      _droneSize = null;
      return;
    }

    final lower = raw.toLowerCase();

    if (lower == 'small' ||
        lower == 'medium' ||
        lower == 'large' ||
        lower == 'specific') {
      _droneSize = lower;
      return;
    }

    if (lower == 'custom') {
      _droneSize = 'custom';
      return;
    }

    _droneSize = 'custom';

    final dimensions = RegExp(
      r'(\d+(?:\.\d+)?)\s*[×xX]\s*(\d+(?:\.\d+)?)(?:\s*[×xX]\s*(\d+(?:\.\d+)?))?',
    ).firstMatch(raw);

    if (dimensions != null) {
      _customDroneLength.text = dimensions.group(1) ?? '';
      _customDroneWidth.text = dimensions.group(2) ?? '';
      _customDroneHeight.text = dimensions.group(3) ?? '';
    }

    final weight = RegExp(
      r'(?:max\s*weight|weight|max)[^\d]*(\d+(?:\.\d+)?)\s*kg',
      caseSensitive: false,
    ).firstMatch(raw);

    if (weight != null) {
      _customDroneWeight.text = weight.group(1) ?? '';
    }

    if (dimensions == null && weight == null) {
      _existingCustomDroneSize = raw;
    }
  }

  bool _validCustomDroneSize() {
    if (_droneSize != 'custom') return true;

    final hasNewInput = [
      _customDroneLength,
      _customDroneWidth,
      _customDroneHeight,
      _customDroneWeight,
    ].any((controller) => controller.text.trim().isNotEmpty);

    if (!hasNewInput &&
        _existingCustomDroneSize != null &&
        _existingCustomDroneSize!.trim().isNotEmpty) {
      return true;
    }

    final length = _positiveNumber(_customDroneLength.text);
    final width = _positiveNumber(_customDroneWidth.text);
    final heightText = _customDroneHeight.text.trim();
    final weightText = _customDroneWeight.text.trim();

    if (length == null || width == null) return false;

    if (heightText.isNotEmpty && _positiveNumber(heightText) == null) {
      return false;
    }

    if (weightText.isNotEmpty && _positiveNumber(weightText) == null) {
      return false;
    }

    return true;
  }

  double? _positiveNumber(String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  String? _droneSizePayload() {
    final value = _droneSize;
    if (value == null || value.trim().isEmpty) return null;

    switch (value) {
      case 'small':
        return 'Small';
      case 'medium':
        return 'Medium';
      case 'large':
        return 'Large';
      case 'specific':
        return 'Specific';
      case 'custom':
        final hasNewInput = [
          _customDroneLength,
          _customDroneWidth,
          _customDroneHeight,
          _customDroneWeight,
        ].any((controller) => controller.text.trim().isNotEmpty);

        if (!hasNewInput && _existingCustomDroneSize != null) {
          return _existingCustomDroneSize!.trim();
        }

        final length = _cleanMeasurement(_customDroneLength.text);
        final width = _cleanMeasurement(_customDroneWidth.text);
        final height = _cleanMeasurement(_customDroneHeight.text);
        final weight = _cleanMeasurement(_customDroneWeight.text);

        final dimensions = height.isEmpty
            ? '$length × $width cm'
            : '$length × $width × $height cm';

        if (weight.isEmpty) {
          return 'Custom: $dimensions';
        }

        return 'Custom: $dimensions · Max weight $weight kg';
      default:
        return value.trim();
    }
  }

  String _cleanMeasurement(String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return value.trim();
    if (parsed == parsed.roundToDouble()) return parsed.toStringAsFixed(0);

    return parsed
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  void _onDroneSizeChanged(String? value) {
    setState(() {
      _droneSize = value;

      if (value != 'custom') {
        _existingCustomDroneSize = null;
        _customDroneLength.clear();
        _customDroneWidth.clear();
        _customDroneHeight.clear();
        _customDroneWeight.clear();
      }
    });
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: IgnorePointer(
              child: Container(
                width: 310,
                height: 310,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withOpacity(0.10),
                      AppColors.blue.withOpacity(0.018),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      children: [
                        _introCard(),
                        const SizedBox(height: 13),
                        _sectionCard(
                          icon: Icons.description_outlined,
                          title: 'Basic information',
                          subtitle: 'Core mission details',
                          child: Column(
                            children: [
                              _label('Job title *'),
                              _field(
                                _title,
                                'Job title',
                                prefixIcon: Icons.work_outline_rounded,
                              ),
                              _label('Service category'),
                              _select(
                                value: _serviceCategory,
                                items: const [
                                  'inspection',
                                  'mapping',
                                  'photography',
                                  'construction',
                                  'surveying',
                                  'other',
                                ],
                                onChanged: (value) =>
                                    setState(() => _serviceCategory = value),
                              ),
                              _label('Description *'),
                              _field(
                                _description,
                                'Describe the mission, site and deliverables...',
                                lines: 5,
                                prefixIcon: Icons.notes_rounded,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 13),
                        _sectionCard(
                          icon: Icons.location_on_outlined,
                          title: 'Location',
                          subtitle: 'Where the mission takes place',
                          child: Column(
                            children: [
                              _label('Country *'),
                              _field(
                                _country,
                                'Country',
                                prefixIcon: Icons.public_rounded,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _label('State'),
                                        _field(_state, 'State'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _label('City'),
                                        _field(_city, 'City'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              _label('Region / area'),
                              _field(
                                _region,
                                'Region or area',
                                prefixIcon: Icons.map_outlined,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 13),
                        _sectionCard(
                          icon: Icons.calendar_month_outlined,
                          title: 'Schedule',
                          subtitle: 'Mission date range',
                          child: Row(
                            children: [
                              Expanded(
                                child: _dateBox(
                                  label: 'Start',
                                  date: _startDate,
                                  onTap: _pickStartDate,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _dateBox(
                                  label: 'End',
                                  date: _endDate,
                                  onTap: _pickEndDate,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 13),
                        _sectionCard(
                          icon: Icons.flight_outlined,
                          title: 'Requirements',
                          subtitle: 'Drone and pilot requirements',
                          child: Column(
                            children: [
                              _label('Drone size'),
                              _select(
                                value: _droneSize,
                                items: const [
                                  'small',
                                  'medium',
                                  'large',
                                  'custom',
                                  'specific',
                                ],
                                labelBuilder: _droneSizeLabel,
                                onChanged: _onDroneSizeChanged,
                              ),
                              const SizedBox(height: 7),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Sent as readable text. For Custom, use unfolded dimensions; max weight is optional.',
                                  style: TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 10.8,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              if (_droneSize == 'custom') ...[
                                const SizedBox(height: 11),
                                _customDroneSizeCard(),
                              ],
                              _label('Required experience'),
                              _select(
                                value: _requiredExperience,
                                items: const [
                                  '1+ year',
                                  '2+ years',
                                  '3+ years',
                                  '5+ years',
                                  '10+ years',
                                ],
                                onChanged: (value) => setState(
                                      () => _requiredExperience = value,
                                ),
                              ),
                              _label('Required capabilities'),
                              _chips(
                                items: const [
                                  'Thermal Camera',
                                  'RTK',
                                  'Zoom',
                                  'LiDAR',
                                  'Multispectral',
                                  'Night Vision',
                                  'Spotlight',
                                  'Winch',
                                ],
                                selected: _requiredCapabilities,
                                onChanged: (value) {
                                  setState(() {
                                    _requiredCapabilities
                                      ..clear()
                                      ..addAll(value);
                                  });
                                },
                              ),
                              _label('Required certifications'),
                              _chips(
                                items: const [
                                  'Part 107 (US)',
                                  'CAA (UK)',
                                  'EASA (EU)',
                                  'Transport Canada',
                                  'Other',
                                ],
                                selected: _requiredCertifications,
                                onChanged: (value) {
                                  setState(() {
                                    _requiredCertifications
                                      ..clear()
                                      ..addAll(value);
                                  });
                                },
                              ),
                              const SizedBox(height: 14),
                              _toggle(
                                icon: Icons.health_and_safety_outlined,
                                title: 'Safety training',
                                subtitle: 'Pilot must have completed safety training',
                                value: _trainingSafetyRequired,
                                onChanged: (value) => setState(
                                      () => _trainingSafetyRequired = value,
                                ),
                              ),
                              const SizedBox(height: 9),
                              _toggle(
                                icon: Icons.lock_outline_rounded,
                                title: 'NDA required',
                                subtitle: 'Pilot must agree to an NDA',
                                value: _ndaRequired,
                                onChanged: (value) =>
                                    setState(() => _ndaRequired = value),
                              ),
                              _label('Other requirements'),
                              _field(
                                _requirementsNotes,
                                'Additional requirements...',
                                lines: 4,
                                prefixIcon: Icons.fact_check_outlined,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 13),
                        _sectionCard(
                          icon: Icons.payments_outlined,
                          title: 'Budget',
                          subtitle: 'Payment structure and range',
                          child: Column(
                            children: [
                              _label('Payment type *'),
                              _select(
                                value: _paymentType,
                                items: const [
                                  'fixed',
                                  'hourly',
                                  'daily',
                                  'negotiable',
                                ],
                                onChanged: (value) {
                                  if (value == null) return;

                                  setState(() {
                                    _paymentType = value;

                                    if (value == 'negotiable') {
                                      _paymentMin.clear();
                                      _paymentMax.clear();
                                    }
                                  });
                                },
                              ),
                              if (_paymentType != 'negotiable') ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _label('Minimum *'),
                                          _field(
                                            _paymentMin,
                                            '500',
                                            type: const TextInputType
                                                .numberWithOptions(
                                              decimal: true,
                                            ),
                                            prefixText: '\$',
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _label('Maximum'),
                                          _field(
                                            _paymentMax,
                                            '800',
                                            type: const TextInputType
                                                .numberWithOptions(
                                              decimal: true,
                                            ),
                                            prefixText: '\$',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                const SizedBox(height: 12),
                                _infoStrip(
                                  icon: Icons.handshake_outlined,
                                  text:
                                  'No payment amount is required for a negotiable job.',
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.job.attachments.isNotEmpty) ...[
                          const SizedBox(height: 13),
                          _sectionCard(
                            icon: Icons.attach_file_rounded,
                            title: 'Existing attachments',
                            subtitle: 'Files already linked to this job',
                            child: _infoStrip(
                              icon: Icons.insert_drive_file_outlined,
                              text:
                              '${widget.job.attachments.length} existing attachment(s) will remain unchanged.',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                _saveBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 17,
              color: AppColors.navy,
            ),
          ),
          const Expanded(
            child: Text(
              'Edit job',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.blueBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _pretty(widget.job.status),
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 9.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _introCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navy,
            AppColors.navy.withOpacity(0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title.text.trim().isEmpty ? 'Job draft' : _title.text.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Update only what changed. Your existing job data stays intact.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.64),
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

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 16),
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
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: AppColors.blueBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: AppColors.blue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _saveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 11, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppColors.cardBorder),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.blue.withOpacity(0.55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _saving
                ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(
              Icons.check_rounded,
              size: 18,
            ),
            label: Text(
              _saving ? 'Saving changes...' : 'Save changes',
              style: const TextStyle(
                fontSize: 12.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // UI HELPERS
  // ==========================================================================

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 13, bottom: 7),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 11.8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController controller,
      String hint, {
        int lines = 1,
        TextInputType type = TextInputType.text,
        IconData? prefixIcon,
        String? prefixText,
      }) {
    return TextField(
      controller: controller,
      minLines: lines,
      maxLines: lines,
      keyboardType: type,
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 12.4,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.lightGrey,
          fontSize: 11.8,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(
          prefixIcon,
          color: AppColors.grey,
          size: 17,
        ),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          color: AppColors.navy,
          fontSize: 12.4,
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: AppColors.bg,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 13,
          vertical: lines > 1 ? 13 : 12,
        ),
        border: _border(AppColors.cardBorder),
        enabledBorder: _border(AppColors.cardBorder),
        focusedBorder: _border(AppColors.blue, width: 1.25),
      ),
    );
  }

  Widget _select({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String Function(String value)? labelBuilder,
  }) {
    final safeValue = value != null && items.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.grey,
      ),
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 12.4,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.bg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 10,
        ),
        border: _border(AppColors.cardBorder),
        enabledBorder: _border(AppColors.cardBorder),
        focusedBorder: _border(AppColors.blue, width: 1.25),
      ),
      hint: const Text(
        'Select...',
        style: TextStyle(
          color: AppColors.lightGrey,
          fontSize: 11.8,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
          value: item,
          child: Text(
            labelBuilder?.call(item) ?? _pretty(item),
          ),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _dateBox({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.bg,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.blueBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.blue,
                  size: 14,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date == null ? 'Select' : _formatDate(date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: date == null
                            ? AppColors.lightGrey
                            : AppColors.navy,
                        fontSize: 11.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chips({
    required List<String> items,
    required Set<String> selected,
    required ValueChanged<Set<String>> onChanged,
  }) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: items.map((item) {
        final active = selected.contains(item);

        return FilterChip(
          label: Text(item),
          selected: active,
          selectedColor: AppColors.blueBg,
          checkmarkColor: AppColors.blue,
          backgroundColor: AppColors.bg,
          labelStyle: TextStyle(
            color: active ? AppColors.blue : AppColors.navy,
            fontSize: 10.7,
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide(
            color: active ? AppColors.blue : AppColors.cardBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            final updated = Set<String>.from(selected);

            if (value) {
              updated.add(item);
            } else {
              updated.remove(item);
            }

            onChanged(updated);
          },
        );
      }).toList(),
    );
  }

  Widget _toggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: value ? AppColors.blueBg : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 16,
              color: value ? AppColors.blue : AppColors.grey,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11.7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 9.7,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.88,
            child: Switch.adaptive(
              value: value,
              activeTrackColor: AppColors.blue,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _customDroneSizeCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.blueBg,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.blue.withOpacity(0.13),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.straighten_rounded,
                size: 16,
                color: AppColors.blue,
              ),
              SizedBox(width: 7),
              Text(
                'Custom dimensions',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 12.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Length × width describe the physical size. Height and maximum weight make the requirement more precise.',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 10.3,
              height: 1.35,
            ),
          ),
          if (_existingCustomDroneSize != null) ...[
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.74),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                'Current: $_existingCustomDroneSize',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 10.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _compactMeasureField(
                  controller: _customDroneLength,
                  label: 'Length',
                  suffix: 'cm',
                  hint: '60',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _compactMeasureField(
                  controller: _customDroneWidth,
                  label: 'Width',
                  suffix: 'cm',
                  hint: '50',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _compactMeasureField(
                  controller: _customDroneHeight,
                  label: 'Height',
                  suffix: 'cm',
                  hint: '20',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _compactMeasureField(
                  controller: _customDroneWeight,
                  label: 'Max weight',
                  suffix: 'kg',
                  hint: '4.5',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: Listenable.merge([
              _customDroneLength,
              _customDroneWidth,
              _customDroneHeight,
              _customDroneWeight,
            ]),
            builder: (context, _) {
              final ready = _validCustomDroneSize();
              final preview = ready ? _droneSizePayload() : null;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  preview ?? 'Enter length and width to build the API text',
                  style: TextStyle(
                    color: ready ? AppColors.navy : AppColors.grey,
                    fontSize: 10.2,
                    fontWeight: ready ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _compactMeasureField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 11.8,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.grey,
          fontSize: 9.8,
        ),
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.lightGrey,
          fontSize: 10.5,
        ),
        suffixText: suffix,
        suffixStyle: const TextStyle(
          color: AppColors.grey,
          fontSize: 9.8,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 11,
        ),
        border: _border(AppColors.cardBorder),
        enabledBorder: _border(AppColors.cardBorder),
        focusedBorder: _border(AppColors.blue, width: 1.2),
      ),
    );
  }

  Widget _infoStrip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.blueBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.blue,
            size: 17,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 10.7,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(
      Color color, {
        double width = 1,
      }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }

  String _droneSizeLabel(String value) {
    switch (value) {
      case 'small':
        return 'Small';
      case 'medium':
        return 'Medium';
      case 'large':
        return 'Large';
      case 'custom':
        return 'Custom dimensions';
      case 'specific':
        return 'Specific requirement';
      default:
        return _pretty(value);
    }
  }

  String? _emptyToNull(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  String _numberText(double? value) {
    if (value == null) return '';

    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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

  void _showSnack(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
          isError ? Colors.red.shade700 : AppColors.navy,
          content: Text(
            message,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
  }
}
