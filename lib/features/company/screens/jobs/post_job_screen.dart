import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/company_shell_screen.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/company_job_controller.dart';
import '../../models/company_create_job_request.dart';
import '../../services/company_job_service.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  late final CompanyJobController _controller;

  final _title = TextEditingController();
  String? _serviceCategory;
  final _description = TextEditingController();

  final _country = TextEditingController();
  final _state = TextEditingController();
  final _city = TextEditingController();
  final _region = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  String? _droneSize;
  final Set<String> _requiredCapabilities = {};
  String? _requiredExperience;
  final Set<String> _requiredCertifications = {};
  bool _safetyTrainingRequired = false;
  bool _ndaRequired = false;
  final _requirementsNotes = TextEditingController();

  String _paymentType = 'fixed';
  final _paymentMin = TextEditingController();
  final _paymentMax = TextEditingController();

  final List<PlatformFile> _attachments = [];

  int _step = 0;
  bool _submitting = false;
  bool _publishingNow = false;

  @override
  void initState() {
    super.initState();
    _controller = CompanyJobController(
      CompanyJobService(ApiClient()),
    );
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
      _requirementsNotes,
      _paymentMin,
      _paymentMax,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }

  // ==========================================================================
  // VALIDATION
  // ==========================================================================

  bool _validStep() {
    if (_step == 0) {
      return _title.text.trim().isNotEmpty &&
          _description.text.trim().isNotEmpty;
    }

    if (_step == 1) {
      return _country.text.trim().isNotEmpty;
    }

    if (_step == 2) {
      if (_startDate == null || _endDate == null) return false;
      return !_endDate!.isBefore(_startDate!);
    }

    if (_step == 4 && _paymentType != 'negotiable') {
      final min = double.tryParse(_paymentMin.text.trim());
      if (min == null || min < 0) return false;

      final maxText = _paymentMax.text.trim();
      if (maxText.isNotEmpty) {
        final max = double.tryParse(maxText);
        if (max == null || max < min) return false;
      }
    }

    return true;
  }

  bool _validAll() {
    if (_title.text.trim().isEmpty ||
        _description.text.trim().isEmpty ||
        _country.text.trim().isEmpty) {
      return false;
    }

    if (_startDate == null || _endDate == null) {
      return false;
    }

    if (_endDate!.isBefore(_startDate!)) {
      return false;
    }

    if (_paymentType != 'negotiable') {
      final min = double.tryParse(_paymentMin.text.trim());
      if (min == null || min < 0) return false;

      final maxText = _paymentMax.text.trim();
      if (maxText.isNotEmpty) {
        final max = double.tryParse(maxText);
        if (max == null || max < min) return false;
      }
    }

    return true;
  }

  void _next() {
    if (!_validStep()) {
      _showSnack(
        'Please complete the required job details.',
        isError: true,
      );
      return;
    }

    setState(() => _step++);
  }

  // ==========================================================================
  // DATE
  // ==========================================================================

  Future<void> _pickStartDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
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
    final firstDate =
        _startDate ?? DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() => _endDate = picked);
  }

  // ==========================================================================
  // ATTACHMENTS
  // ==========================================================================

  Future<void> _pickAttachments() async {
    final remaining = 10 - _attachments.length;

    if (remaining <= 0) {
      _showSnack(
        'Maximum 10 attachments.',
        isError: true,
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );

    if (result == null) return;

    final files = result.files
        .where(
          (file) => file.path != null && file.path!.trim().isNotEmpty,
    )
        .take(remaining)
        .toList();

    setState(() => _attachments.addAll(files));

    if (result.files.length > remaining) {
      _showSnack(
        'Only the first $remaining files were added.',
      );
    }
  }

  // ==========================================================================
  // REQUEST
  // ==========================================================================

  CompanyCreateJobRequest _buildRequest() {
    return CompanyCreateJobRequest(
      title: _title.text.trim(),
      description: _description.text.trim(),
      country: _country.text.trim(),
      serviceCategory: _serviceCategory,
      state: _nullIfEmpty(_state.text),
      city: _nullIfEmpty(_city.text),
      region: _nullIfEmpty(_region.text),
      startDate: _startDate!,
      endDate: _endDate!,
      paymentType: _paymentType,
      paymentMin: _paymentType == 'negotiable'
          ? null
          : double.tryParse(_paymentMin.text.trim()),
      paymentMax: _paymentType == 'negotiable'
          ? null
          : double.tryParse(_paymentMax.text.trim()),
      requiredCapabilities: _requiredCapabilities.toList(),
      requiredExperience: _requiredExperience,
      requiredCertifications: _requiredCertifications.toList(),
      droneSize: _droneSize,
      trainingSafetyRequired: _safetyTrainingRequired,
      ndaRequired: _ndaRequired,
      requirementsNotes: _nullIfEmpty(_requirementsNotes.text),
      attachmentPaths: _attachments
          .map((file) => file.path)
          .whereType<String>()
          .toList(),
    );
  }

  // ==========================================================================
  // SAVE AS DRAFT
  // ==========================================================================

  Future<void> _saveAsDraft() async {
    if (_submitting) return;

    if (!_validAll()) {
      _showSnack(
        'Please complete the required job details.',
        isError: true,
      );
      return;
    }

    setState(() {
      _submitting = true;
      _publishingNow = false;
    });

    final created = await _controller.createJob(
      _buildRequest(),
    );

    if (!mounted) return;

    setState(() => _submitting = false);

    if (created == null) {
      _showSnack(
        _controller.errorMessage ?? 'Unable to create job.',
        isError: true,
      );
      return;
    }

    _showSnack('Job saved as Draft successfully.');

    await _goToMyJobs();
  }

  // ==========================================================================
  // CREATE + PUBLISH
  //
  // Backend flow:
  // 1) Create the job => Draft
  // 2) Publish the returned job id immediately
  // ==========================================================================

  Future<void> _publishJob() async {
    if (_submitting) return;

    if (!_validAll()) {
      _showSnack(
        'Please complete the required job details.',
        isError: true,
      );
      return;
    }

    setState(() {
      _submitting = true;
      _publishingNow = true;
    });

    // STEP 1: Create Draft.
    final created = await _controller.createJob(
      _buildRequest(),
    );

    if (!mounted) return;

    if (created == null) {
      setState(() {
        _submitting = false;
        _publishingNow = false;
      });

      _showSnack(
        _controller.errorMessage ?? 'Unable to create job.',
        isError: true,
      );
      return;
    }

    // STEP 2: Publish the newly-created Draft.
    final published = await _controller.publishJob(created.id);

    if (!mounted) return;

    setState(() {
      _submitting = false;
      _publishingNow = false;
    });

    if (published == null) {
      // Important: creation already succeeded, so do NOT create it again.
      // The job safely remains Draft on the server.
      _showSnack(
        'Job was saved as Draft, but publishing failed: '
            '${_controller.errorMessage ?? 'Unknown error'}',
        isError: true,
      );

      await _goToMyJobs(delayMilliseconds: 1500);
      return;
    }

    _showSnack('Job published successfully.');

    await _goToMyJobs();
  }

  Future<void> _goToMyJobs({
    int delayMilliseconds = 450,
  }) async {
    await Future<void>.delayed(
      Duration(milliseconds: delayMilliseconds),
    );

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const CompanyShellScreen(
          initialIndex: 1,
        ),
      ),
          (route) => false,
    );
  }

  String? _nullIfEmpty(String value) {
    final clean = value.trim();
    return clean.isEmpty ? null : clean;
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

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    const titles = [
      'Basic Information',
      'Location',
      'Schedule',
      'Requirements',
      'Budget',
      'Attachments & Publish',
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _submitting
                        ? null
                        : () {
                      if (_step == 0) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() => _step--);
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      titles[_step],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(
                  6,
                      (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(
                        right: index == 5 ? 0 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: index <= _step
                            ? AppColors.blue
                            : AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: _step == 0
                    ? _basicInfoStep()
                    : _step == 1
                    ? _locationStep()
                    : _step == 2
                    ? _scheduleStep()
                    : _step == 3
                    ? _requirementsStep()
                    : _step == 4
                    ? _budgetStep()
                    : _attachmentsStep(),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder),
                ),
              ),
              child: _bottomButton(),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // STEP 1
  // ==========================================================================

  Widget _basicInfoStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepHeader(
        'Basic Information',
        'Provide the essential details about your job.',
      ),
      _label('Job Title *'),
      _field(
        _title,
        'e.g. Thermal Inspection - Solar Farm',
      ),
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
        labelBuilder: _pretty,
        onChanged: (value) {
          setState(() => _serviceCategory = value);
        },
      ),
      _label('Job Description *'),
      _field(
        _description,
        'Describe the mission scope, site conditions, and expected deliverables...',
        lines: 5,
      ),
    ],
  );

  // ==========================================================================
  // STEP 2
  // ==========================================================================

  Widget _locationStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepHeader(
        'Location',
        'Specify where the job will take place.',
      ),
      _label('Country *'),
      _field(_country, 'e.g. United States'),
      _label('State (optional)'),
      _field(_state, 'e.g. California'),
      _label('City (optional)'),
      _field(_city, 'e.g. Los Angeles'),
      _label('Region / Area (optional)'),
      _field(_region, 'e.g. Downtown, Industrial Zone'),
    ],
  );

  // ==========================================================================
  // STEP 3
  // ==========================================================================

  Widget _scheduleStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepHeader(
        'Schedule',
        'Choose the job start and end dates.',
      ),
      _label('Start Date *'),
      _dateBox(
        date: _startDate,
        hint: 'Select start date',
        onTap: _pickStartDate,
      ),
      _label('End Date *'),
      _dateBox(
        date: _endDate,
        hint: 'Select end date',
        onTap: _pickEndDate,
      ),
    ],
  );

  // ==========================================================================
  // STEP 4
  // ==========================================================================

  Widget _requirementsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepHeader(
        'Requirements',
        'Add optional drone and pilot requirements.',
      ),
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
        labelBuilder: _pretty,
        onChanged: (value) {
          setState(() => _droneSize = value);
        },
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
        selectedItems: _requiredCapabilities,
        onChanged: (items) {
          setState(() {
            _requiredCapabilities
              ..clear()
              ..addAll(items);
          });
        },
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
        onChanged: (value) {
          setState(() => _requiredExperience = value);
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
        selectedItems: _requiredCertifications,
        onChanged: (items) {
          setState(() {
            _requiredCertifications
              ..clear()
              ..addAll(items);
          });
        },
      ),
      const SizedBox(height: 22),
      _toggle(
        'Safety Training Required',
        'Pilot must have completed safety training',
        _safetyTrainingRequired,
            (value) {
          setState(() => _safetyTrainingRequired = value);
        },
      ),
      const SizedBox(height: 10),
      _toggle(
        'NDA Required',
        'Pilot must agree to an NDA for this job',
        _ndaRequired,
            (value) {
          setState(() => _ndaRequired = value);
        },
      ),
      _label('Other Requirements'),
      _field(
        _requirementsNotes,
        'Any additional requirements or notes...',
        lines: 4,
      ),
    ],
  );

  // ==========================================================================
  // STEP 5
  // ==========================================================================

  Widget _budgetStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepHeader(
        'Budget',
        'Set the payment details for this job.',
      ),
      _label('Payment Type *'),
      _select(
        value: _paymentType,
        items: const [
          'fixed',
          'hourly',
          'daily',
          'negotiable',
        ],
        labelBuilder: _pretty,
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
        _label('Maximum Payment (optional)'),
        _field(
          _paymentMax,
          'e.g. 800',
          type: const TextInputType.numberWithOptions(
            decimal: true,
          ),
        ),
      ] else ...[
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.blueBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'Payment amount can be empty for a negotiable job.',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    ],
  );

  // ==========================================================================
  // STEP 6
  // ==========================================================================

  Widget _attachmentsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepHeader(
        'Attachments & Publish',
        'Add up to 10 optional files, then save as Draft or publish now.',
      ),
      _label('Attachments (optional)'),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: _submitting ? null : _pickAttachments,
          icon: const Icon(Icons.attach_file_rounded),
          label: Text(
            _attachments.isEmpty ? 'Choose Files' : 'Add More Files',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.blue,
            side: const BorderSide(color: AppColors.cardBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      if (_attachments.isNotEmpty) ...[
        const SizedBox(height: 14),
        ...List.generate(
          _attachments.length,
              (index) {
            final file = _attachments[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.insert_drive_file_outlined,
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _submitting
                        ? null
                        : () {
                      setState(
                            () => _attachments.removeAt(index),
                      );
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
      const SizedBox(height: 24),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Job Summary',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _title.text.trim(),
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _locationPreview(),
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _previewMetric(
                    'Payment',
                    _paymentPreview(),
                  ),
                ),
                Expanded(
                  child: _previewMetric(
                    'Start',
                    _formatDate(_startDate),
                  ),
                ),
                Expanded(
                  child: _previewMetric(
                    'End',
                    _formatDate(_endDate),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  // ==========================================================================
  // BOTTOM BUTTONS
  // ==========================================================================

  Widget _bottomButton() {
    if (_step != 5) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: _submitting ? null : _next,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text(
            'Next',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
    }

    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _submitting ? null : _saveAsDraft,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _submitting && !_publishingNow
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                ),
              )
                  : const Text(
                'Save as Draft',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: _submitting ? null : _publishJob,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _submitting && _publishingNow
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Publish Job',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // UI HELPERS
  // ==========================================================================

  Widget _stepHeader(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.grey,
          fontSize: 13.5,
        ),
      ),
      const SizedBox(height: 23),
    ],
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 17),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _field(
      TextEditingController controller,
      String hint, {
        int lines = 1,
        TextInputType type = TextInputType.text,
      }) =>
      TextField(
        controller: controller,
        minLines: lines,
        maxLines: lines,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.lightGrey,
            fontSize: 13,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(14),
          border: _border(AppColors.cardBorder),
          enabledBorder: _border(AppColors.cardBorder),
          focusedBorder: _border(AppColors.blue, width: 1.3),
        ),
      );

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

  Widget _select({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String Function(String value)? labelBuilder,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            hint: const Text(
              'Select...',
              style: TextStyle(
                color: AppColors.lightGrey,
                fontSize: 13.5,
              ),
            ),
            items: items
                .map(
                  (item) => DropdownMenuItem(
                value: item,
                child: Text(
                  labelBuilder?.call(item) ?? item,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13.5,
                  ),
                ),
              ),
            )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _dateBox({
    required DateTime? date,
    required String hint,
    required VoidCallback onTap,
  }) =>
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: AppColors.blue,
                ),
                const SizedBox(width: 10),
                Text(
                  date == null ? hint : _formatDate(date),
                  style: TextStyle(
                    color: date == null
                        ? AppColors.lightGrey
                        : AppColors.navy,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _toggle(
      String title,
      String subtitle,
      bool value,
      ValueChanged<bool> onChanged,
      ) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 11.5,
                    ),
                  ),
                ],
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

  Widget _chips({
    required List<String> items,
    required Set<String> selectedItems,
    required ValueChanged<Set<String>> onChanged,
  }) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          final selected = selectedItems.contains(item);

          return FilterChip(
            label: Text(item),
            selected: selected,
            onSelected: (value) {
              final updated = Set<String>.from(selectedItems);

              if (value) {
                updated.add(item);
              } else {
                updated.remove(item);
              }

              onChanged(updated);
            },
            selectedColor: AppColors.blueBg,
            checkmarkColor: AppColors.blue,
            labelStyle: TextStyle(
              color: selected ? AppColors.blue : AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected ? AppColors.blue : AppColors.cardBorder,
            ),
          );
        }).toList(),
      );

  Widget _previewMetric(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.grey,
          fontSize: 11.5,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  String _pretty(String value) {
    if (value.isEmpty) return value;

    return value
        .split('_')
        .map(
          (part) =>
      '${part[0].toUpperCase()}${part.substring(1)}',
    )
        .join(' ');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _locationPreview() {
    final values = [
      _city.text.trim(),
      _state.text.trim(),
      _country.text.trim(),
    ].where((value) => value.isNotEmpty);

    return values.join(', ');
  }

  String _paymentPreview() {
    if (_paymentType == 'negotiable') {
      return 'Negotiable';
    }

    final min = _paymentMin.text.trim();
    final max = _paymentMax.text.trim();

    return max.isEmpty ? '\$$min' : '\$$min - \$$max';
  }
}
