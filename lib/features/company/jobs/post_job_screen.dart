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
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _date = TextEditingController();
  final _budget = TextEditingController();
  final _safety = TextEditingController();
  final _requirements = TextEditingController(text: 'Part 107 required');
  int _step = 0;
  bool _urgent = false;
  bool _siteImages = true;
  bool _pidIncluded = false;
  String _experience = '2+ years';
  String _duration = 'Half day';
  final Set<String> _capabilities = {'Thermal', 'Imaging'};

  @override
  void dispose() {
    for (final controller in [
      _title,
      _description,
      _location,
      _date,
      _budget,
      _safety,
      _requirements,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _validStep() {
    if (_step == 0) {
      return _title.text.trim().isNotEmpty &&
          _description.text.trim().isNotEmpty &&
          _location.text.trim().isNotEmpty;
    }
    return _date.text.trim().isNotEmpty &&
        _budget.text.trim().isNotEmpty &&
        _capabilities.isNotEmpty &&
        _safety.text.trim().isNotEmpty;
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
    location: _location.text.trim(),
    pay: '\$${_budget.text.trim()}/day',
    date: _date.text.trim(),
    distance: 'New',
    companyRating: '4.8',
    description: _description.text.trim(),
    requirements: _requirements.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(),
    capabilities: _capabilities.toList(),
    safetyRequirements: _safety.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(),
    jobsPosted: 47,
    pilotsHired: 4,
    siteImagesProvided: _siteImages,
    pidIncluded: _pidIncluded,
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
    final titles = ['Post a Job', 'Job Requirements', 'Review & Publish'];
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
                  3,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
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
                    ? _detailsStep()
                    : _step == 1
                    ? _requirementsStep()
                    : _reviewStep(),
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

  Widget _detailsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Mission Details',
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 7),
      const Text(
        'Give pilots a clear, complete view of the work.',
        style: TextStyle(color: AppColors.grey, fontSize: 13.5),
      ),
      const SizedBox(height: 23),
      _label('Job Title *'),
      _field(_title, 'e.g. Thermal Inspection - Solar Farm Array'),
      _label('Description *'),
      _field(
        _description,
        'Describe the mission scope, site conditions, and expected deliverables...',
        lines: 5,
      ),
      _label('Location *'),
      _field(_location, 'Address, city, or coordinates'),
      const Text(
        'Exact location is shared only after acceptance.',
        style: TextStyle(color: AppColors.grey, fontSize: 11.5),
      ),
      const SizedBox(height: 16),
      _label('Mission Date *'),
      _field(_date, 'YYYY-MM-DD', type: TextInputType.datetime),
      _label('Budget per day (USD) *'),
      _field(_budget, '1200', type: TextInputType.number),
      _label('Duration'),
      _select(
        value: _duration,
        items: const ['Half day', 'Full day', 'Multiple days'],
        onChanged: (value) => setState(() => _duration = value!),
      ),
    ],
  );

  Widget _requirementsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Job Requirements',
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 7),
      const Text(
        'Set the drone capabilities, qualifications, and site safety rules.',
        style: TextStyle(color: AppColors.grey, fontSize: 13.5, height: 1.4),
      ),
      const SizedBox(height: 24),
      _label('Required Drone Capabilities *'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            ['Thermal', 'Imaging', 'LiDAR', 'Night Vision', 'Radar', 'Laser']
                .map(
                  (item) => FilterChip(
                    label: Text(item),
                    selected: _capabilities.contains(item),
                    onSelected: (selected) => setState(
                      () => selected
                          ? _capabilities.add(item)
                          : _capabilities.remove(item),
                    ),
                    selectedColor: AppColors.greenBg,
                    checkmarkColor: AppColors.green,
                    labelStyle: TextStyle(
                      color: _capabilities.contains(item)
                          ? AppColors.green
                          : AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
                .toList(),
      ),
      const SizedBox(height: 20),
      _label('Minimum Experience'),
      _select(
        value: _experience,
        items: const ['1+ year', '2+ years', '3+ years', '5+ years'],
        onChanged: (value) => setState(() => _experience = value!),
      ),
      _label('Requirements *'),
      _field(
        _requirements,
        'Part 107 required, Thermal camera certified',
        lines: 3,
      ),
      _label('Safety Requirements *'),
      _field(_safety, 'Safety vest required, hard hat during setup', lines: 3),
      _toggle(
        'Provide site images',
        'Upload photos to help pilots assess the site',
        _siteImages,
        (value) => setState(() => _siteImages = value),
      ),
      const SizedBox(height: 9),
      _toggle(
        'Include P&ID / drawings',
        'Share technical documentation with matched pilots',
        _pidIncluded,
        (value) => setState(() => _pidIncluded = value),
      ),
      const SizedBox(height: 9),
      _toggle(
        'Mark as urgent',
        'Urgent jobs get featured placement in search results',
        _urgent,
        (value) => setState(() => _urgent = value),
      ),
    ],
  );

  Widget _reviewStep() {
    final job = _createJob();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Job',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Check the details pilots will see before publishing.',
          style: TextStyle(color: AppColors.grey, fontSize: 13.5),
        ),
        const SizedBox(height: 22),
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
              if (_urgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orangeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Urgent',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                job.title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'SunTech Energy Ltd. · ${job.location}',
                style: const TextStyle(color: AppColors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _previewMetric('Pay', job.pay)),
                  Expanded(child: _previewMetric('Date', job.date)),
                  Expanded(child: _previewMetric('Duration', _duration)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Divider(color: AppColors.cardBorder),
              ),
              Text(
                job.description,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: job.capabilities
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.greenBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.blueBg,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Row(
            children: [
              Icon(Icons.people_outline_rounded, color: AppColors.blue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your job will match pilots with the required capabilities in your region.',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomButton() => SizedBox(
    width: double.infinity,
    height: 52,
    child: _step == 2
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
}
