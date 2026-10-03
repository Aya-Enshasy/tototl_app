class CompanyContractPaymentModel {
  final int id;
  final int contractId;
  final double amount;
  final String currency;
  final String status;
  final DateTime? fundedAt;
  final DateTime? eligibleReleaseAt;
  final DateTime? releasedAt;
  final String provider;
  final String transactionReference;
  final String failureReason;
  final String refundReference;

  const CompanyContractPaymentModel({
    required this.id,
    required this.contractId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.fundedAt,
    required this.eligibleReleaseAt,
    required this.releasedAt,
    required this.provider,
    required this.transactionReference,
    required this.failureReason,
    required this.refundReference,
  });

  factory CompanyContractPaymentModel.fromJson(Map<String, dynamic> json) {
    return CompanyContractPaymentModel(
      id: _asInt(json['id']) ?? 0,
      contractId: _asInt(json['contract_id']) ?? 0,
      amount: _asDouble(json['amount']) ?? 0,
      currency: _asString(json['currency']),
      status: _asString(json['status']),
      fundedAt: _asDate(json['funded_at']),
      eligibleReleaseAt: _asDate(json['eligible_release_at']),
      releasedAt: _asDate(json['released_at']),
      provider: _asString(json['provider']),
      transactionReference: _asString(json['transaction_reference']),
      failureReason: _asString(json['failure_reason']),
      refundReference: _asString(json['refund_reference']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'contract_id': contractId,
        'amount': amount,
        'currency': currency,
        'status': status,
        'funded_at': fundedAt?.toIso8601String(),
        'eligible_release_at': eligibleReleaseAt?.toIso8601String(),
        'released_at': releasedAt?.toIso8601String(),
        'provider': provider.isEmpty ? null : provider,
        'transaction_reference':
            transactionReference.isEmpty ? null : transactionReference,
        'failure_reason': failureReason.isEmpty ? null : failureReason,
        'refund_reference': refundReference.isEmpty ? null : refundReference,
      };

  String get statusLabel => _pretty(status);
  bool get isFunded => status.trim().toLowerCase() == 'funded';
  bool get isFailed => status.trim().toLowerCase() == 'failed';
}

class CompanyContractModel {
  final int id;
  final int jobPostingId;
  final int companyProfileId;
  final int pilotProfileId;
  final int jobApplicationId;
  final double amount;
  final String currency;
  final String paymentType;
  final String terms;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? terminatedAt;
  final DateTime? rejectedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<CompanyContractPaymentModel> payments;

  const CompanyContractModel({
    required this.id,
    required this.jobPostingId,
    required this.companyProfileId,
    required this.pilotProfileId,
    required this.jobApplicationId,
    required this.amount,
    required this.currency,
    required this.paymentType,
    required this.terms,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.startedAt,
    required this.submittedAt,
    required this.completedAt,
    required this.cancelledAt,
    required this.terminatedAt,
    required this.rejectedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.payments,
  });

  factory CompanyContractModel.fromJson(Map<String, dynamic> json) {
    final rawPayments = json['payments'];
    final parsedPayments = <CompanyContractPaymentModel>[];
    if (rawPayments is List) {
      for (final raw in rawPayments) {
        if (raw is Map) {
          parsedPayments.add(
            CompanyContractPaymentModel.fromJson(
              Map<String, dynamic>.from(raw),
            ),
          );
        }
      }
    }

    return CompanyContractModel(
      id: _asInt(json['id']) ?? 0,
      jobPostingId: _asInt(json['job_posting_id']) ?? 0,
      companyProfileId: _asInt(json['company_profile_id']) ?? 0,
      pilotProfileId: _asInt(json['pilot_profile_id']) ?? 0,
      jobApplicationId: _asInt(json['job_application_id']) ?? 0,
      amount: _asDouble(json['amount']) ?? 0,
      currency: _asString(json['currency']),
      paymentType: _asString(json['payment_type']),
      terms: _asString(json['terms']),
      startDate: _asDate(json['start_date']),
      endDate: _asDate(json['end_date']),
      status: _asString(json['status']),
      startedAt: _asDate(json['started_at']),
      submittedAt: _asDate(json['submitted_at']),
      completedAt: _asDate(json['completed_at']),
      cancelledAt: _asDate(json['cancelled_at']),
      terminatedAt: _asDate(json['terminated_at']),
      rejectedAt: _asDate(json['rejected_at']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      payments: List.unmodifiable(parsedPayments),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'job_posting_id': jobPostingId,
        'company_profile_id': companyProfileId,
        'pilot_profile_id': pilotProfileId,
        'job_application_id': jobApplicationId,
        'amount': amount,
        'currency': currency,
        'payment_type': paymentType,
        'terms': terms.isEmpty ? null : terms,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'status': status,
        'started_at': startedAt?.toIso8601String(),
        'submitted_at': submittedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'cancelled_at': cancelledAt?.toIso8601String(),
        'terminated_at': terminatedAt?.toIso8601String(),
        'rejected_at': rejectedAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'payments': payments.map((item) => item.toJson()).toList(),
      };

  String get normalizedStatus => status.trim().toLowerCase();
  bool get isPending => normalizedStatus == 'pending';
  bool get isAccepted => normalizedStatus == 'accepted';
  bool get isActive => normalizedStatus == 'active';
  bool get isInProgress => normalizedStatus == 'in_progress';
  bool get isSubmitted => normalizedStatus == 'submitted';
  bool get isCompleted => normalizedStatus == 'completed';
  bool get isCancelled => normalizedStatus == 'cancelled';
  bool get isTerminated => normalizedStatus == 'terminated';
  bool get isRejected => normalizedStatus == 'rejected';
  bool get canFund => isAccepted;
  bool get canReviewSubmission => isSubmitted;
  bool get canCancelBeforeWork => isPending || isAccepted || isActive;
  bool get canTerminateMidWork => isInProgress;
  bool get canConfigureLocation =>
      isActive || isInProgress || isSubmitted;
  bool get shouldShowLocationSection =>
      isAccepted || isActive || isInProgress || isSubmitted || isCompleted;

  bool get isTerminal =>
      isCompleted || isCancelled || isTerminated || isRejected;

  String get statusLabel => _pretty(status).isEmpty ? 'Unknown' : _pretty(status);
  String get paymentTypeLabel => _pretty(paymentType);
  String get amountLabel {
    final amountText = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    final code = currency.trim().toUpperCase();
    return code.isEmpty ? amountText : '$amountText $code';
  }

  CompanyContractPaymentModel? get latestPayment =>
      payments.isEmpty ? null : payments.last;
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
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}
String _pretty(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return '';
  return clean
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part.length == 1
          ? part.toUpperCase()
          : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}
