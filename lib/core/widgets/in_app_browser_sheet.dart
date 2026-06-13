import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Opens [url] in an in-app WebView bottom sheet (same UX as the home banners).
Future<void> showInAppBrowser(BuildContext context, String url) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => InAppBrowserSheet(url: url),
  );
}

class InAppBrowserSheet extends StatefulWidget {
  const InAppBrowserSheet({super.key, required this.url});

  final String url;

  @override
  State<InAppBrowserSheet> createState() => _InAppBrowserSheetState();
}

class _InAppBrowserSheetState extends State<InAppBrowserSheet> {
  late final WebViewController _controller;
  double _progress = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => setState(() {
          _progress = p / 100.0;
          _loading = p < 100;
        }),
        onPageFinished: (_) => setState(() => _loading = false),
        onNavigationRequest: (request) async {
          final uri = Uri.tryParse(request.url);
          // The WebView can only load http(s). Hand off other schemes
          // (mailto:, tel:, etc.) to the OS so the mail/phone app opens.
          if (uri != null && uri.scheme != 'http' && uri.scheme != 'https') {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  String get _domain {
    final uri = Uri.tryParse(widget.url);
    return uri?.host.replaceFirst('www.', '') ?? widget.url;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.93;
    return SizedBox(
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            // Toolbar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      _domain,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_browser_rounded),
                    tooltip: 'Open in browser',
                    onPressed: () async {
                      final uri = Uri.tryParse(widget.url);
                      if (uri != null) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ),
            ),
            // Progress indicator
            SizedBox(
              height: 2,
              child: _loading
                  ? LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      color: theme.colorScheme.primary,
                      backgroundColor: Colors.transparent,
                    )
                  : const SizedBox.shrink(),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
            Expanded(
              child: WebViewWidget(
                controller: _controller,
                gestureRecognizers: {
                  Factory<VerticalDragGestureRecognizer>(
                    () => VerticalDragGestureRecognizer(),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
