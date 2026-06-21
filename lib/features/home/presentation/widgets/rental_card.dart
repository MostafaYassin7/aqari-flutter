import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/models/rental.dart';
import '../providers/rentals_provider.dart';

class RentalCard extends ConsumerWidget {
  final DailyRental rental;

  const RentalCard({required this.rental, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds = ref.watch(favoritedRentalsProvider);
    final isFav = favIds.contains(rental.id);

    return GestureDetector(
      onTap: () => context.push('/rental/${rental.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo + heart ──────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusM),
                  child: CachedNetworkImage(
                    imageUrl: rental.imageUrls.first,
                    width: double.infinity,
                    height: AppConstants.listingCardImageHeight,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: context.surface,
                      child: const Center(
                        child: AppLoadingIndicator(color: AppColors.primary),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: context.surface,
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
                PositionedDirectional(
                  top: 12,
                  end: 12,
                  child: GestureDetector(
                    onTap: () => ref
                        .read(favoritedRentalsProvider.notifier)
                        .toggle(rental.id),
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
                            : context.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── City · District ────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${rental.city}  ·  ${rental.district}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                // Star rating
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 13, color: AppColors.primary),
                    SizedBox(width: 3),
                    Text(
                      rental.rating.toStringAsFixed(1),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '  (${rental.reviewCount})',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 4),

            // ── Property name ──────────────────────────────
            Text(
              rental.name,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            // ── Stats row ──────────────────────────────────
            Wrap(
              spacing: 12,
              children: [
                _Stat(icon: Icons.straighten_rounded,
                    label: '${rental.area.toInt()} م²'),
                if (rental.bedrooms > 0)
                  _Stat(icon: Icons.bed_rounded,
                      label: '${rental.bedrooms} غرف'),
                if (rental.bathrooms > 0)
                  _Stat(icon: Icons.shower_rounded,
                      label: '${rental.bathrooms} حمامات'),
              ],
            ),

            const SizedBox(height: 6),

            // ── Price per night ────────────────────────────
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text:
                        '${rental.pricePerNight.toStringAsFixed(0)} ريال',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: ' / ليلة',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.textSecondary,
                    ),
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
  final IconData icon;
  final String label;
  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.textSecondary),
        SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: context.textSecondary)),
      ],
    );
  }
}
