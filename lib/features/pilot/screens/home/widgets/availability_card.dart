import 'package:flutter/material.dart';
import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/features/pilot/models/pilot_availability_preference.dart';

class AvailabilityCard extends StatelessWidget {
  const AvailabilityCard({
    super.key,
    required this.preference,
    required this.onTap,
  });

  final PilotAvailabilityPreference preference;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(15, 15, 13, 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFF8FCFC),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.cardBorder.withOpacity(0.95),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.035),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF16C6C7),
                      Color(0xFF087E9C),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A92A2).withOpacity(0.17),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Availability',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: preference.isConfigured
                                ? AppColors.green.withOpacity(0.08)
                                : AppColors.blue.withOpacity(0.055),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            preference.isConfigured ? 'Set' : 'Not set',
                            style: TextStyle(
                              color: preference.isConfigured
                                  ? AppColors.green
                                  : AppColors.blue,
                              fontSize: 8.8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      preference.isConfigured
                          ? preference.dateRangeLabel
                          : 'Set one range instead of selecting every date.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.grey.withOpacity(0.92),
                        fontSize: 10.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (preference.isConfigured) ...[
                      const SizedBox(height: 5),
                      Text(
                        '${preference.daysLabel}  •  ${preference.timeLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontSize: 9.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.055),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.blue,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AvailabilityEditorSheet extends StatefulWidget {
  const AvailabilityEditorSheet({
    super.key,
    required this.initial,
  });

  final PilotAvailabilityPreference initial;

  @override
  State<AvailabilityEditorSheet> createState() =>
      _AvailabilityEditorSheetState();
}

class _AvailabilityEditorSheetState extends State<AvailabilityEditorSheet> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late Set<int> _weekdays;
  late bool _allDay;
  late int _startMinutes;
  late int _endMinutes;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initial.startDate;
    _endDate = widget.initial.endDate;
    _weekdays = widget.initial.weekdays.toSet();
    _allDay = widget.initial.allDay;
    _startMinutes = widget.initial.startMinutes;
    _endMinutes = widget.initial.endMinutes;
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final initialStart = _startDate ?? now;
    final initialEnd = _endDate ?? now.add(const Duration(days: 30));

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3, 12, 31),
      initialDateRange: DateTimeRange(
        start: initialStart.isBefore(now) ? now : initialStart,
        end: initialEnd.isBefore(now) ? now.add(const Duration(days: 30)) : initialEnd,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.blue,
              onPrimary: Colors.white,
              onSurface: AppColors.navy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      _startDate = picked.start;
      _endDate = picked.end;
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final currentMinutes = start ? _startMinutes : _endMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: currentMinutes ~/ 60,
        minute: currentMinutes % 60,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.blue,
              onPrimary: Colors.white,
              onSurface: AppColors.navy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    final minutes = picked.hour * 60 + picked.minute;
    setState(() {
      if (start) {
        _startMinutes = minutes;
      } else {
        _endMinutes = minutes;
      }
    });
  }

  void _save() {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose the availability date range first.'),
        ),
      );
      return;
    }

    if (_weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one available weekday.'),
        ),
      );
      return;
    }

    if (!_allDay && _endMinutes <= _startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time.'),
        ),
      );
      return;
    }

    final value = PilotAvailabilityPreference(
      startDate: _startDate,
      endDate: _endDate,
      weekdays: _weekdays.toList()..sort(),
      allDay: _allDay,
      startMinutes: _startMinutes,
      endMinutes: _endMinutes,
    );

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.13),
                blurRadius: 34,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Work availability',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Set one availability window, then choose the days and hours that repeat inside it.',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 11.2,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                const _FieldTitle(
                  icon: Icons.date_range_outlined,
                  title: 'Availability window',
                ),
                const SizedBox(height: 9),
                _ActionField(
                  icon: Icons.calendar_month_rounded,
                  title: _startDate == null || _endDate == null
                      ? 'Choose start and end date'
                      : '${_date(_startDate!)} – ${_date(_endDate!)}',
                  subtitle: 'Example: available for the next two months',
                  onTap: _pickRange,
                ),
                const SizedBox(height: 19),
                const _FieldTitle(
                  icon: Icons.view_week_outlined,
                  title: 'Days inside this range',
                ),
                const SizedBox(height: 10),
                _WeekdaySelector(
                  selected: _weekdays,
                  onChanged: (day) {
                    setState(() {
                      if (_weekdays.contains(day)) {
                        _weekdays.remove(day);
                      } else {
                        _weekdays.add(day);
                      }
                    });
                  },
                ),
                const SizedBox(height: 19),
                Row(
                  children: [
                    const Expanded(
                      child: _FieldTitle(
                        icon: Icons.schedule_rounded,
                        title: 'Daily hours',
                      ),
                    ),
                    Switch.adaptive(
                      value: _allDay,
                      activeColor: AppColors.blue,
                      onChanged: (value) {
                        setState(() => _allDay = value);
                      },
                    ),
                    const Text(
                      'All day',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (!_allDay) ...[
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeField(
                          label: 'From',
                          value: _clock(_startMinutes),
                          onTap: () => _pickTime(start: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TimeField(
                          label: 'Until',
                          value: _clock(_endMinutes),
                          onTap: () => _pickTime(start: false),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    if (widget.initial.isConfigured)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(
                            const PilotAvailabilityPreference(),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.grey,
                            side: BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Clear',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    if (widget.initial.isConfigured)
                      const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Save availability',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldTitle extends StatelessWidget {
  const _FieldTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.blue, size: 16),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 12.3,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ActionField extends StatelessWidget {
  const _ActionField({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.blue, size: 18),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 11.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 9.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.lightGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdaySelector extends StatelessWidget {
  const _WeekdaySelector({
    required this.selected,
    required this.onChanged,
  });

  final Set<int> selected;
  final ValueChanged<int> onChanged;

  static const labels = <int, String>{
    1: 'M',
    2: 'T',
    3: 'W',
    4: 'T',
    5: 'F',
    6: 'S',
    7: 'S',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: labels.entries.map((entry) {
        final active = selected.contains(entry.key);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: entry.key == 7 ? 0 : 5),
            child: InkWell(
              onTap: () => onChanged(entry.key),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.blue
                      : AppColors.blue.withOpacity(0.045),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active
                        ? AppColors.blue
                        : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 9.3,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _date(DateTime value) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}

String _clock(int totalMinutes) {
  final hour24 = (totalMinutes ~/ 60).clamp(0, 23);
  final minute = totalMinutes.remainder(60).clamp(0, 59);
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
  return '$hour12:${minute.toString().padLeft(2, '0')} $period';
}
