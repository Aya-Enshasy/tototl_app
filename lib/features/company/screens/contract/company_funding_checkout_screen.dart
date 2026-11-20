import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../services/company_collection_service.dart';
import '../../services/pending_stripe_checkout_store.dart';
import '../../services/stripe_checkout_url.dart';
import 'stripe_checkout_webview_screen.dart';

/// Kept compatible with CompanyContractDetailScreen's navigation callback.
enum CompanyFundingOutcome { collectionStarted, collectionUnconfirmed, fundingConfirmed }

/// Server-quoted funding -> POST /fund with method=redirect -> Stripe Checkout
/// -> webhook-confirmed contract status. A redirect is never payment proof.
class CompanyFundingCheckoutScreen extends StatefulWidget {
  const CompanyFundingCheckoutScreen({
    super.key,
    required this.contractId,
    required this.amountLabel,
  });

  final int contractId;
  final String amountLabel;

  @override
  State<CompanyFundingCheckoutScreen> createState() =>
      _CompanyFundingCheckoutScreenState();
}

class _CompanyFundingCheckoutScreenState
    extends State<CompanyFundingCheckoutScreen> with WidgetsBindingObserver {
  late final CompanyCollectionService _service =
      CompanyCollectionService(ApiClient());

  Map<String, dynamic>? _quote;
  ContractFundingSnapshot? _snapshot;
  Uri? _checkoutUri;
  Timer? _statusTimer;
  Timer? _quoteRetryTicker;
  DateTime? _quoteCooldownUntil;
  bool _bootstrapInFlight = false;
  bool _autoCheckoutScheduled = false;
  bool _fundingNavigationCompleted = false;
  bool _autoFundStarted = false;
  int _pollCount = 0;
  bool _preparing = true;
  bool _creatingPayment = false;
  bool _checking = false;
  bool _openedProvider = false;
  bool _paymentStarted = false;
  int? _pendingAttemptId;
  String? _latestAttemptStatus;
  String? _error;

  String _tr(String en, String ar, String de) =>
      switch (AppLanguage.locale.value.languageCode) {
        'ar' => ar,
        'de' => de,
        _ => en,
      };

  bool get _funded => _snapshot?.isFunded == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_bootstrap());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The checkout route itself reconciles after returning from Chrome.
    // Avoid a competing API poll while Stripe / 3DS is on screen.
    if (state == AppLifecycleState.resumed && _paymentStarted &&
        !_openedProvider && !_checking && !_funded) {
      unawaited(_checkServerStatus());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusTimer?.cancel();
    _quoteRetryTicker?.cancel();
    super.dispose();
  }

  int get _quoteRetrySeconds {
    final until = _quoteCooldownUntil;
    if (until == null) return 0;
    final remaining = until.difference(DateTime.now()).inSeconds + 1;
    return remaining > 0 ? remaining : 0;
  }

  void _pauseQuoteRetries(int seconds) {
    final bounded = seconds.clamp(8, 120).toInt();
    _quoteCooldownUntil = DateTime.now().add(Duration(seconds: bounded));
    _quoteRetryTicker?.cancel();
    _quoteRetryTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _quoteRetrySeconds == 0) {
        timer.cancel();
      }
      if (mounted) setState(() {});
    });
  }

  String _safeError(Object e) {
    if (e is CompanyPaymentApiException) {
      final suffix = e.requestId == null || e.requestId!.isEmpty
          ? ''
          : ' (Request: ${e.requestId})';
      if (e.statusCode == 429) {
        return _tr(
          'The server is rate-limiting payment quotes. Please retry after the countdown.',
          'السيرفر محدد عدد طلبات عروض السعر. أعيدي المحاولة بعد العد التنازلي.',
          'Zu viele Anfragen. Bitte nach dem Countdown erneut versuchen.',
        ) + suffix;
      }
      if (e.isPendingAttemptConflict) {
        return _tr('This contract already has a pending payment attempt. '
            'Resume that checkout or ask support to recover/cancel it; do not pay twice.',
            'في محاولة دفع معلّقة على هذا العقد. كمّلي رابط الدفع القديم، '
            'أو اطلبي من الدعم استعادة الرابط أو إلغاء المحاولة؛ لا تعيدي الدفع.',
            'Es gibt bereits einen ausstehenden Zahlungsversuch.') + suffix;
      }
      if (e.statusCode == 422) {
        return _tr('The server rejected this payment request: ',
            'السيرفر رفض طلب الدفع والسبب: ',
            'Der Server hat die Zahlung abgelehnt: ') + e.message + suffix;
      }
      return _tr('Payment API error (HTTP ${e.statusCode ?? 'network'}): ',
          'خطأ في طلب الدفع (HTTP ${e.statusCode ?? 'network'}): ',
          'Zahlungsfehler (HTTP ${e.statusCode ?? 'Netzwerk'}): ') +
          e.message + suffix;
    }
    if (e is DioException) {
      final http = e.response?.statusCode;
      if (http == 429) {
        return _tr('Too many requests. Retry after a short pause.',
            'طلبات كثيرة. حاولي بعد قليل.', 'Zu viele Anfragen.');
      }
      if (http == 502 || http == 503) {
        return _tr('Payment service is temporarily unavailable.',
            'خدمة الدفع غير متاحة مؤقتًا.', 'Zahlungsdienst nicht verfügbar.');
      }
      if (http == 401) {
        return _tr('Please sign in again.', 'يرجى تسجيل الدخول مجددًا.',
            'Bitte erneut anmelden.');
      }
      if (http == 403) {
        return _tr('This company cannot fund this contract.',
            'هذا الحساب غير مخوّل بتمويل العقد.', 'Keine Berechtigung.');
      }
      if (http == 422) {
        return _tr('Quote expired or was rejected. Check the contract status.',
            'عرض السعر منتهي أو مرفوض. افحصي حالة العقد.',
            'Angebot abgelaufen oder abgelehnt.');
      }
    }
    if (e is FormatException) {
      return _tr('The server returned incomplete payment information.',
          'السيرفر رجّع معلومات دفع غير مكتملة.',
          'Unvollständige Zahlungsdaten vom Server.');
    }
    return _tr('Could not complete this request. Check payment status.',
        'تعذّر إكمال الطلب. افحصي حالة الدفع.',
        'Anfrage fehlgeschlagen. Zahlungsstatus prüfen.');
  }

  /// Updating the screen from the authoritative contract must never fail
  /// because optional encrypted cache cleanup throws or takes too long.
  Future<void> _clearCompletedPaymentCache() async {
    for (final task in <Future<void> Function()>[
      () => PendingStripeCheckoutStore.clear(widget.contractId),
      () => PendingStripeQuoteStore.clear(widget.contractId),
      () => PendingStripeAttemptStore.clear(widget.contractId),
    ]) {
      try {
        await task().timeout(const Duration(seconds: 3));
      } catch (_) { /* Local cleanup is best-effort. */ }
    }
  }

  /// Checkout opens automatically whenever the backend has issued a complete
  /// Stripe URL. Merely having an attempt ID is NOT enough to open WebView.
  void _scheduleExistingCheckout() {
    if (_autoCheckoutScheduled || _openedProvider || _funded ||
        _checkoutUri == null || !mounted) return;
    _autoCheckoutScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_funded && _checkoutUri != null) {
        unawaited(_openCheckout());
      }
    });
  }

  /// The contract detail screen refreshes itself after this route pops.
  /// Never claim success from a redirect alone; only a funded server snapshot
  /// may trigger this navigation.
  void _returnWhenFunded() {
    if (_fundingNavigationCompleted || !mounted || !_funded || _openedProvider) return;
    _fundingNavigationCompleted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (kDebugMode) debugPrint(
          '[TOTOTL][PAYMENT][ROUTE_CLOSE] reason=server_confirmed '
          'contract=${widget.contractId}');
        Navigator.of(context).pop(CompanyFundingOutcome.fundingConfirmed);
      }
    });
  }

  Future<void> _bootstrap() async {
    if (_bootstrapInFlight || _creatingPayment || _checking ||
        _quoteRetrySeconds > 0) return;
    _bootstrapInFlight = true;
    _autoFundStarted = false;
    if (mounted) setState(() { _preparing = true; _error = null; });
    try {
      // GET contract before starting any payment to avoid duplicate charges.
      final snapshot = await _service.contractSnapshot(widget.contractId);
      if (!mounted) return;
      final savedUri = await PendingStripeCheckoutStore.read(widget.contractId);
      var savedAttempt = await PendingStripeAttemptStore.read(widget.contractId);
      if (!mounted) return;
      _snapshot = snapshot;
      _latestAttemptStatus = snapshot.paymentStatus;
      // If Laravel returned a resumable URL on GET, do not lose it when the
      // user leaves this screen. This never creates a fresh Stripe attempt.
      if (!snapshot.isFunded && snapshot.checkoutUri != null) {
        try {
          await PendingStripeCheckoutStore.save(
            widget.contractId, snapshot.checkoutUri!,
          ).timeout(const Duration(seconds: 3));
        } catch (_) { /* Optional encrypted persistence. */ }
      }

      if (snapshot.isFunded) {
        // Persisted-cache failures must never hide a server-confirmed payment.
        if (mounted) setState(() {
          _checkoutUri = null;
          _quote = null;
          _paymentStarted = false;
          _pendingAttemptId = null;
          _error = null;
        });
        await _clearCompletedPaymentCache();
        _returnWhenFunded();
        return;
      }
      // Some backends report payment=paid before contract=active. Never
      // issue another funding POST or reopen an already-paid Stripe session.
      if (isProviderPaymentConfirmedStatus(snapshot.paymentStatus)) {
        if (mounted) setState(() {
          _paymentStarted = true;
          _checkoutUri = null;
          _quote = null;
          _pendingAttemptId = snapshot.paymentId ?? savedAttempt;
        });
        _beginStatusWatch();
        return;
      }
      // A known attempt must be inspected BEFORE issuing a new quote or fund.
      // Old contract endpoints sometimes omit payment/client_action fields.
      String? attemptState;
      if (savedAttempt == null && savedUri == null &&
          snapshot.paymentStatus.isEmpty &&
          snapshot.contractStatus == 'accepted') {
        // Do not ask for a NEW quote if an older (possibly another build's)
        // payment is still waiting on Stripe. The contract detail response
        // does not always include payment status or redirect details.
        savedAttempt = await _service.findPendingAttemptForContract(widget.contractId);
        if (savedAttempt != null) {
          attemptState = 'pending';
          await PendingStripeAttemptStore.save(widget.contractId, savedAttempt);
        }
      }
      _pendingAttemptId = snapshot.paymentId ?? savedAttempt;
      if (savedAttempt != null && snapshot.paymentStatus.isEmpty &&
          attemptState == null) {
        try {
          attemptState = await _service.paymentStatusById(savedAttempt, contractId: widget.contractId);
        } catch (_) {
          // Fail closed on an unknown payment state: never charge twice.
        }
      }
      if (snapshot.hasPendingPayment ||
          (savedUri != null && snapshot.paymentStatus.isEmpty &&
              attemptState != 'failed' && attemptState != 'cancelled') ||
          (savedAttempt != null &&
              attemptState != 'failed' && attemptState != 'cancelled')) {
        // A pending attempt may already have a provider URL in the company
        // payments API. GET is safe and never starts another payment.
        Uri? existingUri = snapshot.checkoutUri ?? savedUri;
        final confirmed = isProviderPaymentConfirmedStatus(
            attemptState ?? snapshot.paymentStatus);
        if (existingUri == null && !confirmed) {
          try {
            existingUri = await _service.recoverExistingCheckout(
              widget.contractId,
              paymentId: snapshot.paymentId ?? savedAttempt,
            );
            if (existingUri != null) {
              await PendingStripeCheckoutStore.save(widget.contractId, existingUri)
                  .timeout(const Duration(seconds: 3));
            }
          } catch (_) { /* Keep the payment guard if server GET fails. */ }
        }
        if (!mounted) return;
        setState(() {
          _paymentStarted = true;
          _checkoutUri = confirmed ? null : existingUri;
          _quote = null;
          _error = null;
          _latestAttemptStatus = attemptState ?? snapshot.paymentStatus;
        });
        if (existingUri != null && !confirmed) _scheduleExistingCheckout();
        _beginStatusWatch();
        return;
      }
      if (snapshot.paymentStatus == 'failed' ||
          snapshot.paymentStatus == 'cancelled' ||
          attemptState == 'failed' || attemptState == 'cancelled') {
        await PendingStripeCheckoutStore.clear(widget.contractId);
        await PendingStripeQuoteStore.clear(widget.contractId);
        await PendingStripeAttemptStore.clear(widget.contractId);
        _pendingAttemptId = null;
      }
      // A still-valid, encrypted per-account quote avoids repeated quote POSTs
      // each time the company reopens the same contract payment screen.
      final storedQuote = await PendingStripeQuoteStore.read(widget.contractId);
      if (!mounted) return;
      final quote = storedQuote ?? await _service.quote(widget.contractId);
      if (storedQuote == null) {
        try {
          await PendingStripeQuoteStore.save(widget.contractId, quote);
        } catch (_) {
          // Optional persistence must never block a valid payment quote.
        }
      }
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _checkoutUri = null;
        _paymentStarted = false;
        _latestAttemptStatus = null;
        _quoteCooldownUntil = null;
      });
      if (kDebugMode) {
        debugPrint('[TOTOTL][STRIPE][QUOTE_OK] '
            'contract=${widget.contractId} cache=${storedQuote != null}');
      }
      // Opening the funding route is the user's intent to reach Stripe.
      // The user sees and approves the final amount on Stripe itself.
      if (!_autoFundStarted) {
        _autoFundStarted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_paymentStarted && !_funded && _quote != null) {
            unawaited(_startFunding(skipDialog: true));
          }
        });
      }
    } catch (e) {
      if (e is CompanyPaymentApiException && e.statusCode == 429) {
        _pauseQuoteRetries(e.retryAfterSeconds ?? 20);
      } else if (e is DioException && e.response?.statusCode == 429) {
        _pauseQuoteRetries(
          int.tryParse(e.response?.headers.value('retry-after') ?? '') ?? 20,
        );
      }
      if (kDebugMode) {
        final httpCode = e is CompanyPaymentApiException
            ? e.statusCode
            : e is DioException
                ? e.response?.statusCode
                : null;
        debugPrint('[TOTOTL][STRIPE][BOOTSTRAP_FAIL] '
            'contract=${widget.contractId} type=${e.runtimeType} '
            'http=${httpCode ?? '-'}');
      }
      if (e is CompanyPaymentApiException && e.isPendingAttemptConflict) {
        final attemptId = e.pendingAttemptId;
        if (attemptId != null) {
          try {
            await PendingStripeAttemptStore.save(widget.contractId, attemptId);
          } catch (_) { /* Best-effort local record. */ }
        }
        if (mounted) setState(() {
          _paymentStarted = true;
          _pendingAttemptId = attemptId;
          _quote = null;
          _error = null;
        });
      } else {
        if (mounted) setState(() => _error = _safeError(e));
      }
    } finally {
      _bootstrapInFlight = false;
      if (mounted) setState(() => _preparing = false);
    }
  }

  Future<void> _startFunding({bool skipDialog = false}) async {
    final quote = _quote;
    if (quote == null || _creatingPayment || _paymentStarted || _funded) return;
    final reference = quote['quote_reference']?.toString().trim() ?? '';
    if (reference.isEmpty) return;
    final expiry = DateTime.tryParse('${quote['expires_at'] ?? ''}');
    if (expiry != null && !expiry.isAfter(DateTime.now())) {
      await PendingStripeQuoteStore.clear(widget.contractId);
      if (!mounted) return;
      setState(() {
        _quote = null;
        _error = _tr('Quote expired. Request a new quote.',
            'انتهت صلاحية عرض السعر. اطلبي عرضًا جديدًا.',
            'Angebot abgelaufen.');
      });
      return;
    }

    if (!skipDialog) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(_tr('Confirm Stripe checkout', 'تأكيد الدفع عبر Stripe',
              'Stripe-Zahlung bestätigen'), style: const TextStyle(fontSize: 15)),
          content: Text(
            _tr('You will be redirected to Stripe to pay the server-quoted total. '
                    'The contract is not funded until the backend confirms payment.',
                'رح تفتح صفحة Stripe لدفع المبلغ النهائي حسب عرض السيرفر. '
                    'العقد مش ممول إلا بعد تأكيد الدفع من السيرفر.',
                'Weiterleitung zu Stripe. Erst die Serverbestätigung zählt.'),
            style: const TextStyle(fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_tr('Cancel', 'إلغاء', 'Abbrechen')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_tr('Continue', 'متابعة', 'Weiter')),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() { _creatingPayment = true; _error = null; });
    var fundRequestWasSent = false;
    try {
      // Mutation preflight. A stale widget/cache cannot authorize a second
      // financial attempt after another device already started the checkout.
      final latest = await _service.contractSnapshot(widget.contractId);
      if (!mounted) return;
      if (latest.isFunded || latest.hasPendingPayment ||
          isProviderPaymentConfirmedStatus(latest.paymentStatus)) {
        setState(() {
          _snapshot = latest;
          _paymentStarted = latest.hasPendingPayment ||
              isProviderPaymentConfirmedStatus(latest.paymentStatus);
          _pendingAttemptId = latest.paymentId;
          _checkoutUri = isProviderPaymentConfirmedStatus(latest.paymentStatus)
              ? null
              : (latest.checkoutUri ?? _checkoutUri);
          _quote = null;
        });
        if (latest.paymentId != null) {
          try {
            await PendingStripeAttemptStore.save(widget.contractId, latest.paymentId!);
          } catch (_) { /* Local persistence is best effort. */ }
        }
        if (_checkoutUri == null && !isProviderPaymentConfirmedStatus(latest.paymentStatus)) {
          try {
            final existingUri = await _service.recoverExistingCheckout(
                widget.contractId, paymentId: latest.paymentId);
            if (existingUri != null && mounted) {
              setState(() => _checkoutUri = existingUri);
              await PendingStripeCheckoutStore.save(widget.contractId, existingUri)
                  .timeout(const Duration(seconds: 3));
            }
          } catch (_) { /* Do not create a duplicate payment on GET failure. */ }
        }
        if (_checkoutUri != null &&
            !isProviderPaymentConfirmedStatus(latest.paymentStatus)) {
          _scheduleExistingCheckout();
        }
        if (latest.isFunded) _returnWhenFunded();
        return;
      }
      fundRequestWasSent = true;
      final result = await _service.fundWithRedirect(widget.contractId, reference);
      // Important: the POST has already started a financial attempt. Save its
      // recoverable Checkout URL BEFORE any UI navigation or other store write.
      // Storage errors cannot stop the browser from opening or cause a retry.
      if (result.checkoutUri != null) {
        try {
          await PendingStripeCheckoutStore.save(widget.contractId, result.checkoutUri!)
              .timeout(const Duration(seconds: 3));
        } catch (_) {
          // Cache is optional; still open the exact server-issued session.
        }
      }
      if (result.paymentId != null) {
        try {
          await PendingStripeAttemptStore.save(widget.contractId, result.paymentId!)
              .timeout(const Duration(seconds: 3));
        } catch (_) { /* An attempt marker is optional, never a reason to retry funding. */ }
      }
      try {
        await PendingStripeQuoteStore.clear(widget.contractId)
            .timeout(const Duration(seconds: 3));
      } catch (_) { /* The quote is invalidated by _paymentStarted regardless. */ }
      if (!mounted) return;
      setState(() {
        _snapshot = result;
        _paymentStarted = true;
        _checkoutUri = result.checkoutUri;
        _pendingAttemptId = result.paymentId;
        _latestAttemptStatus = result.paymentStatus;
      });
      if (kDebugMode) {
        debugPrint('[TOTOTL][STRIPE][FUND_STARTED] '
            'contract=${widget.contractId} status=${result.paymentStatus} '
            'hasRedirect=${result.checkoutUri != null}');
      }
      if (result.checkoutUri != null) {
        _autoCheckoutScheduled = true;
        await _openCheckout();
      } else if (!result.isFunded) {
        setState(() => _error = _tr(
              'Payment was started but the server did not return a Stripe redirect link. '
                  'Check payment status rather than submitting another charge.',
              'بدأ طلب الدفع لكن السيرفر ما رجّع رابط Stripe. '
                  'افحصي حالة الدفع بدل إعادة طلب تحصيل جديد.',
              'Zahlung gestartet, aber kein Stripe-Link erhalten.',
            ));
      }
      _beginStatusWatch();
    } catch (e) {
      if (!fundRequestWasSent) {
        // A read-only preflight failure never started a payment. Keep the
        // quoted amount and let the user retry after connectivity improves.
        if (mounted) setState(() => _error = _safeError(e));
        return;
      }
      // Financial POSTs are never retried automatically. A 422 saying
      // "Attempt #N is still pending" proves the server already has an
      // attempt; asking for another quote/fund cannot solve it.
      if (e is CompanyPaymentApiException && e.isPendingAttemptConflict) {
        final attemptId = e.pendingAttemptId;
        if (attemptId != null) {
          try {
            await PendingStripeAttemptStore.save(widget.contractId, attemptId);
          } catch (_) { /* Secure persistence is best-effort. */ }
        }
        if (!mounted) return;
        setState(() {
          _pendingAttemptId = attemptId ?? _pendingAttemptId;
          _latestAttemptStatus = 'pending';
          _paymentStarted = true;
          _quote = null;
          _error = null;
        });
        await PendingStripeQuoteStore.clear(widget.contractId);
        if (kDebugMode) debugPrint('[TOTOTL][STRIPE][PENDING_CONFLICT] '
            'contract=${widget.contractId} attempt=${_pendingAttemptId ?? '-'} '
            'http=${e.statusCode}');
        // Request the status once. GET cannot recreate the old Stripe URL.
        await _checkServerStatus();
      } else {
        // For network timeouts, the server might have accepted the mutation.
        // Keep payment blocked until an authoritative status check.
        if (mounted) setState(() => _paymentStarted = true);
        await _checkServerStatus();
        if (!mounted) return;
        if (e is CompanyPaymentApiException && e.statusCode == 422 &&
            _snapshot?.hasPendingPayment != true &&
            _pendingAttemptId == null) {
          await PendingStripeQuoteStore.clear(widget.contractId);
          if (!mounted) return;
          setState(() {
            _paymentStarted = false;
            _quote = null;
            _error = _safeError(e);
          });
        } else {
          setState(() => _error = _safeError(e));
        }
      }
    } finally {
      if (mounted) setState(() => _creatingPayment = false);
    }
  }

  Future<void> _openCheckout() async {
    final uri = _checkoutUri;
    if (uri == null || !mounted || _openedProvider || _funded ||
        isProviderPaymentConfirmedStatus(_latestAttemptStatus)) return;
    if (!isTrustedStripeCheckoutUri(uri)) {
      setState(() => _error = _tr('Invalid Stripe session link.',
          'رابط جلسة Stripe غير صالح.', 'Ungültiger Stripe-Link.'));
      return;
    }
    _openedProvider = true;
    try {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => StripeCheckoutWebViewScreen(checkoutUri: uri),
        ),
      );
    } finally {
      _openedProvider = false;
      if (mounted) {
        unawaited(_checkServerStatus());
        _beginStatusWatch();
      }
    }
  }

  /// Reconcile without continuously scanning the entire payment collection.
  /// The old implementation made four sequential HTTP requests per tick:
  /// contract -> payments -> collect attempt -> payments. With the actual
  /// backend latency, each tick could run ~20 seconds and provoke 429s.
  Future<void> _checkServerStatus() async {
    if (!mounted || _checking || _openedProvider) return;
    setState(() { _checking = true; _error = null; });
    try {
      final result = await _service.contractSnapshot(widget.contractId);
      if (!mounted) return;

      if (result.isFunded) {
        _statusTimer?.cancel();
        setState(() {
          _snapshot = result;
          _latestAttemptStatus = result.paymentStatus;
          _checkoutUri = null;
          _paymentStarted = false;
          _pendingAttemptId = null;
          _error = null;
        });
        await _clearCompletedPaymentCache();
        _returnWhenFunded();
        return;
      }

      final trackedId = result.paymentId ?? _pendingAttemptId;
      String? attemptStatus;
      Uri? recoveredUri = result.checkoutUri;
      // One attempt-specific GET is enough for normal polling. Its response
      // may carry a client_action URL not present in contract details.
      if (trackedId != null &&
          (result.paymentStatus.isEmpty || recoveredUri == null)) {
        try {
          final attempt = await _service.paymentAttemptStatus(
            widget.contractId, trackedId);
          final payload = attempt['data'];
          attemptStatus = CompanyCollectionService.collectionAttemptStatus(
              payload);
          recoveredUri ??= ContractFundingSnapshot.extractCheckoutUri(payload);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[TOTOTL][STRIPE][ATTEMPT_READ_UNAVAILABLE] '
                'contract=${widget.contractId} attempt=$trackedId '
                'type=${e.runtimeType}');
          }
          // Missing status is NOT permission to create another charge.
        }
      }
      if (!mounted) return;
      final observedStatus = attemptStatus ?? result.paymentStatus;
      final providerConfirmed = isProviderPaymentConfirmedStatus(observedStatus);
      final usableCheckoutUri = providerConfirmed ? null : recoveredUri;
      setState(() {
        _snapshot = result;
        _pendingAttemptId = trackedId;
        if (observedStatus.isNotEmpty) {
          _latestAttemptStatus = observedStatus;
        }
        if (usableCheckoutUri != null) _checkoutUri ??= usableCheckoutUri;
        if (result.hasPendingPayment || trackedId != null ||
            const {'pending', 'processing', 'requires_action'}.contains(observedStatus) ||
            isProviderPaymentConfirmedStatus(observedStatus)) {
          _paymentStarted = true;
        }
      });

      if (providerConfirmed) {
        // The provider may be paid while contract activation is still pending.
        // Never reopen a paid Checkout or claim the contract is Active.
        if (mounted) setState(() => _checkoutUri = null);
        try {
          await PendingStripeCheckoutStore.clear(widget.contractId)
              .timeout(const Duration(seconds: 3));
        } catch (_) { /* Best-effort cleanup. */ }
      } else if (usableCheckoutUri != null) {
        try {
          await PendingStripeCheckoutStore.save(widget.contractId, usableCheckoutUri)
              .timeout(const Duration(seconds: 3));
        } catch (_) { /* The URL still works even if local storage fails. */ }
        _scheduleExistingCheckout();
      }

      if (const {'failed', 'cancelled'}.contains(observedStatus)) {
        _statusTimer?.cancel();
        await _clearCompletedPaymentCache();
        if (mounted) setState(() {
          _paymentStarted = false;
          _pendingAttemptId = null;
          _checkoutUri = null;
          _quote = null;
          _error = _tr(
            'The previous attempt was closed. Open funding to request a new quote.',
            'المحاولة السابقة انتهت. افتحي التمويل لطلب عرض سعر جديد.',
            'Vorheriger Zahlungsversuch wurde beendet.');
        });
      }
      if (kDebugMode) {
        debugPrint('[TOTOTL][STRIPE][SERVER_STATUS] '
            'contract=${widget.contractId} contractState=${result.contractStatus} '
            'paymentState=$observedStatus funded=${result.isFunded} '
            'hasCheckout=${_checkoutUri != null}');
      }
    } catch (e) {
      if (mounted) setState(() => _error = _safeError(e));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _beginStatusWatch() {
    _statusTimer?.cancel();
    if (!mounted || !_paymentStarted || _funded) return;
    _pollCount = 0;
    // No infinite requests when the provider has no confirmation yet.
    // The customer may return later; explicit status checks remain available.
    _statusTimer = Timer.periodic(const Duration(seconds: 40), (timer) {
      if (!mounted || _funded || _pollCount >= 6) {
        timer.cancel();
        return;
      }
      if (!_openedProvider && !_checking) {
        _pollCount++;
        unawaited(_checkServerStatus());
      }
    });
  }

  Widget _line(String label, Object? raw, {bool bold = false}) {
    final value = raw is Map ? raw['amount'] : raw;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11))),
          Text('${value ?? '—'}',
              style: TextStyle(fontSize: 12,
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rtl = AppLanguage.locale.value.languageCode == 'ar';
    final q = _quote;
    final snapshot = _snapshot;
    final pending = _paymentStarted && !_funded;
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          title: Text(_tr('Contract funding', 'تمويل العقد', 'Vertragszahlung'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.navy, AppColors.blue],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_tr('Contract #${widget.contractId} · Stripe',
                        'عقد #${widget.contractId} · Stripe',
                        'Vertrag #${widget.contractId} · Stripe'),
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 10),
                    Text(q == null
                          ? widget.amountLabel
                          : '${q['currency'] ?? ''} ${q['total_payable_amount'] ?? ''}',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 25, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 7),
                    Text(q == null
                        ? _tr('Contract value only. Final fees come from the server quote.',
                            'هذه قيمة العقد فقط، والرسوم النهائية حسب عرض السيرفر.',
                            'Nur Vertragswert. Endbetrag aus Serverangebot.')
                        : _tr('Final payable total calculated by the server.',
                            'الإجمالي النهائي محسوب من السيرفر.',
                            'Gesamtbetrag vom Server berechnet.'),
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_preparing || _creatingPayment)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (q != null && !_autoFundStarted) Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_tr('Review payment & fees', 'مراجعة المبلغ والرسوم',
                          'Betrag und Gebühren prüfen'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      _line(_tr('Contract value', 'قيمة العقد', 'Vertragswert'), q['contract_amount']),
                      _line(_tr('Platform fee', 'رسوم المنصة', 'Plattformgebühr'), q['base_company_platform_fee']),
                      _line(_tr('Processing cost', 'تكلفة المعالجة', 'Bearbeitungsgebühr'), q['payment_cost_recovery']),
                      _line(_tr('Fixed fee', 'رسوم ثابتة', 'Festgebühr'), q['fixed_fee_amount']),
                      const Divider(),
                      _line(_tr('Total payable', 'الإجمالي المطلوب', 'Gesamtbetrag'),
                          '${q['currency'] ?? ''} ${q['total_payable_amount'] ?? ''}', bold: true),
                    ],
                  ),
                ),
              ),
              if (pending || _funded) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(_funded ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                            color: _funded ? Colors.green : AppColors.blue, size: 29),
                        const SizedBox(height: 7),
                        Text(_funded
                              ? _tr('Funding confirmed by the server',
                                  'تم تأكيد التمويل من السيرفر', 'Zahlung bestätigt')
                              : isProviderPaymentConfirmedStatus(_latestAttemptStatus ?? snapshot?.paymentStatus)
                                  ? _tr('Payment recorded; waiting for contract activation',
                                      'الدفع مسجّل، بانتظار تفعيل العقد من السيرفر',
                                      'Zahlung erfasst. Vertragsaktivierung ausstehend')
                                  : _tr('Awaiting provider confirmation',
                                      'بانتظار تأكيد مزود الدفع', 'Warten auf Zahlungsbestätigung'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(_tr('Contract: ${snapshot?.contractStatus ?? '—'} · Payment: ${(_latestAttemptStatus?.isNotEmpty == true ? _latestAttemptStatus : snapshot?.paymentStatus) ?? '—'}',
                                'العقد: ${snapshot?.contractStatus ?? '—'} · الدفع: ${(_latestAttemptStatus?.isNotEmpty == true ? _latestAttemptStatus : snapshot?.paymentStatus) ?? '—'}',
                                'Vertrag: ${snapshot?.contractStatus ?? '—'} · Zahlung: ${(_latestAttemptStatus?.isNotEmpty == true ? _latestAttemptStatus : snapshot?.paymentStatus) ?? '—'}'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11)),
                        if (snapshot?.isTestSession == true)
                          Text(_tr('Stripe test checkout — no real money is charged.',
                              'Stripe تجريبي — ما في خصم حقيقي.',
                              'Stripe-Testmodus – kein echtes Geld.'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10,
                                  color: Colors.deepOrange)),
                      ],
                    ),
                  ),
                ),
              ],
              if (pending && _checkoutUri == null &&
                  !isProviderPaymentConfirmedStatus(
                      _latestAttemptStatus ?? snapshot?.paymentStatus)) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _tr('Waiting for the existing payment session. Stripe opens automatically if a valid Checkout URL is supplied by the server. No new payment will be created.',
                        'جارٍ فحص جلسة الدفع الحالية. إذا أرسل السيرفر رابط Stripe صالحًا، رح تنفتح الصفحة تلقائيًا بدون إنشاء دفعة ثانية.',
                        'Bestehende Zahlungssitzung wird geprüft.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: const Color(0xFFFFF3F1),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_error!, style: const TextStyle(fontSize: 11,
                        color: Color(0xFFAE2828))),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (!_paymentStarted && !_funded && q != null && !_autoFundStarted)
                FilledButton.icon(
                  onPressed: _creatingPayment || _preparing ? null : _startFunding,
                  icon: const Icon(Icons.lock_outline_rounded),
                  label: Text(_creatingPayment
                      ? _tr('Starting Stripe...', 'جارٍ بدء Stripe...', 'Stripe wird geöffnet...')
                      : _tr('Continue to Stripe checkout', 'المتابعة إلى دفع Stripe',
                          'Weiter zum Stripe-Checkout')),
                ),
              if (_checkoutUri != null && !_funded) ...[
                FilledButton.icon(
                  onPressed: _openedProvider ? null : _openCheckout,
                  icon: const Icon(Icons.open_in_browser_rounded),
                  label: Text(_tr('Continue secure payment', 'متابعة الدفع الآمن',
                      'Sichere Zahlung fortsetzen')),
                ),
                const SizedBox(height: 7),
              ],
              if (_error != null)
                OutlinedButton.icon(
                  onPressed: _checking ? null : _checkServerStatus,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(_checking
                      ? _tr('Checking...', 'جارٍ التحقق...', 'Prüfung...')
                      : _tr('Check server payment status', 'فحص حالة الدفع من السيرفر',
                          'Zahlungsstatus prüfen')),
                ),
              if (!_paymentStarted && !_preparing && q == null && !_funded)
                OutlinedButton.icon(
                  onPressed: _quoteRetrySeconds > 0 ? null : _bootstrap,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(_quoteRetrySeconds > 0
                      ? _tr('Retry available in $_quoteRetrySeconds s',
                          'إعادة المحاولة بعد $_quoteRetrySeconds ثانية',
                          'Erneut versuchen in $_quoteRetrySeconds s')
                      : _tr('Retry quote', 'إعادة طلب عرض السعر',
                          'Angebot erneut anfordern')),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  if (kDebugMode) debugPrint(
                    '[TOTOTL][PAYMENT][ROUTE_CLOSE] reason=return_button '
                    'contract=${widget.contractId}');
                  Navigator.of(context).pop(
                    _funded
                      ? CompanyFundingOutcome.fundingConfirmed
                      : _paymentStarted
                        ? CompanyFundingOutcome.collectionStarted
                        : CompanyFundingOutcome.collectionUnconfirmed,
                  );
                },
                child: Text(_tr('Return to contract', 'الرجوع للعقد',
                    'Zurück zum Vertrag')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
