// lib/features/places/presentation/pages/place_details_page.dart
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_provider.dart';
import 'package:future_riverpod/features/home/presentation/providers/favorites_provider.dart';
import 'package:future_riverpod/features/places/domain/models/place_model.dart';
import 'package:future_riverpod/features/places/domain/repositories/place_details_repository.dart';
import 'package:future_riverpod/features/places/presentation/pages/place_location_sheet.dart';
import 'package:future_riverpod/features/places/presentation/pages/place_reviews_sheet.dart';
import 'package:future_riverpod/features/places/presentation/providers/place_details_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PlaceDetailsPage
// ─────────────────────────────────────────────────────────────────────────────

class PlaceDetailsPage extends ConsumerStatefulWidget {
  const PlaceDetailsPage({super.key, required this.placeId});
  final String placeId;

  @override
  ConsumerState<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends ConsumerState<PlaceDetailsPage> {
  final _pageCtrl = PageController();
  final _scrollCtrl = ScrollController();

  int _currentImageIndex = 0;
  bool _descExpanded = false;

  // ── AppBar collapse tracking ─────────────────────────────────────────────
  // Threshold: hero is 380 px tall, collapsed bar is kToolbarHeight (~56 px)
  // So once user scrolls past (380 - 56) = 324 px, the bar is fully collapsed.
  static const _heroHeight = 380.0;
  bool _appBarCollapsed = false;

  bool get _isAr => ref.watch(appLocaleProvider) is ArabicLocale;
  TextTheme get _tt => AppTypography.getTextTheme(_isAr ? 'ar' : 'en', context);

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordView());
  }

  void _onScroll() {
    final collapsed =
        _scrollCtrl.hasClients &&
        _scrollCtrl.offset > (_heroHeight - kToolbarHeight - 10);
    if (collapsed != _appBarCollapsed) {
      setState(() => _appBarCollapsed = collapsed);
    }
  }

  void _recordView() {
    final userId = ref.read(authStateProvider)?.id;
    if (userId == null) return;
    ref
        .read(placeDetailsRepositoryProvider)
        .recordView(widget.placeId, userId)
        .ignore();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Status bar icons: white over the hero image, theme-aware when collapsed
    final overlayStyle = _appBarCollapsed
        ? SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          )
        : const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          );

    SystemChrome.setSystemUIOverlayStyle(overlayStyle);

    final placeAsync = ref.watch(placeDetailsProvider(widget.placeId));
    final imagesAsync = ref.watch(placeImagesProvider(widget.placeId));
    final tagsAsync = ref.watch(placeTagsProvider(widget.placeId));
    final cs = theme.colorScheme;

    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: placeAsync.when(
          loading: () => _buildSkeleton(theme),
          error: (e, _) => _buildError(e.toString()),
          data: (place) {
            final extraImages = imagesAsync.value ?? [];
            final allImages = [
              if (place.coverImageUrl != null) place.coverImageUrl!,
              ...extraImages.map((img) => img.imageUrl),
            ];

            final isFav =
                ref.watch(favoritesProvider).value?.contains(place.id) ?? false;
            final name = _isAr ? place.nameAr : place.nameEn;

            return CustomScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Hero Image Carousel ──────────────────────────────────
                SliverAppBar(
                  expandedHeight: _heroHeight,
                  pinned: true,
                  // ── Dynamic background: transparent over hero, surface when collapsed
                  backgroundColor: _appBarCollapsed
                      ? theme.scaffoldBackgroundColor
                      : Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  systemOverlayStyle: overlayStyle,
                  // ── Place name appears in the bar when collapsed
                  title: _appBarCollapsed
                      ? Text(
                          name,
                          style: _tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  centerTitle: true,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: _ImageCarousel(
                      images: allImages,
                      currentIndex: _currentImageIndex,
                      controller: _pageCtrl,
                      isAr: _isAr,
                      onPageChanged: (i) =>
                          setState(() => _currentImageIndex = i),
                      onImageTap: allImages.isEmpty
                          ? null
                          : () => _openFullscreen(
                              context,
                              allImages,
                              _currentImageIndex,
                            ),
                    ),
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: _GlassButton(
                      onTap: () => Navigator.of(context).pop(),
                      collapsed: _appBarCollapsed,
                      child: Icon(
                        _isAr
                            ? CupertinoIcons.chevron_right
                            : CupertinoIcons.chevron_left,
                        color: _appBarCollapsed ? cs.onSurface : Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12, top: 4),
                      child: _HeartButton(
                        isFavorite: isFav,
                        collapsed: _appBarCollapsed,
                        onTap: () => ref
                            .read(favoritesProvider.notifier)
                            .toggle(place.id, itemType: 'place'),
                      ),
                    ),
                  ],
                ),

                // ── Content ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _ContentPanel(
                    place: place,
                    isAr: _isAr,
                    tt: _tt,
                    descExpanded: _descExpanded,
                    onExpandDesc: () =>
                        setState(() => _descExpanded = !_descExpanded),
                    tagsAsync: tagsAsync,
                    placeId: widget.placeId,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openFullscreen(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) =>
            _FullscreenViewer(images: images, initialIndex: initialIndex),
      ),
    );
  }

  Widget _buildSkeleton(ThemeData theme) => Skeletonizer(
    enabled: true,
    effect: ShimmerEffect(
      baseColor: theme.colorScheme.surfaceContainer,
      highlightColor: theme.colorScheme.surfaceContainerHighest,
    ),
    child: CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: _heroHeight,
          backgroundColor: theme.colorScheme.surfaceContainer,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(22),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Container(
                height: 28,
                width: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 16,
                width: 140,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ]),
          ),
        ),
      ],
    ),
  );

  Widget _buildError(String msg) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          msg,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  _ImageCarousel
