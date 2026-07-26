import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
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
  int _step = 0;
  PilotDrone _selectedDrone = pilotDrones.first;
  bool _proposeDifferentRate = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _coverNoteController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_step == 1 &&
        _proposeDifferentRate &&
        _rateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add your proposed daily rate to continue.'),
        ),
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

    final application = PilotApplication(
      id: 'application-${DateTime.now().millisecondsSinceEpoch}',
      job: widget.job,
      drone: _selectedDrone,
      status: PilotApplicationStatus.submitted,
      submittedAt: 'Submitted just now',
      pilot: pilotProfiles.first,
      coverNote: _coverNoteController.text.trim().isEmpty
          ? null
          : _coverNoteController.text.trim(),
      proposedRate: _proposeDifferentRate
          ? '\$${_rateController.text.trim()}/day'
          : null,
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
    final titles = ['Select Drone', 'Cover Note', 'Review & Submit'];

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
        return _buildDroneStep();
      case 1:
        return _buildCoverNoteStep();
      default:
        return _buildReviewStep();
    }
  }

  Widget _buildDroneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.job.title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 23,
            fontWeight: FontWeight.w800,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose which drone you will use for this job. Green indicates a capability match.',
          style: TextStyle(color: AppColors.grey, fontSize: 13.5, height: 1.45),
        ),
        const SizedBox(height: 22),
        ...pilotDrones.map(
          (drone) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DroneOptionCard(
              drone: drone,
              selected: drone.id == _selectedDrone.id,
              onTap: () => setState(() => _selectedDrone = drone),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can add another drone from your profile.'),
            ),
          ),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 19),
          label: const Text('Add another drone'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverNoteStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cover Note',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Optional',
          style: TextStyle(color: AppColors.grey, fontSize: 13.5),
        ),
        const SizedBox(height: 25),
        const Text(
          'Message to Company (optional)',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _coverNoteController,
          maxLength: 500,
          minLines: 6,
          maxLines: 7,
          style: const TextStyle(color: AppColors.navy, fontSize: 14),
          decoration: InputDecoration(
            hintText:
                'Introduce yourself, highlight relevant experience, or ask a question about the job...',
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
        const SizedBox(height: 12),
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
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final rate = _proposeDifferentRate && _rateController.text.trim().isNotEmpty
        ? '\$${_rateController.text.trim()}/day'
        : widget.job.pay;

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
                      _selectedDrone.name,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedDrone.isFullMatch
                          ? 'Full capability match'
                          : 'Partial capability match',
                      style: TextStyle(
                        color: _selectedDrone.isFullMatch
                            ? AppColors.green
                            : AppColors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          "By submitting this application you confirm the information is accurate and agree to TOTOTL INTGRX's Terms of Service.",
          style: TextStyle(color: AppColors.grey, fontSize: 12.5, height: 1.45),
        ),
      ],
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
