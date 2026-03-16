import 'package:flutter/cupertino.dart';
import 'package:future_riverpod/features/home/presentation/widgets/full_width_feed_card.dart';

class ResultsList extends StatelessWidget {
  const ResultsList({super.key, required this.items, required this.isAr});

  final List<dynamic> items;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, i) => FullWidthFeedCard(item: items[i]),
    );
  }
}
