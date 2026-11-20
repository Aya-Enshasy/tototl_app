import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/theme/app_colors.dart';
import '../../services/stripe_checkout_url.dart';

/// Opens Stripe-hosted Checkout in a real browser surface first (Android
/// Custom Tabs / iOS SFSafariViewController), not an embedded WebView.
/// Embedded WebView opens automatically on emulators without a browser.
/// Returning from any browser never marks a payment successful: the caller
/// refreshes the authenticated contract and payment status from Laravel.
/// Keep this class name so existing routes remain source-compatible.
class StripeCheckoutWebViewScreen extends StatefulWidget {
  const StripeCheckoutWebViewScreen({
    super.key,
    required this.checkoutUri,
  });

  final Uri checkoutUri;

  @override
  State<StripeCheckoutWebViewScreen> createState() =>
      _StripeCheckoutWebViewScreenState();
}

class _StripeCheckoutWebViewScreenState
    extends State<StripeCheckoutWebViewScreen> with WidgetsBindingObserver {
  WebViewController? _controller;
  bool _launching = false;
  bool _browserLaunched = false;
  bool _leftApp = false;
  bool _returnedFromBrowser = false;
  bool _embeddedFallback = false;
  bool _webLoading = false;
  bool _closing = false;
  String? _error;

  String _tr(String en, String ar, String de) =>
      switch (AppLanguage.locale.value.languageCode) {
        'ar' => ar,
        'de' => de,
        _ => en,
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openSecureBrowser();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // An Android browser, permission sheet, payment keyboard or Custom Tab
    // can temporarily pause/resume the app. A resume is NOT a Stripe return
    // nor evidence of payment. Never pop the Checkout route from here: doing
    // so caused TOTOTL to jump back a screen before Checkout was completed.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_browserLaunched) _leftApp = true;
    } else if (state == AppLifecycleState.resumed &&
        _browserLaunched && _leftApp && !_closing) {
      _leftApp = false;
      if (mounted) setState(() => _returnedFromBrowser = true);
      debugPrint('[TOTOTL][STRIPE][BROWSER_RESUMED] '
          'checkout_kept_open=true');
    }
  }

  /// Only close for an explicit status-check action or the trusted Tototl
  /// payment-return URL. A caller resume does not imply payment success.
  void _finishAndCheck({String reason = 'user_check'}) {
    if (_closing || !mounted) return;
    _closing = true;
    debugPrint('[TOTOTL][STRIPE][CHECKOUT_ROUTE_CLOSE] reason=$reason');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  // Try the native browser surface directly. Unlike supportsLaunchMode(),
  // this does not depend on Android's package visibility <queries> check
  // (which was returning false on devices with Chrome installed).
  Future<bool> _tryBrowser(LaunchMode mode) async {
    try {
      final opened = await launchUrl(widget.checkoutUri, mode: mode);
      debugPrint('[TOTOTL][STRIPE][BROWSER_LAUNCH_RESULT] '
          'mode=$mode opened=$opened');
      return opened;
    } catch (error) {
      // Never log the Checkout URL: it contains a session identifier.
      debugPrint('[TOTOTL][STRIPE][BROWSER_LAUNCH_ERROR] '
          'mode=$mode type=${error.runtimeType}');
      return false;
    }
  }

  /// Keep the existing Stripe URL and the original payment-return handling.
  /// First prefer Custom Tabs, then the phone's default browser, then the
  /// existing emulator-friendly embedded WebView as a last resort.
  Future<void> _openSecureBrowser() async {
    if (_launching || _closing || !mounted) return;
    if (!isTrustedStripeCheckoutUri(widget.checkoutUri)) {
      setState(() => _error = _tr(
        'This is not a valid Stripe Checkout link.',
        'رابط الدفع غير صالح أو ليس من Stripe.',
        'Ungültiger Stripe-Checkout-Link.',
      ));
      return;
    }
    setState(() {
      _launching = true;
      _error = null;
    });

    debugPrint('[TOTOTL][STRIPE][OPEN_MODE] custom_tabs_attempt');
    bool launched = await _tryBrowser(LaunchMode.inAppBrowserView);
    if (!mounted || _closing) return;

    if (!launched) {
      debugPrint('[TOTOTL][STRIPE][OPEN_MODE] external_browser_attempt');
      launched = await _tryBrowser(LaunchMode.externalApplication);
    }
    if (!mounted || _closing) return;

    if (launched) {
      setState(() {
        _launching = false;
        _browserLaunched = true;
        _returnedFromBrowser = false;
        _embeddedFallback = false;
        _webLoading = false;
      });
      return;
    }

    // Some emulators have no browser installed. Preserve the ORIGINAL
    // embedded WebView path for those cases, including its return-URL logic.
    debugPrint('[TOTOTL][STRIPE][OPEN_MODE] embedded_last_resort');
    setState(() {
      _launching = false;
      _browserLaunched = false;
    });
    await _openEmbeddedFallback();
  }

  /// Explicit fallback when the in-app browser opens but the real device's
  /// browser provider does not actually display the Checkout page.
  Future<void> _openExternalBrowser() async {
    if (_launching || _closing || !mounted) return;
    if (!isTrustedStripeCheckoutUri(widget.checkoutUri)) return;
    setState(() {
      _launching = true;
      _error = null;
    });
    final launched = await _tryBrowser(LaunchMode.externalApplication);
    if (!mounted || _closing) return;
    setState(() {
      _launching = false;
      if (launched) {
        _browserLaunched = true;
        _returnedFromBrowser = false;
        _embeddedFallback = false;
        _webLoading = false;
      } else {
        _error = _tr(
          'Could not open a browser. Update Chrome or use the built-in viewer.',
          'تعذّر فتح المتصفح. حدّثي Chrome أو اختاري العرض الداخلي.',
          'Browser konnte nicht geöffnet werden. Chrome aktualisieren.',
        );
      }
    });
  }

  Future<void> _openEmbeddedFallback() async {
    if (_closing || !mounted) return;
    setState(() {
      _embeddedFallback = true;
      _webLoading = true;
      _error = null;
    });
    try {
      final controller = _controller ?? WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(Colors.white);
      await controller.setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() { _webLoading = true; _error = null; });
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _webLoading = false);
        },
        onUrlChange: (change) {
          if (isTototlPaymentReturnUri(Uri.tryParse(change.url ?? ''))) {
            _finishAndCheck(reason: 'stripe_return_url');
          }
        },
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (isTototlPaymentReturnUri(uri)) {
            _finishAndCheck(reason: 'stripe_return_url');
            return NavigationDecision.prevent;
          }
          if (uri == null || uri.scheme != 'https') {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onWebResourceError: (error) {
          if (mounted && error.isForMainFrame == true) {
            setState(() {
              _webLoading = false;
              _error = _tr(
                'Stripe could not load in the embedded viewer. Check Android System WebView.',
                'تعذّر تحميل Stripe داخليًا. افحصي Android System WebView.',
                'Stripe konnte im WebView nicht geladen werden.',
              );
            });
          }
        },
      ));
      if (!mounted || _closing) return;
      setState(() => _controller = controller);
      await controller.loadRequest(widget.checkoutUri);
    } catch (error) {
      debugPrint('[TOTOTL][STRIPE][WEBVIEW_FAILED] ${error.runtimeType}');
      if (mounted) {
        setState(() {
          _embeddedFallback = false;
          _webLoading = false;
          _error = _tr(
            'Android System WebView is unavailable. Install or update it to pay in the app.',
            'مكوّن Android System WebView غير متاح. ثبّتيه أو حدّثيه لفتح الدفع داخل التطبيق.',
            'Android System WebView ist nicht verfügbar.',
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rtl = AppLanguage.locale.value.languageCode == 'ar';
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          title: Text(
            _tr('Secure Stripe checkout', 'الدفع الآمن عبر Stripe',
                'Sicherer Stripe-Checkout'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              onPressed: _launching ? null : _openSecureBrowser,
              tooltip: _tr('Open in browser', 'فتح بالمتصفح',
                  'Im Browser öffnen'),
              icon: const Icon(Icons.open_in_browser_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFFE9F8F7),
                padding: const EdgeInsets.all(12),
                child: Text(
                  _tr(
                    'Pay in Stripe, then return to TOTOTL. Only the server can confirm payment.',
                    'أكملي الدفع في Stripe، وبعدها ارجعي إلى TOTOTL. تأكيد الدفع من السيرفر فقط.',
                    'In Stripe bezahlen, dann zurück zu TOTOTL. Nur der Server bestätigt.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, height: 1.45),
                ),
              ),
              Expanded(
                child: _embeddedFallback && _controller != null
                    ? Stack(
                        children: [
                          WebViewWidget(controller: _controller!),
                          if (_webLoading)
                            const LinearProgressIndicator(minHeight: 3),
                        ],
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _browserLaunched
                                    ? Icons.open_in_browser_rounded
                                    : Icons.lock_outline_rounded,
                                size: 44,
                                color: AppColors.blue,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _launching
                                    ? _tr('Opening Stripe...',
                                        'جارٍ فتح Stripe...', 'Stripe wird geöffnet...')
                                    : _browserLaunched
                                        ? _returnedFromBrowser
                                          ? _tr('Back in TOTOTL? Tap Check payment status below. If Stripe is not finished, open the same session again.',
                                              'رجعتي لـTOTOTL؟ اضغطي فحص حالة الدفع تحت. إذا لسه ما خلصتي، افتحي نفس جلسة Stripe مرة ثانية.',
                                              'Zurück in TOTOTL? Zahlungsstatus prüfen oder dieselbe Sitzung fortsetzen.')
                                          : _tr('Complete Checkout in your browser. Return here and tap Check payment status when done.',
                                              'كمّلي الدفع في المتصفح، وارجعي لهون واضغطي فحص حالة الدفع لما تخلصي.',
                                              'Checkout im Browser beenden, dann Zahlungsstatus prüfen.')
                                        : _tr('Open Stripe securely in a browser.',
                                            'افتحي Stripe بأمان من المتصفح.',
                                            'Stripe sicher im Browser öffnen.'),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _launching ? null : _openSecureBrowser,
                                icon: const Icon(Icons.open_in_browser_rounded),
                                label: Text(_tr('Open Stripe in browser',
                                    'فتح Stripe بالمتصفح', 'Stripe im Browser öffnen')),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _launching ? null : _openExternalBrowser,
                                icon: const Icon(Icons.public_rounded, size: 18),
                                label: Text(_tr('Open in phone browser',
                                    'فتح بمتصفح الجهاز', 'Im Handy-Browser öffnen')),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _launching ? null : _openEmbeddedFallback,
                                child: Text(_tr('Use built-in viewer (fallback)',
                                    'العرض الداخلي (احتياطي للمحاكي)', 'Eingebettete Ansicht')),
                              ),
                              if (!_browserLaunched)
                                TextButton.icon(
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(
                                        text: widget.checkoutUri.toString()));
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(_tr(
                                          'Link copied. Open it in a trusted browser; do not share publicly.',
                                          'نسخنا الرابط. افتحيه في متصفح موثوق وما تنشريه.',
                                          'Link kopiert. Sicher im Browser öffnen.',
                                        ))),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.copy_rounded, size: 16),
                                  label: Text(_tr('Copy Checkout link',
                                      'نسخ رابط Stripe', 'Checkout-Link kopieren')),
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.red),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _closing ? null : () => _finishAndCheck(),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: Text(_tr('I finished / Check payment status',
                        'أنهيت الدفع / فحص حالة الدفع',
                        'Fertig / Zahlung prüfen')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
