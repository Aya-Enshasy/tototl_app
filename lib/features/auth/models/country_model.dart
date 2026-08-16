class CountryModel {
  final String iso2;
  final String iso3;
  final String name;
  final String dialCode;
  final List<String> cities;

  CountryModel({
    required this.iso2,
    required this.iso3,
    required this.name,
    required this.dialCode,
    required this.cities,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      iso2: json['iso2'] ?? '',
      iso3: json['iso3'] ?? '',
      name: json['country'] ?? '',
      dialCode: json['dialCode'] ?? '',
      cities: List<String>.from(
        json['cities'] ?? [],
      ),
    );
  }
}