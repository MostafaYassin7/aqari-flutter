import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/listing.dart' show formatPrice;
import '../../../../shared/models/project.dart';

// ignore: depend_on_referenced_packages
import 'package:go_router/go_router.dart';

/// Airbnb-Experience-style project listing card.
class ProjectCard extends ConsumerWidget {
  final Project project;

  const ProjectCard({required this.project, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/project/${project.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo + badges + heart ─────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  child: CachedNetworkImage(
                    imageUrl: project.imageUrls.first,
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
                          Icons.apartment_rounded,
                          size: 56,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),

                // Availability badge — top start
                PositionedDirectional(
                  top: 12,
                  start: 12,
                  child: _AvailabilityBadge(availability: project.availability),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Developer · Project type ───────────────────
            Text(
              '${project.developerName}  ·  ${project.projectType}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),

            const SizedBox(height: 4),

            // ── Project name ──────────────────────────────
            Text(
              project.name,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
              ),
            ),

            const SizedBox(height: 4),

            // ── City ─────────────────────────────────────
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 3),
                Text(
                  project.city,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ── Starting price ────────────────────────────
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'يبدأ من  ',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  TextSpan(
                    text: formatPrice(project.startingPrice),
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ── Description ───────────────────────────────
            Text(
              project.description,
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

// ── Availability badge ────────────────────────────────────────────────────────

class _AvailabilityBadge extends StatelessWidget {
  final ProjectAvailability availability;

  const _AvailabilityBadge({required this.availability});

  @override
  Widget build(BuildContext context) {
    final isReady = availability == ProjectAvailability.ready;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isReady ? AppColors.success : AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        availability.label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
