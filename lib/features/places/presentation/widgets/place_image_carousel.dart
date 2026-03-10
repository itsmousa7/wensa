// lib/features/places/presentation/widgets/place_details/place_image_carousel.dart
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

// ── Carousel ──────────────────────────────────────────────────────────────────

class PlaceImageCarousel extends StatelessWidget {
  const PlaceImageCarousel({
    super.key,
    required this.images,
    required this.currentIndex,
    required this.controller,
    required this.isAr,
    required this.onPageChanged,
    this.onTap,
  });

  final List<String> images;
  final int currentIndex;
  final PageController controller;
  final bool isAr;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Images ──────────────────────────────────────────────────────
        if (images.isEmpty)
          Container(color: cs.surfaceContainer)
        else
          GestureDetector(
            onTap: onTap,
            child: PageView.builder(
              controller: controller,
              itemCount: images.length,
              physics:
                  const PageScrollPhysics(parent: BouncingScrollPhysics()),
              onPageChanged: onPageChanged,
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: images[i],
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: cs.surfaceContainer),
                errorWidget: (_, __, ___) =>
                    Container(color: cs.surfaceContainer),
              ),
            ),
          ),

        // ── Bottom gradient ──────────────────────────────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
          ),
        ),

        // ── Top gradient ─────────────────────────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0, height: 100,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Counter pill ─────────────────────────────────────────────────
        if (images.length > 1)
          Positioned(
            bottom: 52,
            left: isAr ? 18 : null,
            right: isAr ? null : 18,
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${currentIndex + 1} / ${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // ── Expand hint icon ─────────────────────────────────────────────
        if (images.isNotEmpty)
          Positioned(
            bottom: 50,
            left: isAr ? null : 18,
            right: isAr ? 18 : null,
            child: IgnorePointer(
              child: Icon(
                Icons.open_in_full_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 16,
              ),
            ),
          ),

        // ── Dot indicators ───────────────────────────────────────────────
        if (images.length > 1 && images.length <= 10)
          Positioned(
            bottom: 16, left: 0, right: 0,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == currentIndex ? 18 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i == currentIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Fullscreen viewer ─────────────────────────────────────────────────────────

class PlaceFullscreenViewer extends StatefulWidget {
  const PlaceFullscreenViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });
  final List<String> images;
  final int initialIndex;

  @override
  State<PlaceFullscreenViewer> createState() => _PlaceFullscreenViewerState();
}

class _PlaceFullscreenViewerState extends State<PlaceFullscreenViewer> {
  late final PageController _ctrl =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _ctrl,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.images[i],
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          ),
        ),

        // Close button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ),

        if (widget.images.length > 1)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0, right: 0,
            child: Text(
              '${_index + 1} / ${widget.images.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
      ]),
    );
  }
}