import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:future_riverpod/features/search/presentation/widgets/android_search_page.dart';
import 'package:future_riverpod/features/search/presentation/widgets/ios_search_page.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Platform.isIOS ? const IosSearchPage() : const AndroidSearchPage();
  }
}
