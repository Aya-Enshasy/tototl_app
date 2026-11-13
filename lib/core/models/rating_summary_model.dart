
class RatingSummaryModel {
  final String? average;
  final int count;

  const RatingSummaryModel({
    this.average,
    this.count = 0,
  });

  factory RatingSummaryModel.fromJson(Map<String, dynamic> json) {
    return RatingSummaryModel(
      average: _asNullableString(json['average']),
      count: _asInt(json['count']) ?? 0,
    );
  }

  static RatingSummaryModel? tryParse(dynamic value) {
    if (value is! Map) return null;

    return RatingSummaryModel.fromJson(
      Map<String, dynamic>.from(value),
    );
  }

  double? get averageValue {
    final value = average?.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return double.tryParse(value);
  }

  bool get hasRating => count > 0 && averageValue != null;

  String get averageLabel {
    final value = averageValue;

    if (value == null) return 'No ratings yet';

    return value.toStringAsFixed(1);
  }

  String get reviewsCountLabel {
    if (count == 0) return 'No reviews';
    if (count == 1) return '1 review';

    return '$count reviews';
  }

  String get fullLabel {
    if (!hasRating) return 'No ratings yet';

    return '$averageLabel · $reviewsCountLabel';
  }
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;

  final text = value.toString().trim();

  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }

  return text;
}

int? _asInt(dynamic value) {
  if (value == null) return null;

  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value.toString());
}