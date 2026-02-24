// lib/core/constants/locale/locale_state.dart
sealed class LocaleState {
  const LocaleState();
}

final class EnglishLocale extends LocaleState {
  const EnglishLocale();
}

final class ArabicLocale extends LocaleState {
  const ArabicLocale();
}

final class SystemLocale extends LocaleState {
  const SystemLocale();
}