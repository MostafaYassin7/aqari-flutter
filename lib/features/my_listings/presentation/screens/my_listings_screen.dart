import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/ltr_app_bar.dart';
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
      backgroundColor: context.surface,
      appBar: LtrAppBar(AppBar(
        backgroundColor: context.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            size: 20,
            color: context.textPrimary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'إعلاناتي',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: context.divider),
        ),
      )),
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

            SliverToBoxAdapter(
              child: Divider(
                height: 1,
                thickness: 1,
                color: context.divider,
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
                      color: context.textSecondary,
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
                  child: AppLoadingIndicator(color: AppColors.primary),
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
                    child: AppLoadingIndicator(color: AppColors.primary),
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
      color: context.background,
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
      color: context.background,
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
        color: selected ? AppColors.primary : context.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
        border: Border.all(
          color: selected ? AppColors.primary : context.divider,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: selected ? AppColors.white : context.textPrimary,
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
    final card = GestureDetector(
      onTap: () => context.push('/property/${listing.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
        decoration: BoxDecoration(
          color: context.background,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(color: context.divider),
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
                  color: context.surface,
                  child: Icon(
                    Icons.home_rounded,
                    color: context.textHint,
                    size: 32,
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 90,
                  height: 90,
                  color: context.surface,
                  child: Icon(
                    Icons.home_rounded,
                    color: context.textHint,
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
                      color: context.textPrimary,
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
                      color: context.textSecondary,
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
                        color: context.textSecondary,
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
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      // Views
                      if (listing.viewCount > 0) ...[
                        Icon(
                          Icons.visibility_rounded,
                          size: 12,
                          color: context.textHint,
                        ),
                        SizedBox(width: 3),
                        Text(
                          '${listing.viewCount}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: context.textSecondary,
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
    if (listing.status != 'draft') return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        card,
        Container(
          margin: const EdgeInsets.only(
            top: 4,
            left: AppConstants.spaceM,
            right: AppConstants.spaceM,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8EC),
            border: Border.all(color: AppColors.primary),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'أكمل بيانات الترخيص لنشر هذا الإعلان',
                  style: AppTextStyles.bodySmall,
                ),
              ),
              TextButton(
                onPressed: () =>
                    context.push('/complete-license', extra: listing),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'إكمال الترخيص',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
      color: context.textSecondary,
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  Color _bg(BuildContext context) {
    switch (status) {
      case 'published':
        return AppColors.success.withAlpha(25);
      case 'paused_temp':
        return AppColors.warning.withAlpha(25);
      case 'paused':
        return context.textHint.withAlpha(40);
      case 'expired':
        return AppColors.error.withAlpha(25);
      case 'pending':
        return AppColors.warning.withAlpha(20);
      case 'draft':
        return const Color(0xFF999999).withAlpha(40);
      default:
        return context.textHint.withAlpha(40);
    }
  }

  Color _fg(BuildContext context) {
    switch (status) {
      case 'published':
        return AppColors.success;
      case 'paused_temp':
        return AppColors.warning;
      case 'paused':
        return context.textSecondary;
      case 'expired':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      case 'draft':
        return const Color(0xFF999999);
      default:
        return context.textSecondary;
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
      case 'draft':
        return 'مسودة';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _bg(context),
      borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
      border: Border.all(color: _fg(context).withAlpha(80)),
    ),
    child: Text(
      _label,
      style: AppTextStyles.labelSmall.copyWith(
        color: _fg(context),
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
              color: context.divider,
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد إعلانات',
              style: AppTextStyles.headlineSmall.copyWith(
                color: context.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'أضف إعلانك الأول وابدأ في الوصول إلى المشترين',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
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
