import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Loads the bundled seat-map viewer (a single inlined HTML file built from
/// `wansa-admin-dashboard/src/viewer/`) inside a WebView. The viewer reads
/// `window.WENSA_VIEWER_PARAMS` for the event id and Supabase access token,
/// then renders the map and pings us via the `WensaSeatMap` JS channel when
/// the user taps a section or seat.
class SeatMapWebView extends StatefulWidget {
  const SeatMapWebView({
    super.key,
    required this.eventId,
    required this.onSectionTap,
    required this.onSeatTap,
    this.onBack,
  });

  final String eventId;
  final void Function(SeatMapSectionTap event) onSectionTap;
  final void Function(SeatMapSeatTap event) onSeatTap;
  final VoidCallback? onBack;

  @override
  State<SeatMapWebView> createState() => SeatMapWebViewState();
}

class SeatMapWebViewState extends State<SeatMapWebView> {
  WebViewController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final raw = await rootBundle.loadString('assets/viewer/index.html');
    final accessToken =
        Supabase.instance.client.auth.currentSession?.accessToken;

    // Injected before the React app boots so readViewerParams() picks it up.
    final injected = '''
<script>
  window.WENSA_VIEWER_PARAMS = ${jsonEncode({
          'eventId': widget.eventId,
          'accessToken': accessToken,
          'debug': false,
        })};
</script>''';
    // Insert right after <head> so it runs before the bundled module.
    final patched = raw.replaceFirst('<head>', '<head>$injected');

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'WensaSeatMap',
        onMessageReceived: _onJsMessage,
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _ready = true);
        },
      ))
      ..loadHtmlString(
        patched,
        // Set a hostable base URL so fetch() against Supabase works (file://
        // origins block CORS preflight in some Android builds).
        baseUrl: 'https://wensa-viewer.local/',
      );

    if (!mounted) return;
    setState(() => _controller = controller);
  }

  void _onJsMessage(JavaScriptMessage message) {
    try {
      final decoded = jsonDecode(message.message) as Map<String, dynamic>;
      final type = decoded['type'] as String?;
      switch (type) {
        case 'sectionTap':
          widget.onSectionTap(SeatMapSectionTap(
            sectionId: decoded['sectionId'] as String? ?? '',
            sectionKey: decoded['sectionKey'] as String? ?? '',
            sectionKind: decoded['sectionKind'] as String? ?? 'seating',
          ));
          break;
        case 'seatTap':
          widget.onSeatTap(SeatMapSeatTap(
            sectionId: decoded['sectionId'] as String? ?? '',
            seatId: decoded['seatId'] as String? ?? '',
            rowLabel: decoded['rowLabel'] as String? ?? '',
            seatLabel: decoded['seatLabel'] as String? ?? '',
          ));
          break;
        case 'back':
          widget.onBack?.call();
          break;
        case 'ready':
        case 'error':
          // No-op — could surface a snackbar for errors in future.
          break;
      }
    } catch (_) {
      // Malformed payload — ignore.
    }
  }

  /// Forces the viewer to re-fetch layout + seat availability. Call after
  /// payment success / hold expiry / cancelled hold so the UI stays fresh.
  Future<void> reload() async {
    final c = _controller;
    if (c == null || !_ready) return;
    await c.runJavaScript('window.wensaReload && window.wensaReload();');
  }

  /// Open a section programmatically (drill-in) without waiting for a tap.
  Future<void> openSection(String? sectionId) async {
    final c = _controller;
    if (c == null || !_ready) return;
    final arg = sectionId == null ? 'null' : '"$sectionId"';
    await c
        .runJavaScript('window.wensaOpenSection && window.wensaOpenSection($arg);');
  }

  /// Push the user's current selection back into the viewer so it can render
  /// each selected seat with a highlight ring.
  Future<void> setSelectedSeats(List<String> seatIds) async {
    final c = _controller;
    if (c == null || !_ready) return;
    final payload = jsonEncode(seatIds);
    await c.runJavaScript(
        'window.wensaSetSelectedSeats && window.wensaSetSelectedSeats($payload);');
  }

  /// Shifts the zoom/reset button bar up by [px] so it clears any Flutter
  /// widget (e.g. the selection summary bar) overlaid at the bottom.
  Future<void> setBottomInset(double px) async {
    final c = _controller;
    if (c == null || !_ready) return;
    await c.runJavaScript(
        'window.wensaSetBottomInset && window.wensaSetBottomInset($px);');
  }

  /// Enable/disable interaction with the map. While a Flutter sheet is open
  /// over the map, the native WebView would still receive touches (iOS
  /// platform views release unclaimed touches to the native view, so a
  /// Flutter IgnorePointer / modal barrier can't block them). We inject a
  /// transparent full-viewport overlay *inside* the web content that swallows
  /// every pointer event, leaving the map visible but inert.
  Future<void> setInteractive(bool interactive) async {
    final c = _controller;
    if (c == null || !_ready) return;
    if (interactive) {
      await c.runJavaScript(
        "(function(){var b=document.getElementById('__wensa_block__');if(b)b.remove();})();",
      );
    } else {
      await c.runJavaScript(
        "(function(){if(document.getElementById('__wensa_block__'))return;"
        "var d=document.createElement('div');d.id='__wensa_block__';"
        "d.style.cssText='position:fixed;top:0;left:0;right:0;bottom:0;"
        "z-index:2147483647;background:transparent;touch-action:none;';"
        "document.body.appendChild(d);})();",
      );
    }
  }

  /// Push the seats that should render with the red "orphan / warning"
  /// highlight (pulsing ring). Called after every change to either the
  /// selection or the available seats list.
  Future<void> setWarningSeats(List<String> seatIds) async {
    final c = _controller;
    if (c == null || !_ready) return;
    final payload = jsonEncode(seatIds);
    await c.runJavaScript(
        'window.wensaSetWarningSeats && window.wensaSetWarningSeats($payload);');
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const ColoredBox(
        color: Colors.white,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return WebViewWidget(controller: controller);
  }
}

class SeatMapSectionTap {
  const SeatMapSectionTap({
    required this.sectionId,
    required this.sectionKey,
    required this.sectionKind,
  });
  final String sectionId;
  final String sectionKey;
  final String sectionKind;

  bool get isGeneralAdmission => sectionKind == 'general_admission';
}

class SeatMapSeatTap {
  const SeatMapSeatTap({
    required this.sectionId,
    required this.seatId,
    required this.rowLabel,
    required this.seatLabel,
  });
  final String sectionId;
  final String seatId;
  final String rowLabel;
  final String seatLabel;
}
