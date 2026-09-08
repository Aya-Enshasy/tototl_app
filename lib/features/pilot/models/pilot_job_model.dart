class PilotJobModel {
  final int id;
  final int? companyProfileId;
  final String title;
  final String description;
  final String country;
  final String state;
  final String city;
  final String region;
  final DateTime? startDate;
  final DateTime? endDate;
  final String paymentType;
  final double? paymentMin;
  final double? paymentMax;
  final List<String> requiredCapabilities;
  final String requirementsNotes;
  final String status;
  final DateTime? publishedAt;
  final DateTime? closedAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String serviceCategory;
  final String requiredExperience;
  final List<String> requiredCertifications;
  final String droneSize;
  final bool trainingSafetyRequired;
  final bool ndaRequired;
  final String cancellationReason;
  final List<PilotJobAttachmentModel> attachments;

  /// Returned by GET /jobs/{id}.
  final PilotJobCompanySummary? company;

  /// Returned by GET /jobs/{id}.
  final PilotJobApplicationSummary? application;

  const PilotJobModel({
    required this.id,
    this.companyProfileId,
    this.title = '',
    this.description = '',
    this.country = '',
    this.state = '',
    this.city = '',
    this.region = '',
    this.startDate,
    this.endDate,
    this.paymentType = '',
    this.paymentMin,
    this.paymentMax,
    this.requiredCapabilities = const [],
    this.requirementsNotes = '',
    this.status = '',
    this.publishedAt,
    this.closedAt,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
    this.serviceCategory = '',
    this.requiredExperience = '',
    this.requiredCertifications = const [],
    this.droneSize = '',
    this.trainingSafetyRequired = false,
    this.ndaRequired = false,
    this.cancellationReason = '',
    this.attachments = const [],
    this.company,
    this.application,
  });

  factory PilotJobModel.fromJson(Map<String, dynamic> json) {
    final rawCompany = json['company'];
    final rawApplication = json['application'];

    return PilotJobModel(
      id: _asInt(json['id']) ?? 0,
      companyProfileId: _asInt(json['company_profile_id']),
      title: _asString(json['title']),
      description: _asString(json['description']),
      country: _asString(json['country']),
      state: _asString(json['state']),
      city: _asString(json['city']),
      region: _asString(json['region']),
      startDate: _asDate(json['start_date']),
      endDate: _asDate(json['end_date']),
      paymentType: _asString(json['payment_type']),
      paymentMin: _asDouble(json['payment_min']),
      paymentMax: _asDouble(json['payment_max']),
      requiredCapabilities: _asStringList(json['required_capabilities']),
      requirementsNotes: _asString(json['requirements_notes']),
      status: _asString(json['status']),
      publishedAt: _asDate(json['published_at']),
      closedAt: _asDate(json['closed_at']),
      cancelledAt: _asDate(json['cancelled_at']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      serviceCategory: _asString(json['service_category']),
      requiredExperience: _asString(json['required_experience']),
      requiredCertifications: _asStringList(json['required_certifications']),
      droneSize: _asString(json['drone_size']),
      trainingSafetyRequired: _asBool(json['training_safety_required']),
      ndaRequired: _asBool(json['nda_required']),
      cancellationReason: _asString(json['cancellation_reason']),
      attachments: _asAttachments(json['attachments']),
      company: rawCompany is Map
          ? PilotJobCompanySummary.fromJson(
              Map<String, dynamic>.from(rawCompany),
            )
          : null,
      application: rawApplication is Map
          ? PilotJobApplicationSummary.fromJson(
              Map<String, dynamic>.from(rawApplication),
            )
          : null,
    );
  }

  String get locationLabel {
    final parts = <String>[
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (country.isNotEmpty) country,
    ];

    if (parts.isEmpty && region.isNotEmpty) return region;
    return parts.isEmpty ? 'Location not specified' : parts.join(', ');
  }

  String get detailedLocationLabel {
    final parts = <String>[
      if (region.isNotEmpty) region,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (country.isNotEmpty) country,
    ];

    return parts.isEmpty ? 'Location not specified' : parts.join(', ');
  }

  String get categoryLabel =>
      _pretty(serviceCategory, fallback: 'Drone Service');

  String get paymentTypeLabel =>
      _pretty(paymentType, fallback: 'Payment');

  String get payLabel {
    if (paymentType.toLowerCase() == 'negotiable') {
      return 'Negotiable';
    }

    final min = _money(paymentMin);
    final max = _money(paymentMax);

    if (paymentMin == null && paymentMax == null) {
      return paymentTypeLabel;
    }

    if (paymentMax == null) {
      return '\$$min · $paymentTypeLabel';
    }

    return '\$$min – \$$max · $paymentTypeLabel';
  }

  String get dateLabel {
    if (startDate == null && endDate == null) {
      return 'Date not specified';
    }

    if (startDate != null &&
        (endDate == null || _sameDay(startDate!, endDate!))) {
      return _friendlyDate(startDate!);
    }

    if (startDate == null) return _friendlyDate(endDate!);

    return '${_friendlyDate(startDate!)} – ${_friendlyDate(endDate!)}';
  }

  String get publishedLabel {
    if (publishedAt == null) return '';
    return 'Posted ${_friendlyDate(publishedAt!)}';
  }

  List<String> get requirementLines {
    final values = <String>[];

    if (requiredExperience.isNotEmpty) {
      values.add('Experience: $requiredExperience');
    }

    if (droneSize.isNotEmpty) {
      values.add('Drone size: ${_pretty(droneSize)}');
    }

    if (requiredCertifications.isNotEmpty) {
      values.add('Certifications: ${requiredCertifications.join(', ')}');
    }

    if (trainingSafetyRequired) {
      values.add('Safety training required');
    }

    if (ndaRequired) {
      values.add('NDA required');
    }

    if (requirementsNotes.isNotEmpty) {
      values.add(requirementsNotes);
    }

    return values;
  }
}

class PilotJobCompanySummary {
  final int id;
  final String name;
  final bool verified;

  const PilotJobCompanySummary({
    required this.id,
    this.name = '',
    this.verified = false,
  });

  factory PilotJobCompanySummary.fromJson(Map<String, dynamic> json) {
    return PilotJobCompanySummary(
      id: _asInt(json['id']) ?? 0,
      name: _asString(json['name']),
      verified: _asBool(json['verified']),
    );
  }

  String get displayName => name.isEmpty ? 'Company #$id' : name;
}

class PilotJobApplicationSummary {
  final bool hasApplied;
  final int? id;
  final String status;

  const PilotJobApplicationSummary({
    this.hasApplied = false,
    this.id,
    this.status = '',
  });

  factory PilotJobApplicationSummary.fromJson(Map<String, dynamic> json) {
    return PilotJobApplicationSummary(
      hasApplied: _asBool(json['has_applied']),
      id: _asInt(json['id']),
      status: _asString(json['status']),
    );
  }

  String get statusLabel =>
      _pretty(status, fallback: hasApplied ? 'Submitted' : '');
}

class PilotJobAttachmentModel {
  final String type;
  final String name;
  final int size;
  final String url;

  const PilotJobAttachmentModel({
    this.type = '',
    this.name = '',
    this.size = 0,
    this.url = '',
  });

  factory PilotJobAttachmentModel.fromJson(Map<String, dynamic> json) {
    return PilotJobAttachmentModel(
      type: _asString(json['type']),
      name: _asString(json['name']),
      size: _asInt(json['size']) ?? 0,
      url: _asString(json['url']),
    );
  }

  bool get isImage => type.toLowerCase().startsWith('image/');
}

class PilotJobsPage {
  final List<PilotJobModel> jobs;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const PilotJobsPage({
    this.jobs = const [],
    this.currentPage = 1,
    this.perPage = 15,
    this.total = 0,
    this.lastPage = 1,
  });

  bool get hasNextPage => currentPage < lastPage;
}

String _asString(dynamic value) =>
    value == null ? '' : value.toString().trim();

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : DateTime.tryParse(text);
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  return text == 'true' || text == '1';
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];

  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

List<PilotJobAttachmentModel> _asAttachments(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map(
          (item) => PilotJobAttachmentModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  final text = _asString(value);
  if (text.isEmpty) return const [];

  return [
    PilotJobAttachmentModel(
      name: 'Attachment',
      url: text,
    ),
  ];
}

String _pretty(String value, {String fallback = ''}) {
  final clean = value.trim();
  if (clean.isEmpty) return fallback;

  return clean
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) =>
            '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String _money(double? value) {
  if (value == null) return '';
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _friendlyDate(DateTime date) {
  const months = [
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

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
