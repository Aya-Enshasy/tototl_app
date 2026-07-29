import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../pilot/shared/pilot_data.dart';
import '../company_shell_screen.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  // 1. Basic Information
  final _title = TextEditingController();
  final _serviceCategory = TextEditingController();
  final _description = TextEditingController();

  // 2. Location
  final _country = TextEditingController();
  final _city = TextEditingController();
  final _region = TextEditingController();
  final _address = TextEditingController();
  final _gpsCoordinates = TextEditingController();
  String? _indoorOutdoor;

  // 3. Schedule
  final _date = TextEditingController();
  final _startTime = TextEditingController();
  final _duration = TextEditingController();
  bool _flexibleSchedule = false;

  // 4. Requirements
  String? _droneSize;
  final Set<String> _droneEquipment = {};
  final TextEditingController _otherDroneEquipment = TextEditingController();
  String _experience = '2+ years';
  final Set<String> _licenseTypes = {};
  final Set<String> _certificationTypes = {};
  bool _safetyTrainingRequired = false;
  final TextEditingController _otherRequirements = TextEditingController();
  final Set<String> _requiredSkills = {};

  // 5. Budget
  String _paymentType = 'Fixed';
  final _budget = TextEditingController();
  bool _urgent = false;

  // 6. Attachments
  bool _siteImages = true;
  bool _pidIncluded = false;
  final Set<String> _attachments = {};

  int _step = 0;

  @override
  void dispose() {
    for (final controller in [
      _title,
      _serviceCategory,
      _description,
      _country,
      _city,
      _region,
      _address,
      _gpsCoordinates,
      _date,
      _startTime,
      _duration,
      _budget,
      _otherDroneEquipment,
      _otherRequirements,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _validStep() {
    if (_step == 0) {
      return _title.text.trim().isNotEmpty &&
          _serviceCategory.text.trim().isNotEmpty &&
          _description.text.trim().isNotEmpty;
    }
    if (_step == 1) {
      return _country.text.trim().isNotEmpty &&
          _city.text.trim().isNotEmpty &&
          _region.text.trim().isNotEmpty;
    }
    if (_step == 2) {
      return _date.text.trim().isNotEmpty && _duration.text.trim().isNotEmpty;
    }
    if (_step == 3) {
      return _droneSize != null && _droneEquipment.isNotEmpty;
    }
    if (_step == 4) {
      return _budget.text.trim().isNotEmpty;
    }
    return true;
  }

  void _next() {
    if (!_validStep()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the required job details.'),
        ),
      );
      return;
    }
    setState(() => _step += 1);
  }

  PilotJob _createJob() => PilotJob(
    id: 'suntech-${DateTime.now().millisecondsSinceEpoch}',
    title: _title.text.trim(),
    company: 'SunTech Energy Ltd.',
    location: '${_city.text.trim()}, ${_country.text.trim()}',
    country: _country.text.trim(),
    city: _city.text.trim(),
    region: _region.text.trim(),
    address: _address.text.trim().isEmpty ? null : _address.text.trim(),
    gpsCoordinates: _gpsCoordinates.text.trim().isEmpty
        ? null
        : _gpsCoordinates.text.trim(),
    pay: '\$${_budget.text.trim()}/day',
    date: _date.text.trim(),
    distance: 'New',
    companyRating: '4.8',
    description: _description.text.trim(),
    requirements: [
      'Experience: $_experience',
      if (_licenseTypes.isNotEmpty) 'Licenses: ${_licenseTypes.join(", ")}',
      if (_certificationTypes.isNotEmpty)
        'Certifications: ${_certificationTypes.join(", ")}',
      if (_safetyTrainingRequired) 'Safety Training Required',
      if (_otherRequirements.text.trim().isNotEmpty)
        _otherRequirements.text.trim(),
    ],
    capabilities: _droneEquipment.toList(),
    safetyRequirements: [
      if (_siteImages) 'Site images provided',
      if (_pidIncluded) 'P&ID drawings included',
    ],
    jobsPosted: 47,
    pilotsHired: 4,
    siteImagesProvided: _siteImages,
    pidIncluded: _pidIncluded,
    jobTypes: _requiredSkills.toList(),
    droneSize: _droneSize,
    safetyTrainingRequired: _safetyTrainingRequired,
    specialCertificationsRequired: _certificationTypes.isNotEmpty,
    // New fields
    serviceCategory: _serviceCategory.text.trim(),
    indoorOutdoor: _indoorOutdoor,
    startTime: _startTime.text.trim().isEmpty ? null : _startTime.text.trim(),
    flexibleSchedule: _flexibleSchedule,
    paymentType: _paymentType,
    requiredSkills: _requiredSkills.toList(),
    attachments: _attachments.toList(),
  );

  void _save(CompanyJobStatus status) {
    final job = _createJob();
    CompanyJobsStore.instance.save(
      CompanyJob(
        job: job,
        status: status,
        postedAt: status == CompanyJobStatus.active
            ? 'Posted just now'
            : 'Saved just now',
        urgent: _urgent,
      ),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const CompanyShellScreen(initialIndex: 1),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
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
                    onPressed: () => _step == 0
                        ? Navigator.of(context).pop()
                        : setState(() => _step -= 1),
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
                      margin: EdgeInsets.only(right: index == 5 ? 0 : 6),
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
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: _bottomButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _basicInfoStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Basic Information',
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 7),
      const Text(
        'Provide the essential details about your job.',
        style: TextStyle(color: AppColors.grey, fontSize: 13.5),
      ),
      const SizedBox(height: 23),
      _label('Job Title *'),
      _field(_title, 'e.g. Thermal Inspection - Solar Farm Array'),
      _label('Service Category *'),
      _select(
        value: _serviceCategory.text,
        items: const [
          'Inspection',
          'Mapping',
          'Surveying',
          'Photography',
          'Construction Monitoring',
          'Agriculture',
          'Emergency Response',
          'Other',
        ],
        onChanged: (value) => setState(() => _serviceCategory.text = value!),
      ),
      _label('Job Description *'),
      _field(
        _description,
        'Describe the mission scope, site conditions, and expected deliverables...',
        lines: 5,
      ),
    ],
  );

  Widget _locationStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Location',
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 7),
      const Text(
        'Specify where the job will take place.',
        style: TextStyle(color: AppColors.grey, fontSize: 13.5),
      ),
      const SizedBox(height: 23),
      _label('Country *'),
      _field(_country, 'e.g. United States'),
      _label('City *'),
      _field(_city, 'e.g. Los Angeles'),
      _label('Region / Area *'),
      _field(_region, 'e.g. Downtown, Industrial Zone, Al-Rimal'),
      _label('Specific Address (optional)'),
      _field(_address, 'e.g. 123 Main Street, Downtown'),
      const SizedBox(height: 4),
      const Text(
        'The exact address is shared with the pilot only after acceptance.',
        style: TextStyle(color: AppColors.grey, fontSize: 11.5),
      ),
      _label('GPS Coordinates (optional)'),
      _field(_gpsCoordinates, 'e.g. 34.0522° N, 118.2437° W'),
      const SizedBox(height: 20),
      _label('Indoor / Outdoor (optional)'),
      Row(
        children: ['Indoor', 'Outdoor', 'Both'].map((type) {
          final isSelected = _indoorOutdoor == type;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _indoorOutdoor = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.blue : AppColors.cardBorder,
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.navy,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );

  Widget _scheduleStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Schedule',
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 7),
      const Text(
        'Set the preferred timing for this job.',
        style: TextStyle(color: AppColors.grey, fontSize: 13.5),
      ),
      const SizedBox(height: 23),
      _label('Preferred Date *'),
      _field(_date, 'YYYY-MM-DD', type: TextInputType.datetime),
      _label('Preferred Start Time (optional)'),
      _field(_startTime, 'e.g. 9:00 AM', type: TextInputType.text),
      _label('Estimated Duration *'),
      _field(_duration, 'e.g. 2 days', type: TextInputType.text),
      const SizedBox(height: 20),
      _label('Flexible Schedule'),
      Row(
        children: [
          Switch.adaptive(
            value: _flexibleSchedule,
            activeTrackColor: AppColors.blue,
            onChanged: (value) => setState(() => _flexibleSchedule = value),
          ),
          const SizedBox(width: 12),
          const Text(
            'Schedule can be adjusted',
            style: TextStyle(color: AppColors.navy, fontSize: 13.5),
          ),
        ],
      ),
    ],
  );

  Widget _requirementsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Requirements',
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 7),
      const Text(
        'Specify drone and pilot requirements.',
        style: TextStyle(color: AppColors.grey, fontSize: 13.5),
      ),
      const SizedBox(height: 23),
      _label('Drone Size *'),
      Row(
        children: ['Small', 'Medium', 'Large'].map((size) {
          final isSelected = _droneSize == size;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _droneSize = size),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.blue : AppColors.cardBorder,
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      size,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.navy,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 24),
      _label('Camera / Sensor *'),
      const Text(
        'Select all required equipment',
        style: TextStyle(color: AppColors.grey, fontSize: 12),
      ),
      const SizedBox(height: 8),
      _buildMultiSelectChips(
        items: const [
          'Thermal Camera',
          'Imaging',
          'LiDAR',
          'Night Vision',
          'Laser',
          'Radar',
          'Other',
        ],
        selectedItems: _droneEquipment,
        onChanged: (items) {
          setState(() {
            _droneEquipment.clear();
            _droneEquipment.addAll(items);
          });
        },
      ),
      if (_droneEquipment.contains('Other')) ...[
        const SizedBox(height: 12),
        _label('Specify Other Equipment *'),
        _field(_otherDroneEquipment, 'Please specify'),
      ],
      const SizedBox(height: 24),
      _label('Required Experience *'),
      _select(
        value: _experience,
        items: const [
          '1+ year',
          '2+ years',
          '3+ years',
          '5+ years',
          '10+ years',
        ],
        onChanged: (value) => setState(() => _experience = value!),
      ),
      const SizedBox(height: 20),
      _label('Required Certifications'),
      const Text(
        'Select all required certifications',
        style: TextStyle(color: AppColors.grey, fontSize: 12),
      ),
      const SizedBox(height: 8),
      _buildMultiSelectChips(
        items: const [
          'Part 107 (US)',
          'CAA (UK)',
          'EASA (EU)',
          'Transport Canada',
          'Other',
        ],
        selectedItems: _licenseTypes,
        onChanged: (items) {
          setState(() {
            _licenseTypes.clear();
            _licenseTypes.addAll(items);
          });
        },
      ),
      const SizedBox(height: 20),
      _label('Skills Required'),
      const Text(
        'Select all required skills',
        style: TextStyle(color: AppColors.grey, fontSize: 12),
      ),
      const SizedBox(height: 8),
      _buildMultiSelectChips(
        items: const [
          'Mapping',
          'Thermal Inspection',
          'Photography',
          'Surveying',
          'Construction Monitoring',
          'Other',
        ],
        selectedItems: _requiredSkills,
        onChanged: (items) {
          setState(() {
            _requiredSkills.clear();
            _requiredSkills.addAll(items);
          });
        },
      ),
      const SizedBox(height: 20),
      _label('Safety Training Required'),
      Row(
        children: [
          Switch.adaptive(
            value: _safetyTrainingRequired,
            activeTrackColor: AppColors.blue,
            onChanged: (value) =>
                setState(() => _safetyTrainingRequired = value),
          ),
          const SizedBox(width: 12),
          const Text(
            'Pilot must have completed safety training',
            style: TextStyle(color: AppColors.navy, fontSize: 13.5),
          ),
        ],
      ),
      const SizedBox(height: 20),
      _label('Other Requirements'),
      _field(
        _otherRequirements,
        'Any additional requirements or special permissions...',
        lines: 3,
      ),
    ],
  );

  Widget _budgetStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Budget',
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 7),
      const Text(
        'Set the payment details for this job.',
        style: TextStyle(color: AppColors.grey, fontSize: 13.5),
      ),
      const SizedBox(height: 23),
      _label('Payment Type *'),
      Row(
        children: ['Fixed', 'Hourly', 'Project'].map((type) {
          final isSelected = _paymentType == type;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _paymentType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.blue : AppColors.cardBorder,
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.navy,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 24),
      _label('Budget *'),
      _field(_budget, 'e.g. 1200', type: TextInputType.number),
      const SizedBox(height: 20),
      _label('Urgent Job'),
      Row(
        children: [
          Switch.adaptive(
            value: _urgent,
            activeTrackColor: AppColors.blue,
            onChanged: (value) => setState(() => _urgent = value),
          ),
          const SizedBox(width: 12),
          const Text(
            'Mark as urgent for featured placement',
            style: TextStyle(color: AppColors.navy, fontSize: 13.5),
          ),
        ],
      ),
    ],
  );

  Widget _attachmentsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Attachments & Publish',
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 7),
      const Text(
        'Add optional attachments and publish your job.',
        style: TextStyle(color: AppColors.grey, fontSize: 13.5),
      ),
      const SizedBox(height: 23),
      _label('Attachments (optional)'),
      const Text(
        'Select all attachment types to include',
        style: TextStyle(color: AppColors.grey, fontSize: 12),
      ),
      const SizedBox(height: 8),
      _buildMultiSelectChips(
        items: const ['Images', 'PDF', 'Site Plan', 'Documents'],
        selectedItems: _attachments,
        onChanged: (items) {
          setState(() {
            _attachments.clear();
            _attachments.addAll(items);
          });
        },
      ),
      const SizedBox(height: 24),
      _toggle(
        'Include Site Images',
        'Upload photos to help pilots assess the site',
        _siteImages,
        (value) => setState(() => _siteImages = value),
      ),
      const SizedBox(height: 9),
      _toggle(
        'Include P&ID / Drawings',
        'Share technical documentation with matched pilots',
        _pidIncluded,
        (value) => setState(() => _pidIncluded = value),
      ),
      const SizedBox(height: 30),
      Container(
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
              '${_city.text.trim()}, ${_country.text.trim()}',
              style: const TextStyle(color: AppColors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _previewMetric('Budget', '\$${_budget.text.trim()}'),
                ),
                Expanded(child: _previewMetric('Date', _date.text.trim())),
                Expanded(
                  child: _previewMetric('Duration', _duration.text.trim()),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  Widget _bottomButton() => SizedBox(
    width: double.infinity,
    height: 52,
    child: _step == 5
        ? Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _save(CompanyJobStatus.draft),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Save as Draft',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => _save(CompanyJobStatus.active),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Publish Job',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          )
        : FilledButton(
            onPressed: _next,
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
  }) => TextField(
    controller: controller,
    minLines: lines,
    maxLines: lines,
    keyboardType: type,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.lightGrey, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(14),
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
        borderSide: const BorderSide(color: AppColors.blue, width: 1.3),
      ),
    ),
  );
  Widget _select({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) => Container(
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
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(color: AppColors.navy, fontSize: 13.5),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    ),
  );
  Widget _toggle(
    String title,
    String detail,
    bool value,
    ValueChanged<bool> onChanged,
  ) => Container(
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
                detail,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 11.5,
                  height: 1.3,
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
  Widget _previewMetric(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.grey, fontSize: 11.5),
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

  Widget _buildMultiSelectChips({
    required List<String> items,
    required Set<String> selectedItems,
    required ValueChanged<Set<String>> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);
        return FilterChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (selected) {
            final updated = Set<String>.from(selectedItems);
            if (selected) {
              updated.add(item);
            } else {
              updated.remove(item);
            }
            onChanged(updated);
          },
          selectedColor: AppColors.blueBg,
          checkmarkColor: AppColors.blue,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.blue : AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isSelected ? AppColors.blue : AppColors.cardBorder,
          ),
        );
      }).toList(),
    );
  }
}
