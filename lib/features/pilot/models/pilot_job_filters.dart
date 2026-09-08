class PilotJobFilters {
  final String search;
  final String country;
  final String state;
  final String city;
  final String region;
  final String category;
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
    this.dateFrom,
    this.dateTo,
    this.paymentMin,
    this.paymentMax,
    this.capabilities = const [],
    this.sort = 'newest',
  });

  PilotJobFilters copyWith({
    String? search,
    String? country,
    String? state,
    String? city,
    String? region,
    String? category,
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
  }) {
    return PilotJobFilters(
      search: search ?? this.search,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      region: region ?? this.region,
      category: category ?? this.category,
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
    if (category.isNotEmpty) count++;
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
