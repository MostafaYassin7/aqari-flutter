import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../providers/add_listing_provider.dart';

class Step3Info extends ConsumerStatefulWidget {
  const Step3Info({super.key});

  @override
  ConsumerState<Step3Info> createState() => _Step3InfoState();
}

class _Step3InfoState extends ConsumerState<Step3Info> {
  late TextEditingController _titleCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _commissionCtrl;
  late TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(addListingProvider);
    _titleCtrl = TextEditingController(text: s.title);
    _priceCtrl = TextEditingController(text: s.price);
    _areaCtrl = TextEditingController(text: s.area);
    _commissionCtrl = TextEditingController(text: s.commissionPercent);
    _descCtrl = TextEditingController(text: s.description);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _areaCtrl.dispose();
    _commissionCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(addListingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          Text(
            'المعلومات الأساسية',
            style: AppTextStyles.headlineMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'أدخل تفاصيل العقار الأساسية',
            style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondary),
          ),
          const SizedBox(height: 24),

          // ── Title ────────────────────────────────────────
          _FieldLabel('عنوان الإعلان'),
          SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            onChanged: (v) =>
                ref.read(addListingProvider.notifier).setTitle(v),
            style: AppTextStyles.bodyMedium.copyWith(
                color: context.textPrimary),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'مثال: شقة للبيع في حي العليا',
              hintStyle: AppTextStyles.bodyMedium
                  .copyWith(color: context.textHint),
              filled: true,
              fillColor: context.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(color: context.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(color: context.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),

          // ── Price ────────────────────────────────────────
          _FieldLabel('السعر الإجمالي'),
          const SizedBox(height: 6),
          _NumberField(
            controller: _priceCtrl,
            hint: '0',
            suffix: 'ريال',
            onChanged: (v) =>
                ref.read(addListingProvider.notifier).setPrice(v),
          ),
          const SizedBox(height: 16),

          // ── Area ─────────────────────────────────────────
          _FieldLabel('المساحة'),
          const SizedBox(height: 6),
          _NumberField(
            controller: _areaCtrl,
            hint: '0',
            suffix: 'م²',
            onChanged: (v) =>
                ref.read(addListingProvider.notifier).setArea(v),
          ),
          const SizedBox(height: 16),

          // ── Residential / Commercial ─────────────────────
          _FieldLabel('نوع الاستخدام'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _UseTypeChip(
                  label: 'سكني',
                  icon: Icons.home_rounded,
                  selected: s.isResidential,
                  onTap: () => ref
                      .read(addListingProvider.notifier)
                      .setIsResidential(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _UseTypeChip(
                  label: 'تجاري',
                  icon: Icons.business_center_rounded,
                  selected: !s.isResidential,
                  onTap: () => ref
                      .read(addListingProvider.notifier)
                      .setIsResidential(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Commission toggle ─────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(color: context.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'يوجد عمولة',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: context.textPrimary),
                  ),
                ),
                if (Platform.isIOS)
                  CupertinoSwitch(
                    value: s.hasCommission,
                    onChanged: (v) => ref
                        .read(addListingProvider.notifier)
                        .setHasCommission(v),
                    activeTrackColor: AppColors.primary,
                  )
                else
                  Switch(
                    value: s.hasCommission,
                    onChanged: (v) => ref
                        .read(addListingProvider.notifier)
                        .setHasCommission(v),
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ),
          if (s.hasCommission) ...[
            const SizedBox(height: 10),
            _FieldLabel('نسبة العمولة'),
            const SizedBox(height: 6),
            _NumberField(
              controller: _commissionCtrl,
              hint: '2.5',
              suffix: '٪',
              onChanged: (v) => ref
                  .read(addListingProvider.notifier)
                  .setCommissionPercent(v),
            ),
          ],
          const SizedBox(height: 16),

          // ── Description ───────────────────────────────────
          _FieldLabel('وصف العقار'),
          SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            onChanged: (v) =>
                ref.read(addListingProvider.notifier).setDescription(v),
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            style: AppTextStyles.bodyMedium.copyWith(
                color: context.textPrimary),
            decoration: InputDecoration(
              hintText: 'اكتب وصفاً تفصيلياً للعقار...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: context.textHint),
              filled: true,
              fillColor: context.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(color: context.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(color: context.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.titleSmall.copyWith(
          color: context.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String suffix;
  final ValueChanged<String> onChanged;
  const _NumberField({
    required this.controller,
    required this.hint,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
        ],
        style: AppTextStyles.bodyLarge.copyWith(
            color: context.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: context.textHint),
          suffixText: suffix,
          suffixStyle: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondary),
          filled: true,
          fillColor: context.surface,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.radiusM),
            borderSide:
                BorderSide(color: context.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.radiusM),
            borderSide:
                BorderSide(color: context.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.radiusM),
            borderSide: const BorderSide(
                color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      );
}

class _UseTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _UseTypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryLight
                : context.surface,
            borderRadius:
                BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(
              color:
                  selected ? AppColors.primary : context.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20,
                  color: selected
                      ? AppColors.primary
                      : context.textSecondary),
              SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: selected
                      ? AppColors.primary
                      : context.textPrimary,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
}
