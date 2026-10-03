class SubscriptionPlanModel {
  final int id;
  final String name;
  final String price;
  final String currency;
  final String billingPeriod;
  final List<String> features;
  final List<String> limits;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SubscriptionPlanModel({
    required this.id,
    this.name = '',
    this.price = '0',
    this.currency = '',
    this.billingPeriod = 'free',
    this.features = const [],
    this.limits = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: _asInt(json['id']) ?? 0,
      name: _asString(json['name']),
      price: _asString(json['price'], fallback: '0'),
      currency: _asString(json['currency']),
      billingPeriod: _asString(json['billing_period'], fallback: 'free').toLowerCase(),
      features: _dynamicEntries(json['features']),
      limits: _dynamicEntries(json['limits']),
      isActive: _asBool(json['is_active'], fallback: true),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
    );
  }

  bool get isFree => billingPeriod == 'free' || (double.tryParse(price) ?? 0) == 0;

  String get displayName => name.trim().isEmpty ? 'Plan #$id' : name.trim();

  String get priceLabel {
    if (isFree) return 'Free';
    final value = price.trim().isEmpty ? '0' : price.trim();
    final curr = currency.trim();
    return curr.isEmpty ? value : '$value $curr';
  }

  String get periodLabel {
    switch (billingPeriod) {
      case 'monthly':
        return 'Monthly';
      case 'annual':
        return 'Annual';
      case 'custom':
        return 'Custom';
      default:
        return 'Free';
    }
  }
}

class UserSubscriptionModel {
  final int id;
  final int userId;
  final int subscriptionPlanId;
  final String status;
  final DateTime startDate;
  final DateTime? expirationDate;
  final DateTime? renewalDate;
  final String providerReference;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserSubscriptionModel({
    required this.id,
    required this.userId,
    required this.subscriptionPlanId,
    required this.status,
    required this.startDate,
    this.expirationDate,
    this.renewalDate,
    this.providerReference = '',
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UserSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionModel(
      id: _asInt(json['id']) ?? 0,
      userId: _asInt(json['user_id']) ?? 0,
      subscriptionPlanId: _asInt(json['subscription_plan_id']) ?? 0,
      status: _asString(json['status'], fallback: 'active').toLowerCase(),
      startDate: _asDate(json['start_date']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      expirationDate: _asDate(json['expiration_date']),
      renewalDate: _asDate(json['renewal_date']),
      providerReference: _asString(json['provider_reference']),
      cancelledAt: _asDate(json['cancelled_at']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
    );
  }

  bool get isActive => status == 'active';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => status == 'expired';
  bool get isPastDue => status == 'past_due';

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Active';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Cancelled';
      case 'past_due':
        return 'Past Due';
      default:
        return _pretty(status);
    }
  }
}

class SubscriptionPaymentModel {
  final int id;
  final int userSubscriptionId;
  final int userId;
  final String amount;
  final String currency;
  final String provider;
  final String transactionReference;
  final String status;
  final String failureReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SubscriptionPaymentModel({
    required this.id,
    required this.userSubscriptionId,
    required this.userId,
    this.amount = '0',
    this.currency = '',
    this.provider = '',
    this.transactionReference = '',
    this.status = 'pending',
    this.failureReason = '',
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPaymentModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPaymentModel(
      id: _asInt(json['id']) ?? 0,
      userSubscriptionId: _asInt(json['user_subscription_id']) ?? 0,
      userId: _asInt(json['user_id']) ?? 0,
      amount: _asString(json['amount'], fallback: '0'),
      currency: _asString(json['currency']),
      provider: _asString(json['provider']),
      transactionReference: _asString(json['transaction_reference']),
      status: _asString(json['status'], fallback: 'pending').toLowerCase(),
      failureReason: _asString(json['failure_reason']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
    );
  }

  String get amountLabel {
    final curr = currency.trim();
    return curr.isEmpty ? amount : '$amount $curr';
  }

  String get statusLabel => _pretty(status);
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String _asString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase() ?? '';
  if (const {'1', 'true', 'yes', 'active'}.contains(text)) return true;
  if (const {'0', 'false', 'no', 'inactive'}.contains(text)) return false;
  return fallback;
}

DateTime? _asDate(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

List<String> _dynamicEntries(dynamic raw) {
  final values = <String>[];

  void add(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && !values.contains(text)) values.add(text);
  }

  if (raw is List) {
    for (final item in raw) {
      if (item is Map) {
        for (final entry in item.entries) {
          final key = entry.key.toString().trim();
          final value = entry.value;
          if (value is bool) {
            if (value) add(key);
          } else if (value != null) {
            add(key.isEmpty ? value : '$key: $value');
          }
        }
      } else {
        add(item);
      }
    }
  } else if (raw is Map) {
    for (final entry in raw.entries) {
      final key = entry.key.toString().trim();
      final value = entry.value;
      if (value is bool) {
        if (value) add(key);
      } else if (value != null) {
        add(key.isEmpty ? value : '$key: $value');
      }
    }
  } else if (raw != null) {
    add(raw);
  }

  return List.unmodifiable(values);
}

String _pretty(String value) {
  final clean = value.trim().replaceAll('_', ' ');
  if (clean.isEmpty) return 'Unknown';
  return clean
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
