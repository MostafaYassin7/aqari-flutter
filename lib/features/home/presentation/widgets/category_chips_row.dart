import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/home_provider.dart';

/// Horizontally scrollable property type filter chips.
/// Uses propertyTypes from app_enums, shows Arabic names, sends English values.
class CategoryChipsRow extends ConsumerWidget {
  final NotifierProvider<Notifier<String?>, String?> propertyTypeProvider;

  const CategoryChipsRow({required this.propertyTypeProvider, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(propertyTypeProvider);

    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
        itemCount: propertyTypes.length + 1, // +1 for "الكل"
        itemBuilder: (_, i) {
          if (i == 0) {
            final isActive = selected == null;
            return _PropertyTypeChip(
              label: 'الكل',
              icon: Icons.apps_rounded,
              isActive: isActive,
              onTap: () => (ref.read(propertyTypeProvider.notifier) as dynamic)
                  .select(null),
            );
          }

          final type = propertyTypes[i - 1];
          final arabicName = propertyTypeArabicNames[type] ?? type;
          final icon = propertyTypeIcons[type] ?? Icons.home_rounded;
          final isActive = selected == type;

          return _PropertyTypeChip(
            label: arabicName,
            icon: icon,
            isActive: isActive,
            onTap: () => (ref.read(propertyTypeProvider.notifier) as dynamic)
                .select(isActive ? null : type),
          );
        },
      ),
    );
  }
}

class _PropertyTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _PropertyTypeChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsetsDirectional.only(end: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.dividerLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? AppColors.white : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isActive ? AppColors.white : AppColors.textPrimaryLight,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
