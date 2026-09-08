class DroneModel {
  final int id;
  final int? pilotProfileId;

  final String make;
  final String model;
  final int? manufactureYear;
  final String serialNumber;
  final double? weightKg;

  final List<String> capabilities;

  final int? flightTimePerBatteryMinutes;
  final int? totalBatteries;
  final String batteryType;
  final double? batteryUsageFee;

  final double? hourlyRate;
  final double? dailyRate;
  final double? emergencyCalloutFee;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<DroneMediaModel> media;

  const DroneModel({
    required this.id,
    this.pilotProfileId,
    this.make = '',
    this.model = '',
    this.manufactureYear,
    this.serialNumber = '',
    this.weightKg,
    this.capabilities = const [],
    this.flightTimePerBatteryMinutes,
    this.totalBatteries,
    this.batteryType = '',
    this.batteryUsageFee,
    this.hourlyRate,
    this.dailyRate,
    this.emergencyCalloutFee,
    this.createdAt,
    this.updatedAt,
    this.media = const [],
  });

  factory DroneModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final capabilities = <String>[];

    final rawCapabilities = json['capabilities'];

    if (rawCapabilities is List) {
      for (final item in rawCapabilities) {
        final value = item?.toString().trim() ?? '';

        if (value.isNotEmpty) {
          capabilities.add(value);
        }
      }
    } else if (rawCapabilities != null) {
      capabilities.addAll(
        rawCapabilities
            .toString()
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty),
      );
    }

    final media = <DroneMediaModel>[];
    final rawMedia = json['media'];

    if (rawMedia is List) {
      for (final item in rawMedia) {
        if (item is Map) {
          media.add(
            DroneMediaModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return DroneModel(
      id: _asInt(json['id']) ?? 0,
      pilotProfileId:
      _asInt(json['pilot_profile_id']),
      make:
      _asString(json['make']),
      model:
      _asString(json['model']),
      manufactureYear:
      _asInt(json['manufacture_year']),
      serialNumber:
      _asString(json['serial_number']),
      weightKg:
      _asDouble(json['weight_kg']),
      capabilities:
      capabilities,
      flightTimePerBatteryMinutes:
      _asInt(
        json['flight_time'] ??
            json['flight_time_per_battery_minutes'],
      ),
      totalBatteries:
      _asInt(json['total_batteries']),
      batteryType:
      _asString(json['battery_type']),
      batteryUsageFee:
      _asDouble(json['battery_usage_fee']),
      hourlyRate:
      _asDouble(json['hourly_rate']),
      dailyRate:
      _asDouble(json['daily_rate']),
      emergencyCalloutFee:
      _asDouble(
        json['emergency_callout_fee'],
      ),
      createdAt:
      _asDate(json['created_at']),
      updatedAt:
      _asDate(json['updated_at']),
      media:
      media,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pilot_profile_id': pilotProfileId,
      'make': make,
      'model': model,
      'manufacture_year': manufactureYear,
      'serial_number': serialNumber,
      'weight_kg': weightKg,
      'capabilities': capabilities,
      'flight_time':
      flightTimePerBatteryMinutes,
      'total_batteries': totalBatteries,
      'battery_type': batteryType,
      'battery_usage_fee': batteryUsageFee,
      'hourly_rate': hourlyRate,
      'daily_rate': dailyRate,
      'emergency_callout_fee':
      emergencyCalloutFee,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'media':
      media.map((item) => item.toJson()).toList(),
    };
  }

  String get title {
    final values = <String>[
      make.trim(),
      model.trim(),
    ].where((item) => item.isNotEmpty).toList();

    return values.isEmpty
        ? 'Drone'
        : values.join(' ');
  }

  String get imageUrl {
    for (final item in media) {
      if (item.collectionName == 'image' &&
          item.url.trim().isNotEmpty) {
        return item.url.trim();
      }
    }

    for (final item in media) {
      if (item.url.trim().isNotEmpty) {
        return item.url.trim();
      }
    }

    return '';
  }

  String get yearLabel =>
      manufactureYear?.toString() ?? '';

  String get weightLabel {
    if (weightKg == null) {
      return 'Not specified';
    }

    return '${_cleanNumber(weightKg!)} kg';
  }

  String get flightTimeLabel {
    if (flightTimePerBatteryMinutes == null) {
      return 'Not specified';
    }

    return '$flightTimePerBatteryMinutes min';
  }

  String get batteriesLabel {
    if (totalBatteries == null) {
      return 'Not specified';
    }

    return '$totalBatteries';
  }

  String get hourlyRateLabel =>
      _money(hourlyRate);

  String get dailyRateLabel =>
      _money(dailyRate);

  String get emergencyRateLabel =>
      _money(emergencyCalloutFee);

  String get batteryUsageFeeLabel =>
      _money(batteryUsageFee);
}

class DroneMediaModel {
  final int? id;
  final String collectionName;
  final String fileName;
  final String mimeType;
  final int? size;
  final String url;
  final String downloadUrl;
  final DateTime? createdAt;

  const DroneMediaModel({
    this.id,
    this.collectionName = '',
    this.fileName = '',
    this.mimeType = '',
    this.size,
    this.url = '',
    this.downloadUrl = '',
    this.createdAt,
  });

  factory DroneMediaModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return DroneMediaModel(
      id:
      _asInt(json['id']),
      collectionName:
      _asString(json['collection_name']),
      fileName:
      _asString(json['file_name']),
      mimeType:
      _asString(json['mime_type']),
      size:
      _asInt(json['size']),
      url:
      _asString(json['url']),
      downloadUrl:
      _asString(json['download_url']),
      createdAt:
      _asDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collection_name': collectionName,
      'file_name': fileName,
      'mime_type': mimeType,
      'size': size,
      'url': url,
      'download_url': downloadUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

String _asString(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;

  return int.tryParse(
    value.toString(),
  );
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();

  return double.tryParse(
    value.toString(),
  );
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;

  final text =
  value.toString().trim();

  if (text.isEmpty) return null;

  return DateTime.tryParse(text);
}

String _cleanNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _money(double? value) {
  if (value == null) {
    return 'Not specified';
  }

  return '\$${_cleanNumber(value)}';
}
