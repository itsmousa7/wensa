import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';
import 'package:future_riverpod/features/search/presentation/widgets/search_field.dart';
import 'package:go_router/go_router.dart';

class IosFloatingSearchBar extends StatelessWidget {
  const IosFloatingSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isAr,
    required this.hasText,
    required this.onChanged,
    required this.onClearText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isAr;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClearText;

  static const double totalHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: totalHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // ── Search field — keeps its own surfaceContainer color ────
            Expanded(
              child: SearchField(
                controller: controller,
                focusNode: focusNode,
                isAr: isAr,
                hasText: hasText,
                onChanged: onChanged,
                onClear: onClearText,
                // transparent: false (default) — field keeps its background
              ),
            ),

            const SizedBox(width: 8),

            // ── X — pops back ─────────────────────────────────────────
            CNButton.icon(
              onPressed: () {
                focusNode.unfocus();
                context.pop();
              },
              icon: const CNSymbol('xmark'),
            ),
          ],
        ),
      ),
    );
  }
}
