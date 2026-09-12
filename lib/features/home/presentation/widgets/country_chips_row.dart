import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/home_provider.dart';

/// Horizontally scrollable country filter chips.
/// Shows Arabic names, sends English values to the API.
class CountryChipsRow extends ConsumerWidget {
  final NotifierProvider<Notifier<String?>, String?>? cityProvider;
  final String? currentCity;
  final ValueChanged<String?>? onCityChanged;

  const CountryChipsRow({required this.cityProvider, super.key})
    : currentCity = null,
      onCityChanged = null;
  const CountryChipsRow.controlled({
    required this.currentCity,
    required this.onCityChanged,
    super.key,
  }) : cityProvider = null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCity = cityProvider == null
        ? currentCity
        : ref.watch(cityProvider!);
    void select(String? city) {
      if (onCityChanged != null) {
        onCityChanged!(city);
      } else {
        (ref.read(cityProvider!.notifier) as dynamic).select(city);
      }
    }

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 6),
        itemCount: countries.length + 1, // +1 for "الكل"
        itemBuilder: (_, i) {
          if (i == 0) {
            final isActive = selectedCity == null;
            return _CityChip(
              label: 'الكل',
              isActive: isActive,
              onTap: () => select(null),
            );
          }
          final city = countries[i - 1];
          final arabicName = cityArabicNames[city] ?? city;
          final isActive = selectedCity == city;

          return _CityChip(
            label: arabicName,
            isActive: isActive,
            onTap: () => select(isActive ? null : city),
          );
        },
      ),
    );
  }
}

class _CityChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CityChip({
    required this.label,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : context.appColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? AppColors.primary : context.appColors.divider,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: isActive ? AppColors.white : context.appColors.textPrimary,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
