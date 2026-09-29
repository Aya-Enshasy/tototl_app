class PaymentModel {
  final int id;
  final int contractId;
  final int? jobPostingId;
  final int? companyProfileId;
  final int? pilotProfileId;
  final double amount;
  final String currency;
  final String status;
  final String provider;
  final String transactionReference;
  final DateTime? fundedAt;
  final DateTime? eligibleReleaseAt;
  final DateTime? releasedAt;
  final String failureReason;
  final String refundReference;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PaymentModel({
    required this.id,
    required this.contractId,
    required this.jobPostingId,
    required this.companyProfileId,
    required this.pilotProfileId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.provider,
    required this.transactionReference,
    required this.fundedAt,
    required this.eligibleReleaseAt,
    required this.releasedAt,
    required this.failureReason,
    required this.refundReference,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: _asInt(json['id']) ?? 0,
      contractId: _asInt(json['contract_id']) ?? 0,
      jobPostingId: _asInt(json['job_posting_id']),
      companyProfileId: _asInt(json['company_profile_id']),
      pilotProfileId: _asInt(json['pilot_profile_id']),
      amount: _asDouble(json['amount']) ?? 0,
      currency: _asString(json['currency']).toUpperCase(),
      status: _asString(json['status']).toLowerCase(),
      provider: _asString(json['provider']),
      transactionReference: _asString(json['transaction_reference']),
      fundedAt: _asDate(json['funded_at']),
      eligibleReleaseAt: _asDate(json['eligible_release_at']),
      releasedAt: _asDate(json['released_at']),
      failureReason: _asString(json['failure_reason']),
      refundReference: _asString(json['refund_reference']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
    );
  }

  bool get isPending => status == 'pending';
  bool get isFunded => status == 'funded';
  bool get isHeld => status == 'held';
  bool get isReleasePending => status == 'release_pending';
  bool get isReleased => status == 'released';
  bool get isFailed => status == 'failed';
  bool get isRefunded => status == 'refunded';
  bool get isPartiallyRefunded => status == 'partially_refunded';
  bool get isCancelled => status == 'cancelled';

  String get statusLabel => _pretty(status.isEmpty ? 'pending' : status);

  String get amountLabel {
    final code = currency.isEmpty ? 'USD' : currency;
    final value = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    return '$code $value';
  }

  String get releaseSummary {
    if (isReleased) return 'Released to pilot';
    if (isReleasePending) return 'Waiting for automatic release';
    if (isFunded || isHeld) return 'Funds secured';
    if (isFailed) return 'Payment failed';
    if (isRefunded) return 'Payment refunded';
    if (isPartiallyRefunded) return 'Partially refunded';
    if (isCancelled) return 'Payment cancelled';
    return 'Payment pending';
  }
}

String _asString(dynamic value) => value == null ? '' : value.toString().trim();
int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _asDate(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : DateTime.tryParse(text);
}

String _pretty(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return '';
  return clean
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}
