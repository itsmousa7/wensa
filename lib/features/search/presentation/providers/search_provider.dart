// lib/features/search/presentation/providers/search_provider.dart

import 'dart:async';

import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';
import 'package:future_riverpod/features/search/domain/repositories/search_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_provider.g.dart';

enum SearchStatus { idle, loading, error, empty, results }

class SearchState {
  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.hasError = false,
  });

  final String query;
  final List<CategoryFeedItem> results;
  final bool isLoading;
  final bool hasError;

  bool get isEmpty => query.trim().isEmpty;
  bool get hasResults => results.isNotEmpty;

  SearchStatus get status {
    if (isEmpty) return SearchStatus.idle;
    if (isLoading) return SearchStatus.loading;
    if (hasError) return SearchStatus.error;
    if (!hasResults) return SearchStatus.empty;
    return SearchStatus.results;
  }

  SearchState copyWith({
    String? query,
    List<CategoryFeedItem>? results,
    bool? isLoading,
    bool? hasError,
  }) => SearchState(
    query: query ?? this.query,
    results: results ?? this.results,
    isLoading: isLoading ?? this.isLoading,
    hasError: hasError ?? this.hasError,
  );
}

@riverpod
class SearchNotifier extends _$SearchNotifier {
  Timer? _debounce;

  static const _debounceDuration = Duration(milliseconds: 400);

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const SearchState();
  }

  void onQueryChanged(String query) {
    _debounce?.cancel();

    state = state.copyWith(
      query: query,
      results: query.trim().isEmpty ? [] : state.results,
      isLoading: query.trim().isNotEmpty,
      hasError: false,
    );

    if (query.trim().isEmpty) return;

    _debounce = Timer(_debounceDuration, () => _fetch(query));
  }

  void clear() {
    _debounce?.cancel();
    state = const SearchState();
  }

  Future<void> _fetch(String query) async {
    try {
      final results = await ref.read(searchRepositoryProvider).search(query);
      if (state.query != query) return;
      state = state.copyWith(
        results: results,
        isLoading: false,
        hasError: false,
      );
    } catch (_) {
      if (state.query != query) return;
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }
}
