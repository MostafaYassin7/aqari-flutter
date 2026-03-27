import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/projects_provider.dart';

/// Horizontally scrollable city filter chips for the Projects tab.
class ProjectCityChipsRow extends ConsumerWidget {
  const ProjectCityChipsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedProjectCityProvider);

    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
        itemCount: projectCities.length,
        itemBuilder: (_, i) {
          final city = projectCities[i];
          final isActive = i == selected;

          return GestureDetector(
            onTap: () =>
                ref.read(selectedProjectCityProvider.notifier).select(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsetsDirectional.only(end: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color:
                      isActive ? AppColors.primary : AppColors.dividerLight,
                ),
              ),
              child: Text(
                city,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isActive
                      ? AppColors.white
                      : AppColors.textPrimaryLight,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
