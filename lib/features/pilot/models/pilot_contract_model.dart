class PilotContractModel {
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

  final List<dynamic> payments;

  const PilotContractModel({
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

  factory PilotContractModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return PilotContractModel(
      id: _asInt(json['id']) ?? 0,
      jobPostingId:
      _asInt(json['job_posting_id']) ?? 0,
      companyProfileId:
      _asInt(json['company_profile_id']) ?? 0,
      pilotProfileId:
      _asInt(json['pilot_profile_id']) ?? 0,
      jobApplicationId:
      _asInt(json['job_application_id']) ?? 0,
      amount:
      _asDouble(json['amount']) ?? 0,
      currency:
      _asString(json['currency']).toUpperCase(),
      paymentType:
      _asString(json['payment_type']).toLowerCase(),
      terms:
      _asString(json['terms']),
      startDate:
      _asDate(json['start_date']),
      endDate:
      _asDate(json['end_date']),
      status:
      _asString(json['status'])
          .trim()
          .toLowerCase(),
      startedAt:
      _asDate(json['started_at']),
      submittedAt:
      _asDate(json['submitted_at']),
      completedAt:
      _asDate(json['completed_at']),
      cancelledAt:
      _asDate(json['cancelled_at']),
      terminatedAt:
      _asDate(json['terminated_at']),
      rejectedAt:
      _asDate(json['rejected_at']),
      createdAt:
      _asDate(json['created_at']),
      updatedAt:
      _asDate(json['updated_at']),
      payments:
      json['payments'] is List
          ? List<dynamic>.from(
        json['payments'],
      )
          : const [],
    );
  }

  // ===========================================================================
  // STATUS
  // ===========================================================================

  /// Canonical status value used by UI, workflow and live-refresh logic.
  ///
  /// Examples:
  /// "In_Progress" -> "in_progress"
  /// " ACTIVE "     -> "active"
  String get normalizedStatus =>
      status.trim().toLowerCase();

  bool get isPending =>
      normalizedStatus == 'pending';

  bool get isAccepted =>
      normalizedStatus == 'accepted';

  bool get isActive =>
      normalizedStatus == 'active';

  bool get isInProgress =>
      normalizedStatus == 'in_progress';

  bool get isSubmitted =>
      normalizedStatus == 'submitted';

  bool get isCompleted =>
      normalizedStatus == 'completed';

  bool get isCancelled =>
      normalizedStatus == 'cancelled';

  bool get isTerminated =>
      normalizedStatus == 'terminated';

  bool get isRejected =>
      normalizedStatus == 'rejected';

  // ===========================================================================
  // WORKFLOW PERMISSIONS
  // ===========================================================================

  bool get canPilotDecide =>
      isPending;

  bool get canViewExactLocation =>
      isActive ||
          isInProgress ||
          isSubmitted ||
          isCompleted;

  bool get canStartWork =>
      isActive;

  bool get canSubmitWork =>
      isInProgress;

  bool get isAwaitingReview =>
      isSubmitted;

  bool get isTerminal =>
      isCompleted ||
          isCancelled ||
          isTerminated ||
          isRejected;

  // ===========================================================================
  // LABELS
  // ===========================================================================

  String get statusLabel =>
      _pretty(
        normalizedStatus.isEmpty
            ? 'pending'
            : normalizedStatus,
      );

  String get paymentTypeLabel =>
      _pretty(
        paymentType.trim().isEmpty
            ? 'fixed'
            : paymentType,
      );

  String get amountLabel {
    final cleanCurrency =
    currency.trim().isEmpty
        ? 'USD'
        : currency.trim();

    final amountText =
    amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);

    return '$cleanCurrency $amountText';
  }

  String get dateRangeLabel {
    final start =
    _dateOnly(startDate);

    final end =
    _dateOnly(endDate);

    if (start == '—' && end == '—') {
      return 'Schedule not specified';
    }

    if (end == '—') {
      return 'Starts $start';
    }

    return '$start → $end';
  }

  String get createdLabel =>
      _dateTime(createdAt);

  // ===========================================================================
  // COPY WITH
  // ===========================================================================

  PilotContractModel copyWith({
    String? status,
    DateTime? startedAt,
    DateTime? submittedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? terminatedAt,
    DateTime? rejectedAt,
    DateTime? updatedAt,
    List<dynamic>? payments,
  }) {
    return PilotContractModel(
      id: id,
      jobPostingId: jobPostingId,
      companyProfileId: companyProfileId,
      pilotProfileId: pilotProfileId,
      jobApplicationId: jobApplicationId,
      amount: amount,
      currency: currency,
      paymentType: paymentType,
      terms: terms,
      startDate: startDate,
      endDate: endDate,

      status:
      (status ?? this.status)
          .trim()
          .toLowerCase(),

      startedAt:
      startedAt ?? this.startedAt,

      submittedAt:
      submittedAt ?? this.submittedAt,

      completedAt:
      completedAt ?? this.completedAt,

      cancelledAt:
      cancelledAt ?? this.cancelledAt,

      terminatedAt:
      terminatedAt ?? this.terminatedAt,

      rejectedAt:
      rejectedAt ?? this.rejectedAt,

      createdAt:
      createdAt,

      updatedAt:
      updatedAt ?? this.updatedAt,

      payments:
      payments ?? this.payments,
    );
  }
}

// =============================================================================
// PARSERS
// =============================================================================

String _asString(dynamic value) {
  return value == null
      ? ''
      : value.toString().trim();
}

int? _asInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
    value.toString(),
  );
}

double? _asDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
    value.toString(),
  );
}

DateTime? _asDate(dynamic value) {
  if (value == null) {
    return null;
  }

  final text =
  value.toString().trim();

  if (text.isEmpty) {
    return null;
  }

  return DateTime.tryParse(
    text,
  );
}

String _pretty(String value) {
  final clean =
  value.trim();

  if (clean.isEmpty) {
    return '';
  }

  return clean
      .split(
    RegExp(r'[_\s-]+'),
  )
      .where(
        (part) => part.isNotEmpty,
  )
      .map(
        (part) =>
    '${part[0].toUpperCase()}'
        '${part.substring(1).toLowerCase()}',
  )
      .join(' ');
}

String _dateOnly(
    DateTime? value,
    ) {
  if (value == null) {
    return '—';
  }

  final local =
  value.toLocal();

  final month =
  local.month
      .toString()
      .padLeft(2, '0');

  final day =
  local.day
      .toString()
      .padLeft(2, '0');

  return '${local.year}-$month-$day';
}

String _dateTime(
    DateTime? value,
    ) {
  if (value == null) {
    return '—';
  }

  final local =
  value.toLocal();

  final month =
  local.month
      .toString()
      .padLeft(2, '0');

  final day =
  local.day
      .toString()
      .padLeft(2, '0');

  final hour =
  local.hour
      .toString()
      .padLeft(2, '0');

  final minute =
  local.minute
      .toString()
      .padLeft(2, '0');

  return '${local.year}-$month-$day · $hour:$minute';
}