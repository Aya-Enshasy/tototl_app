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
  final _customDroneLength = TextEditingController();
  final _customDroneWidth = TextEditingController();
  final _customDroneHeight = TextEditingController();
  final _customDroneWeight = TextEditingController();

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

  static const _stepTitles = <String>[
    'Basic information',
    'Location',
    'Schedule',
    'Requirements',
    'Budget',
    'Attachments & publish',
  ];

  static const _stepSubtitles = <String>[
    'Add the core mission details pilots need to understand the job.',
    'Tell pilots where the mission will take place.',
    'Choose the expected start and end dates.',
    'Define the drone, pilot and compliance requirements.',
    'Set the payment structure and expected range.',
    'Review the job, attach files and choose how to save it.',
  ];

  static const _stepIcons = <IconData>[
    Icons.description_outlined,
    Icons.location_on_outlined,
    Icons.calendar_month_outlined,
    Icons.flight_outlined,
    Icons.payments_outlined,
    Icons.publish_outlined,
  ];

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
      _customDroneLength,
      _customDroneWidth,
      _customDroneHeight,
      _customDroneWeight,
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

    if (_step == 3) {
      return _validCustomDroneSize();
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

    if (!_validCustomDroneSize()) {
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
      if (_step == 3 && !_validCustomDroneSize()) {
        _showSnack(
          'For a custom drone size, enter at least length and width.',
          isError: true,
        );
        return;
      }

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
  // DRONE SIZE
  // ==========================================================================

  void _onDroneSizeChanged(String? value) {
    setState(() {
      _droneSize = value;

      if (value != 'custom') {
        _customDroneLength.clear();
        _customDroneWidth.clear();
        _customDroneHeight.clear();
        _customDroneWeight.clear();
      }
    });
  }

  bool _validCustomDroneSize() {
    if (_droneSize != 'custom') return true;

    final length = _positiveNumber(_customDroneLength.text);
    final width = _positiveNumber(_customDroneWidth.text);
    final heightText = _customDroneHeight.text.trim();
    final weightText = _customDroneWeight.text.trim();

    if (length == null || width == null) {
      return false;
    }

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

    if (parsed == null || parsed <= 0) {
      return null;
    }

    return parsed;
  }

  String? _droneSizePayload() {
    final value = _droneSize;

    if (value == null || value.trim().isEmpty) {
      return null;
    }

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
        if (!_validCustomDroneSize()) {
          return null;
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

    if (parsed == null) {
      return value.trim();
    }

    if (parsed == parsed.roundToDouble()) {
      return parsed.toStringAsFixed(0);
    }

    return parsed
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
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
      droneSize: _droneSizePayload(),
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
      if (!_validCustomDroneSize()) {
        _showSnack(
          'For a custom drone size, enter at least length and width.',
          isError: true,
        );
        return;
      }

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
  // ==========================================================================

  Future<void> _publishJob() async {
    if (_submitting) return;

    if (!_validAll()) {
      if (!_validCustomDroneSize()) {
        _showSnack(
          'For a custom drone size, enter at least length and width.',
          isError: true,
        );
        return;
      }

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

    final published = await _controller.publishJob(created.id);

    if (!mounted) return;

    setState(() {
      _submitting = false;
      _publishingNow = false;
    });

    if (published == null) {
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: const EdgeInsets.all(16),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
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
                _progressBar(),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      24,
                    ),
                    child: Column(
                      children: [
                        _introCard(),
                        const SizedBox(height: 13),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: KeyedSubtree(
                            key: ValueKey<int>(_step),
                            child: _currentStep(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _bottomBar(),
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
            tooltip: _step == 0 ? 'Back' : 'Previous step',
            onPressed: _submitting
                ? null
                : () {
              if (_step == 0) {
                Navigator.of(context).pop();
                return;
              }

              setState(() => _step--);
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 17,
              color: AppColors.navy,
            ),
          ),
          const Expanded(
            child: Text(
              'Post a job',
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
              '${_step + 1}/6',
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

  Widget _progressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 1, 20, 8),
      child: Row(
        children: List.generate(
          _stepTitles.length,
              (index) => Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 4,
              margin: EdgeInsets.only(
                right: index == _stepTitles.length - 1 ? 0 : 6,
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
            child: Icon(
              _stepIcons[_step],
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stepTitles[_step],
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
                  _stepSubtitles[_step],
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

  Widget _currentStep() {
    switch (_step) {
      case 0:
        return _basicInfoStep();
      case 1:
        return _locationStep();
      case 2:
        return _scheduleStep();
      case 3:
        return _requirementsStep();
      case 4:
        return _budgetStep();
      default:
        return _attachmentsStep();
    }
  }

  // ==========================================================================
  // STEP 1
  // ==========================================================================

  Widget _basicInfoStep() {
    return _sectionCard(
      icon: Icons.description_outlined,
      title: 'Basic information',
      subtitle: 'Core mission details',
      child: Column(
        children: [
          _label('Job title *'),
          _field(
            _title,
            'Thermal Inspection - Solar Farm',
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
            labelBuilder: _pretty,
            onChanged: (value) {
              setState(() => _serviceCategory = value);
            },
          ),
          _label('Description *'),
          _field(
            _description,
            'Describe the mission, site conditions and expected deliverables...',
            lines: 5,
            prefixIcon: Icons.notes_rounded,
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // STEP 2
  // ==========================================================================

  Widget _locationStep() {
    return _sectionCard(
      icon: Icons.location_on_outlined,
      title: 'Location',
      subtitle: 'Where the mission takes place',
      child: Column(
        children: [
          _label('Country *'),
          _field(
            _country,
            'United States',
            prefixIcon: Icons.public_rounded,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _label('State'),
                    _field(
                      _state,
                      'California',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    _label('City'),
                    _field(
                      _city,
                      'Los Angeles',
                    ),
                  ],
                ),
              ),
            ],
          ),
          _label('Region / area'),
          _field(
            _region,
            'Downtown, industrial zone...',
            prefixIcon: Icons.map_outlined,
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // STEP 3
  // ==========================================================================

  Widget _scheduleStep() {
    return _sectionCard(
      icon: Icons.calendar_month_outlined,
      title: 'Schedule',
      subtitle: 'Mission date range',
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
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
          const SizedBox(height: 12),
          _infoStrip(
            icon: Icons.info_outline_rounded,
            text:
            'Choose an end date that is the same as or later than the start date.',
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // STEP 4
  // ==========================================================================

  Widget _requirementsStep() {
    return _sectionCard(
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
              'Choose Custom dimensions when you need an exact physical size.',
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
            onChanged: (value) {
              setState(() => _requiredExperience = value);
            },
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
            onChanged: (items) {
              setState(() {
                _requiredCapabilities
                  ..clear()
                  ..addAll(items);
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
            onChanged: (items) {
              setState(() {
                _requiredCertifications
                  ..clear()
                  ..addAll(items);
              });
            },
          ),
          const SizedBox(height: 14),
          _toggle(
            icon: Icons.health_and_safety_outlined,
            title: 'Safety training',
            subtitle: 'Pilot must have completed safety training',
            value: _safetyTrainingRequired,
            onChanged: (value) {
              setState(() => _safetyTrainingRequired = value);
            },
          ),
          const SizedBox(height: 9),
          _toggle(
            icon: Icons.lock_outline_rounded,
            title: 'NDA required',
            subtitle: 'Pilot must agree to an NDA for this job',
            value: _ndaRequired,
            onChanged: (value) {
              setState(() => _ndaRequired = value);
            },
          ),
          _label('Other requirements'),
          _field(
            _requirementsNotes,
            'Additional requirements or notes...',
            lines: 4,
            prefixIcon: Icons.fact_check_outlined,
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // STEP 5
  // ==========================================================================

  Widget _budgetStep() {
    return _sectionCard(
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _label('Minimum *'),
                      _field(
                        _paymentMin,
                        '500',
                        type: const TextInputType.numberWithOptions(
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
                        type: const TextInputType.numberWithOptions(
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
    );
  }

  // ==========================================================================
  // STEP 6
  // ==========================================================================

  Widget _attachmentsStep() {
    return Column(
      children: [
        _sectionCard(
          icon: Icons.attach_file_rounded,
          title: 'Attachments',
          subtitle: 'Optional mission files',
          child: Column(
            children: [
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _submitting ? null : _pickAttachments,
                  icon: const Icon(
                    Icons.attach_file_rounded,
                    size: 17,
                  ),
                  label: Text(
                    _attachments.isEmpty
                        ? 'Choose files'
                        : 'Add more files',
                    style: const TextStyle(
                      fontSize: 11.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    backgroundColor: AppColors.bg,
                    side: const BorderSide(
                      color: AppColors.cardBorder,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...List.generate(
                  _attachments.length,
                      (index) {
                    final file = _attachments[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.fromLTRB(
                        10,
                        9,
                        7,
                        9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: AppColors.cardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 31,
                            height: 31,
                            decoration: BoxDecoration(
                              color: AppColors.blueBg,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              Icons.insert_drive_file_outlined,
                              color: AppColors.blue,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              file.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 10.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: _submitting
                                ? null
                                : () {
                              setState(
                                    () => _attachments.removeAt(index),
                              );
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 17,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 13),
        _jobSummaryCard(),
      ],
    );
  }

  Widget _jobSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
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
          const Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                color: AppColors.blue,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Job summary',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _title.text.trim().isEmpty
                ? 'Untitled job'
                : _title.text.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _locationPreview().isEmpty
                ? 'Location not specified'
                : _locationPreview(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 10.6,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _previewMetric(
                  'Payment',
                  _paymentPreview(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _previewMetric(
                  'Start',
                  _formatDate(_startDate),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _previewMetric(
                  'End',
                  _formatDate(_endDate),
                ),
              ),
            ],
          ),
          if (_droneSizePayload() != null) ...[
            const SizedBox(height: 11),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.blueBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.flight_outlined,
                    color: AppColors.blue,
                    size: 15,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _droneSizePayload()!,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 10.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // BOTTOM BAR
  // ==========================================================================

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 11, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: AppColors.cardBorder,
          ),
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
        child: _step == 5
            ? SizedBox(
          height: 50,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                  _submitting ? null : _saveAsDraft,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(
                      color: AppColors.cardBorder,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _submitting && !_publishingNow
                      ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Save draft',
                    style: TextStyle(
                      fontSize: 11.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                  _submitting ? null : _publishJob,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    AppColors.blue.withOpacity(0.55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _submitting && _publishingNow
                      ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons.publish_rounded,
                    size: 17,
                  ),
                  label: const Text(
                    'Publish',
                    style: TextStyle(
                      fontSize: 11.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
            : SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: _submitting ? null : _next,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(
              Icons.arrow_forward_rounded,
              size: 17,
            ),
            label: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 12.4,
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
        border: Border.all(
          color: AppColors.cardBorder,
        ),
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

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 13,
          bottom: 7,
        ),
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
        focusedBorder: _border(
          AppColors.blue,
          width: 1.25,
        ),
      ),
    );
  }

  Widget _select({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String Function(String value)? labelBuilder,
  }) {
    final safeValue =
    value != null && items.contains(value) ? value : null;

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
        focusedBorder: _border(
          AppColors.blue,
          width: 1.25,
        ),
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
            (item) => DropdownMenuItem<String>(
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
            border: Border.all(
              color: AppColors.cardBorder,
            ),
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
            color:
            active ? AppColors.blue : AppColors.cardBorder,
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
      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        8,
        10,
      ),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
              value ? AppColors.blueBg : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 16,
              color:
              value ? AppColors.blue : AppColors.grey,
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
            'Length × width are required. Height and maximum weight are optional.',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 10.3,
              height: 1.35,
            ),
          ),
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
              final preview =
              ready ? _droneSizePayload() : null;

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
                  preview ??
                      'Enter length and width to build the API text',
                  style: TextStyle(
                    color: ready
                        ? AppColors.navy
                        : AppColors.grey,
                    fontSize: 10.2,
                    fontWeight: ready
                        ? FontWeight.w700
                        : FontWeight.w500,
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
      keyboardType:
      const TextInputType.numberWithOptions(
        decimal: true,
      ),
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
        focusedBorder: _border(
          AppColors.blue,
          width: 1.2,
        ),
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

  Widget _previewMetric(
      String label,
      String value,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 9.7,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 10.8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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
    ].where(
          (value) => value.isNotEmpty,
    );

    return values.join(', ');
  }

  String _paymentPreview() {
    if (_paymentType == 'negotiable') {
      return 'Negotiable';
    }

    final min = _paymentMin.text.trim();
    final max = _paymentMax.text.trim();

    if (min.isEmpty) {
      return '—';
    }

    return max.isEmpty
        ? '\$$min'
        : '\$$min - \$$max';
  }
}
