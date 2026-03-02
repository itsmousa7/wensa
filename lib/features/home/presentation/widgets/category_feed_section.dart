// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
// import 'package:future_riverpod/core/constants/locale/locale_state.dart';
// import 'package:future_riverpod/features/home/presentation/providers/category_feed_provider.dart';
// import 'package:skeletonizer/skeletonizer.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// //  CategoryFeedSection
// //
// //  ✅ Every code-path returns a Sliver widget so it can live directly
// //     inside a CustomScrollView slivers list without wrapping errors.
// // ─────────────────────────────────────────────────────────────────────────────
// class CategoryFeedSection extends ConsumerWidget {
//   const CategoryFeedSection({
//     super.key,
//     required this.categoryId,
//     required this.categoryNameEn,
//     required this.categoryNameAr,
//   });

//   final String categoryId;
//   final String categoryNameEn;
//   final String categoryNameAr;

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final feed = ref.watch(categoryFeedProvider(categoryId));
//     final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
//     final theme = Theme.of(context).colorScheme;
//     final textTheme = Theme.of(context).textTheme;

//     // ── First-page loading ─────────────────────────────────────────────────
//     if (feed.items.isEmpty && feed.isLoading) {
//       return _SkeletonSliver(theme: theme);
//     }

//     // ── Empty state — wrapped in SliverToBoxAdapter ✅ ─────────────────────
//     if (feed.items.isEmpty && !feed.hasMore) {
//       final name = isAr ? categoryNameAr : categoryNameEn;
//       return SliverToBoxAdapter(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 22),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 Icons.search_off_rounded,
//                 size: 48,
//                 color: theme.onSurface.withValues(alpha: 0.25),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 isAr
//                     ? 'لا توجد أماكن في فئة $name'
//                     : 'No places found in $name',
//                 textAlign: TextAlign.center,
//                 style: textTheme.bodyMedium?.copyWith(
//                   color: theme.onSurface.withValues(alpha: 0.45),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     // ── Feed list — SliverList ✅ ────────────────────────────────────────────
//     return SliverList(
//       delegate: SliverChildBuilderDelegate((context, index) {
//         // Footer: load-more or end caption
//         if (index == feed.items.length) {
//           if (feed.hasMore) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               ref.read(categoryFeedProvider(categoryId).notifier).loadMore();
//             });
//             return _LoadMoreIndicator(theme: theme);
//           }
//           return _EndCaption(isAr: isAr, textTheme: textTheme, theme: theme);
//         }

//         return Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
//           child: _FeedCard(item: feed.items[index], isAr: isAr),
//         );
//       }, childCount: feed.items.length + 1),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// //  _SkeletonSliver — SliverList skeleton (first-load state) ✅
// // ─────────────────────────────────────────────────────────────────────────────
// class _SkeletonSliver extends StatelessWidget {
//   const _SkeletonSliver({required this.theme});
//   final ColorScheme theme;

//   @override
//   Widget build(BuildContext context) => SliverList(
//     delegate: SliverChildBuilderDelegate(
//       (_, __) => Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
//         child: Skeletonizer(
//           enabled: true,
//           effect: ShimmerEffect(
//             baseColor: theme.surfaceContainer,
//             highlightColor: theme.surfaceContainerHighest,
//           ),
//           child: Container(
//             height: 260,
//             decoration: BoxDecoration(
//               color: theme.surfaceContainer,
//               borderRadius: BorderRadius.circular(20),
//             ),
//           ),
//         ),
//       ),
//       childCount: 4,
//     ),
//   );
// }

// // ─────────────────────────────────────────────────────────────────────────────
// //  _FeedCard — full-width tappable card, no Explore button
// // ─────────────────────────────────────────────────────────────────────────────
// class _FeedCard extends StatelessWidget {
//   const _FeedCard({required this.item, required this.isAr});

//   final CategoryFeedItem item;
//   final bool isAr;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context).colorScheme;
//     final textTheme = Theme.of(context).textTheme;

