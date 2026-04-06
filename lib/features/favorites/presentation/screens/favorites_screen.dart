import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/listing.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../providers/favorites_provider.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';

// ── View mode toggle provider ─────────────────────────────────────────────────

class _ViewModeNotifier extends Notifier<bool> {
  @override
  bool build() => true; // true = grid, false = list
  void toggle() => state = !state;
}

final _viewModeProvider = NotifierProvider<_ViewModeNotifier, bool>(
  _ViewModeNotifier.new,
);

// ── Screen ────────────────────────────────────────────────────────────────────

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFavorites = ref.watch(apiFavoritesProvider);
    final listings = asyncFavorites.value ?? <Listing>[];
    final isGrid = ref.watch(_viewModeProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
          'المفضلة',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
        actions: [
          if (listings.isNotEmpty)
            IconButton(
              icon: Icon(
                isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: AppColors.textPrimaryLight,
                size: 22,
              ),
              onPressed: () => ref.read(_viewModeProvider.notifier).toggle(),
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.dividerLight),
        ),
      ),
      body: asyncFavorites.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => const _EmptyState(),
        data: (data) => data.isEmpty
            ? const _EmptyState()
            : isGrid
            ? _GridView(listings: data)
            : _ListView(listings: data),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: -1),
    );
  }
}

// ── Grid view ─────────────────────────────────────────────────────────────────

class _GridView extends StatelessWidget {
  final List<Listing> listings;
  const _GridView({required this.listings});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.spaceM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 20,
        childAspectRatio: 0.68,
      ),
      itemCount: listings.length,
      itemBuilder: (_, i) => _GridCard(listing: listings[i]),
    );
  }
}

class _GridCard extends ConsumerWidget {
  final Listing listing;
  const _GridCard({required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/property/${listing.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo + heart ─────────────────────────────
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  child: CachedNetworkImage(
                    imageUrl: listing.imageUrls.first,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.surfaceLight,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.surfaceLight,
                      child: const Center(
                        child: Icon(
                          Icons.home_rounded,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                // Heart button
                PositionedDirectional(
                  top: 8,
                  end: 8,
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(favoritedIdsProvider.notifier)
                          .toggle(listing.id);
                      // Refresh favorites list after a short delay
                      Future.delayed(const Duration(milliseconds: 500), () {
                        ref.invalidate(apiFavoritesProvider);
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 17,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Title ─────────────────────────────────────
          Text(
            listing.title,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),

          // ── Price ─────────────────────────────────────
          Text(
            formatPrice(listing.price),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),

          // ── City · Category ───────────────────────────
          Text(
            '${listing.city}  ·  ${listing.category}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── List view ─────────────────────────────────────────────────────────────────

class _ListView extends StatelessWidget {
  final List<Listing> listings;
  const _ListView({required this.listings});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceM,
        vertical: AppConstants.spaceM,
      ),
      itemCount: listings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => _ListCard(listing: listings[i]),
    );
  }
}

class _ListCard extends ConsumerWidget {
  final Listing listing;
  const _ListCard({required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/property/${listing.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo ─────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                child: CachedNetworkImage(
                  imageUrl: listing.imageUrls.first,
                  width: 120,
                  height: 110,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 120,
                    height: 110,
                    color: AppColors.surfaceLight,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 120,
                    height: 110,
                    color: AppColors.surfaceLight,
                    child: const Center(
                      child: Icon(
                        Icons.home_rounded,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              // Heart button
              PositionedDirectional(
                top: 8,
                end: 8,
                child: GestureDetector(
                  onTap: () {
                    ref.read(favoritedIdsProvider.notifier).toggle(listing.id);
                    Future.delayed(const Duration(milliseconds: 500), () {
                      ref.invalidate(apiFavoritesProvider);
                    });
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 15,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // ── Details ───────────────────────────────────
          Expanded(
            child: SizedBox(
              height: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title
                  Text(
                    listing.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // City · Category
                  Text(
                    '${listing.city}  ·  ${listing.category}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),

                  // Stats
                  _MiniStats(listing: listing),

                  // Price
                  Text(
                    formatPrice(listing.price),
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryLight,
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
}

// ── Mini stats (area + beds + baths) ─────────────────────────────────────────

class _MiniStats extends StatelessWidget {
  final Listing listing;
  const _MiniStats({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: [
        _MiniStat(icon: Icons.straighten_rounded, label: '${listing.area} م²'),
        if (listing.bedrooms > 0)
          _MiniStat(icon: Icons.bed_rounded, label: '${listing.bedrooms}'),
        if (listing.bathrooms > 0)
          _MiniStat(icon: Icons.shower_rounded, label: '${listing.bathrooms}'),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondaryLight),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
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
            // Heart illustration
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 58,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد مفضلة بعد',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'احفظ العقارات التي تعجبك باضغط على القلب ❤',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(200, AppConstants.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                elevation: 0,
              ),
              child: Text(
                'ابدأ التصفح',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white,
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
