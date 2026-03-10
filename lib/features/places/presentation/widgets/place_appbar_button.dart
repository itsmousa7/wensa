// lib/features/places/presentation/widgets/place_details/place_appbar_buttons.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Back / Nav button ─────────────────────────────────────────────────────────

class PlaceNavButton extends StatelessWidget {
  const PlaceNavButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.collapsed,
  });

  final Widget icon;
  final VoidCallback onTap;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return GestureDetector(
        onTap: onTap,
        child: SizedBox(width: 38, height: 38, child: Center(child: icon)),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}

// ── Heart / favourite button ──────────────────────────────────────────────────

class PlaceHeartButton extends ConsumerStatefulWidget {
  const PlaceHeartButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
    required this.collapsed,
  });

  final bool isFavorite;
  final VoidCallback onTap;
  final bool collapsed;

  @override
  ConsumerState<PlaceHeartButton> createState() => _PlaceHeartButtonState();
}

class _PlaceHeartButtonState extends ConsumerState<PlaceHeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _scale = Tween(begin: 1.0, end: 1.4).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = widget.isFavorite
        ? Colors.redAccent
        : (widget.collapsed ? cs.onSurface : Colors.white);

    final icon = ScaleTransition(
      scale: _scale,
      child: Icon(
        widget.isFavorite
            ? Icons.favorite_rounded
            : Icons.favorite_border_rounded,
        color: iconColor,
        size: 20,
      ),
    );

    if (widget.collapsed) {
      return GestureDetector(
        onTap: _onTap,
        child: SizedBox(width: 38, height: 38, child: Center(child: icon)),
      );
    }
    return GestureDetector(
      onTap: _onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}