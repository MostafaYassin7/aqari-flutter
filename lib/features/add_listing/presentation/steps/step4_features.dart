import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../providers/add_listing_provider.dart';

class _Feature {
  final String name;
  final IconData icon;
  const _Feature(this.name, this.icon);
}

const _features = [
  _Feature('ماء', Icons.water_drop_rounded),
  _Feature('كهرباء', Icons.electric_bolt_rounded),
  _Feature('صرف صحي', Icons.plumbing_rounded),
  _Feature('سطح خاص', Icons.roofing_rounded),
  _Feature('داخل فيلا', Icons.villa_rounded),
  _Feature('مدخلين', Icons.meeting_room_rounded),
  _Feature('مدخل خاص', Icons.door_front_door_rounded),
  _Feature('مطبخ راكب', Icons.kitchen_rounded),
  _Feature('غرفة سائق', Icons.bedroom_child_rounded),
  _Feature('غرفة عمالة', Icons.people_rounded),
  _Feature('تكييف', Icons.ac_unit_rounded),
  _Feature('موقف سيارة', Icons.local_parking_rounded),
];

class Step4Features extends ConsumerWidget {
  const Step4Features({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(addListingProvider).features;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'ما الذي يوفره العقار؟',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اختر المميزات المتوفرة في عقارك',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 24),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.1,
            ),
            itemCount: _features.length,
            itemBuilder: (_, i) {
              final f = _features[i];
              final isOn = selected.contains(f.name);
              return GestureDetector(
                onTap: () => ref
                    .read(addListingProvider.notifier)
                    .toggleFeature(f.name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isOn
                        ? AppColors.primary
                        : AppColors.surfaceLight,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusM),
                    border: Border.all(
                      color: isOn
                          ? AppColors.primary
                          : AppColors.dividerLight,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        f.icon,
                        size: 26,
                        color: isOn
                            ? AppColors.white
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        f.name,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isOn
                              ? AppColors.white
                              : AppColors.textPrimaryLight,
                          fontWeight: isOn
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          if (selected.isNotEmpty)
            Text(
              'تم اختيار ${selected.length} ميزة',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
