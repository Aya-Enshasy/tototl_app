import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/country_model.dart';

class LocationService {
  Future<List<CountryModel>> getCountries() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/all_countries.json',
    );

    final Map<String, dynamic> jsonData =
    json.decode(jsonString);

    final List<dynamic> countries =
        jsonData['data'] ?? [];

    return countries
        .map(
          (country) => CountryModel.fromJson(
        country as Map<String, dynamic>,
      ),
    )
        .toList();
  }
}