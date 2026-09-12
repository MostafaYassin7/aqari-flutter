import 'dart:convert';
import '../../../../core/preview/ui_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/add_listing_provider.dart';
import '../../data/add_listing_repository.dart';
import '../../../../core/network/api_failure.dart';

class Step2Media extends ConsumerWidget {
  const Step2Media({super.key});

  // Generates a new mock photo URL using a random seed
  String _mockPhotoUrl(int index) =>
      'https://picsum.photos/seed/listing_upload_$index/600/400';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addListingProvider);
    final photos = state.photos;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'أضف صور العقار (اختياري)',
            style: AppTextStyles.headlineMedium.copyWith(
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'JPG، PNG، WEBP — حتى 15MB لكل صورة. يمكنك المتابعة بدون صور.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // ── Upload area ──────────────────────────────────
          GestureDetector(
            onTap: state.value('uploading') == 'true'
                ? null
                : () async {
                    try {
                      final photos = await ref
                          .read(listingImagePickerProvider)
                          .pickMultiImage();
                      ref
                          .read(addListingProvider.notifier)
                          .field('uploadError', '');
                      if (!context.mounted) return;
                      for (final photo in photos) {
                        final ext = photo.name.split('.').last.toLowerCase();
                        if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
                          if (context.mounted) {
                            await previewResult(
                              context,
                              'نوع صورة غير مدعوم',
                              'اختر JPG أو PNG أو WEBP.',
                            );
                          }
                          continue;
                        }
                        if (await photo.length() > 15 * 1024 * 1024) {
                          if (context.mounted) {
                            await previewResult(
                              context,
                              'الصورة كبيرة',
                              'الحد الأقصى 15MB لكل صورة.',
                            );
                          }
                          continue;
                        }
                        if (!uiPreview) {
                          final n = ref.read(addListingProvider.notifier);
                          n.field('uploading', 'true');
                          try {
                            final url = await ref
                                .read(addListingRepositoryProvider)
                                .upload(photo, (progress) {
                                  n.field(
                                    'uploadProgress',
                                    '${(progress * 100).round()}',
                                  );
                                });
                            n.addPhoto(url);
                          } catch (e) {
                            n.field(
                              'uploadError',
                              ApiFailure.fromError(e).message,
                            );
                            break;
                          } finally {
                            n.field('uploading', 'false');
                          }
                          continue;
                        }
                        final bytes = await photo.readAsBytes();
                        if (!context.mounted) return;
                        final value =
                            'data:image/jpeg;base64,${base64Encode(bytes)}';
                        if (!ref
                            .read(addListingProvider)
                            .photos
                            .contains(value)) {
                          ref.read(addListingProvider.notifier).addPhoto(value);
                        }
                      }
                    } catch (_) {
                      if (context.mounted) {
                        previewResult(
                          context,
                          'تعذر اختيار الصور',
                          'يمكنك المحاولة مرة أخرى.',
                        );
                      }
                    }
                  },
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: context.appColors.surface,
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
                      color: context.appColors.primaryTint,
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
                    state.value('uploading') == 'true'
                        ? 'جارٍ الرفع ${state.value('uploadProgress')}٪'
                        : 'JPG, PNG, WEBP',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.appColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (state.value('uploadError').isNotEmpty)
            Text(
              state.value('uploadError'),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          if (uiPreview)
            TextButton(
              onPressed: () => ref
                  .read(addListingProvider.notifier)
                  .addPhoto(
                    _mockPhotoUrl(DateTime.now().microsecondsSinceEpoch),
                  ),
              child: const Text('إضافة صورة تجريبية'),
            ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الصور المضافة (${photos.length})',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'اسحب لإعادة الترتيب',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: photos.length,
              onReorderItem: (oldIndex, newIndex) => ref
                  .read(addListingProvider.notifier)
                  .reorderPhotos(
                    oldIndex,
                    newIndex > oldIndex ? newIndex + 1 : newIndex,
                  ),
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
                border: Border.all(color: AppColors.warning.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يمكنك إضافة صور لإبراز عقارك — أضفت ${photos.length} حتى الآن',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String url;
  final bool isCover;
  final VoidCallback onDelete;
  const _PhotoTile({
    required super.key,
    required this.url,
    required this.isCover,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: isCover ? AppColors.primary : context.appColors.divider,
          width: isCover ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusM - 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            url.startsWith('data:')
                ? Image.memory(
                    base64Decode(url.split(',').last),
                    fit: BoxFit.cover,
                  )
                : CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: context.appColors.surface,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: context.appColors.surface,
                      child: Icon(
                        Icons.image_rounded,
                        color: context.appColors.textHint,
                        size: 36,
                      ),
                    ),
                  ),
            // Cover badge
            if (isCover)
              PositionedDirectional(
                top: 8,
                start: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusCircle,
                    ),
                  ),
                  child: Text(
                    'الغلاف',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
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
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            // Drag handle
            const PositionedDirectional(
              top: 0,
              bottom: 0,
              end: 40,
              child: Center(
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
