import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../providers/add_listing_provider.dart';

class Step7Review extends ConsumerWidget {
  final void Function(int step) onEdit;
  const Step7Review({required this.onEdit, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(addListingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'مراجعة الإعلان',
            style: AppTextStyles.headlineMedium
                .copyWith(color: AppColors.textPrimaryLight),
          ),
          const SizedBox(height: 4),
          Text(
            'راجع جميع التفاصيل قبل النشر',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 20),

          // ── Section 1: Category ──────────────────────────
          _ReviewSection(
            title: 'نوع العقار',
            onEdit: () => onEdit(0),
            child: _ReviewRow(
              label: 'الفئة',
              value: s.category ?? '—',
            ),
          ),

          // ── Section 2: Media ─────────────────────────────
          _ReviewSection(
            title: 'الصور',
            onEdit: () => onEdit(1),
            child: Text(
              '${s.photos.length} صورة مضافة'
              '${s.photos.length < 3 ? '  ⚠️ أقل من 3 صور' : ''}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: s.photos.length < 3
                    ? AppColors.warning
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),

          // ── Section 3: Info ──────────────────────────────
          _ReviewSection(
            title: 'المعلومات الأساسية',
            onEdit: () => onEdit(2),
            child: Column(
              children: [
                _ReviewRow(
                    label: 'السعر',
                    value: s.price.isEmpty
                        ? '—'
                        : '${s.price} ريال'),
                _ReviewRow(
                    label: 'المساحة',
                    value: s.area.isEmpty ? '—' : '${s.area} م²'),
                _ReviewRow(
                    label: 'الاستخدام',
                    value: s.isResidential ? 'سكني' : 'تجاري'),
                if (s.hasCommission)
                  _ReviewRow(
                      label: 'العمولة',
                      value: '${s.commissionPercent}٪'),
                if (s.description.isNotEmpty)
                  _ReviewRow(
                      label: 'الوصف',
                      value: s.description.length > 60
                          ? '${s.description.substring(0, 60)}...'
                          : s.description),
              ],
            ),
          ),

          // ── Section 4: Features ──────────────────────────
          _ReviewSection(
            title: 'المميزات',
            onEdit: () => onEdit(3),
            child: s.features.isEmpty
                ? Text('لم يتم الاختيار',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight))
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: s.features
                        .map((f) => _Chip(f))
                        .toList(),
                  ),
          ),

          // ── Section 5: Details ───────────────────────────
          _ReviewSection(
            title: 'التفاصيل',
            onEdit: () => onEdit(4),
            child: Column(
              children: [
                _ReviewRow(label: 'غرف النوم', value: '${s.bedrooms}'),
                _ReviewRow(
                    label: 'غرف الجلوس',
                    value: '${s.livingRooms}'),
                _ReviewRow(label: 'الحمامات', value: '${s.bathrooms}'),
                if (s.facade != null)
                  _ReviewRow(label: 'الواجهة', value: s.facade!),
                if (s.streetWidth.isNotEmpty)
                  _ReviewRow(
                      label: 'عرض الشارع',
                      value: '${s.streetWidth} م'),
                if (s.propertyAge.isNotEmpty)
                  _ReviewRow(
                      label: 'عمر العقار',
                      value: '${s.propertyAge} سنة'),
                _ReviewRow(
                    label: 'مفروش',
                    value: s.isFurnished ? 'نعم' : 'لا'),
              ],
            ),
          ),

          // ── Section 6: Location ──────────────────────────
          _ReviewSection(
            title: 'الموقع',
            onEdit: () => onEdit(5),
            child: _ReviewRow(
              label: 'العنوان',
              value: s.address.isEmpty ? '—' : s.address,
            ),
          ),

          const SizedBox(height: 8),

          // ── Publish note ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(20),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border:
                  Border.all(color: AppColors.success.withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.success, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'سيتم مراجعة إعلانك خلال 24 ساعة قبل ظهوره للمستخدمين',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimaryLight),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Review section ────────────────────────────────────────────────────────────

class _ReviewSection extends StatelessWidget {
  final String title;
  final VoidCallback onEdit;
  final Widget child;
  const _ReviewSection({
    required this.title,
    required this.onEdit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(color: AppColors.dividerLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Text(
                    'تعديل',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.dividerLight),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius:
              BorderRadius.circular(AppConstants.radiusCircle),
          border: Border.all(
              color: AppColors.primary.withAlpha(100)),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600),
        ),
      );
}
