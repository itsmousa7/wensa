import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/services/wayl_api_service.dart';

/// Displays the Wayl-hosted checkout page in a full-screen WebView.
///
/// Detects payment completion via two mechanisms:
/// 1. URL interception — when the WebView navigates to [redirectionUrl].
/// 2. Status polling  — polls GET /api/v1/links/{referenceId} every 3 s
///    and resolves when status becomes "Complete" or "Failed".
class WaylWebViewScreen extends StatefulWidget {
  const WaylWebViewScreen({
    super.key,
    required this.paymentUrl,
    this.referenceId,
    this.redirectionUrl,
    this.apiService,
    this.onPaymentSuccess,
    this.onPaymentFailed,
    this.onPaymentCancelled,
  });

  final String paymentUrl;
  final String? referenceId;
  final String? redirectionUrl;
  final WaylApiService? apiService;
  final void Function(String referenceId, String orderId)? onPaymentSuccess;
  final void Function()? onPaymentFailed;
  final void Function()? onPaymentCancelled;

  @override
  State<WaylWebViewScreen> createState() => _WaylWebViewScreenState();
}

class _WaylWebViewScreenState extends State<WaylWebViewScreen> {
  late final WebViewController _webViewController;
  late final WaylApiService _apiService;
  bool _isLoading = true;
  bool _hasError = false;
  bool _resultHandled = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? WaylApiService();
    _initWebView();
    if (widget.referenceId != null) _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    // If we leave the screen without success/failure (X button, system back,
    // gesture, OS pop), treat it as a user cancel so the parent can release
    // any pending booking row server-side. Guarded by `_resultHandled` to
    // avoid double-firing alongside success/failure.
    if (!_resultHandled) {
      _resultHandled = true;
      widget.onPaymentCancelled?.call();
    }
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_resultHandled) {
        _pollingTimer?.cancel();
        return;
      }
      try {
        final status =
            await _apiService.checkPaymentStatus(widget.referenceId!);
        if (_resultHandled) return;
        final statusLower = status.status.toLowerCase();
        final isComplete = statusLower == 'complete' ||
            statusLower == 'completed' ||
            statusLower == 'paid' ||
            statusLower == 'success' ||
            status.completedAt != null;
        final isFailed = statusLower == 'failed' ||
            statusLower == 'cancelled' ||
            statusLower == 'canceled';

        if (isComplete) {
          _resultHandled = true;
          _pollingTimer?.cancel();
          debugPrint('[WaylWebView] polling: payment COMPLETE');
          _dismissWithSuccess(status.referenceId, status.id);
        } else if (isFailed) {
          _resultHandled = true;
          _pollingTimer?.cancel();
          debugPrint('[WaylWebView] polling: payment FAILED');
          _dismissWithFailure();
        }
      } catch (_) {
        // Ignore transient polling errors; keep retrying.
      }
    });
  }

  /// Checks if [url] signals payment success or failure.
  /// Returns true if a result was detected and handled.
  bool _checkForPaymentResult(String url) {
    if (_resultHandled) {
      debugPrint('[WaylWebView] result already handled, skipping: $url');
      return true;
    }

    final redirectBase = widget.redirectionUrl;
    final uri = Uri.tryParse(url);
    // Normalize param keys to lowercase for case-insensitive lookup.
    final params = uri?.queryParameters.map(
      (k, v) => MapEntry(k.toLowerCase(), v),
    );
    final hasSuccessParams = params != null &&
        params.containsKey('referenceid') &&
        (params.containsKey('orderid') || params.containsKey('order_id'));

    // Case-insensitive comparison — iOS may normalise the URL scheme.
    final matchesRedirect = redirectBase != null &&
        redirectBase.isNotEmpty &&
        url.toLowerCase().startsWith(redirectBase.toLowerCase());

    if (matchesRedirect || hasSuccessParams) {
      _resultHandled = true;
      _pollingTimer?.cancel();
      final referenceId = params?['referenceid'] ?? '';
      final orderId = params?['orderid'] ?? params?['order_id'] ?? '';
      debugPrint('[WaylWebView] payment SUCCESS detected — popping');
      _dismissWithSuccess(referenceId, orderId);
      return true;
    }

    if (url.contains('status=failed') || url.contains('status=cancelled')) {
      _resultHandled = true;
      _pollingTimer?.cancel();
      debugPrint('[WaylWebView] payment FAILED detected — popping');
      _dismissWithFailure();
      return true;
    }

    return false;
  }

  void _dismissWithSuccess(String referenceId, String orderId) {
    // Wait 3 seconds so the user sees the Wayl success page before closing.
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) {
        debugPrint('[WaylWebView] NOT mounted — cannot pop');
        return;
      }
      debugPrint('[WaylWebView] mounted — calling onPaymentSuccess + pop');
      widget.onPaymentSuccess?.call(referenceId, orderId);
      Navigator.of(context).pop();
    });
  }

  void _dismissWithFailure() {
    Future.microtask(() {
      if (!mounted) return;
      widget.onPaymentFailed?.call();
      Navigator.of(context).pop();
    });
  }

  NavigationDecision _handleNavigation(String url) {
    debugPrint('[WaylWebView] navigating to: $url');
    if (_checkForPaymentResult(url)) return NavigationDecision.prevent;
    return NavigationDecision.navigate;
  }

  /// On iOS, WKWebView silently drops navigations to custom URL schemes
  /// (e.g. wansa://). Inject JS that intercepts the redirect attempt and
  /// forwards it to Flutter via a JavaScript channel.
  void _injectRedirectInterceptor() {
    final scheme =
        Uri.tryParse(widget.redirectionUrl ?? '')?.scheme ?? 'wansa';

    _webViewController.runJavaScript('''
      (function() {
        if (window._paymentRedirectInjected) return;
        window._paymentRedirectInjected = true;

        var scheme = '$scheme://';

        // Override location.assign / location.replace
        var origAssign = Location.prototype.assign;
        Location.prototype.assign = function(url) {
          if (typeof url === 'string' && url.toLowerCase().indexOf(scheme) === 0) {
            window.PaymentRedirect.postMessage(url);
            return;
          }
          return origAssign.call(this, url);
        };
        var origReplace = Location.prototype.replace;
        Location.prototype.replace = function(url) {
          if (typeof url === 'string' && url.toLowerCase().indexOf(scheme) === 0) {
            window.PaymentRedirect.postMessage(url);
            return;
          }
          return origReplace.call(this, url);
        };

        // Periodically scan <a> tags for redirect links
        var interval = setInterval(function() {
          var links = document.querySelectorAll('a[href]');
          for (var i = 0; i < links.length; i++) {
            var href = links[i].getAttribute('href') || '';
            if (href.toLowerCase().indexOf(scheme) === 0) {
              window.PaymentRedirect.postMessage(href);
              clearInterval(interval);
              return;
            }
          }
        }, 500);
        setTimeout(function() { clearInterval(interval); }, 120000);
      })();
    ''');
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('PaymentRedirect', onMessageReceived: (message) {
        _checkForPaymentResult(message.message);
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
            _checkForPaymentResult(url);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            // On iOS, inject JS to intercept custom-scheme redirects.
            if (Platform.isIOS) _injectRedirectInterceptor();
          },
          onWebResourceError: (error) {
            // Ignore errors caused by custom-scheme navigation attempts.
            if (_resultHandled) return;
            if (error.isForMainFrame ?? true) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
          onHttpAuthRequest: (HttpAuthRequest request) {
            request.onCancel();
          },
          onNavigationRequest: (request) => _handleNavigation(request.url),
          onUrlChange: (change) {
            if (change.url != null) _checkForPaymentResult(change.url!);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          // Fire the cancel callback BEFORE pop so the parent's state reset +
          // snackbar happen immediately, rather than waiting ~300ms for the
          // pop animation to complete before dispose() fires. System-back /
          // gesture pops still get caught by the guarded dispose() handler.
          onPressed: () {
            if (!_resultHandled) {
              _resultHandled = true;
              widget.onPaymentCancelled?.call();
            }
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Online Payment',
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (!_hasError) WebViewWidget(controller: _webViewController),

          if (_isLoading && !_hasError)
            const Center(child: CircularProgressIndicator()),

          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 56, color: Color(0xFFBBBBBB)),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to load payment page',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please check your internet connection and try again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isLoading = true;
                        });
                        _webViewController
                            .loadRequest(Uri.parse(widget.paymentUrl));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
