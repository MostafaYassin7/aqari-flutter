import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../providers/add_listing_provider.dart';

class Step2Media extends ConsumerWidget {
  const Step2Media({super.key});

  // Generates a new mock photo URL using a random seed
  String _mockPhotoUrl(int index) =>
      'https://picsum.photos/seed/listing_upload_$index/600/400';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(addListingProvider).photos;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'أضف الصور والفيديو',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'أضف 3 صور على الأقل لإبراز عقارك',
            style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 20),

          // ── Upload area ──────────────────────────────────
          GestureDetector(
            onTap: () {
              // Simulate picking a photo
              ref
                  .read(addListingProvider.notifier)
                  .addPhoto(_mockPhotoUrl(photos.length + 1));
            },
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                border: Border.all(
                  color: AppColors.primary.withAlpha(128),
                  width: 2,
                  // Dashed effect via strokeAlign
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'اضغط لإضافة صور',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JPG, PNG, HEIC',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHintLight),
                  ),
                ],
              ),
            ),
          ),

          if (photos.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الصور المضافة (${photos.length})',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'اسحب لإعادة الترتيب',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: photos.length,
              onReorder: (oldIndex, newIndex) => ref
                  .read(addListingProvider.notifier)
                  .reorderPhotos(oldIndex, newIndex),
              itemBuilder: (_, i) => _PhotoTile(
                key: ValueKey(photos[i]),
                url: photos[i],
                isCover: i == 0,
                onDelete: () =>
                    ref.read(addListingProvider.notifier).removePhoto(i),
              ),
            ),
          ],

          // ── Photo count hint ─────────────────────────────
          if (photos.length < 3) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(25),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(
                    color: AppColors.warning.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الحد الأدنى 3 صور — أضفت ${photos.length} حتى الآن',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimaryLight),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Video option ─────────────────────────────────
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('سيتم دعم رفع الفيديو قريباً')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(color: AppColors.dividerLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videocam_rounded,
                      color: AppColors.textSecondaryLight, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'أضف فيديو (اختياري)',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimaryLight),
                    ),
                  ),
                  const Icon(Icons.add_circle_outline_rounded,
                      color: AppColors.primary, size: 22),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String url;
  final bool isCover;
  final VoidCallback onDelete;
  const _PhotoTile(
      {required super.key,
      required this.url,
      required this.isCover,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: isCover ? AppColors.primary : AppColors.dividerLight,
          width: isCover ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusM - 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                  color: AppColors.surfaceLight,
                  child: const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary))),
              errorWidget: (_, __, ___) => Container(
                  color: AppColors.surfaceLight,
                  child: const Icon(Icons.image_rounded,
                      color: AppColors.textHintLight, size: 36)),
            ),
            // Cover badge
            if (isCover)
              PositionedDirectional(
                top: 8,
                start: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(
                        AppConstants.radiusCircle),
                  ),
                  child: Text(
                    'الغلاف',
                    style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            // Delete button
            PositionedDirectional(
              top: 6,
              end: 6,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.overlay,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.white, size: 16),
                ),
              ),
            ),
            // Drag handle
            const PositionedDirectional(
              top: 0,
              bottom: 0,
              end: 40,
              child: Center(
                child: Icon(Icons.drag_indicator_rounded,
                    color: AppColors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
