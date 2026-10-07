class DroneCapabilityItem {
  final String value;
  final String label;

  const DroneCapabilityItem({
    required this.value,
    required this.label,
  });
}
class DroneCapabilities {
  DroneCapabilities._();

  static const String thermal = 'thermal';
  static const String rtk = 'rtk';
  static const String zoom = 'zoom';
  static const String lidar = 'lidar';
  static const String laser = 'laser';
  static const String multispectral = 'multispectral';
  static const String nightVision = 'night_vision';
  static const String spotlight = 'spotlight';
  static const String winch = 'winch';
  static const String speaker = 'speaker';
  static const String parachute = 'parachute';

  static const List<DroneCapabilityItem> options = <DroneCapabilityItem>[
    DroneCapabilityItem(value: thermal, label: 'Thermal Camera'),
    DroneCapabilityItem(value: rtk, label: 'RTK'),
    DroneCapabilityItem(value: zoom, label: 'Zoom'),
    DroneCapabilityItem(value: lidar, label: 'LiDAR'),
    DroneCapabilityItem(value: laser, label: 'Laser'),
    DroneCapabilityItem(value: multispectral, label: 'Multispectral'),
    DroneCapabilityItem(value: nightVision, label: 'Night Vision'),
    DroneCapabilityItem(value: spotlight, label: 'Spotlight'),
    DroneCapabilityItem(value: winch, label: 'Winch'),
    DroneCapabilityItem(value: speaker, label: 'Speaker'),
    DroneCapabilityItem(value: parachute, label: 'Parachute'),
  ];

  static const List<String> labels = <String>[
    'Thermal Camera',
    'RTK',
    'Zoom',
    'LiDAR',
    'Laser',
    'Multispectral',
    'Night Vision',
    'Spotlight',
    'Winch',
    'Speaker',
    'Parachute',
  ];

  /// Converts all known legacy/UI variants to the same API value.
  ///
  /// Examples:
  /// Zoom / Zoom Camera / zoom -> zoom
  /// Night Vision / night_vision -> night_vision
  /// Thermal Camera / Thermal / thermal -> thermal
  static String canonicalize(String raw) {
    var value = raw.trim().toLowerCase();

    if (value.isEmpty) return '';

    value = value
        .replaceAll('&', ' and ')
        .replaceAll('/', ' ')
        .replaceAll(RegExp(r'[_\s-]+'), ' ')
        .trim();

    switch (value) {
      case 'thermal':
      case 'thermal camera':
      case 'thermal sensor':
        return thermal;

      case 'rtk':
      case 'rtk module':
        return rtk;

      case 'zoom':
      case 'zoom camera':
        return zoom;

      case 'lidar':
      case 'li dar':
        return lidar;

      case 'laser':
        return laser;

      case 'multispectral':
      case 'multispectral sensor':
      case 'multispectral camera':
        return multispectral;

      case 'night vision':
      case 'nightvision':
        return nightVision;

      case 'spotlight':
        return spotlight;

      case 'winch':
      case 'winch release mechanism':
      case 'release mechanism':
        return winch;

      case 'speaker':
      case 'loudspeaker':
      case 'speaker loudspeaker':
        return speaker;

      case 'parachute':
      case 'parachute safety system':
        return parachute;
    }

    // Defensive fallback for future controlled values.
    return value.replaceAll(' ', '_');
  }

  static List<String> canonicalizeAll(Iterable<String> values) {
    final result = <String>[];
    final seen = <String>{};

    for (final item in values) {
      final canonical = canonicalize(item);
      if (canonical.isEmpty || !seen.add(canonical)) continue;
      result.add(canonical);
    }

    return result;
  }

  static bool isFullMatch({
    required Iterable<String> required,
    required Iterable<String> available,
  }) {
    final requiredSet = canonicalizeAll(required).toSet();
    if (requiredSet.isEmpty) return true;

    final availableSet = canonicalizeAll(available).toSet();
    return requiredSet.every(availableSet.contains);
  }

  static List<String> missing({
    required Iterable<String> required,
    required Iterable<String> available,
  }) {
    final requiredSet = canonicalizeAll(required).toSet();
    final availableSet = canonicalizeAll(available).toSet();

    return requiredSet
        .where((item) => !availableSet.contains(item))
        .toList(growable: false);
  }

  static String labelFor(String raw) {
    final value = canonicalize(raw);

    for (final option in options) {
      if (option.value == value) return option.label;
    }

    if (value.isEmpty) return '';

    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}
