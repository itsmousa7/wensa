import 'package:flutter/widgets.dart';

/// Constrains its [child] to a mobile-like column width and centers it.
///
/// On phones this is a no-op — the [maxWidth] is clamped to the (smaller)
/// screen width, so the child fills the screen as before. On tablets / very
/// wide screens it keeps place cards, images and rows from stretching
/// edge-to-edge by capping the content column and letterboxing the sides with
/// the surrounding background.
///
/// Wrap a page's scrollable body (`CustomScrollView`, `ListView`, …) with this.
class ResponsivePageWidth extends StatelessWidget {
  const ResponsivePageWidth({
    super.key,
    required this.child,
    this.maxWidth = 500,
  });

  /// The (typically scrollable) page body to constrain.
  final Widget child;

  /// Maximum content width on large screens. Defaults to a mobile-like 500.
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
