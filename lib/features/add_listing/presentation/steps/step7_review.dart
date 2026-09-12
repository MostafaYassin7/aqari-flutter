import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/preview/ui_preview.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/add_listing_provider.dart';
import '../data/listing_locations.dart';
import '../widgets/listing_flow_steps.dart' show serviceLabels;

class Step7Review extends ConsumerWidget {
  final ValueChanged<String> onEdit;
  const Step7Review({required this.onEdit, super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(addListingProvider);
    Widget row(String label, String value) =>
        _ReviewRow(label: label, value: value.isEmpty ? '—' : value);
    Widget section(String id, String title, List<Widget> rows) =>
        _ReviewSection(
          title: title,
          onEdit: () => onEdit(id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          ),
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'مراجعة الإعلان',
            style: AppTextStyles.headlineMedium.copyWith(
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'راجع جميع التفاصيل قبل النشر',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          section('role', 'صفة المعلن', [
            row(
              'الصفة',
              {
                'owner': 'مالك',
                'agent': 'وكيل',
                'broker': 'مسوق عقاري',
                'host': 'مضيف',
              }[s.role]!,
            ),
          ]),
          section('license', 'بيانات الترخيص', [
            if (s.value('skipLicense') == 'true' &&
                (s.role == 'owner' || s.role == 'agent'))
              row('البيانات', 'تم التخطي')
            else ...[
              if (s.role == 'host') row('الترخيص السياحي', s.value('tourism')),
              if (s.role == 'broker') ...[
                row('ترخيص الإعلان', s.value('adLicense')),
                row('هوية المالك', s.value('brokerOwnerId')),
              ],
              if (s.role == 'owner' || s.role == 'agent') ...[
                row('وثيقة الملكية', s.value('document')),
                row('هوية المالك', s.value('ownerId')),
                if (s.value('idType').isEmpty ||
                    s.value('idType') == 'national')
                  row('ميلاد المالك', s.value('birth')),
                if (s.role == 'agent') ...[
                  row('الوكالة', s.value('agency')),
                  row('هوية الوكيل', s.value('agentId')),
                  row('ميلاد الوكيل', s.value('agentBirth')),
                ],
              ],
              row(
                'حالة الترخيص',
                uiPreview
                    ? 'لم يتم التحقق · معاينة'
                    : s.value('licenseId').isEmpty
                    ? 'يتم إرساله عند تقديم الإعلان'
                    : 'تم حفظ بيانات الترخيص',
              ),
            ],
          ]),
          section('category', 'نوع العقار', [
            row('الفئة', s.category ?? ''),
            row(
              'نوع الإعلان',
              s.group == 'hall'
                  ? 'إيجار قاعة'
                  : s.isDaily
                  ? 'إيجار يومي'
                  : s.listingType == 'sale'
                  ? 'للبيع'
                  : 'للإيجار',
            ),
          ]),
          section('media', 'الصور', [
            row('الصور', '${s.photos.length} صورة مضافة'),
          ]),
          section('info', 'المعلومات الأساسية', [
            row('العنوان', s.value('title')),
            row(
              'السعر',
              '${s.price} ريال${s.isDaily
                  ? ' / ليلة'
                  : s.group == 'hall'
                  ? ' / يوم'
                  : ''}',
            ),
            row('المساحة', '${s.area} م²'),
            row('الاستخدام', s.isResidential ? 'سكني' : 'تجاري'),
            if (s.hasCommission) row('العمولة', '${s.commissionPercent}%'),
            if (s.description.isNotEmpty) row('الوصف', s.description),
          ]),
          section('features', 'المميزات', [
            if (s.features.isEmpty)
              row('المميزات', 'لم يتم الاختيار')
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: s.features.map((f) => _Chip(f)).toList(),
              ),
          ]),
          section('details', 'التفاصيل', [
            if (s.group == 'residential') ...[
              row('غرف النوم', '${s.bedrooms}'),
              row('غرف الجلوس', '${s.livingRooms}'),
            ],
            if (s.group == 'residential' || s.group == 'commercial') ...[
              row('الحمامات', '${s.bathrooms}'),
              if (s.floorNumber.isNotEmpty) row('الدور', s.floorNumber),
              if (s.propertyAge.isNotEmpty)
                row('العمر', '${s.propertyAge} سنة'),
            ],
            if (['residential', 'commercial', 'land'].contains(s.group)) ...[
              if (s.facade != null) row('الواجهة', s.facade!),
              if (s.streetWidth.isNotEmpty)
                row('عرض الشارع', '${s.streetWidth} م'),
            ],
            if (s.group == 'residential') ...[
              row('مفروش', s.isFurnished ? 'نعم' : 'لا'),
              row('مطبخ', s.hasKitchen ? 'نعم' : 'لا'),
              row('وحدة إضافية', s.hasExtraUnit ? 'نعم' : 'لا'),
              row('مدخل سيارة', s.hasCarEntrance ? 'نعم' : 'لا'),
              row('مصعد', s.hasElevator ? 'نعم' : 'لا'),
            ],
            if (s.group == 'hall') ...[
              row('السعة', s.value('capacity')),
              if (s.value('halfDay').isNotEmpty)
                row('نصف يوم', '${s.value('halfDay')} ريال'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: serviceLabels.entries
                    .where((e) => s.value(e.key) == 'true')
                    .map((e) => _Chip(e.value))
                    .toList(),
              ),
            ],
            if (s.group == 'other') row('التفاصيل', 'لا توجد تفاصيل إضافية'),
          ]),
          if (s.isDaily)
            section('booking', 'إعدادات الحجز', [
              row('الضيوف', s.value('capacity')),
              row('الحد الأدنى', '${s.value('minNights')} ليلة'),
              row('الوصول', s.value('checkIn')),
              row('المغادرة', s.value('checkOut')),
            ]),
          section('location', 'الموقع', [
            row('المدينة', listingCities[s.value('city')] ?? s.value('city')),
            if (s.value('district').isNotEmpty)
              row(
                'الحي',
                listingDistricts[s.value('city')]?[s.value('district')] ??
                    s.value('district'),
              ),
            if (s.address.isNotEmpty) row('العنوان', s.address),
            row(
              'الخريطة',
              s.value('pin') == 'selected'
                  ? 'تم تحديد الموقع'
                  : 'لم يتم التحديد',
            ),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(20),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(color: AppColors.success.withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    uiPreview
                        ? 'هذه معاينة فقط؛ لن يتم نشر إعلان أو إصدار ترخيص.'
                        : 'سيتم إرسال الإعلان بعد مراجعة البيانات وتأكيد الإرسال.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.appColors.textPrimary,
                    ),
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
      color: context.appColors.card,
      borderRadius: BorderRadius.circular(AppConstants.radiusL),
      border: Border.all(color: context.appColors.divider),
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
                color: context.appColors.textPrimary,
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
        Divider(height: 1, color: context.appColors.divider),
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
              color: context.appColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.appColors.textPrimary,
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
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: context.appColors.primaryTint,
      borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
      border: Border.all(color: AppColors.primary.withAlpha(100)),
    ),
    child: Text(
      label,
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
