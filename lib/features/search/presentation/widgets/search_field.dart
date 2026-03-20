import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isAr,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isAr;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        autofocus: true,
        textAlignVertical: TextAlignVertical.center,
        style: tt.bodyMedium?.copyWith(
          color: cs.outline,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          fillColor: cs.surfaceContainer,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
          hintText: isAr
              ? 'ابحث عن أماكن وفعاليات...'
              : 'Search places & events...',
          hintStyle: tt.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.4),
          ),
          // Search icon on the start side
          prefixIcon: Icon(
            CupertinoIcons.search,
            color: cs.onTertiary,
            size: 20,
          ),
          // X clear button on the end side — only visible when there's text
          suffixIcon: hasText
              ? GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    CupertinoIcons.clear_circled_solid,
                    color: cs.onTertiary,
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          isDense: true,
        ),
      ),
    );
  }
}
