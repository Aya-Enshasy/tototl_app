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

class _EditCompanyJobScreenState
    extends State<EditCompanyJobScreen> {
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

  String? _serviceCategory;
  String _paymentType = 'fixed';
  String? _droneSize;
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

    _droneSize =
        job.droneSize.isEmpty ? null : job.droneSize;

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
    _title.dispose();
    _description.dispose();
    _country.dispose();
    _state.dispose();
    _city.dispose();
    _region.dispose();
    _paymentMin.dispose();
    _paymentMax.dispose();
    _requirementsNotes.dispose();

    super.dispose();
  }

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
      droneSize: _emptyToNull(_droneSize),
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

  Future<void> _pickStartDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text(
          'Edit Job',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Basic Information'),
                    _label('Job Title *'),
                    _field(_title, 'Job title'),
                    _label('Service Category'),
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
                      'Describe the job...',
                      lines: 5,
                    ),

                    _sectionTitle('Location'),
                    _label('Country *'),
                    _field(_country, 'Country'),
                    _label('State'),
                    _field(_state, 'State'),
                    _label('City'),
                    _field(_city, 'City'),
                    _label('Region / Area'),
                    _field(_region, 'Region'),

                    _sectionTitle('Schedule'),
                    _label('Start Date *'),
                    _dateBox(
                      date: _startDate,
                      onTap: _pickStartDate,
                    ),
                    _label('End Date *'),
                    _dateBox(
                      date: _endDate,
                      onTap: _pickEndDate,
                    ),

                    _sectionTitle('Requirements'),
                    _label('Drone Size'),
                    _select(
                      value: _droneSize,
                      items: const [
                        'small',
                        'medium',
                        'large',
                        'custom',
                        'specific',
                      ],
                      onChanged: (value) =>
                          setState(() => _droneSize = value),
                    ),
                    _label('Required Experience'),
                    _select(
                      value: _requiredExperience,
                      items: const [
                        '1+ year',
                        '2+ years',
                        '3+ years',
                        '5+ years',
                        '10+ years',
                      ],
                      onChanged: (value) =>
                          setState(() => _requiredExperience = value),
                    ),
                    _label('Required Capabilities'),
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
                    _label('Required Certifications'),
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
                    const SizedBox(height: 18),
                    _toggle(
                      title: 'Safety Training Required',
                      value: _trainingSafetyRequired,
                      onChanged: (value) => setState(
                        () => _trainingSafetyRequired = value,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _toggle(
                      title: 'NDA Required',
                      value: _ndaRequired,
                      onChanged: (value) =>
                          setState(() => _ndaRequired = value),
                    ),
                    _label('Other Requirements'),
                    _field(
                      _requirementsNotes,
                      'Additional requirements...',
                      lines: 4,
                    ),

                    _sectionTitle('Budget'),
                    _label('Payment Type *'),
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
                      _label('Minimum Payment *'),
                      _field(
                        _paymentMin,
                        'e.g. 500',
                        type: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      _label('Maximum Payment'),
                      _field(
                        _paymentMax,
                        'e.g. 800',
                        type: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ],

                    if (widget.job.attachments.isNotEmpty) ...[
                      _sectionTitle('Existing Attachments'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.cardBorder,
                          ),
                        ),
                        child: Text(
                          '${widget.job.attachments.length} existing attachment(s) will remain unchanged.',
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                18,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: AppColors.cardBorder,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 2),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _field(
    TextEditingController controller,
    String hint, {
    int lines = 1,
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      minLines: lines,
      maxLines: lines,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(14),
        border: _border(AppColors.cardBorder),
        enabledBorder: _border(AppColors.cardBorder),
        focusedBorder: _border(AppColors.blue, width: 1.3),
      ),
    );
  }

  Widget _select({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue =
        value != null && items.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        border: _border(AppColors.cardBorder),
        enabledBorder: _border(AppColors.cardBorder),
        focusedBorder: _border(AppColors.blue, width: 1.3),
      ),
      hint: const Text('Select...'),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(_pretty(item)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _dateBox({
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.blue,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                date == null ? 'Select date' : _formatDate(date),
                style: TextStyle(
                  color: date == null
                      ? AppColors.lightGrey
                      : AppColors.navy,
                  fontWeight: FontWeight.w600,
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
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final active = selected.contains(item);

        return FilterChip(
          label: Text(item),
          selected: active,
          selectedColor: AppColors.blueBg,
          checkmarkColor: AppColors.blue,
          backgroundColor: Colors.white,
          side: BorderSide(
            color:
                active ? AppColors.blue : AppColors.cardBorder,
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
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.blue,
            onChanged: onChanged,
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
    if (value.trim().isEmpty) return '';

    return value
        .split('_')
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
          content: Text(message),
        ),
      );
  }
}
