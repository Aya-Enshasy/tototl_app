import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/user_session_storage.dart';
import 'stripe_checkout_url.dart';

/// The checkout URL is a temporary bearer capability. Persist it only in
/// encrypted, per-account storage so a checkout can be resumed after a
/// navigation interruption, without exposing it to logs or other accounts.
class PendingStripeCheckoutStore {
  PendingStripeCheckoutStore._();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const Duration _maxAge = Duration(hours: 24);

  static Future<String?> _key(int contractId) async {
    final userId = await UserSessionStorage.getUserId();
    if (userId == null || userId <= 0) return null;
    return 'tototl_stripe_checkout_v1_${userId}_$contractId';
  }

  static Future<void> save(int contractId, Uri checkout) async {
    if (!isTrustedStripeCheckoutUri(checkout)) return;
    final key = await _key(contractId);
    if (key == null) return;
    await _storage.write(
      key: key,
      value: jsonEncode({
        'uri': checkout.toString(),
        'saved_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  static Future<Uri?> read(int contractId) async {
    final key = await _key(contractId);
    if (key == null) return null;
    try {
      final raw = await _storage.read(key: key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final saved = DateTime.tryParse('${decoded['saved_at']}');
      if (saved == null ||
          DateTime.now().toUtc().difference(saved.toUtc()) > _maxAge) {
        await _storage.delete(key: key);
        return null;
      }
      final uri = Uri.tryParse('${decoded['uri']}');
      if (isTrustedStripeCheckoutUri(uri)) {
        return uri;
      }
    } catch (_) {
      // A corrupt local cache must not prevent the payment-status check.
    }
    return null;
  }

  static Future<void> clear(int contractId) async {
    final key = await _key(contractId);
    if (key != null) await _storage.delete(key: key);
  }
}

/// Quote cache scoped to the authenticated company and contract. It avoids
/// issuing a new POST /quote every time the same payment page is reopened.
/// A saved quote is NOT proof of funding; /fund still validates it server-side.
class PendingStripeQuoteStore {
  PendingStripeQuoteStore._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const Duration _maxAge = Duration(minutes: 12);

  static Future<String?> _key(int contractId) async {
    final userId = await UserSessionStorage.getUserId();
    if (userId == null || userId <= 0) return null;
    return 'tototl_stripe_quote_v1_${userId}_$contractId';
  }

  static Future<void> save(
    int contractId,
    Map<String, dynamic> quote,
  ) async {
    final key = await _key(contractId);
    if (key == null || !_stillValid(quote)) return;
    await _storage.write(
      key: key,
      value: jsonEncode({
        'quote': quote,
        'saved_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  static bool _stillValid(Map<String, dynamic> quote) {
    final reference = quote['quote_reference']?.toString().trim() ?? '';
    final expires = DateTime.tryParse('${quote['expires_at'] ?? ''}');
    // Leave a minute to complete the confirmation flow.
    return reference.isNotEmpty &&
        expires != null &&
        expires.toUtc().isAfter(
          DateTime.now().toUtc().add(const Duration(minutes: 1)),
        );
  }

  static Future<Map<String, dynamic>?> read(int contractId) async {
    final key = await _key(contractId);
    if (key == null) return null;
    try {
      final raw = await _storage.read(key: key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['quote'] is! Map) return null;
      final saved = DateTime.tryParse('${decoded['saved_at']}');
      if (saved == null ||
          DateTime.now().toUtc().difference(saved.toUtc()) > _maxAge) {
        await _storage.delete(key: key);
        return null;
      }
      final quote = Map<String, dynamic>.from(decoded['quote'] as Map);
      if (!_stillValid(quote)) {
        await _storage.delete(key: key);
        return null;
      }
      return quote;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear(int contractId) async {
    final key = await _key(contractId);
    if (key != null) await _storage.delete(key: key);
  }
}


/// A marker for a known in-flight funding attempt. Account-scoped and
/// encrypted. This is intentionally separate from a Checkout URL, because an
/// old attempt may be pending without a resumable URL in the API response.
class PendingStripeAttemptStore {
  PendingStripeAttemptStore._();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> _key(int contractId) async {
    final userId = await UserSessionStorage.getUserId();
    if (userId == null || userId <= 0) return null;
    return 'tototl_pending_fund_attempt_v1_${userId}_$contractId';
  }

  static Future<void> save(int contractId, int attemptId) async {
    final key = await _key(contractId);
    if (key == null || attemptId <= 0) return;
    await _storage.write(key: key, value: attemptId.toString());
  }

  static Future<int?> read(int contractId) async {
    final key = await _key(contractId);
    if (key == null) return null;
    try {
      final value = int.tryParse(await _storage.read(key: key) ?? '');
      return value != null && value > 0 ? value : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear(int contractId) async {
    final key = await _key(contractId);
    if (key != null) await _storage.delete(key: key);
  }
}