//     final title = isAr ? item.titleAr : item.titleEn;
//     final subtitle = isAr ? item.subtitleAr : item.subtitleEn;

//     return GestureDetector(
//       onTap: () {
//         // TODO: Navigate to place detail
//       },
//       child: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: theme.surfaceContainer,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: theme.surfaceContainerHighest.withValues(alpha: 0.4),
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // ── Cover image ────────────────────────────────────────────────
//             Stack(
//               children: [
//                 ClipRRect(
//                   borderRadius: const BorderRadius.vertical(
//                     top: Radius.circular(20),
//                   ),
//                   child: SizedBox(
//                     height: 200,
//                     width: double.infinity,
//                     child: item.coverImageUrl != null
//                         ? CachedNetworkImage(
//                             imageUrl: item.coverImageUrl!,
//                             fit: BoxFit.cover,
//                             placeholder: (_, __) =>
//                                 Container(color: theme.surfaceContainerHighest),
//                             errorWidget: (_, __, ___) =>
//                                 Container(color: theme.surfaceContainerHighest),
//                           )
//                         : Container(color: theme.surfaceContainerHighest),
//                   ),
//                 ),

//                 // Gradient overlay
//                 Positioned.fill(
//                   child: ClipRRect(
//                     borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(20),
//                     ),
//                     child: DecoratedBox(
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           begin: Alignment.topCenter,
//                           end: Alignment.bottomCenter,
//                           colors: [
//                             Colors.transparent,
//                             Colors.black.withValues(alpha: 0.35),
//                           ],
//                           stops: const [0.5, 1.0],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),

//                 // Verified badge — top trailing corner
//                 if (item.isVerified)
//                   Positioned(
//                     top: 12,
//                     right: isAr ? null : 12,
//                     left: isAr ? 12 : null,
//                     child: Container(
//                       width: 30,
//                       height: 30,
//                       decoration: BoxDecoration(
//                         color: Colors.black.withValues(alpha: 0.45),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Center(
//                         child: Icon(
//                           Icons.verified_rounded,
//                           size: 16,
//                           color: theme.secondary,
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),

//             // ── Text area ──────────────────────────────────────────────────
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: textTheme.titleMedium?.copyWith(
//                       color: theme.onSurface,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   if (subtitle != null) ...[
//                     const SizedBox(height: 6),
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.location_on_rounded,
//                           size: 13,
//                           color: theme.primary,
//                         ),
//                         const SizedBox(width: 4),
//                         Expanded(
//                           child: Text(
//                             subtitle,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: textTheme.bodySmall?.copyWith(
//                               color: theme.onSurface.withValues(alpha: 0.55),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Helper widgets ────────────────────────────────────────────────────────────
// class _LoadMoreIndicator extends StatelessWidget {
//   const _LoadMoreIndicator({required this.theme});
//   final ColorScheme theme;

//   @override
//   Widget build(BuildContext context) => Padding(
//     padding: const EdgeInsets.symmetric(vertical: 20),
//     child: Center(
//       child: SizedBox(
//         width: 20,
//         height: 20,
//         child: CircularProgressIndicator(strokeWidth: 2, color: theme.primary),
//       ),
//     ),
//   );
// }

// class _EndCaption extends StatelessWidget {
//   const _EndCaption({
//     required this.isAr,
//     required this.textTheme,
//     required this.theme,
//   });
//   final bool isAr;
//   final TextTheme textTheme;
//   final ColorScheme theme;

//   @override
//   Widget build(BuildContext context) => Padding(
//     padding: const EdgeInsets.symmetric(vertical: 24),
//     child: Center(
//       child: Text(
//         isAr ? '— لقد وصلت للنهاية —' : '— You\'ve reached the end —',
//         style: textTheme.labelSmall?.copyWith(
//           color: theme.onSurface.withValues(alpha: 0.3),
//         ),
//       ),
//     ),
//   );
// }
