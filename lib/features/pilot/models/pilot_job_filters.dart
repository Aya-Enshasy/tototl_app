class PilotJobFilters {
  final String search;
  final String country;
  final String state;
  final String city;
  final String region;

  /// Legacy single-category value kept for compatibility with older callers.
  final String category;

  /// Phase 4: GET /jobs accepts more than one category.
  final List<String> categories;

  /// API values: fixed | daily | hourly | negotiable.
  final String paymentType;

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double? paymentMin;
  final double? paymentMax;
  final List<String> capabilities;

  /// API values: newest | pay | date
  final String sort;

  const PilotJobFilters({
    this.search = '',
    this.country = '',
    this.state = '',
    this.city = '',
    this.region = '',
    this.category = '',
    this.categories = const [],
    this.paymentType = '',
    this.dateFrom,
    this.dateTo,
    this.paymentMin,
    this.paymentMax,
    this.capabilities = const [],
    this.sort = 'newest',
  });

  List<String> get effectiveCategories {
    final source = categories.isNotEmpty
        ? categories
        : category.split(',');

    final seen = <String>{};
    final values = <String>[];

    for (final raw in source) {
      final value = raw.trim();
      if (value.isEmpty) continue;

      final key = value.toLowerCase();
      if (seen.add(key)) {
        values.add(value);
      }
    }

    return List.unmodifiable(values);
  }

  bool get hasCategoryFilter => effectiveCategories.isNotEmpty;

  PilotJobFilters copyWith({
    String? search,
    String? country,
    String? state,
    String? city,
    String? region,
    String? category,
    List<String>? categories,
    String? paymentType,
    DateTime? dateFrom,
    DateTime? dateTo,
    double? paymentMin,
    double? paymentMax,
    List<String>? capabilities,
    String? sort,
    bool clearDateFrom = false,
    bool clearDateTo = false,
    bool clearPaymentMin = false,
    bool clearPaymentMax = false,
    bool clearPaymentType = false,
  }) {
    final nextCategories = categories != null
        ? List<String>.from(categories)
        : category != null
        ? const <String>[]
        : this.categories;

    final nextLegacyCategory = category != null
        ? category
        : categories != null
        ? ''
        : this.category;

    return PilotJobFilters(
      search: search ?? this.search,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      region: region ?? this.region,
      category: nextLegacyCategory,
      categories: nextCategories,
      paymentType: clearPaymentType
          ? ''
          : (paymentType ?? this.paymentType),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      paymentMin:
      clearPaymentMin ? null : (paymentMin ?? this.paymentMin),
      paymentMax:
      clearPaymentMax ? null : (paymentMax ?? this.paymentMax),
      capabilities: capabilities ?? this.capabilities,
      sort: sort ?? this.sort,
    );
  }

  int get activeFilterCount {
    var count = 0;

    if (country.isNotEmpty) count++;
    if (state.isNotEmpty) count++;
    if (city.isNotEmpty) count++;
    if (region.isNotEmpty) count++;
    if (hasCategoryFilter) count++;
    if (paymentType.isNotEmpty) count++;
    if (dateFrom != null || dateTo != null) count++;
    if (paymentMin != null || paymentMax != null) count++;
    if (capabilities.isNotEmpty) count++;
    if (sort != 'newest') count++;

    return count;
  }

  bool get hasAdvancedFilters => activeFilterCount > 0;

  PilotJobFilters clearAdvanced() {
    return PilotJobFilters(search: search);
  }
}
