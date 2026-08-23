class PilotProfileUpdateRequest {
  final String? bio;
  final int experienceYears;
  final String? nationality;
  final DateTime? dateOfBirth;
  final String? linkedinUrl;
  final String? previousCompany;
  final List<String> languages;
  final String? currentCountry;
  final String? currentState;
  final String? currentCity;
  final List<PilotWorkRegionInput> workRegions;

  const PilotProfileUpdateRequest({
    this.bio,
    required this.experienceYears,
    this.nationality,
    this.dateOfBirth,
    this.linkedinUrl,
    this.previousCompany,
    this.languages = const [],
    this.currentCountry,
    this.currentState,
    this.currentCity,
    this.workRegions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'bio': _nullable(bio),
      'experience_years': experienceYears,
      'nationality': _nullable(nationality),
      'date_of_birth': dateOfBirth == null
          ? null
          : DateTime.utc(
        dateOfBirth!.year,
        dateOfBirth!.month,
        dateOfBirth!.day,
      ).toIso8601String(),
      'linkedin_url': _nullable(linkedinUrl),
      'previous_company': _nullable(previousCompany),
      'languages': languages.isEmpty ? null : languages,
      'current_country': _nullable(currentCountry),
      'current_state': _nullable(currentState),
      'current_city': _nullable(currentCity),
      'work_regions': workRegions.map((region) => region.toJson()).toList(),
    };
  }
}

class PilotWorkRegionInput {
  final String country;
  final String? state;
  final String? city;

  const PilotWorkRegionInput({
    required this.country,
    this.state,
    this.city,
  });

  Map<String, dynamic> toJson() {
    return {
      'country': country.trim(),
      'state': _nullable(state),
      'city': _nullable(city),
    };
  }

  String get displayLabel {
    final values = <String>[
      city ?? '',
      state ?? '',
      country,
    ].where((value) => value.trim().isNotEmpty).toList();

    return values.isEmpty ? 'Region' : values.join(', ');
  }
}

String? _nullable(String? value) {
  if (value == null) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}
