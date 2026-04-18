import 'package:flutter/cupertino.dart';
import 'package:future_riverpod/core/widgets/full_width_feed_card.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: buildFullWidthSkeleton(context),
    );
  }
}
