// lib/features/events/presentation/pages/event_details_page.dart
//
// EventDetailsPage — mirrors PlaceDetailsPage 1:1.
// Reuses PlaceImageCarousel, PlaceFullscreenViewer, and PlaceAppBarButton
// directly (no duplication).  Event-specific body is handled by EventInfoSection.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/constants/theme/theme_provider.dart';
import 'package:future_riverpod/core/constants/theme/theme_state.dart';
import 'package:future_riverpod/core/share/content_share_card.dart';
import 'package:future_riverpod/core/share/share_link.dart';
import 'package:future_riverpod/core/share/share_service.dart';
import 'package:future_riverpod/core/widgets/detail_error_page.dart';
import 'package:future_riverpod/features/events/domain/models/event_model.dart';
import 'package:future_riverpod/features/events/domain/repositories/events_repository.dart';
import 'package:future_riverpod/features/events/presentation/providers/event_app_bar_state.dart';
import 'package:future_riverpod/features/events/presentation/providers/event_details_provider.dart';
import 'package:future_riverpod/features/events/presentation/widgets/event_details_skeleton.dart';
import 'package:future_riverpod/features/events/presentation/widgets/event_info_section.dart';
import 'package:future_riverpod/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_appbar_button.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_image_carousel.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';

class EventDetailsPage extends ConsumerStatefulWidget {
  const EventDetailsPage({super.key, required this.eventId});
  final String eventId;

  @override
  ConsumerState<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends ConsumerState<EventDetailsPage> {
  final _pageCtrl = PageController();
  late final ScrollController _scrollCtrl;
  final ShareService _share = ShareService();
  bool _sharing = false;

  String _fmtDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  bool get _isAr => ref.watch(appLocaleProvider) is ArabicLocale;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()
      ..addListener(() {
        ref
            .read(eventAppbarStateProvider(widget.eventId).notifier)
            .onScroll(_scrollCtrl.offset);
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eventAppbarStateProvider(widget.eventId).notifier).recordView();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _onShare(EventModel event) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final name = _isAr
          ? (event.titleAr.isNotEmpty ? event.titleAr : event.titleEn)
          : (event.titleEn.isNotEmpty ? event.titleEn : event.titleAr);
      final subtitle = _fmtDate(event.startDate);
      final cover = event.coverImageUrl;
      final coverBytes = (cover != null && cover.isNotEmpty)
          ? await _share.fetchImageBytes(cover)
          : null;
      if (!mounted) return;
      final png = await _share.renderToPng(
        context,
        ContentShareCard(
          name: name,
          subtitle: subtitle,
          coverBytes: coverBytes,
          isAr: _isAr,
          footerText: _isAr ? 'اكتشفه على ونسة' : 'Discover on Wensa',
        ),
        isAr: _isAr,
      );
      if (!mounted) return;
      final result = await _share.shareImage(
        context,
        png,
        caption: eventShareCaption(name: name, id: event.id, isAr: _isAr),
        fileName: 'wensa_event.png',
      );
      if (result.status != ShareResultStatus.dismissed) {
        ref.read(eventsRepositoryProvider).recordShare(event.id).ignore();
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isAr ? 'تعذّرت المشاركة' : 'Couldn\'t share'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _openFullscreen(List<String> images, int index) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        pageBuilder: (_, _, _) =>
            PlaceFullscreenViewer(images: images, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeState = ref.watch(appThemeProvider);
    final isDark = switch (themeState) {
      DarkTheme() => true,
      LightTheme() => false,
      SystemTheme() =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    final state = ref.watch(eventAppbarStateProvider(widget.eventId));
    final eventAsync = ref.watch(eventDetailsProvider(widget.eventId));
    final collapsed = state.appBarCollapsed;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: collapsed
            ? (isDark ? Brightness.light : Brightness.dark)
            : Brightness.light,
      ),
    );

    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: eventAsync.when(
          loading: () => const EventDetailsSkeleton(),
          error: (e, _) => DetailErrorScreen(
            isAr: _isAr,
            onRetry: () => ref.invalidate(eventDetailsProvider(widget.eventId)),
          ),
          data: (event) {
            final title = _isAr ? event.titleAr : event.titleEn;

            // Events have a single cover image (no gallery table yet).
            final images = [
              if (event.coverImageUrl != null) event.coverImageUrl!,
            ];

            final isFav =
                ref.watch(favoritesProvider).value?.contains(event.id) ?? false;

            final safeIdx = images.isEmpty
                ? 0
                : state.currentImageIndex.clamp(0, images.length - 1);

            return CustomScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  // Same dimensions as PlaceDetailsPage for a seamless feel.
                  expandedHeight: 352,
                  pinned: true,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  automaticallyImplyLeading: false,
                  backgroundColor: collapsed
                      ? theme.scaffoldBackgroundColor
                      : AppColors.transparent,
                  systemOverlayStyle: const SystemUiOverlayStyle(
                    statusBarColor: AppColors.transparent,
                  ),

                  // ── Rounded cap ─────────────────────────────────────────
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(28),
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                    ),
                  ),

                  // ── Collapsed title ──────────────────────────────────────
                  title: collapsed
                      ? Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: cs.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  leadingWidth: 70,
                  toolbarHeight: 50,

                  // ── Back button ──────────────────────────────────────────
                  leading: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 20),
                    child: PlaceAppBarButton(
                      icon: Icon(
                        _isAr
                            ? CupertinoIcons.chevron_right
                            : CupertinoIcons.chevron_left,
                        color: collapsed
                            ? theme.colorScheme.outline
                            : AppColors.white,
                      ),
                      onTap: () => Navigator.pop(context),
                      collapsed: collapsed,
                      sfSymbol: _isAr ? 'chevron.right' : 'chevron.left',
                    ),
                  ),

                  // ── Favourite button ────────────────────────────────────
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4),
                      child: PlaceAppBarButton(
                        icon: Icon(
                          CupertinoIcons.share,
                          color: collapsed ? cs.onSurface : AppColors.white,
                        ),
                        onTap: () => _onShare(event),
                        collapsed: collapsed,
                        sfSymbol: 'square.and.arrow.up',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: PlaceAppBarButton(
                        icon: Icon(
                          isFav
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          color: isFav
                              ? AppColors.alert
                              : (collapsed
                                    ? cs.onSurface
                                    : AppColors.lightRedSecondary),
                        ),
                        onTap: () => ref
                            .read(favoritesProvider.notifier)
                            .toggle(event.id, itemType: 'event'),
                        collapsed: collapsed,
                        animate: true,
                        sfSymbol: isFav ? 'heart.fill' : 'heart',
                      ),
                    ),
                  ],

                  // ── Image carousel ──────────────────────────────────────
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: PlaceImageCarousel(
                      images: images,
                      currentIndex: safeIdx,
                      controller: _pageCtrl,
                      isAr: _isAr,
                      onPageChanged: (i) => ref
                          .read(
                            eventAppbarStateProvider(widget.eventId).notifier,
                          )
                          .setImageIndex(i),
                      onTap: (images.isEmpty || collapsed)
                          ? null
                          : () => _openFullscreen(images, safeIdx),
                    ),
                  ),
                ),

                // ── Info body ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    color: theme.scaffoldBackgroundColor,
                    child: EventInfoSection(
                      event: event,
                      eventId: widget.eventId,
                      isAr: _isAr,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
