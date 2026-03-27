import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../providers/add_listing_provider.dart';

class _ListingCategory {
  final String name;
  final IconData icon;
  const _ListingCategory(this.name, this.icon);
}

const _categories = [
  _ListingCategory('شقة للبيع', Icons.apartment_rounded),
  _ListingCategory('شقة للإيجار', Icons.home_work_rounded),
  _ListingCategory('فيلا', Icons.house_rounded),
  _ListingCategory('أرض', Icons.landscape_rounded),
  _ListingCategory('تجاري', Icons.business_center_rounded),
  _ListingCategory('دوبلكس', Icons.villa_rounded),
  _ListingCategory('استراحة', Icons.holiday_village_rounded),
  _ListingCategory('عمارة', Icons.domain_rounded),
];

class Step1Category extends ConsumerWidget {
  const Step1Category({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(addListingProvider).category;

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
            style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight),
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
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final isSelected = selected == cat.name;
              return GestureDetector(
                onTap: () => ref
                    .read(addListingProvider.notifier)
                    .setCategory(cat.name),
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
                        cat.icon,
                        size: 32,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat.name,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimaryLight,
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
