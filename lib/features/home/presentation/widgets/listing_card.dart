import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/listing.dart';
import '../providers/home_provider.dart';

// ignore: depend_on_referenced_packages
import 'package:go_router/go_router.dart';

/// Airbnb-style property listing card.
class ListingCard extends ConsumerWidget {
  final Listing listing;

  const ListingCard({required this.listing, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds = ref.watch(favoritedIdsProvider);
    final isFav = favIds.contains(listing.id);

    return GestureDetector(
      onTap: () => context.push('/property/${listing.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo + heart button ─────────────────────
            Stack(
              children: [
                // Property image
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusM),
                  child: CachedNetworkImage(
                    imageUrl: listing.imageUrls.first,
                    width: double.infinity,
                    height: AppConstants.listingCardImageHeight,
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
                          size: 56,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),

                // Favorite / heart button
                PositionedDirectional(
                  top: 12,
                  end: 12,
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(favoritedIdsProvider.notifier)
                          .toggle(listing.id);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 20,
                        color: isFav
                            ? AppColors.error
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── City · Category ──────────────────────────
            Text(
              '${listing.city}  ·  ${listing.category}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),

            const SizedBox(height: 4),

            // ── Price ────────────────────────────────────
            Text(
              formatPrice(listing.price),
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
              ),
            ),

            const SizedBox(height: 6),

            // ── Stats row ────────────────────────────────
            _StatsRow(listing: listing),

            const SizedBox(height: 6),

            // ── Description ──────────────────────────────
            Text(
              listing.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Listing listing;

  const _StatsRow({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: [
        _Stat(icon: Icons.straighten_rounded, label: '${listing.area} م²'),
        if (listing.bedrooms > 0)
          _Stat(
              icon: Icons.bed_rounded, label: '${listing.bedrooms} غرف'),
        if (listing.bathrooms > 0)
          _Stat(
              icon: Icons.shower_rounded,
              label: '${listing.bathrooms} حمامات'),
        if (listing.livingRooms > 0)
          _Stat(
              icon: Icons.weekend_rounded,
              label: '${listing.livingRooms} مجالس'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondaryLight),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
