import 'package:flutter/material.dart';

class ViewAllCard extends StatelessWidget {
  const ViewAllCard({
    super.key,
    required this.isAr,
    required this.onTap,
    this.height = 210,
    // How much of the bottom is "text area" below the image.
    // FeedCard image = 130px, text area ≈ 68px → offset = 68.
    this.textAreaHeight = 68,
  });

  final bool isAr;
  final VoidCallback onTap;
  final double height;
  final double textAreaHeight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = isAr ? 'عرض الكل' : 'View All';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        height: height,
        child: Padding(
          // Shift content up by half the text-area height so it visually
          // centres against the image portion of the adjacent FeedCards.
          padding: EdgeInsets.only(bottom: textAreaHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAr
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.arrow_forward_ios_rounded,
                  color: cs.primary,
                  size: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
