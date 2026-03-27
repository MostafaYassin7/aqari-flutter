import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/home_provider.dart';

/// Horizontally scrollable category filter chips — Airbnb style.
class CategoryChipsRow extends ConsumerWidget {
  const CategoryChipsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
        itemCount: homeCategories.length,
        itemBuilder: (_, i) {
          final cat = homeCategories[i];
          final isActive = i == selected;

          return GestureDetector(
            onTap: () =>
                ref.read(selectedCategoryProvider.notifier).select(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsetsDirectional.only(end: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color:
                      isActive ? AppColors.primary : AppColors.dividerLight,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.icon,
                    size: 15,
                    color:
                        isActive ? AppColors.white : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat.name,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isActive
                          ? AppColors.white
                          : AppColors.textPrimaryLight,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
