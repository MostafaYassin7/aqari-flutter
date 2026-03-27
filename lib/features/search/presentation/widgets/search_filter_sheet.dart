import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/search_provider.dart';

/// Shows the search filter bottom sheet. Call from an IconButton or FAB.
void showSearchFilterSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL)),
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
  // Local state mirrors the providers so we can apply/discard changes.
  late RangeValues _priceRange;
  late Set<String> _types;
  late int _bedrooms;
  late Set<String> _amenities;

  @override
  void initState() {
    super.initState();
    final pr = ref.read(priceRangeProvider);
    _priceRange = RangeValues(pr.min, pr.max);
    _types = Set.from(ref.read(selectedPropertyTypesProvider));
    _bedrooms = ref.read(bedroomsFilterProvider);
    _amenities = Set.from(ref.read(selectedAmenitiesProvider));
  }

  void _clearAll() {
    setState(() {
      _priceRange = const RangeValues(
          PriceRangeNotifier.kMin, PriceRangeNotifier.kMax);
      _types = {};
      _bedrooms = -1;
      _amenities = {};
    });
  }

  void _apply() {
    ref
        .read(priceRangeProvider.notifier)
        .set(_priceRange.start, _priceRange.end);
    ref.read(selectedPropertyTypesProvider.notifier).clear();
    for (final t in _types) {
      ref.read(selectedPropertyTypesProvider.notifier).toggle(t);
    }
    ref.read(bedroomsFilterProvider.notifier).select(_bedrooms);
    ref.read(selectedAmenitiesProvider.notifier).clear();
    for (final a in _amenities) {
      ref.read(selectedAmenitiesProvider.notifier).toggle(a);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
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
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusCircle),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Title row ─────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الفلاتر',
                    style: AppTextStyles.titleLarge
                        .copyWith(fontWeight: FontWeight.w700)),
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
                _SectionTitle('نطاق السعر (ريال)'),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatPrice(_priceRange.start),
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight),
                    ),
                    Text(
                      _formatPrice(_priceRange.end),
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.primary,
                    thumbColor: AppColors.primary,
                    inactiveTrackColor: AppColors.dividerLight,
                    overlayColor: AppColors.primary.withAlpha(30),
                    rangeThumbShape: const RoundRangeSliderThumbShape(
                        enabledThumbRadius: 8),
                  ),
                  child: RangeSlider(
                    min: PriceRangeNotifier.kMin,
                    max: PriceRangeNotifier.kMax,
                    divisions: 100,
                    values: _priceRange,
                    onChanged: (v) => setState(() => _priceRange = v),
                  ),
                ),

                const SizedBox(height: 8),
                const Divider(color: AppColors.dividerLight),
                const SizedBox(height: 8),

                // ── Property type ──────────────────────────────
                _SectionTitle('نوع العقار'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: searchPropertyTypes
                      .map((t) => _CheckChip(
                            label: t,
                            selected: _types.contains(t),
                            onTap: () => setState(() {
                              if (_types.contains(t)) {
                                _types.remove(t);
                              } else {
                                _types.add(t);
                              }
                            }),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 8),
                const Divider(color: AppColors.dividerLight),
                const SizedBox(height: 8),

                // ── Bedrooms ───────────────────────────────────
                _SectionTitle('عدد غرف النوم'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _BedroomPill(
                        label: 'أي',
                        selected: _bedrooms == -1,
                        onTap: () => setState(() => _bedrooms = -1)),
                    const SizedBox(width: 8),
                    ...List.generate(
                      5,
                      (i) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _BedroomPill(
                          label: i == 4 ? '5+' : '${i + 1}',
                          selected: _bedrooms == (i == 4 ? 5 : i + 1),
                          onTap: () => setState(
                              () => _bedrooms = (i == 4 ? 5 : i + 1)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const Divider(color: AppColors.dividerLight),
                const SizedBox(height: 8),

                // ── Amenities ──────────────────────────────────
                _SectionTitle('المرافق'),
                const SizedBox(height: 12),
                ...searchAmenities.map((a) => _AmenityRow(
                      label: a,
                      checked: _amenities.contains(a),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _amenities.add(a);
                        } else {
                          _amenities.remove(a);
                        }
                      }),
                    )),

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
              AppConstants.spaceM +
                  MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: AppColors.backgroundLight,
              border: Border(
                  top: BorderSide(color: AppColors.dividerLight)),
            ),
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize:
                    const Size(double.infinity, AppConstants.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusM),
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

  String _formatPrice(double v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1)} م';
    }
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)} ألف';
    return v.toInt().toString();
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

class _CheckChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CheckChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceLight,
            borderRadius:
                BorderRadius.circular(AppConstants.radiusCircle),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.dividerLight,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color:
                  selected ? AppColors.white : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}

class _BedroomPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _BedroomPill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 42,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceLight,
            borderRadius:
                BorderRadius.circular(AppConstants.radiusS),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.dividerLight,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: selected
                    ? AppColors.white
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
}

class _AmenityRow extends StatelessWidget {
  final String label;
  final bool checked;
  final ValueChanged<bool?> onChanged;
  const _AmenityRow(
      {required this.label,
      required this.checked,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => onChanged(!checked),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: checked,
                  onChanged: onChanged,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusS / 2)),
                  side: const BorderSide(color: AppColors.dividerLight),
                ),
              ),
              const SizedBox(width: 12),
              Text(label,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textPrimaryLight)),
            ],
          ),
        ),
      );
}
