import 'package:flutter/material.dart';

class CompanyJobCategoryAssets {
  CompanyJobCategoryAssets._();

  static const String inspection =
      'assets/images/Inspection.png';

  static const String mapping =
      'assets/images/Mapping.png';

  static const String photography =
      'assets/images/Photography.png';

  static const String construction =
      'assets/images/Construction.png';

  static const String surveying =
      'assets/images/Surveying.png';

  static const String other =
      'assets/images/Other.png';

  static String forCategory(String rawCategory) {
    final value =
    rawCategory.trim().toLowerCase();

    if (value.contains('inspection')) {
      return inspection;
    }

    if (value.contains('mapping')) {
      return mapping;
    }

    if (value.contains('photography') ||
        value.contains('photo')) {
      return photography;
    }

    if (value.contains('construction')) {
      return construction;
    }

    if (value.contains('surveying') ||
        value.contains('survey')) {
      return surveying;
    }

    return other;
  }

  static IconData fallbackIcon(
      String rawCategory,
      ) {
    final value =
    rawCategory.trim().toLowerCase();

    if (value.contains('inspection')) {
      return Icons.manage_search_rounded;
    }

    if (value.contains('mapping')) {
      return Icons.map_outlined;
    }

    if (value.contains('photography') ||
        value.contains('photo')) {
      return Icons.photo_camera_outlined;
    }

    if (value.contains('construction')) {
      return Icons.construction_outlined;
    }

    if (value.contains('surveying') ||
        value.contains('survey')) {
      return Icons.straighten_rounded;
    }

    return Icons.flight_takeoff_rounded;
  }
}
