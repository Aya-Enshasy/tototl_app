import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../applications/applications_screen.dart';
import '../../jobs/find_job.dart';
import '../../shared/pilot_data.dart';
import '../widgets/home_header.dart';
import '../widgets/job_card.dart';
import '../widgets/my_drone_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [

          SafeArea(
            child: AnimatedBuilder(
              animation: PilotApplicationsStore.instance,
              builder: (context, _) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HomeHeader(),
                    const SizedBox(height: 18),
                    const MyDroneCard(),
                    const SizedBox(height: 26),
                    _SectionHeader(
                      title: 'Recommended Jobs',
                      onSeeAll: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FindDroneJobsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const JobCard(),
                    const SizedBox(height: 26),
                    _SectionHeader(title: 'My Availability', onSeeAll: () {}),
                    const SizedBox(height: 12),
                    _AvailabilityLauncher(
                      onTap: () => showDialog<List<AvailabilitySlot>>(
                        context: context,
                        barrierDismissible: true,
                        builder: (_) => const AvailabilityPickerDialog(),
                      ),
                    ),
                    const SizedBox(height: 26),
                    _SectionHeader(
                      title: 'My Applications',
                      onSeeAll: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ApplicationsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const ApplicationsScreen(compact: true),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'See all',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Distinctive tile that lives on the Home page and opens the
/// availability date/time picker popup when tapped.
class _AvailabilityLauncher extends StatelessWidget {
  const _AvailabilityLauncher({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.blue,
                    AppColors.blue.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set Your Availability',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Tap to pick the dates and times you're free",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.blueBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.blue,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single available date with a start and end time.
class AvailabilitySlot {
  AvailabilitySlot({
    required this.date,
    required this.start,
    required this.end,
  });

  final DateTime date;
  TimeOfDay start;
  TimeOfDay end;
}

/// Popup dialog: pick one or more dates from a calendar, then set a
/// time range for each. Mirrors the "Date" + "Selected Dates and Time"
/// reference design, with Cancel / Ok actions.
class AvailabilityPickerDialog extends StatefulWidget {
  const AvailabilityPickerDialog({super.key, this.initialSlots});

  final List<AvailabilitySlot>? initialSlots;

  @override
  State<AvailabilityPickerDialog> createState() =>
      _AvailabilityPickerDialogState();
}

class _AvailabilityPickerDialogState extends State<AvailabilityPickerDialog> {
  late DateTime _visibleMonth;
  final Map<DateTime, AvailabilitySlot> _slots = {};

  static const _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _monthLabels = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    final initial = widget.initialSlots;
    if (initial != null) {
      for (final slot in initial) {
        _slots[_dateKey(slot.date)] = slot;
      }
    }
  }

  DateTime _dateKey(DateTime d) => DateTime(d.year, d.month, d.day);

  List<DateTime?> _buildMonthGrid() {
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final leadingEmpty = firstOfMonth.weekday % 7; // Sunday = 0
    final cells = <DateTime?>[];
    for (var i = 0; i < leadingEmpty; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_visibleMonth.year, _visibleMonth.month, d));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  void _toggleDate(DateTime date) {
    final key = _dateKey(date);
    setState(() {
      if (_slots.containsKey(key)) {
        _slots.remove(key);
      } else {
        _slots[key] = AvailabilitySlot(
          date: key,
          start: const TimeOfDay(hour: 9, minute: 0),
          end: const TimeOfDay(hour: 12, minute: 0),
        );
      }
    });
  }

  Future<void> _pickTime(AvailabilitySlot slot, {required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? slot.start : slot.end,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        slot.start = picked;
      } else {
        slot.end = picked;
      }
    });
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${_monthLabels[d.month - 1].substring(0, 3)}-${d.year}';

  @override
  Widget build(BuildContext context) {
    final cells = _buildMonthGrid();
    final sortedSlots = _slots.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final today = _dateKey(DateTime.now());

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 640),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                color: AppColors.blue,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set Your Availability',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Pick dates, then set the time for each',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => setState(() {
                              _visibleMonth = DateTime(
                                _visibleMonth.year,
                                _visibleMonth.month - 1,
                              );
                            }),
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              color: AppColors.navy,
                            ),
                          ),
                          Text(
                            '${_monthLabels[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() {
                              _visibleMonth = DateTime(
                                _visibleMonth.year,
                                _visibleMonth.month + 1,
                              );
                            }),
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: _weekdayLabels
                            .map(
                              (l) => Expanded(
                                child: Center(
                                  child: Text(
                                    l,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.grey.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 4),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cells.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              childAspectRatio: 1,
                            ),
                        itemBuilder: (context, index) {
                          final date = cells[index];
                          if (date == null) return const SizedBox.shrink();
                          final key = _dateKey(date);
                          final isSelected = _slots.containsKey(key);
                          final isPast = key.isBefore(today);
                          final isToday = key == today;
                          return Padding(
                            padding: const EdgeInsets.all(2),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: isPast ? null : () => _toggleDate(date),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.blue
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isToday && !isSelected
                                      ? Border.all(
                                          color: AppColors.blue,
                                          width: 1.2,
                                        )
                                      : null,
                                ),
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : isPast
                                        ? AppColors.grey.withValues(alpha: 0.4)
                                        : AppColors.navy,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Selected Dates and Times',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (sortedSlots.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Tap dates above to add availability',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.grey.withValues(alpha: 0.8),
                            ),
                          ),
                        )
                      else
                        ...sortedSlots.map(
                          (slot) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    _formatDate(slot.date),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      InkWell(
                                        onTap: () =>
                                            _pickTime(slot, isStart: true),
                                        child: Text(
                                          _formatTime(slot.start),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.blue,
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        '  -  ',
                                        style: TextStyle(
                                          color: AppColors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () =>
                                            _pickTime(slot, isStart: false),
                                        child: Text(
                                          _formatTime(slot.end),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => setState(
                                    () => _slots.remove(_dateKey(slot.date)),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: AppColors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.cardBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.grey,
                          side: BorderSide(color: AppColors.cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(sortedSlots),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Ok',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
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
}
