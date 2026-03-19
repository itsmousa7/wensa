import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/theme/theme_provider.dart';
import 'package:future_riverpod/core/constants/theme/theme_state.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key, required this.isAr});

  final bool isAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final themeState = ref.watch(appThemeProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          isAr ? 'المظهر' : 'Appearance',
          style: theme.textTheme.titleLarge?.copyWith(color: cs.outline),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          // ── Card ──────────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── Follow Device ──────────────────────────────────────────
                _ThemeRadioTile(
                  icon: Icons.brightness_auto_rounded,
                  title: isAr ? 'تتبع مظهر الجهاز' : 'Follow Device',
                  selected: themeState is SystemTheme,
                  isFirst: true,
                  isLast: false,
                  onTap: () =>
                      ref.read(appThemeProvider.notifier).followSystem(),
                ),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 62,
                  color: cs.onSurface.withValues(alpha: 0.08),
                ),
                // ── Light ──────────────────────────────────────────────────
                _ThemeRadioTile(
                  icon: CupertinoIcons.sun_max_fill,
                  title: isAr ? 'الوضع الفاتح' : 'Light',
                  selected: themeState is LightTheme,
                  isFirst: false,
                  isLast: false,
                  onTap: () => ref
                      .read(appThemeProvider.notifier)
                      .switchTheme(const LightTheme()),
                ),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 62,
                  color: cs.onSurface.withValues(alpha: 0.08),
                ),
                // ── Dark ───────────────────────────────────────────────────
                _ThemeRadioTile(
                  icon: CupertinoIcons.moon_fill,
                  title: isAr ? 'الوضع الداكن' : 'Dark',
                  selected: themeState is DarkTheme,
                  isFirst: false,
                  isLast: true,
                  onTap: () => ref
                      .read(appThemeProvider.notifier)
                      .switchTheme(const DarkTheme()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _ThemeRadioTile
// ─────────────────────────────────────────────────────────────────────────────
class _ThemeRadioTile extends StatelessWidget {
  const _ThemeRadioTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // ── Icon ────────────────────────────────────────────────────────
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: cs.primary),
            ),
            const SizedBox(width: 14),

            // ── Label ────────────────────────────────────────────────────────
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.outline,
                ),
              ),
            ),

            // ── Radio circle ─────────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.3),
                  width: selected ? 0 : 1.5,
                ),
                color: selected ? cs.primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
