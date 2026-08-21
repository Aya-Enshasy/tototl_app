import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../shared/pilot_data.dart';
import 'application_details_screen.dart';

class ApplyForJobScreen extends StatefulWidget {
  const ApplyForJobScreen({super.key, required this.job});

  final PilotJob job;

  @override
  State<ApplyForJobScreen> createState() => _ApplyForJobScreenState();
}

class _ApplyForJobScreenState extends State<ApplyForJobScreen> {
  final _coverNoteController = TextEditingController();
  final _rateController = TextEditingController();
  final _completionTimeController = TextEditingController();
  final _startDateController = TextEditingController();
  // Additional notes / answers requested by the company when posting the job
  final _additionalNotesController = TextEditingController();

  // --- Drone information the pilot fills ---
  String? _droneType; // e.g. 'DJI Mavic Series'
  final _droneModelController = TextEditingController();
  // Drone size: Small / Medium / Large / Custom / Normal
  String? _droneSize;
  // custom dimensions when _droneSize == 'Custom'
  final _customLengthController = TextEditingController();
  final _customWidthController = TextEditingController();

  // Drone capabilities the pilot declares
  final Set<String> _equipmentConfirmed = {};

  // Pilot certifications/licences selected for this application
  final Set<String> _certificatesSelected = {};

  // Experience related to this job
  String _experienceRelated = '1-5';

  // Availability time of day
  String? _availableTimeOfDay; // Morning / Afternoon / Evening

  // Example uploads placeholder (filenames or ids)
  final List<String> _exampleUploads = [];

  // Skills the pilot confirms they can provide for this job (if any)
  final Set<String> _skillsConfirmed = {};

