import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_text_field.dart';




class HomeSearchBar extends ConsumerStatefulWidget {
  const HomeSearchBar({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends ConsumerState<HomeSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;

    final hint = isAr
        ? 'ابحث عن أماكن وفعاليات...'
        : 'Search for places and events...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
      child: Form(
        key: _formKey,
        child: AppTextField(
          hint: hint,
          controller: _controller,
          prefixIcon: Icon(CupertinoIcons.search),
        ),
      ),
    );
  }
}
