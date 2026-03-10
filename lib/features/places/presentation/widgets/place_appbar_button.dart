// lib/features/places/presentation/widgets/place_details/place_appbar_buttons.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlaceAppBarButton extends ConsumerStatefulWidget {
  const PlaceAppBarButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.collapsed,
    this.activeColor,
    this.isActive = false,

    this.animate = false,
  });

  final Widget icon;
  final VoidCallback onTap;
  final bool collapsed;
  final Color? activeColor;
  final bool isActive;

  final bool animate;

  @override
  ConsumerState<PlaceAppBarButton> createState() => _PlaceAppBarButtonState();
}

class _PlaceAppBarButtonState extends ConsumerState<PlaceAppBarButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _scale = Tween(
    begin: 1.0,
    end: 1.4,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

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
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(54),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Center(child: child),
      ),
    );
  }
}
