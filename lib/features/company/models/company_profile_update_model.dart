// ============================================================================
// COMPANY PROFILE UPDATE REQUEST
// ============================================================================

class CompanyProfileUpdateRequest {
  final String companyName;
  final String? industryType;
  final String? description;
  final String? country;
  final String? state;
  final String? city;
  final String? address;
  final String? website;

  final List<CompanyWorkRegionInput>
  workRegions;

  const CompanyProfileUpdateRequest({
    required this.companyName,
    this.industryType,
    this.description,
    this.country,
    this.state,
    this.city,
    this.address,
    this.website,
    this.workRegions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'company_name':
      companyName.trim(),

      'industry_type':
      _nullable(
        industryType,
      ),

      'description':
      _nullable(
        description,
      ),

      'country':
      _nullable(
        country,
      ),

      'state':
      _nullable(
        state,
      ),

      'city':
      _nullable(
        city,
      ),

      'address':
      _nullable(
        address,
      ),

      'website':
      _nullable(
        website,
      ),

      'work_regions':
      workRegions
          .map(
            (region) =>
            region.toJson(),
      )
          .toList(),
    };
  }
}

// ============================================================================
// COMPANY WORK REGION INPUT
// ============================================================================

class CompanyWorkRegionInput {
  final String country;
  final String? state;
  final String? city;

  const CompanyWorkRegionInput({
    required this.country,
    this.state,
    this.city,
  });

  Map<String, dynamic> toJson() {
    return {
      'country':
      country.trim(),

      'state':
      _nullable(
        state,
      ),

      'city':
      _nullable(
        city,
      ),
    };
  }
}

// ============================================================================
// HELPER
// ============================================================================

String? _nullable(
    String? value,
    ) {
  if (value == null) {
    return null;
  }

  final clean =
  value.trim();

  return clean.isEmpty
      ? null
      : clean;
}
