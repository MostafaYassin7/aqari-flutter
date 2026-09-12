import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/add_listing_provider.dart';
import '../../../../core/preview/ui_preview.dart';

class Step3Info extends ConsumerStatefulWidget {
  const Step3Info({super.key});

  @override
  ConsumerState<Step3Info> createState() => _Step3InfoState();
}

class _Step3InfoState extends ConsumerState<Step3Info> {
  late TextEditingController _priceCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _commissionCtrl;
  late TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(addListingProvider);
    _priceCtrl = TextEditingController(text: s.price);
    _areaCtrl = TextEditingController(text: s.area);
    _commissionCtrl = TextEditingController(text: s.commissionPercent);
    _descCtrl = TextEditingController(text: s.description);
  }

  @override
  void dispose() {
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
          const SizedBox(height: 8),
          Text(
            'المعلومات الأساسية',
            style: AppTextStyles.headlineMedium.copyWith(
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'أدخل تفاصيل العقار الأساسية',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          PreviewField(
            label: 'عنوان الإعلان *',
            value: s.value('title'),
            maxLength: 100,
            onChanged: (v) =>
                ref.read(addListingProvider.notifier).field('title', v),
          ),
          // ── Price ────────────────────────────────────────
          _FieldLabel(
            s.isDaily
                ? 'السعر لكل ليلة *'
                : s.group == 'hall'
                ? 'السعر ليوم كامل *'
                : 'السعر الإجمالي *',
          ),
          const SizedBox(height: 6),
          _NumberField(
            controller: _priceCtrl,
            hint: '0',
            suffix: 'ريال',
            onChanged: (v) => ref.read(addListingProvider.notifier).setPrice(v),
          ),
          const SizedBox(height: 16),

          // ── Area ─────────────────────────────────────────
          _FieldLabel('المساحة *'),
          const SizedBox(height: 6),
          _NumberField(
            controller: _areaCtrl,
            hint: '0',
            suffix: 'م²',
            onChanged: (v) => ref.read(addListingProvider.notifier).setArea(v),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(color: context.appColors.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'يوجد عمولة',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.appColors.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  value: s.hasCommission,
                  onChanged: (v) =>
                      ref.read(addListingProvider.notifier).setHasCommission(v),
                  activeThumbColor: AppColors.primary,
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
              onChanged: (v) =>
                  ref.read(addListingProvider.notifier).setCommissionPercent(v),
            ),
          ],
          const SizedBox(height: 16),

          // ── Description ───────────────────────────────────
          _FieldLabel('وصف العقار (اختياري)'),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            onChanged: (v) =>
                ref.read(addListingProvider.notifier).setDescription(v),
            maxLines: 5,
            maxLength: 2000,
            keyboardType: TextInputType.multiline,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'اكتب وصفاً تفصيلياً للعقار...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: context.appColors.textHint,
              ),
              filled: true,
              fillColor: context.appColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(color: context.appColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(color: context.appColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
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
      color: context.appColors.textPrimary,
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
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
    style: AppTextStyles.bodyLarge.copyWith(
      color: context.appColors.textPrimary,
    ),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: context.appColors.textHint,
      ),
      suffixText: suffix,
      suffixStyle: AppTextStyles.bodyMedium.copyWith(
        color: context.appColors.textSecondary,
      ),
      filled: true,
      fillColor: context.appColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: BorderSide(color: context.appColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: BorderSide(color: context.appColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
            ? context.appColors.primaryTint
            : context.appColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: selected ? AppColors.primary : context.appColors.divider,
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: selected
                ? AppColors.primary
                : context.appColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: selected
                  ? AppColors.primary
                  : context.appColors.textPrimary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
  );
}
