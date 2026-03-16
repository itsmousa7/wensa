// lib/features/search/presentation/pages/search_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/search/presentation/providers/search_provider.dart';
import 'package:future_riverpod/features/search/presentation/widgets/search_body.dart';
import 'package:future_riverpod/features/search/presentation/widgets/search_field.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    ref.read(searchProvider.notifier).onQueryChanged(value);
  }

  void _clear() {
    _controller.clear();
    ref.read(searchProvider.notifier).clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;

    final search = ref.watch(searchProvider);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _focusNode.unfocus(),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          // ── App bar with search field ──────────────────────────────────────
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SearchField(
                controller: _controller,
                focusNode: _focusNode,
                isAr: isAr,
                hasText: search.query.isNotEmpty,
                onChanged: _onChanged,
                onClear: _clear,
              ),
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────────
          body: SearchBody(search: search, isAr: isAr),
        ),
      ),
    );
  }
}
