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

    final padding = MediaQuery.of(context).padding; // safe area
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final barBottom = keyboardHeight > 0 ? keyboardHeight : padding.bottom;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            // ── Results — respect top safe area and bottom bar ─────────
            Positioned(
              top: padding.top, // ← pushes content below status bar
              left: 0,
              right: 0,
              bottom: barBottom + IosFloatingSearchBar.totalHeight,
              child: SearchBody(search: search, isAr: isAr),
            ),

            // ── Floating search bar rides the keyboard ─────────────────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              bottom: barBottom,
              child: IosFloatingSearchBar(
                controller: _controller,
                focusNode: _focusNode,
                isAr: isAr,
                hasText: search.query.isNotEmpty,
                onChanged: _onChanged,
                onClearText: _clearText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
