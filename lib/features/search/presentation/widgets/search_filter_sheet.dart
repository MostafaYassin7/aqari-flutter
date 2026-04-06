import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/search_provider.dart';

/// Shows the search filter bottom sheet.
void showSearchFilterSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppConstants.radiusXL),
      ),
    ),
    builder: (_) => const _FilterSheetContent(),
  );
}

class _FilterSheetContent extends ConsumerStatefulWidget {
  const _FilterSheetContent();

  @override
  ConsumerState<_FilterSheetContent> createState() =>
      _FilterSheetContentState();
}

class _FilterSheetContentState extends ConsumerState<_FilterSheetContent> {
  late final TextEditingController _priceFromCtrl;
  late final TextEditingController _priceToCtrl;
  late final TextEditingController _areaFromCtrl;
  late final TextEditingController _areaToCtrl;
  late int? _bedrooms;
  late bool? _isFurnished;
  late bool? _hasElevator;

  @override
  void initState() {
    super.initState();
    final pf = ref.read(searchPriceFromProvider);
    final pt = ref.read(searchPriceToProvider);
    final af = ref.read(searchAreaFromProvider);
    final at = ref.read(searchAreaToProvider);
    _priceFromCtrl = TextEditingController(
      text: pf != null ? pf.toInt().toString() : '',
    );
    _priceToCtrl = TextEditingController(
      text: pt != null ? pt.toInt().toString() : '',
    );
    _areaFromCtrl = TextEditingController(
      text: af != null ? af.toInt().toString() : '',
    );
    _areaToCtrl = TextEditingController(
      text: at != null ? at.toInt().toString() : '',
    );
    _bedrooms = ref.read(searchBedroomsProvider);
    _isFurnished = ref.read(searchFurnishedProvider);
    _hasElevator = ref.read(searchElevatorProvider);
  }

  @override
  void dispose() {
    _priceFromCtrl.dispose();
    _priceToCtrl.dispose();
    _areaFromCtrl.dispose();
    _areaToCtrl.dispose();
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      _priceFromCtrl.clear();
      _priceToCtrl.clear();
      _areaFromCtrl.clear();
      _areaToCtrl.clear();
      _bedrooms = null;
      _isFurnished = null;
      _hasElevator = null;
    });
  }

  void _apply() {
    final pf = double.tryParse(_priceFromCtrl.text);
    final pt = double.tryParse(_priceToCtrl.text);
    final af = double.tryParse(_areaFromCtrl.text);
    final at = double.tryParse(_areaToCtrl.text);

    ref.read(searchPriceFromProvider.notifier).set(pf);
    ref.read(searchPriceToProvider.notifier).set(pt);
    ref.read(searchAreaFromProvider.notifier).set(af);
    ref.read(searchAreaToProvider.notifier).set(at);
    ref.read(searchBedroomsProvider.notifier).select(_bedrooms);
    ref.read(searchFurnishedProvider.notifier).set(_isFurnished);
    ref.read(searchElevatorProvider.notifier).set(_hasElevator);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Column(
        children: [
          // ── Handle ───────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Title row ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceM,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الفلاتر',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: _clearAll,
                  child: Text(
                    'مسح الكل',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.dividerLight),

          // ── Scrollable body ───────────────────────────────────
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppConstants.spaceM),
              children: [
                // ── Price range ────────────────────────────────
                const _SectionTitle('نطاق السعر (ريال)'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        controller: _priceFromCtrl,
                        hint: 'من',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumberField(
                        controller: _priceToCtrl,
                        hint: 'إلى',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const Divider(color: AppColors.dividerLight),
                const SizedBox(height: 8),

                // ── Area range ─────────────────────────────────
                const _SectionTitle('المساحة (م²)'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        controller: _areaFromCtrl,
                        hint: 'من',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumberField(controller: _areaToCtrl, hint: 'إلى'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const Divider(color: AppColors.dividerLight),
                const SizedBox(height: 8),

                // ── Bedrooms ───────────────────────────────────
                const _SectionTitle('عدد غرف النوم'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _BedroomPill(
                      label: 'أي',
                      selected: _bedrooms == null,
                      onTap: () => setState(() => _bedrooms = null),
                    ),
                    const SizedBox(width: 8),
                    ...List.generate(
                      5,
                      (i) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _BedroomPill(
                          label: i == 4 ? '5+' : '${i + 1}',
                          selected: _bedrooms == (i == 4 ? 5 : i + 1),
                          onTap: () =>
                              setState(() => _bedrooms = (i == 4 ? 5 : i + 1)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const Divider(color: AppColors.dividerLight),
                const SizedBox(height: 8),

                // ── Furnished ──────────────────────────────────
                _ToggleRow(
                  label: 'مؤثث',
                  icon: Icons.weekend_rounded,
                  value: _isFurnished,
                  onChanged: (v) => setState(() => _isFurnished = v),
                ),
                const SizedBox(height: 8),

                // ── Elevator ───────────────────────────────────
                _ToggleRow(
                  label: 'يوجد مصعد',
                  icon: Icons.elevator_rounded,
                  value: _hasElevator,
                  onChanged: (v) => setState(() => _hasElevator = v),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Bottom action bar ─────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              AppConstants.spaceM,
              AppConstants.spaceS,
              AppConstants.spaceM,
              AppConstants.spaceM + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: AppColors.backgroundLight,
              border: Border(top: BorderSide(color: AppColors.dividerLight)),
            ),
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(
                  double.infinity,
                  AppConstants.buttonHeight,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
              ),
              child: Text(
                'عرض النتائج',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.bodyLarge.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimaryLight,
    ),
  );
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _NumberField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimaryLight),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textHintLight,
      ),
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
    ),
  );
}

class _BedroomPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _BedroomPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 48,
      height: 42,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.dividerLight,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: selected ? AppColors.white : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  const _ToggleRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () {
      // cycle: null → true → false → null
      if (value == null) {
        onChanged(true);
      } else if (value == true) {
        onChanged(false);
      } else {
        onChanged(null);
      }
    },
    borderRadius: BorderRadius.circular(AppConstants.radiusS),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: value != null ? AppColors.primary : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondaryLight),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
          Text(
            value == null
                ? 'أي'
                : value == true
                ? 'نعم'
                : 'لا',
            style: AppTextStyles.bodySmall.copyWith(
              color: value != null
                  ? AppColors.primary
                  : AppColors.textHintLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
