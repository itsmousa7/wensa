import 'dart:io';

import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlaceAppBarButton extends ConsumerStatefulWidget {
  const PlaceAppBarButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.collapsed,
    this.isActive = false,
    this.animate = false,
    this.sfSymbol,
  });

  final Widget icon;
  final VoidCallback onTap;
  final bool collapsed;
  final bool isActive;
  final bool animate;
  final String? sfSymbol;

  @override
  ConsumerState<PlaceAppBarButton> createState() => _PlaceAppBarButtonState();
}

class _PlaceAppBarButtonState extends ConsumerState<PlaceAppBarButton>
    with SingleTickerProviderStateMixin {
  // ✅ Declare without initializing — no lazy late initializer
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // ✅ Initialize in initState where vsync: this is safe
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.animate) _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    // ── iOS: native liquid glass button ──────────────────────────────────
    if (Platform.isIOS && widget.sfSymbol != null) {
      return CNButton.icon(
        icon: CNSymbol(widget.sfSymbol!),
        onPressed: _onTap,
        size: 50,
      );
    }

    // ── Android: frosted glass button ─────────────────────────────────────
    final child = ScaleTransition(scale: _scale, child: widget.icon);

    if (widget.collapsed) {
      return GestureDetector(
        onTap: _onTap,
        child: SizedBox(width: 50, height: 50, child: Center(child: child)),
      );
    }

    return GestureDetector(
      onTap: _onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(54),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}
