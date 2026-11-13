class SubscriptionEntitlementsModel {
  final SubscriptionLimitsModel limits;
  final List<dynamic> features;

  const SubscriptionEntitlementsModel({
    this.limits = const SubscriptionLimitsModel(),
    this.features = const [],
  });

  factory SubscriptionEntitlementsModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final rawLimits = json['limits'];
    final rawFeatures = json['features'];

    return SubscriptionEntitlementsModel(
      limits: rawLimits is Map
          ? SubscriptionLimitsModel.fromJson(
        Map<String, dynamic>.from(rawLimits),
      )
          : const SubscriptionLimitsModel(),
      features: rawFeatures is List
          ? List<dynamic>.unmodifiable(rawFeatures)
          : const [],
    );
  }

  bool get hasUnlimitedCompanyJobPostings =>
      limits.maxActiveJobPostingsPerCompany == null;

  bool get hasUnlimitedPilotApplications =>
      limits.maxActiveApplicationsPerPilot == null;

  bool hasFeature(String feature) {
    final wanted = feature.trim().toLowerCase();

    if (wanted.isEmpty) {
      return false;
    }

    for (final item in features) {
      if (item is String &&
          item.trim().toLowerCase() == wanted) {
        return true;
      }

      if (item is Map) {
        final map = Map<String, dynamic>.from(item);

        for (final key in const [
          'key',
          'name',
          'code',
          'feature',
          'slug',
        ]) {
          final value = map[key]?.toString().trim().toLowerCase();

          if (value == wanted) {
            return true;
          }
        }
      }
    }

    return false;
  }
}

class SubscriptionLimitsModel {
  final int? maxActiveJobPostingsPerCompany;
  final int? maxActiveApplicationsPerPilot;

  const SubscriptionLimitsModel({
    this.maxActiveJobPostingsPerCompany,
    this.maxActiveApplicationsPerPilot,
  });

  factory SubscriptionLimitsModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return SubscriptionLimitsModel(
      maxActiveJobPostingsPerCompany: _asNullableInt(
        json['max_active_job_postings_per_company'],
      ),
      maxActiveApplicationsPerPilot: _asNullableInt(
        json['max_active_applications_per_pilot'],
      ),
    );
  }

  bool get companyJobPostingsUnlimited =>
      maxActiveJobPostingsPerCompany == null;

  bool get pilotApplicationsUnlimited =>
      maxActiveApplicationsPerPilot == null;

  String get companyJobPostingsLimitLabel {
    final limit = maxActiveJobPostingsPerCompany;

    return limit == null
        ? 'Unlimited'
        : '$limit active job${limit == 1 ? '' : 's'}';
  }

  String get pilotApplicationsLimitLabel {
    final limit = maxActiveApplicationsPerPilot;

    return limit == null
        ? 'Unlimited'
        : '$limit active application${limit == 1 ? '' : 's'}';
  }

  bool canCreateCompanyJob({
    required int activeCount,
  }) {
    final limit = maxActiveJobPostingsPerCompany;

    if (limit == null) {
      return true;
    }

    return activeCount < limit;
  }

  bool canCreatePilotApplication({
    required int activeCount,
  }) {
    final limit = maxActiveApplicationsPerPilot;

    if (limit == null) {
      return true;
    }

    return activeCount < limit;
  }

  int? remainingCompanyJobSlots({
    required int activeCount,
  }) {
    final limit = maxActiveJobPostingsPerCompany;

    if (limit == null) {
      return null;
    }

    final remaining = limit - activeCount;
    return remaining < 0 ? 0 : remaining;
  }

  int? remainingPilotApplicationSlots({
    required int activeCount,
  }) {
    final limit = maxActiveApplicationsPerPilot;

    if (limit == null) {
      return null;
    }

    final remaining = limit - activeCount;
    return remaining < 0 ? 0 : remaining;
  }
}

int? _asNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  final text = value.toString().trim();

  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }

  return int.tryParse(text);
}
