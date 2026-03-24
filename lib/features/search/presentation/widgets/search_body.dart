import 'package:flutter/cupertino.dart';
import 'package:future_riverpod/features/search/presentation/providers/search_provider.dart';
import 'package:future_riverpod/features/search/presentation/widgets/empty_hint.dart';
import 'package:future_riverpod/features/search/presentation/widgets/error_search_hint.dart';
import 'package:future_riverpod/features/search/presentation/widgets/idle_hint.dart';
import 'package:future_riverpod/features/search/presentation/widgets/loading_indicator.dart';
import 'package:future_riverpod/features/search/presentation/widgets/results_list.dart';

class SearchBody extends StatelessWidget {
  const SearchBody({super.key, required this.search, required this.isAr});

  final SearchState search;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return switch (search.status) {
      SearchStatus.idle => IdleHint(isAr: isAr),
      SearchStatus.loading => const LoadingIndicator(),
      SearchStatus.error => ErrorSearchHint(isAr: isAr),
      SearchStatus.empty => EmptyHint(query: search.query, isAr: isAr),
      SearchStatus.results => ResultsList(items: search.results, isAr: isAr),
    };
  }
}
