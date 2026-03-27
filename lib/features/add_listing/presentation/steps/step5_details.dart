import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../providers/add_listing_provider.dart';

class Step5Details extends ConsumerStatefulWidget {
  const Step5Details({super.key});

  @override
  ConsumerState<Step5Details> createState() => _Step5DetailsState();
}

class _Step5DetailsState extends ConsumerState<Step5Details> {
  late TextEditingController _streetWidthCtrl;
  late TextEditingController _floorCtrl;
  late TextEditingController _ageCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(addListingProvider);
    _streetWidthCtrl = TextEditingController(text: s.streetWidth);
    _floorCtrl = TextEditingController(text: s.floorNumber);
    _ageCtrl = TextEditingController(text: s.propertyAge);
  }

  @override
  void dispose() {
    _streetWidthCtrl.dispose();
    _floorCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(addListingProvider);
    final notifier = ref.read(addListingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'تفاصيل العقار',
            style: AppTextStyles.headlineMedium
                .copyWith(color: AppColors.textPrimaryLight),
          ),
          const SizedBox(height: 6),
          Text(
            'أدخل المواصفات التفصيلية للعقار',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 24),

          // ── Steppers ─────────────────────────────────────
          _StepperRow(
            label: 'غرف النوم',
            icon: Icons.bed_rounded,
            value: s.bedrooms,
            onDecrement: () => notifier.setBedrooms(s.bedrooms - 1),
            onIncrement: () => notifier.setBedrooms(s.bedrooms + 1),
          ),
          const SizedBox(height: 12),
          _StepperRow(
            label: 'غرف الجلوس',
            icon: Icons.weekend_rounded,
            value: s.livingRooms,
            onDecrement: () => notifier.setLivingRooms(s.livingRooms - 1),
            onIncrement: () => notifier.setLivingRooms(s.livingRooms + 1),
          ),
          const SizedBox(height: 12),
          _StepperRow(
            label: 'الحمامات / دورات المياه',
            icon: Icons.bathroom_rounded,
            value: s.bathrooms,
            onDecrement: () => notifier.setBathrooms(s.bathrooms - 1),
            onIncrement: () => notifier.setBathrooms(s.bathrooms + 1),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.dividerLight),
          const SizedBox(height: 16),

          // ── Facade ───────────────────────────────────────
          _SectionLabel('الواجهة'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['شمال', 'جنوب', 'شرق', 'غرب', 'شمال شرق', 'شمال غرب', 'جنوب شرق', 'جنوب غرب']
                .map((d) => _FacadePill(
                      label: d,
                      selected: s.facade == d,
                      onTap: () => notifier.setFacade(
                          s.facade == d ? null : d),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.dividerLight),
          const SizedBox(height: 16),

          // ── Numeric inputs ───────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MiniInput(
                  label: 'عرض الشارع (م)',
                  controller: _streetWidthCtrl,
                  onChanged: notifier.setStreetWidth,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniInput(
                  label: 'رقم الدور',
                  controller: _floorCtrl,
                  onChanged: notifier.setFloorNumber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MiniInput(
            label: 'عمر العقار (سنة)',
            controller: _ageCtrl,
            onChanged: notifier.setPropertyAge,
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.dividerLight),
          const SizedBox(height: 16),

          // ── Checklist ────────────────────────────────────
          _SectionLabel('التجهيزات والخصائص'),
          const SizedBox(height: 12),
          _ToggleRow(
            label: 'مفروش',
            icon: Icons.chair_rounded,
            value: s.isFurnished,
            onChanged: notifier.setIsFurnished,
          ),
          _ToggleRow(
            label: 'مطبخ',
            icon: Icons.kitchen_rounded,
            value: s.hasKitchen,
            onChanged: notifier.setHasKitchen,
          ),
          _ToggleRow(
            label: 'وحدة إضافية',
            icon: Icons.add_home_rounded,
            value: s.hasExtraUnit,
            onChanged: notifier.setHasExtraUnit,
          ),
          _ToggleRow(
            label: 'مدخل سيارة',
            icon: Icons.garage_rounded,
            value: s.hasCarEntrance,
            onChanged: notifier.setHasCarEntrance,
          ),
          _ToggleRow(
            label: 'مصعد',
            icon: Icons.elevator_rounded,
            value: s.hasElevator,
            onChanged: notifier.setHasElevator,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.titleSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
        ),
      );
}

class _StepperRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  const _StepperRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: AppColors.dividerLight),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20, color: AppColors.textSecondaryLight),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textPrimaryLight)),
            ),
            _CounterButton(
              icon: Icons.remove_rounded,
              onTap: value > 0 ? onDecrement : null,
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
            _CounterButton(
              icon: Icons.add_rounded,
              onTap: onIncrement,
            ),
          ],
        ),
      );
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CounterButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: onTap != null
                  ? AppColors.primary
                  : AppColors.dividerLight,
            ),
            color: onTap != null
                ? AppColors.primaryLight
                : AppColors.surfaceLight,
          ),
          child: Icon(
            icon,
            size: 18,
            color: onTap != null
                ? AppColors.primary
                : AppColors.textHintLight,
          ),
        ),
      );
}

class _FacadePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FacadePill(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : AppColors.surfaceLight,
            borderRadius:
                BorderRadius.circular(AppConstants.radiusCircle),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.dividerLight,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: selected
                  ? AppColors.white
                  : AppColors.textPrimaryLight,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      );
}

class _MiniInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _MiniInput({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly
            ],
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textPrimaryLight),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textHintLight),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusM),
                borderSide:
                    const BorderSide(color: AppColors.dividerLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusM),
                borderSide:
                    const BorderSide(color: AppColors.dividerLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusM),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
          ),
        ],
      );
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          secondary: Icon(icon,
              size: 20, color: AppColors.textSecondaryLight),
          title: Text(label,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimaryLight)),
          dense: true,
        ),
      );
}
