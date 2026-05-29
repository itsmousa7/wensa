// lib/core/share/share_service.dart
//
// Single entry point for sharing: render a widget to PNG off-screen, share an
// image (or text) via the native sheet, and fetch remote image bytes.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  final ScreenshotController _controller = ScreenshotController();

  /// Rasterize [card] off-screen at [pixelRatio]. The card is wrapped with the
  /// current Theme, the correct Directionality (RTL/LTR), a neutral MediaQuery
  /// (textScaler fixed to 1.0 so the image looks consistent), and a transparent
  /// Material. [delay] lets post-frame layout (e.g. ticket tear-line) settle.
  Future<Uint8List> renderToPng(
    BuildContext context,
    Widget card, {
    required bool isAr,
    double pixelRatio = 3,
    Duration delay = const Duration(milliseconds: 200),
  }) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final wrapped = MediaQuery(
      data: mq.copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Theme(
          data: theme,
          child: Material(type: MaterialType.transparency, child: card),
        ),
      ),
    );
    return _controller.captureFromLongWidget(
      InheritedTheme.captureAll(context, wrapped),
      delay: delay,
      pixelRatio: pixelRatio,
      context: context,
    );
  }

  /// Share a PNG with an optional [caption]. Writes a temp file first (most
  /// reliable across platforms). Returns the platform [ShareResult].
  Future<ShareResult> shareImage(
    BuildContext context,
    Uint8List png, {
    required String caption,
    String fileName = 'wensa_share.png',
  }) async {
    // Capture render box before async gap to satisfy use_build_context_synchronously.
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box != null ? box.localToGlobal(Offset.zero) & box.size : null;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(png, flush: true);
    return SharePlus.instance.share(
      ShareParams(
        text: caption,
        files: [XFile(file.path, mimeType: 'image/png')],
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<ShareResult> shareText(BuildContext context, String text) {
    final box = context.findRenderObject() as RenderBox?;
    return SharePlus.instance.share(
      ShareParams(
        text: text,
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      ),
    );
  }

  /// Fetch remote image bytes (for cover images that must rasterize in an
  /// off-screen capture). Returns null on any failure — callers fall back.
  Future<Uint8List?> fetchImageBytes(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return res.bodyBytes;
      }
    } catch (_) {}
    return null;
  }
}
