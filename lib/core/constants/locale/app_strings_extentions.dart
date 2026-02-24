// lib/core/constants/locale/app_strings_extentions.dart
import 'package:flutter/material.dart';

import 'app_strings.dart';

extension AppStringsExtension on BuildContext {
  String tr(String key) {
    final languageCode = Localizations.localeOf(this).languageCode;
    return AppStrings.get(key, languageCode);
  }
}
