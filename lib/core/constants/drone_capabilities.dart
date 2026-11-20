import 'package:tototl_app/core/localization/app_language.dart';

class DroneCapabilityItem {
  final String value;
  final String label;

  const DroneCapabilityItem({required this.value, required this.label});
}

/// Canonical capability values shared by registration, drone CRUD, job posting,
/// pilot search, job details and application matching.
/// All network requests must carry a list of these exact values, not labels.
class DroneCapabilities {
  DroneCapabilities._();

  static const String thermal = 'thermal';
  static const String laser = 'laser';
  static const String nightVision = 'night_vision';
  static const String lidar = 'lidar';
  static const String radar = 'radar';
  static const String imaging = 'imaging';
  static const String rtk = 'rtk';
  static const String zoom = 'zoom';
  static const String other = 'other';

  static const List<DroneCapabilityItem> options = [
    DroneCapabilityItem(value: thermal, label: 'Thermal Camera'),
    DroneCapabilityItem(value: laser, label: 'Laser'),
    DroneCapabilityItem(value: nightVision, label: 'Night Vision'),
    DroneCapabilityItem(value: lidar, label: 'LiDAR'),
    DroneCapabilityItem(value: radar, label: 'Radar'),
    DroneCapabilityItem(value: imaging, label: 'Imaging'),
    DroneCapabilityItem(value: rtk, label: 'RTK'),
    DroneCapabilityItem(value: zoom, label: 'Zoom'),
    DroneCapabilityItem(value: other, label: 'Other'),
  ];

  static const List<String> labels = [
    'Thermal Camera', 'Laser', 'Night Vision', 'LiDAR', 'Radar',
    'Imaging', 'RTK', 'Zoom', 'Other',
  ];

  static const List<String> values = [
    thermal, laser, nightVision, lidar, radar, imaging, rtk, zoom, other,
  ];

  static const _allowed = {
    thermal, laser, nightVision, lidar, radar, imaging, rtk, zoom, other,
  };

  /// `other` must be explicitly present in the data, not inferred from an
  /// unsupported legacy accessory. Otherwise the mobile UI reports a full
  /// match while the Laravel application endpoint correctly rejects the drone.
  /// Do not turn values such as spotlight/multispectral/speaker into `other`.
  static String canonicalize(String raw) {
    final value = raw.trim().toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll('/', ' ')
        .replaceAll(RegExp(r'[_\s-]+'), ' ')
        .trim();
    if (value.isEmpty) return '';
    switch (value) {
      case 'thermal':
      case 'thermal camera':
      case 'thermal sensor':
        return thermal;
      case 'laser':
        return laser;
      case 'night vision':
      case 'nightvision':
        return nightVision;
      case 'lidar':
      case 'li dar':
        return lidar;
      case 'radar':
        return radar;
      case 'imaging':
      case 'imaging camera':
      case 'camera':
        return imaging;
      case 'rtk':
      case 'rtk module':
        return rtk;
      case 'zoom':
      case 'zoom camera':
        return zoom;
      case 'other':
        return other;
      default:
        // Reject unknown legacy accessories rather than fabricating `other`.
        // This is essential for matching the backend's exact capability values.
        return '';
    }
  }

  static bool isAllowed(String value) => _allowed.contains(value);

  static List<String> canonicalizeAll(Iterable<String> capabilities) {
    final found = <String>{};
    for (final item in capabilities) {
      final value = canonicalize(item);
      if (value.isNotEmpty) found.add(value);
    }
    // Keep a stable order matching the server's documented enum.
    return List.unmodifiable(values.where(found.contains));
  }

  static bool isFullMatch({
    required Iterable<String> required,
    required Iterable<String> available,
  }) {
    final availableSet = canonicalizeAll(available).toSet();
    return canonicalizeAll(required).every(availableSet.contains);
  }

  static List<String> missing({
    required Iterable<String> required,
    required Iterable<String> available,
  }) {
    final availableSet = canonicalizeAll(available).toSet();
    return canonicalizeAll(required)
        .where((value) => !availableSet.contains(value))
        .toList(growable: false);
  }

  static String labelFor(String raw) {
    final value = canonicalize(raw);
    if (value.isEmpty) return '';
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return 'Other';
  }

  static String localizedLabelFor(String raw) => AppLanguage.text(labelFor(raw));
}