// ─────────────────────────────────────────────────────────────────────────────

class _ImageCarousel extends StatelessWidget {
  const _ImageCarousel({
    required this.images,
    required this.currentIndex,
    required this.controller,
    required this.isAr,
    required this.onPageChanged,
    this.onImageTap,
  });

  final List<String> images;
  final int currentIndex;
  final PageController controller;
  final bool isAr;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onImageTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (images.isEmpty)
          Container(color: cs.surfaceContainer)
        else
          GestureDetector(
            onTap: onImageTap,
            child: PageView.builder(
              controller: controller,
              itemCount: images.length,
              physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
              onPageChanged: onPageChanged,
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: images[i],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: cs.surfaceContainer),
                errorWidget: (_, __, ___) =>
                    Container(color: cs.surfaceContainer),
              ),
            ),
          ),

        // Bottom gradient
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Top gradient
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 100,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Counter pill
        if (images.length > 1)
          Positioned(
            bottom: 52,
            left: isAr ? 18 : null,
            right: isAr ? null : 18,
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${currentIndex + 1} / ${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Tap hint icon
        if (images.isNotEmpty)
          Positioned(
            bottom: 50,
            left: isAr ? null : 18,
            right: isAr ? 18 : null,
            child: IgnorePointer(
              child: Icon(
                Icons.open_in_full_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 16,
              ),
            ),
          ),

        // Dot indicators
        if (images.length > 1 && images.length <= 10)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == currentIndex ? 18 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i == currentIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _FullscreenViewer
// ─────────────────────────────────────────────────────────────────────────────

class _FullscreenViewer extends StatefulWidget {
  const _FullscreenViewer({required this.images, required this.initialIndex});
  final List<String> images;
  final int initialIndex;

  @override
  State<_FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<_FullscreenViewer> {
  late final PageController _ctrl = PageController(
    initialPage: widget.initialIndex,
  );
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      children: [
        PageView.builder(
          controller: _ctrl,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (_, i) => InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.images[i],
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
        if (widget.images.length > 1)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: Text(
              '${_currentIndex + 1} / ${widget.images.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  _ContentPanel
// ─────────────────────────────────────────────────────────────────────────────

class _ContentPanel extends ConsumerWidget {
  const _ContentPanel({
    required this.place,
    required this.isAr,
    required this.tt,
    required this.descExpanded,
    required this.onExpandDesc,
    required this.tagsAsync,
    required this.placeId,
  });

  final PlaceModel place;
  final bool isAr;
  final TextTheme tt;
  final bool descExpanded;
  final VoidCallback onExpandDesc;
  final AsyncValue tagsAsync;
  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final name = isAr ? place.nameAr : place.nameEn;
    final desc = isAr ? place.descriptionAr : place.descriptionEn;
    const descLimit = 160;
    final descLong = (desc ?? '').length > descLimit;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name + Verified ─────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
              if (place.isVerified) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: isAr ? 'موثّق' : 'Verified',
                  child: const Icon(
                    Icons.verified_rounded,
                    color: AppColors.lightGreenSecondary,
                    size: 22,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // ── Location chip ────────────────────────────────────────────
          if (place.area != null || place.city.isNotEmpty)
            GestureDetector(
              onTap: (place.latitude != null && place.longitude != null)
                  ? () => showLocationSheet(
                      context: context,
                      latitude: place.latitude!,
                      longitude: place.longitude!,
                      placeName: name,
                      isAr: isAr,
                    )
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      [
                        if (place.area != null && place.area!.isNotEmpty)
                          place.area!,
                        if (place.city.isNotEmpty) place.city,
                      ].join(' · '),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (place.latitude != null && place.longitude != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 12,
                        color: cs.primary.withValues(alpha: 0.7),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ── Stats row ────────────────────────────────────────────────
          Row(
            children: [
              _StatChip(
                icon: Icons.visibility_outlined,
                value: _compact(place.viewCount),
                label: isAr ? 'مشاهدة' : 'Views',
                cs: cs,
                tt: tt,
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.bookmark_border_rounded,
                value: _compact(place.savesCount),
                label: isAr ? 'حفظ' : 'Saves',
                cs: cs,
                tt: tt,
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => showReviewsSheet(
                  context: context,
                  placeId: placeId,
                  placeName: name,
                  isAr: isAr,
                ),
                child: _StatChip(
                  icon: Icons.star_rounded,
                  value: _compact(place.reviewsCount),
                  label: isAr ? 'تقييم' : 'Reviews',
                  cs: cs,
                  tt: tt,
                  highlighted: true,
                ),
              ),
            ],
          ),

          // ── Price range ──────────────────────────────────────────────
          if (place.priceRange != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  isAr ? 'نطاق السعر:' : 'Price range:',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: List.generate(
                    4,
                    (i) => Text(
                      '\$',
                      style: tt.bodyMedium?.copyWith(
                        color: i < (place.priceRange ?? 0)
                            ? AppColors.lightGreenSecondary
                            : cs.onSurface.withValues(alpha: 0.2),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ── Tags ─────────────────────────────────────────────────────
          tagsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (tags) {
              if ((tags as List).isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            isAr ? tag.nameAr : tag.nameEn,
                            style: tt.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),

          // ── Description ──────────────────────────────────────────────
          if (desc != null && desc.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(title: isAr ? 'عن المكان' : 'About', tt: tt, cs: cs),
            const SizedBox(height: 10),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: descExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(
                descLong && !descExpanded
                    ? '${desc.substring(0, descLimit)}...'
                    : desc,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.72),
                  height: 1.65,
                ),
              ),
              secondChild: Text(
                desc,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.72),
                  height: 1.65,
                ),
              ),
            ),
            if (descLong)
              GestureDetector(
                onTap: onExpandDesc,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    descExpanded
                        ? (isAr ? 'عرض أقل' : 'Show less')
                        : (isAr ? 'اقرأ المزيد' : 'Read more'),
                    style: tt.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],

          // ── Opening Hours (collapsible) ────────────────────────────
          if (place.openingHours != null && place.openingHours!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _OpeningHoursWidget(
              hours: place.openingHours!,
              isAr: isAr,
              tt: tt,
              cs: cs,
            ),
          ],

          // ── Contact ─────────────────────────────────────────────────
          if (place.phone != null ||
              place.instagramUrl != null ||
              place.websiteUrl != null) ...[
            const SizedBox(height: 24),
            _SectionHeader(title: isAr ? 'التواصل' : 'Contact', tt: tt, cs: cs),
            const SizedBox(height: 12),
            _ContactRow(place: place, isAr: isAr, tt: tt, cs: cs),
          ],

          // ── Reviews CTA button ────────────────────────────────────────
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => showReviewsSheet(
              context: context,
              placeId: placeId,
              placeName: name,
              isAr: isAr,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, AppColors.lightGreenSecondary],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isAr
                        ? 'التقييمات (${place.reviewsCount})'
                        : 'Reviews (${place.reviewsCount})',
                    style: tt.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _OpeningHoursWidget
//  ── Week displayed Sun → Sat (matches Middle East convention)
//  ── JSON keys in Supabase are 3-letter: sun/mon/tue/wed/thu/fri/sat
//  ── Values are "HH:MM-HH:MM" e.g. "08:00-00:00"
//  ── Collapsed by default — shows only today's row
// ─────────────────────────────────────────────────────────────────────────────

class _OpeningHoursWidget extends StatefulWidget {
  const _OpeningHoursWidget({
    required this.hours,
    required this.isAr,
    required this.tt,
    required this.cs,
  });
  final Map<String, dynamic> hours;
  final bool isAr;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  State<_OpeningHoursWidget> createState() => _OpeningHoursWidgetState();
}

class _OpeningHoursWidgetState extends State<_OpeningHoursWidget> {
  bool _expanded = false;

  // Week starts Sunday — order matches Middle East convention.
  // Keys must match exactly what is stored in Supabase JSONB.
  static const _keys = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
  static const _daysEn = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  static const _daysAr = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  @override
  Widget build(BuildContext context) {
    // DateTime.weekday: 1=Mon … 7=Sun
    // Map to our 0-based Sun-first index:  weekday % 7  (7%7=0=Sun, 1%7=1=Mon … 6%7=6=Sat)
    final todayIndex = DateTime.now().weekday % 7;
    final cs = widget.cs;
    final tt = widget.tt;
    final isAr = widget.isAr;

    final indicesToShow = _expanded ? List.generate(7, (i) => i) : [todayIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header (tappable) ──────────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isAr ? 'أوقات العمل' : 'Opening Hours',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 220),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── Rows (animated expand/collapse) ────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: indicesToShow.map((i) {
                final key = _keys[i];
                // Value is e.g. "08:00-00:00" — show as-is
                final val =
                    widget.hours[key]?.toString() ?? (isAr ? 'مغلق' : 'Closed');
                final isToday = i == todayIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          isAr ? _daysAr[i] : _daysEn[i],
                          style: tt.bodySmall?.copyWith(
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isToday
                                ? cs.primary
                                : cs.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            val,
                            style: tt.bodySmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        Text(
                          val,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Small private widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Glass button that becomes a plain icon button when the app bar is collapsed
class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.child,
    required this.onTap,
    this.collapsed = false,
  });
  final Widget child;
  final VoidCallback onTap;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (collapsed) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: child),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _HeartButton extends ConsumerStatefulWidget {
  const _HeartButton({
    required this.isFavorite,
    required this.onTap,
    this.collapsed = false,
  });
  final bool isFavorite;
  final VoidCallback onTap;
  final bool collapsed;

  @override
  ConsumerState<_HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends ConsumerState<_HeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _scale = Tween(
    begin: 1.0,
    end: 1.4,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

  void _onTap() {
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onTap();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = widget.isFavorite
        ? Colors.redAccent
        : (widget.collapsed ? cs.onSurface : Colors.white);

    Widget icon = ScaleTransition(
      scale: _scale,
      child: Icon(
        widget.isFavorite
            ? Icons.favorite_rounded
            : Icons.favorite_border_rounded,
        color: iconColor,
        size: 20,
      ),
    );

    if (widget.collapsed) {
      return GestureDetector(
        onTap: _onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: icon),
        ),
      );
    }

    return GestureDetector(
      onTap: _onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.cs,
    required this.tt,
    this.highlighted = false,
  });
  final IconData icon;
  final String value;
  final String label;
  final ColorScheme cs;
  final TextTheme tt;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: highlighted
          ? cs.primary.withValues(alpha: 0.08)
          : cs.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      border: highlighted
          ? Border.all(color: cs.primary.withValues(alpha: 0.25))
          : null,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: highlighted ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 5),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: tt.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: highlighted ? cs.primary : cs.onSurface,
              ),
            ),
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.tt,
    required this.cs,
  });
  final String title;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 3,
        height: 18,
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
    ],
  );
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.place,
    required this.isAr,
    required this.tt,
    required this.cs,
  });
  final PlaceModel place;
  final bool isAr;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      if (place.phone != null)
        _ContactChip(
          icon: Icons.phone_outlined,
          label: place.phone!,
          color: const Color(0xFF34C759),
          onTap: () => _launch('tel:${place.phone}'),
          cs: cs,
          tt: tt,
        ),
      if (place.instagramUrl != null)
        _ContactChip(
          icon: Icons.camera_alt_outlined,
          label: 'Instagram',
          color: const Color(0xFFE1306C),
          onTap: () => _launch(place.instagramUrl!),
          cs: cs,
          tt: tt,
        ),
      if (place.websiteUrl != null)
        _ContactChip(
          icon: Icons.language_outlined,
          label: isAr ? 'الموقع الإلكتروني' : 'Website',
          color: const Color(0xFF007AFF),
          onTap: () => _launch(place.websiteUrl!),
          cs: cs,
          tt: tt,
        ),
    ],
  );

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.cs,
    required this.tt,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: tt.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
