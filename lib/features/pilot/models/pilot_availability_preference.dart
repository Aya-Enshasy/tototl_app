class PilotAvailabilityPreference {
  const PilotAvailabilityPreference({
    this.startDate,
    this.endDate,
    this.weekdays = const <int>[1, 2, 3, 4, 5, 6, 7],
    this.allDay = true,
    this.startMinutes = 9 * 60,
    this.endMinutes = 17 * 60,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final List<int> weekdays;
  final bool allDay;
  final int startMinutes;
  final int endMinutes;

  bool get isConfigured => startDate != null && endDate != null;

  PilotAvailabilityPreference copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<int>? weekdays,
    bool? allDay,
    int? startMinutes,
    int? endMinutes,
  }) {
    return PilotAvailabilityPreference(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      weekdays: weekdays ?? this.weekdays,
      allDay: allDay ?? this.allDay,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
    );
  }

  factory PilotAvailabilityPreference.fromJson(Map<String, dynamic> json) {
    final rawWeekdays = json['weekdays'];

    return PilotAvailabilityPreference(
      startDate: _date(json['available_from']),
      endDate: _date(json['available_until']),
      weekdays: _weekdays(rawWeekdays),
      allDay: _bool(json['all_day'], fallback: true),
      startMinutes: _int(json['start_minutes']) ?? 9 * 60,
      endMinutes: _int(json['end_minutes']) ?? 17 * 60,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'available_from': _day(startDate),
      'available_until': _day(endDate),
      'weekdays': weekdays,
      'all_day': allDay,
      'start_minutes': startMinutes,
      'end_minutes': endMinutes,
    };
  }

  String get dateRangeLabel {
    if (!isConfigured) return 'No availability window set';
    return '${_shortDate(startDate!)} – ${_shortDate(endDate!)}';
  }

  String get daysLabel {
    if (weekdays.length == 7) return 'Every day';
    if (_same(weekdays, const <int>[1, 2, 3, 4, 5])) return 'Mon–Fri';
    if (_same(weekdays, const <int>[6, 7])) return 'Weekend';

    const labels = <int, String>{
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };

    return weekdays.map((item) => labels[item] ?? '').where((e) => e.isNotEmpty).join(', ');
  }

  String get timeLabel {
    if (allDay) return 'All day';
    return '${_clock(startMinutes)} – ${_clock(endMinutes)}';
  }
}

List<int> _weekdays(dynamic raw) {
  if (raw is! List) return const <int>[1, 2, 3, 4, 5, 6, 7];

  final result = raw
      .map((item) => int.tryParse(item.toString()))
      .whereType<int>()
      .where((item) => item >= 1 && item <= 7)
      .toSet()
      .toList();
  result.sort();
  return result.isEmpty ? const <int>[1, 2, 3, 4, 5, 6, 7] : result;
}

bool _bool(dynamic value, {required bool fallback}) {
  if (value is bool) return value;
  if (value == null) return fallback;
  final text = value.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}

DateTime? _date(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

int? _int(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

String? _day(DateTime? value) {
  if (value == null) return null;
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String _shortDate(DateTime value) {
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

bool _same(List<int> first, List<int> second) {
  if (first.length != second.length) return false;
  final a = [...first]..sort();
  final b = [...second]..sort();
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
