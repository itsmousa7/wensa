import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';

/// Guest-count picker shown under the shift picker in [FarmSection]
/// whenever the selected shift has party pricing configured — independent
/// of whether the flat-fee toggle in [PartyOptionCard] is on. Whenever the
/// count exceeds [includedPersons], the per-guest overage fee applies.
/// Purely presentational — the caller owns all state.
class GuestCountCard extends StatefulWidget {
  const GuestCountCard({
    super.key,
    required this.includedPersons,
    required this.extraPersonFeeIqd,
    required this.guestCount,
    required this.onGuestCountChanged,
    this.maxGuests = 100,
    this.showError = false,
  });

  final int includedPersons;
  final int extraPersonFeeIqd;
  final int guestCount;
  final ValueChanged<int> onGuestCountChanged;

  /// Highest selectable guest count on the wheel.
  final int maxGuests;

  /// True once the user has tried to proceed without entering a guest
  /// count — flips the card into its error styling.
  final bool showError;

  static String _formatIqd(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  State<GuestCountCard> createState() => _GuestCountCardState();
}

class _GuestCountCardState extends State<GuestCountCard> {
  static const double _itemExtent = 44;
  static const double _wheelHeight = 48;

  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: _clamped(widget.guestCount));
  }

  @override
  void didUpdateWidget(covariant GuestCountCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _clamped(widget.guestCount);
    // Only drive the wheel when the count was changed from the outside —
    // a change that came from the wheel itself is already in position.
    if (_controller.hasClients && _controller.selectedItem != target) {
      _controller.animateToItem(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _clamped(int value) => value.clamp(0, widget.maxGuests);

  void _onSelected(int index) {
    if (index == widget.guestCount) return;
    HapticFeedback.selectionClick();
    widget.onGuestCountChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final extraGuests = (widget.guestCount - widget.includedPersons).clamp(0, 1 << 30);
    final extraTotal = extraGuests * widget.extraPersonFeeIqd;
    final bool isEmpty = widget.guestCount <= 0;
    final bool hasError = widget.showError && isEmpty;
    final String helperText = hasError
        ? (isAr
            ? 'الرجاء إدخال عدد الأشخاص'
            : 'Please enter the number of guests')
        : extraGuests <= 0
            ? (isAr
                ? 'بدون رسوم إضافية حتى ${widget.includedPersons} ضيوف'
                : 'No extra charge up to ${widget.includedPersons} guests')
            : (isAr
                ? '+${GuestCountCard._formatIqd(extraTotal)} د.ع لـ $extraGuests ضيوف إضافيين'
                : '+${GuestCountCard._formatIqd(extraTotal)} IQD for $extraGuests extra guest(s)');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasError ? AppColors.danger.withValues(alpha: 0.06) : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError ? AppColors.danger : cs.outlineVariant,
          width: hasError ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'كم عدد الأشخاص القادمين؟' : 'How many people are going?',
            style: (tt.bodySmall ?? const TextStyle())
                .copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 8),
          _GuestWheel(
            controller: _controller,
            maxGuests: widget.maxGuests,
            selected: _clamped(widget.guestCount),
            hasError: hasError,
            isRtl: isAr,
            itemExtent: _itemExtent,
            height: _wheelHeight,
            onSelected: _onSelected,
          ),
          const SizedBox(height: 6),
          Text(
            helperText,
            style: (tt.labelSmall ?? const TextStyle()).copyWith(
              color: hasError
                  ? AppColors.danger
                  : extraGuests > 0
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.5),
              fontWeight: hasError || extraGuests > 0
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// The scrollable number strip: a [ListWheelScrollView] turned on its side so
/// the values run horizontally, sitting in a rounded well with the centred
/// value highlighted and the neighbours fading out towards both edges.
class _GuestWheel extends StatelessWidget {
  const _GuestWheel({
    required this.controller,
    required this.maxGuests,
    required this.selected,
    required this.hasError,
    required this.isRtl,
    required this.itemExtent,
    required this.height,
    required this.onSelected,
  });

  final FixedExtentScrollController controller;
  final int maxGuests;
  final int selected;
  final bool hasError;
  final bool isRtl;
  final double itemExtent;
  final double height;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final accent = hasError ? AppColors.danger : cs.primary;

    // quarterTurns 3 lays the list out left-to-right, 1 right-to-left; each
    // child is turned back by the complement so the digits stay upright.
    final int wheelTurns = isRtl ? 1 : 3;
    final int childTurns = isRtl ? 3 : 1;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selection indicator sitting behind the numbers.
          Container(
            width: itemExtent,
            height: height - 10,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0.0, 0.22, 0.78, 1.0],
            ).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: RotatedBox(
              quarterTurns: wheelTurns,
              child: ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: itemExtent,
                physics: const FixedExtentScrollPhysics(),
                diameterRatio: 2.4,
                perspective: 0.004,
                overAndUnderCenterOpacity: 0.45,
                onSelectedItemChanged: onSelected,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: maxGuests + 1,
                  builder: (context, index) {
                    final isSelected = index == selected;
                    return RotatedBox(
                      quarterTurns: childTurns,
                      child: Center(
                        child: Text(
                          '$index',
                          style: (isSelected
                                  ? (tt.titleMedium ?? const TextStyle())
                                  : (tt.bodyMedium ?? const TextStyle()))
                              .copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected
                                ? (hasError ? AppColors.danger : cs.onSurface)
                                : cs.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
