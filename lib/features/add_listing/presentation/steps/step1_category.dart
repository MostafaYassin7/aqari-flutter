import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/add_listing_provider.dart';
import '../data/listing_categories.dart';
import '../../../../core/preview/ui_preview.dart';
import '../../../../shared/models/listing_category.dart';
import '../../../my_listings/presentation/providers/my_listings_provider.dart';
import '../../data/add_listing_repository.dart';

const _propertyIcons = {
  'apartment': Icons.apartment_rounded,
  'villa': Icons.house_rounded,
  'land': Icons.landscape_rounded,
  'building': Icons.domain_rounded,
  'shop': Icons.storefront_rounded,
  'house': Icons.home_rounded,
  'rest_house': Icons.holiday_village_rounded,
  'farm': Icons.grass_rounded,
  'chalet': Icons.cabin_rounded,
  'commercial_office': Icons.business_center_rounded,
  'warehouse': Icons.warehouse_rounded,
  'floor': Icons.layers_rounded,
  'camp': Icons.festival_rounded,
  'other': Icons.grid_view_rounded,
  'event_hall': Icons.celebration_outlined,
};

class Step1Category extends ConsumerWidget {
  const Step1Category({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addListingProvider);
    final selected = state.categoryId;
    final source = uiPreview ? null : ref.watch(listingCategoriesProvider);
    if (source != null && source.isLoading && !source.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (source != null && (source.hasError || (source.value ?? []).isEmpty)) {
      return Center(
        child: TextButton(
          onPressed: () => ref.invalidate(listingCategoriesProvider),
          child: const Text('تعذر تحميل الفئات المتاحة · إعادة المحاولة'),
        ),
      );
    }
    final categories = uiPreview
        ? [
            for (final c in listingCategoryOptions)
              ListingCategory(
                id: c.id,
                name: c.label,
                nameAr: c.label,
                propertyType: c.propertyType,
                listingType: c.listingType,
                sortOrder: 0,
                isActive: true,
              ),
          ]
        : (source?.value ?? <ListingCategory>[])
              .where((c) => c.isActive)
              .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'ما نوع العقار؟',
            style: AppTextStyles.headlineMedium.copyWith(
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اختر نوع العقار الذي تريد إضافته',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
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
              final isSelected = selected == cat.id;
              return GestureDetector(
                onTap:
                    !uiPreview &&
                        cat.propertyType == 'event_hall' &&
                        !ref.watch(eventHallCreationEnabledProvider)
                    ? () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'إضافة القاعات غير متاحة حتى اكتمال التحقق من الخدمة.',
                          ),
                        ),
                      )
                    : () => ref
                          .read(addListingProvider.notifier)
                          .selectType(
                            cat.propertyType,
                            cat.listingType,
                            cat.nameAr.isEmpty ? cat.name : cat.nameAr,
                            categoryId: cat.id,
                          ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.appColors.primaryTint
                        : context.appColors.surface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : context.appColors.divider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _propertyIcons[cat.propertyType] ?? Icons.home_rounded,
                        size: 32,
                        color: isSelected
                            ? AppColors.primary
                            : context.appColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat.nameAr.isEmpty ? cat.name : cat.nameAr,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : context.appColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
