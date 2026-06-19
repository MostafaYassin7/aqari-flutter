import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../providers/add_listing_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _listingCategoriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await apiClient.get(ApiEndpoints.listingCategories);
  return List<Map<String, dynamic>>.from(res.data as List);
});

// ── Icon map (propertyType → Flutter icon) ────────────────────────────────────

IconData _iconFor(String? propertyType) {
  switch (propertyType) {
    case 'apartment':
      return Icons.apartment_rounded;
    case 'villa':
      return Icons.house_rounded;
    case 'floor':
      return Icons.layers_rounded;
    case 'land':
      return Icons.landscape_rounded;
    case 'building':
      return Icons.domain_rounded;
    case 'shop':
    case 'commercial_office':
      return Icons.business_center_rounded;
    case 'rest_house':
    case 'chalet':
      return Icons.holiday_village_rounded;
    case 'farm':
      return Icons.grass_rounded;
    case 'warehouse':
      return Icons.warehouse_rounded;
    case 'camp':
      return Icons.festival_rounded;
    default:
      return Icons.home_rounded;
  }
}

// ── Step ──────────────────────────────────────────────────────────────────────

class Step1Category extends ConsumerWidget {
  const Step1Category({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(addListingProvider).categoryId;
    final categoriesAsync = ref.watch(_listingCategoriesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'ما نوع العقار؟',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اختر نوع العقار الذي تريد إضافته',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 24),

          categoriesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (_, __) => Center(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  const Icon(Icons.wifi_off_rounded,
                      size: 48, color: AppColors.textSecondaryLight),
                  const SizedBox(height: 12),
                  Text('تعذّر تحميل الفئات',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(_listingCategoriesProvider),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
            data: (categories) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i];
                final id = cat['id'] as String;
                final nameAr = (cat['nameAr'] ?? cat['name'] ?? '') as String;
                final propertyType = (cat['propertyType'] ?? '') as String;
                final listingType = (cat['listingType'] ?? 'sale') as String;
                final isSelected = selectedId == id;

                return GestureDetector(
                  onTap: () => ref
                      .read(addListingProvider.notifier)
                      .setCategory(
                        id: id,
                        nameAr: nameAr,
                        propertyType: propertyType,
                        listingType: listingType,
                      ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryLight
                          : AppColors.surfaceLight,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusL),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.dividerLight,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _iconFor(propertyType),
                          size: 32,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          nameAr,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimaryLight,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