  int _step = 0;
  bool _proposeDifferentRate = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _coverNoteController.dispose();
    _rateController.dispose();
    _completionTimeController.dispose();
    _startDateController.dispose();
    _additionalNotesController.dispose();
    _droneModelController.dispose();
    _customLengthController.dispose();
    _customWidthController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_step == 0) {
      // validate drone info
      if (_droneType == null || _droneType!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your drone type.')),
        );
        return;
      }
      if (_droneModelController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your drone model.')),
        );
        return;
      }
      if (_droneSize == null || _droneSize!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your drone size.')),
        );
        return;
      }
    }

    if (_step == 1 &&
        widget.job.paymentType != 'Fixed' &&
        _proposeDifferentRate &&
        _rateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add your proposed daily rate to continue.'),
        ),
      );
      return;
    }
    if (_step == 1 && _completionTimeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify estimated completion time.'),
        ),
      );
      return;
    }
    if (_step == 1 && _startDateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please specify available start date.')),
      );
      return;
    }

    if (_step < 2) {
      HapticFeedback.selectionClick();
      setState(() => _step += 1);
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // create a PilotDrone object from the pilot-entered drone info
    final createdDrone = PilotDrone(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: '${_droneType ?? ''} ${_droneModelController.text.trim()}'.trim(),
      year: '',
      capabilities: _equipmentConfirmed.toList(),
      // Consider it a full match if it includes all required capabilities for the job
      isFullMatch: widget.job.capabilities.every((c) => _equipmentConfirmed.contains(c)),
    );

    // Merge additional notes and structured selections so company sees them
    final buffer = StringBuffer();
    if (_additionalNotesController.text.trim().isNotEmpty) {
      buffer.writeln(_additionalNotesController.text.trim());
    }
    if (_certificatesSelected.isNotEmpty) {
      buffer.writeln('Certificates: ${_certificatesSelected.join(", ")}');
    }
    if (_experienceRelated.isNotEmpty) {
      buffer.writeln('Similar jobs completed: $_experienceRelated');
    }
    if (_availableTimeOfDay != null && _availableTimeOfDay!.isNotEmpty) {
      buffer.writeln('Available time of day: $_availableTimeOfDay');
    }
    if (_exampleUploads.isNotEmpty) {
      buffer.writeln('Example uploads: ${_exampleUploads.length} files');
    }

    final application = PilotApplication(
      id: 'application-${DateTime.now().millisecondsSinceEpoch}',
      job: widget.job,
      drone: createdDrone,
      status: PilotApplicationStatus.submitted,
      submittedAt: 'Submitted just now',
      pilot: pilotProfiles.first,
      coverNote: _coverNoteController.text.trim().isEmpty
          ? null
          : _coverNoteController.text.trim(),
      proposedRate: _proposeDifferentRate
          ? '\$${_rateController.text.trim()}/day'
          : null,
      estimatedCompletionTime: _completionTimeController.text.trim(),
      availableStartDate: _startDateController.text.trim(),
      additionalNotes: buffer.toString().trim().isEmpty
          ? null
          : buffer.toString().trim(),
      droneSize: _droneSize,
      droneDimensions: null,
      skillsConfirmed: _skillsConfirmed.toList(),
      equipmentConfirmed: _equipmentConfirmed.toList(),
    );
    PilotApplicationsStore.instance.submit(application);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ApplicationDetailsScreen(application: application),
      ),
    );
  }

  void _goBack() {
    if (_isSubmitting) return;
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step -= 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Select Drone', 'Proposal & Timing', 'Review & Submit'];

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
                    tooltip: 'Back',
                    onPressed: _goBack,
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
                children: List.generate(3, (index) {
                  final reached = index <= _step;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                      height: 4,
                      decoration: BoxDecoration(
                        color: reached ? AppColors.blue : AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: _buildStep(),
                ),
              ),
            ),
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildSelectDroneStep();
      case 1:
        return _buildProposalStep();
      default:
        return _buildReviewStep();
    }
  }

  Widget _buildSelectDroneStep() {
    final pilot = pilotProfiles.first;
    final job = widget.job;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Job title
        Text(
          job.title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 23,
            fontWeight: FontWeight.w800,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 12),
        // Profile summary (auto-filled, non-editable)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              // avatar placeholder
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.blueBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pilot.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${pilot.location} · ${pilot.experience}', style: const TextStyle(color: AppColors.grey, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: AppColors.green),
                        const SizedBox(width: 6),
                        Text(pilot.rating, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 10),
                        if (pilot.verified) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.greenBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Verified', style: TextStyle(color: AppColors.green, fontSize: 11.5, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Drone information',
          style: TextStyle(color: AppColors.navy, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        // Drone type dropdown
        _label('Drone type'),
        _select(
          value: _droneType ?? '',
          items: const [
            'DJI Mavic Series',
            'DJI Phantom',
            'DJI Inspire',
            'Autel',
            'Other',
          ],
          onChanged: (v) => setState(() => _droneType = v),
        ),
        _label('Drone model'),
        _field(_droneModelController, 'e.g. DJI Mavic 3 Enterprise'),
        _label('Drone size'),
        Row(
          children: ['Small', 'Medium', 'Large', 'Custom', 'Specific'].map((size) {
            final isSelected = _droneSize == size;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() {
                    _droneSize = size;
                    if (size != 'Custom') {
                      _customLengthController.text = '';
                      _customWidthController.text = '';
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? AppColors.blue : AppColors.cardBorder, width: 1.2),
                    ),
                    child: Center(
                      child: Text(size, style: TextStyle(fontSize: 13.5, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : AppColors.navy)),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_droneSize == 'Custom') ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  _customLengthController,
                  'Length (m)',
                  type: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  _customWidthController,
                  'Width (m)',
                  type: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        const SizedBox(height: 18),
        _label('Drone capabilities'),
        const Text('Select capabilities your drone has', style: TextStyle(color: AppColors.grey, fontSize: 12.5)),
        const SizedBox(height: 8),
        _buildMultiSelectChips(
          items: const [
            'Thermal Camera',
            'LiDAR',
            'Laser Scanner',
            'Night Vision',
            'High Resolution Camera',
            'Zoom Camera',
            'RTK GPS',
            'Other',
          ],
          selectedItems: _equipmentConfirmed,
          onChanged: (items) => setState(() {
            _equipmentConfirmed.clear();
            _equipmentConfirmed.addAll(items);
          }),
        ),
        const SizedBox(height: 16),
        _label('Certifications & Licenses'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Drone License',
            'Pilot Certificate',
            'Insurance Certificate',
            'Safety Training Certificate',
          ].map((cert) {
            final selected = _certificatesSelected.contains(cert);
            return FilterChip(
              label: Text(cert),
              selected: selected,
              onSelected: (v) => setState(() {
                if (v) _certificatesSelected.add(cert); else _certificatesSelected.remove(cert);
              }),
              selectedColor: AppColors.blueBg,
              checkmarkColor: AppColors.blue,
              backgroundColor: Colors.white,
              side: BorderSide(color: selected ? AppColors.blue : AppColors.cardBorder),
              labelStyle: TextStyle(color: selected ? AppColors.blue : AppColors.navy, fontWeight: FontWeight.w700),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _label('Experience related to this job'),
        _select(
          value: _experienceRelated,
          items: const ['0', '1-5', '5-20', '20+'],
          onChanged: (v) => setState(() => _experienceRelated = v ?? _experienceRelated),
        ),
      ],
    );
  }

  Widget _buildProposalStep() {
    final job = widget.job;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (job.requiredSkills.isNotEmpty) ...[
          _label('Skills requested by company'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: job.requiredSkills.map((skill) {
              final selected = _skillsConfirmed.contains(skill);
              return ChoiceChip(
                label: Text(
                  skill,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.navy,
                  ),
                ),
                selected: selected,
                selectedColor: AppColors.blue,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.cardBorder),
                ),
                onSelected: (v) => setState(() {
                  if (v)
                    _skillsConfirmed.add(skill);
                  else
                    _skillsConfirmed.remove(skill);
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select skills you will provide for this job (optional).',
            style: TextStyle(color: AppColors.grey, fontSize: 12.5),
          ),
          const SizedBox(height: 18),
        ],
        if (job.capabilities.isNotEmpty) ...[
          _label('Equipment requested by company'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: job.capabilities.map((equip) {
              final selected = _equipmentConfirmed.contains(equip);
              return ChoiceChip(
                label: Text(
                  equip,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.navy,
                  ),
                ),
                selected: selected,
                selectedColor: AppColors.green,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.cardBorder),
                ),
                onSelected: (v) => setState(() {
                  if (v)
                    _equipmentConfirmed.add(equip);
                  else
                    _equipmentConfirmed.remove(equip);
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Confirm equipment you will provide for this job (optional).',
            style: TextStyle(color: AppColors.grey, fontSize: 12.5),
          ),
          const SizedBox(height: 18),
        ],

        const Text(
          'Proposal & Timing',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Provide your proposal and availability details.',
          style: TextStyle(color: AppColors.grey, fontSize: 13.5),
        ),
        const SizedBox(height: 23),
        _label('Proposal (optional)'),
        TextField(
          controller: _coverNoteController,
          maxLength: 500,
          minLines: 4,
          maxLines: 5,
          style: const TextStyle(color: AppColors.navy, fontSize: 14),
          decoration: InputDecoration(
            hintText:
                'Tell the company why you are suitable for this job (e.g. experience with industrial thermal inspection...)',
            hintStyle: const TextStyle(color: AppColors.lightGrey, height: 1.4),
            counterStyle: const TextStyle(color: AppColors.grey),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.blue, width: 1.4),
            ),
          ),
        ),
const SizedBox(height: 20),
_label('Availability'),
Row(
  children: [
    Expanded(
      child: _field(
        _startDateController,
        'Available date (YYYY-MM-DD)',
        type: TextInputType.datetime,
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: _select(
        value: _availableTimeOfDay ?? '',
        items: const ['Morning', 'Afternoon', 'Evening'],
        onChanged: (v) => setState(() => _availableTimeOfDay = v),
      ),
    ),
  ],
),
const SizedBox(height: 14),
_label('Upload examples (optional)'),
Row(
  children: [
    FilledButton(
      onPressed: () => setState(() => _exampleUploads.add('Example ${_exampleUploads.length + 1}')),
      child: const Text('Add Example (placeholder)'),
    ),
    const SizedBox(width: 12),
    Text('${_exampleUploads.length} files selected', style: const TextStyle(color: AppColors.grey)),
  ],
),
const SizedBox(height: 12),
        if (job.paymentType != 'Fixed') ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Propose a different rate',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _proposeDifferentRate,
                      activeTrackColor: AppColors.blue,
                      onChanged: (value) =>
                          setState(() => _proposeDifferentRate = value),
                    ),
                  ],
                ),
                if (_proposeDifferentRate) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      prefixText: r'$ ',
                      suffixText: ' / day',
                      hintText: 'Your proposed rate',
                      filled: true,
                      fillColor: AppColors.bg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.cardBorder,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        _label('Estimated Completion Time *'),
        _select(
          value: _completionTimeController.text,
          items: const ['Same Day', '2 Days', '1 Week', 'Custom', 'Normal'],
          onChanged: (value) =>
              setState(() => _completionTimeController.text = value!),
        ),
        if (_completionTimeController.text == 'Custom') ...[
          const SizedBox(height: 12),
          _field(
            _completionTimeController,
            'e.g. 5 days',
            type: TextInputType.text,
          ),
        ],
        const SizedBox(height: 20),
        _label('Available Start Date *'),
        _field(
          _startDateController,
          'YYYY-MM-DD',
          type: TextInputType.datetime,
        ),
        // Allow pilot to provide any additional notes or answers the company requested
        const SizedBox(height: 14),
        _label('Additional information (optional)'),
        TextField(
          controller: _additionalNotesController,
          maxLength: 500,
          minLines: 3,
          maxLines: 5,
          style: const TextStyle(color: AppColors.navy, fontSize: 14),
          decoration: InputDecoration(
            hintText:
                'Answer any company questions or provide extra details...',
            hintStyle: const TextStyle(color: AppColors.lightGrey, height: 1.4),
            counterStyle: const TextStyle(color: AppColors.grey),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.blue, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final rate = _proposeDifferentRate && _rateController.text.trim().isNotEmpty
        ? '\$${_rateController.text.trim()}/day'
        : widget.job.pay;
    final job = widget.job;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Application',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 24),
        _ReviewCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Applying for',
                style: TextStyle(color: AppColors.grey, fontSize: 12.5),
              ),
              const SizedBox(height: 6),
              Text(
                widget.job.title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${widget.job.company} · ${widget.job.location}',
                style: const TextStyle(color: AppColors.grey, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetric(label: 'Rate', value: rate),
                  ),
                  Expanded(
                    child: _MiniMetric(label: 'Date', value: widget.job.date),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ReviewCard(
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.greenBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flight_rounded, color: AppColors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Drone Selected',
                      style: TextStyle(color: AppColors.grey, fontSize: 12.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_droneType ?? ''} ${_droneModelController.text.trim()}',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Builder(builder: (_) {
                      final fullMatch = widget.job.capabilities.every((c) => _equipmentConfirmed.contains(c));
                      return Text(
                        fullMatch ? 'Full capability match' : 'Partial capability match',
                        style: TextStyle(
                          color: fullMatch ? AppColors.green : AppColors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ReviewCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Timing',
                style: TextStyle(color: AppColors.grey, fontSize: 12.5),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'Completion Time:',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _completionTimeController.text.trim(),
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Start Date:',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _startDateController.text.trim(),
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_coverNoteController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          _ReviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Proposal',
                  style: TextStyle(color: AppColors.grey, fontSize: 12.5),
                ),
                const SizedBox(height: 6),
                Text(
                  _coverNoteController.text.trim(),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_additionalNotesController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          _ReviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Additional information',
                  style: TextStyle(color: AppColors.grey, fontSize: 12.5),
                ),
                const SizedBox(height: 6),
                Text(
                  _additionalNotesController.text.trim(),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        const Text(
          "By submitting this application you confirm the information is accurate and agree to TOTOTL INTGRX's Terms of Service.",
          style: TextStyle(color: AppColors.grey, fontSize: 12.5, height: 1.45),
        ),
      ],
    );
  }

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
        value: value.isEmpty ? null : value,
        isExpanded: true,
        hint: Text(
          'Select an option',
          style: TextStyle(color: AppColors.lightGrey, fontSize: 13.5),
        ),
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

  Widget _buildBottomAction() {
    final label = _step == 2 ? 'Submit Application' : 'Continue';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: _isSubmitting ? null : _continue,
          style: FilledButton.styleFrom(


            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: _isSubmitting
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('Sending Your Application...'),
                  ],
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

class _DroneOptionCard extends StatelessWidget {
  const _DroneOptionCard({
    required this.drone,
    required this.selected,
    required this.onTap,
  });

  final PilotDrone drone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = drone.isFullMatch ? AppColors.green : AppColors.orange;
    final background = drone.isFullMatch
        ? AppColors.greenBg
        : AppColors.orangeBg;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color : AppColors.cardBorder,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.flight_rounded, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drone.name,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          drone.year,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? color : AppColors.lightGrey,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  drone.isFullMatch ? 'Full Match' : 'Partial Match',
                  style: TextStyle(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: drone.capabilities
                    .map((capability) => _CapabilityChip(label: capability))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.tagBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.grey, fontSize: 11.5),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
