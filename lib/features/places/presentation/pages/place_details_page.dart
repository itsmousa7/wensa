// lib/features/places/presentation/pages/place_details_page.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/core/widgets/detail_error_page.dart';
import 'package:future_riverpod/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_app_bar_state.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_appbar_button.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_details_skeleton.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_image_carousel.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_info_section.dart';

class PlaceDetailsPage extends ConsumerStatefulWidget {
  const PlaceDetailsPage({super.key, required this.placeId});
  final String placeId;

  @override
  ConsumerState<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends ConsumerState<PlaceDetailsPage> {
  final _pageCtrl = PageController();
  late final ScrollController _scrollCtrl;

  bool get _isAr => ref.watch(appLocaleProvider) is ArabicLocale;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()
      ..addListener(() {
        ref
            .read(placeAppbarStateProvider(widget.placeId).notifier)
            .onScroll(_scrollCtrl.offset);
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(placeAppbarStateProvider(widget.placeId).notifier).recordView();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(placeAppbarStateProvider(widget.placeId));
    final placeAsync = ref.watch(placeDetailsProvider(widget.placeId));
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
        body: placeAsync.when(
          loading: () => const PlaceDetailsSkeleton(),
          error: (e, _) => DetailErrorScreen(
            isAr: _isAr,
            onRetry: () => ref.invalidate(placeDetailsProvider(widget.placeId)),
          ),
          data: (place) {
            final name = _isAr ? place.nameAr : place.nameEn;
            final images = [
              if (place.coverImageUrl != null) place.coverImageUrl!,
              ...place
                  .additionalImages, // ← reads from the JSONB column directly
            ];
            final isFav =
                ref.watch(favoritesProvider).value?.contains(place.id) ?? false;
            final safeIdx = images.isEmpty
                ? 0
                : state.currentImageIndex.clamp(0, images.length - 1);

            return CustomScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  // 380px image - 28px radius cap = 352px net image height
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

                  // ── Rounded cap — renders ON TOP of the image ──────────
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

                  title: collapsed
                      ? Text(
                          name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: cs.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  leadingWidth: 70,
                  toolbarHeight: 50,
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
                      // ← chevron direction matches RTL/LTR
                      sfSymbol: _isAr ? 'chevron.right' : 'chevron.left',
                    ),
                  ),

                  actions: [
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
                            .toggle(place.id, itemType: 'place'),
                        collapsed: collapsed,
                        animate: true,
                        // ← symbol switches based on current favorite state
                        sfSymbol: isFav ? 'heart.fill' : 'heart',
                      ),
                    ),
                  ],

                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: PlaceImageCarousel(
                      images: images,
                      currentIndex: safeIdx,
                      controller: _pageCtrl,
                      isAr: _isAr,
                      onPageChanged: (i) => ref
                          .read(
                            placeAppbarStateProvider(widget.placeId).notifier,
                          )
                          .setImageIndex(i),
                      onTap: (images.isEmpty || collapsed)
                          ? null
                          : () => _openFullscreen(images, safeIdx),
                    ),
                  ),
                ),

                // ── Info section — same background, seamless join ────────
                SliverToBoxAdapter(
                  child: Container(
                    color: theme.scaffoldBackgroundColor,
                    child: PlaceInfoSection(
                      place: place,
                      placeId: widget.placeId,
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
