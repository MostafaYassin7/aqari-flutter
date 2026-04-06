import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/listing.dart' show formatPrice;
import '../../../../shared/models/listing_category.dart';
import '../providers/my_listings_provider.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncListings = ref.watch(myListingsProvider);
    final listings = asyncListings.value ?? <MyListing>[];

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 20,
            color: AppColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'إعلاناتي',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.dividerLight),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200) {
            ref.read(myListingsProvider.notifier).loadMore();
          }
          return false;
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Category filter ───────────────────────────────
            const SliverToBoxAdapter(child: _CategoryFilter()),

            // ── Status filter ─────────────────────────────────
            const SliverToBoxAdapter(child: _StatusFilter()),

            const SliverToBoxAdapter(
              child: Divider(
                height: 1,
                thickness: 1,
                color: AppColors.dividerLight,
              ),
            ),

            // ── Results count ─────────────────────────────────
            if (!asyncListings.isLoading && listings.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    '${listings.length} إعلان',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // ── Loading / Empty / List ────────────────────────
            if (asyncListings.isLoading && listings.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (!asyncListings.isLoading && listings.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.spaceXS / 2,
                    ),
                    child: _MyListingCard(listing: listings[i]),
                  ),
                  childCount: listings.length,
                ),
              ),

            if (asyncListings.isLoading && listings.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),

      // ── FAB ──────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addListing),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

// ── Category filter (horizontal chips from API) ───────────────────────────────

class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCategories = ref.watch(listingCategoriesProvider);
    final categories = asyncCategories.value ?? <ListingCategory>[];
    final selected = ref.watch(selectedCategoryProvider);

    return Container(
      color: AppColors.backgroundLight,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceM,
        12,
        AppConstants.spaceM,
        4,
      ),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            if (i == 0) {
              return _ChipButton(
                label: 'الكل',
                selected: selected == null,
                onTap: () =>
                    ref.read(selectedCategoryProvider.notifier).select(null),
              );
            }
            final cat = categories[i - 1];
            return _ChipButton(
              label: cat.nameAr,
              selected: selected == cat.id,
              onTap: () =>
                  ref.read(selectedCategoryProvider.notifier).select(cat.id),
            );
          },
        ),
      ),
    );
  }
}

// ── Status filter (horizontal chips) ──────────────────────────────────────────

class _StatusFilter extends ConsumerWidget {
  const _StatusFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedStatusProvider);

    return Container(
      color: AppColors.backgroundLight,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceM,
        4,
        AppConstants.spaceM,
        10,
      ),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: statusFilters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final entry = statusFilters.entries.elementAt(i);
            return _ChipButton(
              label: entry.value,
              selected: selected == entry.key,
              onTap: () =>
                  ref.read(selectedStatusProvider.notifier).select(entry.key),
            );
          },
        ),
      ),
    );
  }
}

// ── Generic chip ──────────────────────────────────────────────────────────────

class _ChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.dividerLight,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: selected ? AppColors.white : AppColors.textPrimaryLight,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
  );
}

// ── My listing card ───────────────────────────────────────────────────────────

class _MyListingCard extends StatelessWidget {
  final MyListing listing;
  const _MyListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/property/${listing.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(color: AppColors.dividerLight),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              child: CachedNetworkImage(
                imageUrl: listing.coverPhoto ?? '',
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 90,
                  height: 90,
                  color: AppColors.surfaceLight,
                  child: const Icon(
                    Icons.home_rounded,
                    color: AppColors.textHintLight,
                    size: 32,
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 90,
                  height: 90,
                  color: AppColors.surfaceLight,
                  child: const Icon(
                    Icons.home_rounded,
                    color: AppColors.textHintLight,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ─────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    listing.title,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Category + Ad number
                  Text(
                    [
                      if (listing.category != null) listing.category!.nameAr,
                      listing.adNumber,
                    ].where((s) => s.isNotEmpty).join('  ·  '),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // City + district
                  if (listing.city.isNotEmpty)
                    Text(
                      [listing.city, listing.district]
                          .where((s) => s.isNotEmpty && s != 'string')
                          .join('  ·  '),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  const SizedBox(height: 4),

                  // Stats
                  Wrap(
                    spacing: 8,
                    children: [
                      if (listing.area > 0)
                        _Stat('${listing.area.toStringAsFixed(0)} م²'),
                      if (listing.bedrooms > 0)
                        _Stat('${listing.bedrooms} غرف'),
                      if (listing.bathrooms > 0)
                        _Stat('${listing.bathrooms} حمام'),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Price + badges row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatPrice(listing.totalPrice),
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      // Views
                      if (listing.viewCount > 0) ...[
                        Icon(
                          Icons.visibility_rounded,
                          size: 12,
                          color: AppColors.textHintLight,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${listing.viewCount}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Message count
                      if (listing.messageCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusCircle,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.message_rounded,
                                size: 10,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${listing.messageCount}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Status badge
                      _StatusBadge(listing.status),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String text;
  const _Stat(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.bodySmall.copyWith(
      color: AppColors.textSecondaryLight,
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  Color get _bg {
    switch (status) {
      case 'published':
        return AppColors.success.withAlpha(25);
      case 'paused_temp':
        return AppColors.warning.withAlpha(25);
      case 'paused':
        return AppColors.textHintLight.withAlpha(40);
      case 'expired':
        return AppColors.error.withAlpha(25);
      case 'pending':
        return AppColors.warning.withAlpha(20);
      default:
        return AppColors.textHintLight.withAlpha(40);
    }
  }

  Color get _fg {
    switch (status) {
      case 'published':
        return AppColors.success;
      case 'paused_temp':
        return AppColors.warning;
      case 'paused':
        return AppColors.textSecondaryLight;
      case 'expired':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  String get _label {
    switch (status) {
      case 'published':
        return 'منشور';
      case 'paused_temp':
        return 'موقوف مؤقتاً';
      case 'paused':
        return 'موقوف';
      case 'expired':
        return 'منتهي';
      case 'pending':
        return 'قيد المراجعة';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _bg,
      borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
      border: Border.all(color: _fg.withAlpha(80)),
    ),
    child: Text(
      _label,
      style: AppTextStyles.labelSmall.copyWith(
        color: _fg,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 80,
              color: AppColors.dividerLight,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد إعلانات',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'أضف إعلانك الأول وابدأ في الوصول إلى المشترين',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.addListing),
              icon: const Icon(Icons.add_rounded),
              label: const Text('أضف أول إعلان'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                minimumSize: const Size(200, AppConstants.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                elevation: 0,
                textStyle: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
