class CompanyJobPostingModel {
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
  final String requiredExperience;
  final List<String> requiredCertifications;

  final String droneSize;

  final bool trainingSafetyRequired;
  final bool ndaRequired;

  final String requirementsNotes;
  final String serviceCategory;

  final String status;

  final DateTime? publishedAt;
  final DateTime? closedAt;
  final DateTime? cancelledAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String cancellationReason;

  final List<CompanyJobAttachmentModel> attachments;

  /// Present on GET /company/job-postings/{id}.
  /// It is usually absent from the My Jobs list response.
  final CompanyJobCompanyProfileModel? companyProfile;

  const CompanyJobPostingModel({
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
    this.requiredExperience = '',
    this.requiredCertifications = const [],
    this.droneSize = '',
    this.trainingSafetyRequired = false,
    this.ndaRequired = false,
    this.requirementsNotes = '',
    this.serviceCategory = '',
    this.status = '',
    this.publishedAt,
    this.closedAt,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
    this.cancellationReason = '',
    this.attachments = const [],
    this.companyProfile,
  });

  factory CompanyJobPostingModel.fromJson(Map<String, dynamic> json) {
    final companyRaw = json['company_profile'];

    return CompanyJobPostingModel(
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
      requiredExperience: _asString(json['required_experience']),
      requiredCertifications:
          _asStringList(json['required_certifications']),
      droneSize: _asString(json['drone_size']),
      trainingSafetyRequired:
          _asBool(json['training_safety_required']),
      ndaRequired: _asBool(json['nda_required']),
      requirementsNotes: _asString(json['requirements_notes']),
      serviceCategory: _asString(json['service_category']),
      status: _asString(json['status']),
      publishedAt: _asDate(json['published_at']),
      closedAt: _asDate(json['closed_at']),
      cancelledAt: _asDate(json['cancelled_at']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      cancellationReason: _asString(json['cancellation_reason']),
      attachments: _asAttachments(json['attachments']),
      companyProfile: companyRaw is Map
          ? CompanyJobCompanyProfileModel.fromJson(
              Map<String, dynamic>.from(companyRaw),
            )
          : null,
    );
  }
}

class CompanyJobAttachmentModel {
  final String type;
  final String name;
  final int size;
  final String url;

  const CompanyJobAttachmentModel({
    this.type = '',
    this.name = '',
    this.size = 0,
    this.url = '',
  });

  factory CompanyJobAttachmentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CompanyJobAttachmentModel(
      type: _asString(json['type']),
      name: _asString(json['name']),
      size: _asInt(json['size']) ?? 0,
      url: _asString(json['url']),
    );
  }

  bool get isImage => type.toLowerCase().startsWith('image/');
}

class CompanyJobCompanyProfileModel {
  final int id;
  final int? userId;
  final String companyName;
  final String industryType;
  final String description;
  final String country;
  final String state;
  final String city;
  final String address;
  final String website;

  const CompanyJobCompanyProfileModel({
    required this.id,
    this.userId,
    this.companyName = '',
    this.industryType = '',
    this.description = '',
    this.country = '',
    this.state = '',
    this.city = '',
    this.address = '',
    this.website = '',
  });

  factory CompanyJobCompanyProfileModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CompanyJobCompanyProfileModel(
      id: _asInt(json['id']) ?? 0,
      userId: _asInt(json['user_id']),
      companyName: _asString(json['company_name']),
      industryType: _asString(json['industry_type']),
      description: _asString(json['description']),
      country: _asString(json['country']),
      state: _asString(json['state']),
      city: _asString(json['city']),
      address: _asString(json['address']),
      website: _asString(json['website']),
    );
  }
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
  return text == '1' || text == 'true';
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];

  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

List<CompanyJobAttachmentModel> _asAttachments(dynamic value) {
  if (value is! List) return const [];

  return value
      .whereType<Map>()
      .map(
        (item) => CompanyJobAttachmentModel.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList();
}
