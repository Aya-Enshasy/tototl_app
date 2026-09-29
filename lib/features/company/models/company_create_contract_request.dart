class CompanyCreateContractRequest {
  final double amount;
  final String currency;
  final String paymentType;
  final String? terms;
  final DateTime startDate;
  final DateTime? endDate;

  const CompanyCreateContractRequest({
    required this.amount,
    required this.currency,
    required this.paymentType,
    required this.startDate,
    this.terms,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    final cleanTerms = terms?.trim();

    return <String, dynamic>{
      'amount': amount,
      'currency': currency.trim().toUpperCase(),
      'payment_type': paymentType.trim().toLowerCase(),
      'start_date': _dateOnlyToApi(startDate),
      'terms': cleanTerms == null || cleanTerms.isEmpty ? null : cleanTerms,
      'end_date': endDate == null ? null : _dateOnlyToApi(endDate!),
    };
  }

  static String _dateOnlyToApi(DateTime value) {
    return DateTime.utc(
      value.year,
      value.month,
      value.day,
    ).toIso8601String();
  }
}
