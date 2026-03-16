import 'package:flutter/material.dart';
import 'package:future_riverpod/features/profile/presentation/widgets/profile_error.dart';

class ErrorSearchHint extends StatelessWidget {
  const ErrorSearchHint({super.key, required this.isAr});
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GlobalErrorWidget(cs: cs, isAr: isAr, tt: tt);
  }
}
