import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/profile/presentation/widgets/profile_error.dart';
import 'package:future_riverpod/features/search/presentation/providers/search_provider.dart';

class ErrorSearchHint extends ConsumerWidget {
  const ErrorSearchHint({super.key, required this.isAr});
  final bool isAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GlobalErrorWidget(
      cs: cs,
      isAr: isAr,
      tt: tt,
      onTap: () => ref.invalidate(searchProvider),
    );
  }
}
