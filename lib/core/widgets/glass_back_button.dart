import 'dart:io';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Back button that follows the ambient text direction (RTL → chevron.right,
/// LTR → chevron.left).
///
/// iOS renders a native Liquid Glass [CNButton] chevron. Android (and other
/// platforms) keep the original plain Material chevron. Defaults to popping
/// the current route.
class GlassBackButton extends StatelessWidget {
  const GlassBackButton({super.key, this.onPressed, this.size = 50});

  /// Override the default pop behavior.
  final VoidCallback? onPressed;

  /// Diameter of the glass circle (iOS only). Defaults to 50.
  final double size;

  /// AppBar `leading` that reuses the booking pages' glass back button.
  ///
  /// iOS only — returns `null` on Android (and elsewhere) so the `AppBar`
  /// keeps its default Material back button. Pair with [appBarLeadingWidth]
  /// on the AppBar's `leadingWidth`. The `start: 15` inset matches the
  /// ticket detail page so the glass circle isn't squeezed into an oval.
  static Widget? appBarLeading({VoidCallback? onPressed}) => Platform.isIOS
      ? Padding(
          padding: const EdgeInsetsDirectional.only(start: 15),
          child: GlassBackButton(onPressed: onPressed),
        )
      : null;

  /// `leadingWidth` to pair with [appBarLeading]; `null` keeps the default
  /// on non-iOS platforms.
  static double? get appBarLeadingWidth => Platform.isIOS ? 70 : null;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final onTap = onPressed ?? () => Navigator.of(context).maybePop();

    // iOS — native Liquid Glass chevron.
    if (Platform.isIOS) {
      return CNButton.icon(
        icon: CNSymbol(isRtl ? 'chevron.right' : 'chevron.left'),
        onPressed: onTap,
        config: CNButtonConfig(
          style: CNButtonStyle.glass,
          width: size,
          minHeight: size,
        ),
      );
    }

    // Android — original plain chevron.
    return IconButton(
      icon: Icon(
        isRtl ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: onTap,
    );
  }
}
