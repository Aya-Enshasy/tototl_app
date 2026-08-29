class DroneFormRequest {
  final String make;
  final String model;
  final int manufactureYear;
  final String serialNumber;
  final double weightKg;

  final List<String> capabilities;

  final int flightTimePerBatteryMinutes;
  final int totalBatteries;
  final String? batteryType;
  final double? batteryUsageFee;

  final double hourlyRate;
  final double dailyRate;
  final double emergencyCalloutFee;

  final String? imagePath;

  const DroneFormRequest({
    required this.make,
    required this.model,
    required this.manufactureYear,
    required this.serialNumber,
    required this.weightKg,
    this.capabilities = const [],
    required this.flightTimePerBatteryMinutes,
    required this.totalBatteries,
    this.batteryType,
    this.batteryUsageFee,
    required this.hourlyRate,
    required this.dailyRate,
    required this.emergencyCalloutFee,
    this.imagePath,
  });

  // ==========================================================================
  // NORMAL TEXT FIELDS
  //
  // capabilities are intentionally NOT included here.
  // They are added separately in DroneService as indexed multipart fields:
  // capabilities[0], capabilities[1], ...
  // Laravel then receives them as a real array.
  // ==========================================================================

  Map<String, dynamic> toFields() {
    return {
      'make': make.trim(),
      'model': model.trim(),
      'manufacture_year': manufactureYear.toString(),
      'serial_number': serialNumber.trim(),
      'weight_kg': _number(weightKg),

      'flight_time_per_battery_minutes':
      flightTimePerBatteryMinutes.toString(),

      'total_batteries': totalBatteries.toString(),

      'battery_type': _nullable(batteryType),

      'battery_usage_fee': batteryUsageFee == null
          ? null
          : _number(batteryUsageFee!),

      'hourly_rate': _number(hourlyRate),

      'daily_rate': _number(dailyRate),

      'emergency_callout_fee':
      _number(emergencyCalloutFee),
    };
  }
}

String? _nullable(String? value) {
  if (value == null) {
    return null;
  }

  final clean = value.trim();

  return clean.isEmpty ? null : clean;
}

String _number(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}