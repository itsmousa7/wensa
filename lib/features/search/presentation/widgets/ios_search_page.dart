import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/search/presentation/providers/search_provider.dart';
import 'package:future_riverpod/features/search/presentation/widgets/ios_floating_search_bar.dart';
import 'package:future_riverpod/features/search/presentation/widgets/search_body.dart';

class IosSearchPage extends ConsumerStatefulWidget {
  const IosSearchPage({super.key});

  @override
  ConsumerState<IosSearchPage> createState() => _IosSearchPageState();
}

class _IosSearchPageState extends ConsumerState<IosSearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) =>
      ref.read(searchProvider.notifier).onQueryChanged(value);

  void _clearText() {
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
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SearchBody(search: search, isAr: isAr),
              ),
              IosFloatingSearchBar(
                controller: _controller,
                focusNode: _focusNode,
                isAr: isAr,
                hasText: search.query.isNotEmpty,
                onChanged: _onChanged,
                onClearText: _clearText,
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
