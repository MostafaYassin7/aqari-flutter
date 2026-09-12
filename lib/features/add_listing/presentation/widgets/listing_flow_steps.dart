import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/preview/ui_preview.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/add_listing_provider.dart';
import '../listing_ui_rules.dart';

const listingStepLabels = <String, String>{
  'role': 'صفة المعلن',
  'ownerInfo': 'إصدار ترخيص الإعلان',
  'license': 'بيانات الترخيص',
  'category': 'النوع',
  'media': 'الصور',
  'info': 'المعلومات',
  'features': 'المميزات',
  'details': 'التفاصيل',
  'booking': 'إعدادات الحجز',
  'location': 'الموقع',
  'review': 'المراجعة',
};
const propertyLabels = {
  'apartment': 'شقة',
  'villa': 'فيلا',
  'land': 'أرض',
  'building': 'عمارة',
  'shop': 'محل',
  'house': 'بيت',
  'rest_house': 'استراحة',
  'farm': 'مزرعة',
  'chalet': 'شاليه',
  'commercial_office': 'مكتب تجاري',
  'warehouse': 'مستودع',
  'floor': 'دور',
  'camp': 'مخيم',
  'other': 'أخرى',
  'event_hall': 'قاعة مناسبات',
};
const serviceLabels = {
  'catering': 'ضيافة وطعام',
  'sound_system': 'نظام صوتي',
  'projector': 'بروجكتور',
  'decoration': 'ديكور',
  'security': 'أمن',
  'parking': 'مواقف سيارات',
};
const detailLabels = {
  'capacity': 'الطاقة الاستيعابية',
  'halfDay': 'سعر نصف يوم (ريال)',
  'bedrooms': 'غرف النوم',
  'livingRooms': 'غرف الجلوس',
  'bathrooms': 'الحمامات',
  'floor': 'الدور',
  'age': 'عمر العقار (سنة)',
  'street': 'عرض الشارع (م)',
  'facade': 'الواجهة',
  'minNights': 'الحد الأدنى لليالي',
  'checkIn': 'وقت الوصول',
  'checkOut': 'وقت المغادرة',
  'furnished': 'مفروش',
  'kitchen': 'مطبخ',
  'extra': 'وحدة إضافية',
  'car': 'مدخل سيارة',
  'elevator': 'مصعد',
};
List<String> detailKeys(AddListingState s) => switch (s.group) {
  'hall' => ['capacity', 'halfDay'],
  'residential' => [
    'bedrooms',
    'livingRooms',
    'bathrooms',
    'floor',
    'age',
    'street',
    'facade',
    'furnished',
    'kitchen',
    'extra',
    'car',
    'elevator',
  ],
  'commercial' => ['bathrooms', 'floor', 'age', 'street', 'facade'],
  'land' => ['street', 'facade'],
  _ => [],
};
const boolDetails = ['furnished', 'kitchen', 'extra', 'car', 'elevator'];

class ListingFlowStep extends ConsumerWidget {
  final String step;
  final ValueChanged<String>? onEdit;
  const ListingFlowStep(this.step, {super.key, this.onEdit});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(addListingProvider);
    final n = ref.read(addListingProvider.notifier);
    Widget field(
      String key,
      String label, {
      bool numeric = false,
      int lines = 1,
    }) {
      final required = licenseRequiredKeys.contains(key);
      final text = required ? '$label *' : label;
      if (key == 'birth' || key == 'agentBirth') {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            key: ValueKey(
              '$step-$key-${s.role}-${s.value('idType')}-${s.value(key)}',
            ),
            initialValue: s.value(key),
            readOnly: true,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              labelText: text,
              filled: true,
              fillColor: context.appColors.surface,
              suffixIcon: const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onTap: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(s.value(key)) ?? DateTime(1990),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (selected != null) {
                n.field(
                  key,
                  '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}',
                );
              }
            },
          ),
        );
      }
      return PreviewField(
        key: ValueKey('$step-$key-${s.role}-${s.value('idType')}'),
        label: text,
        value: s.value(key),
        onChanged: (v) => n.field(key, v),
        numeric: numeric,
        lines: lines,
      );
    }

    Widget choices(String key, Map<String, String> options, {String? value}) =>
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries
              .map(
                (e) => PreviewChoice(
                  e.value,
                  selected: (value ?? s.value(key)) == e.key,
                  onTap: () => n.field(key, e.key),
                ),
              )
              .toList(),
        );
    final children = <Widget>[];
    switch (step) {
      case 'role':
        children.addAll([
          Text('ما هو دورك؟', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'اختر صفتك لنساعدك في إضافة إعلانك',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, box) {
              final wideText = MediaQuery.textScalerOf(context).scale(12) > 17;
              final cards = [
                _RoleCard(
                  label: 'مالك / وكيل',
                  icon: Icons.key_rounded,
                  selected: s.role == 'owner' || s.role == 'agent',
                  onTap: () => n.setRole('owner'),
                ),
                _RoleCard(
                  label: 'مسوق عقاري',
                  icon: Icons.work_outline_rounded,
                  selected: s.role == 'broker',
                  onTap: () => n.setRole('broker'),
                ),
                _RoleCard(
                  label: 'مضيف',
                  icon: Icons.bed_outlined,
                  selected: s.role == 'host',
                  onTap: () => n.setRole('host'),
                ),
              ];
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: cards
                    .map(
                      (card) => SizedBox(
                        width: wideText
                            ? box.maxWidth
                            : (box.maxWidth - 20) / 3,
                        child: card,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 32),
          Text('ماذا تريد أن تفعل؟', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          _ServiceCard(
            title: 'إضافة إعلان عقاري',
            subtitle: 'اعرض عقارك للبيع أو الإيجار',
            icon: Icons.add_home_outlined,
            selected: true,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _ServiceCard(
            title: 'طلب تسويق عقار',
            subtitle: 'اطلب من وسطاء تسويق عقارك',
            icon: Icons.campaign_outlined,
            selected: false,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('هذه الخدمة قادمة قريباً'),
                behavior: SnackBarBehavior.floating,
              ),
            ),
          ),
        ]);
      case 'ownerInfo':
        children.add(const _OwnerLicenseIntroduction());
      case 'license':
        if (s.role == 'host') {
          children.addAll([
            const Text(
              'لإضافة إعلان إيجار يومي يجب أن يكون لديك ترخيص من وزارة السياحة',
            ),
            const SizedBox(height: 16),
            field('tourism', 'رقم ترخيص وزارة السياحة'),
          ]);
        } else if (s.role == 'broker') {
          children.addAll([
            const Text(
              'لإضافة إعلان يجب أن يكون لديك ترخيص إعلان صادر من الهيئة العامة للعقار',
            ),
            const SizedBox(height: 16),
            field('adLicense', 'رقم ترخيص الإعلان'),
            const Text('نوع هوية المالك *'),
            choices('brokerIdType', {
              'national': 'هوية وطنية',
              'commercial': 'سجل تجاري',
            }),
            const SizedBox(height: 16),
            field(
              'brokerOwnerId',
              s.value('brokerIdType') == 'commercial'
                  ? 'رقم السجل التجاري'
                  : 'رقم هوية المالك',
            ),
          ]);
        } else {
          children.addAll([
            Text('صفة مقدم الإعلان', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['owner', 'agent']
                  .map(
                    (role) => PreviewChoice(
                      role == 'owner' ? 'مالك' : 'وكيل',
                      selected: s.role == role,
                      onTap: () => n.setRole(role),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text('وثيقة الملكية', style: AppTextStyles.titleMedium),
            choices('documentType', {
              'deed': 'صك إلكتروني / سجل عيني',
              'other': 'غير ذلك',
            }),
            const SizedBox(height: 16),
            const Text('نوع هوية المالك *'),
            const SizedBox(height: 8),
            choices('idType', {
              'national': 'هوية وطنية',
              'commercial': 'سجل تجاري',
              'unified': 'رقم موحد 700',
            }),
            const SizedBox(height: 16),
            field(
              'ownerId',
              s.value('idType') == 'commercial'
                  ? 'السجل التجاري'
                  : s.value('idType') == 'unified'
                  ? 'الرقم الموحد 700'
                  : 'هوية المالك',
            ),
            if (s.value('idType').isEmpty ||
                s.value('idType') == 'national') ...[
              field('birth', 'تاريخ ميلاد المالك'),
              choices('calendar', {'gregorian': 'ميلادي', 'hijri': 'هجري'}),
              const SizedBox(height: 16),
              field('phone', 'جوال المالك (اختياري)'),
            ],
            field('document', 'رقم الصك أو العقار أو السجل العيني'),
            field('coOwner', 'هوية أحد الملاك (اختياري)'),
            if (s.role == 'agent') ...[
              field('agency', 'رقم الوكالة'),
              field('agentId', 'هوية الوكيل'),
              field('agentBirth', 'تاريخ ميلاد الوكيل'),
              field('agentPhone', 'جوال الوكيل (اختياري)'),
            ],
            TextButton(
              onPressed: () async {
                final skip = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('تخطي بيانات الترخيص؟'),
                    content: Text(
                      uiPreview
                          ? 'لن يتم نشر الإعلان حتى تكتمل بيانات الترخيص. ستكون النتيجة مسودة؛ في هذه المعاينة لا يتم حفظ شيء على الخادم.'
                          : 'لن يتم نشر الإعلان حتى تكتمل بيانات الترخيص. سيتم حفظه كمسودة عند إرسال الإعلان.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('رجوع'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('تخطي'),
                      ),
                    ],
                  ),
                );
                if (skip == true) {
                  n.field('skipLicense', 'true');
                  onEdit?.call('category');
                }
              },
              child: Text(
                s.value('skipLicense') == 'true'
                    ? 'تم اختيار التخطي'
                    : 'تخطي بيانات الترخيص',
              ),
            ),
          ]);
        }
        children.add(const PreviewNotice());
    }
    return ListView(padding: const EdgeInsets.all(16), children: children);
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _RoleCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 22),
        decoration: BoxDecoration(
          color: selected
              ? context.appColors.primaryTint
              : context.appColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : context.appColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 30,
              color: selected ? AppColors.primary : context.appColors.icon,
            ),
            const SizedBox(height: 14),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSmall.copyWith(
                color: selected
                    ? AppColors.primary
                    : context.appColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ServiceCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected
            ? context.appColors.primaryTint
            : context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.primary : context.appColors.divider,
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: .12)
                  : context.appColors.divider,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: selected ? AppColors.primary : context.appColors.icon,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: selected
                        ? AppColors.primary
                        : context.appColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.chevron_left_rounded,
            color: selected ? AppColors.primary : context.appColors.icon,
            size: 20,
          ),
        ],
      ),
    ),
  );
}

class _OwnerLicenseIntroduction extends StatelessWidget {
  const _OwnerLicenseIntroduction();
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const steps = [
      'إضافة معلومات المالك أو الوكيل ووثيقة الملكية',
      'إضافة معلومات الإعلان',
      'سداد رسوم الإعلان',
      'الموافقة على عقد الوساطة',
    ];
    const requirements = [
      'وثيقة ملكية وهوية سارية',
      'سداد رسوم الإعلان',
      'الموافقة على عقد الوساطة',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.successSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.successText.withValues(alpha: .25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: colors.successText,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'الترخيص من خلال عقار يعفي من عمولة البيع أو التأجير',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.successText,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.divider),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'يقوم عقار بإصدار ترخيص إعلان للملاك والوكلاء',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'الخطوات',
                style: AppTextStyles.titleMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              for (var index = 0; index < steps.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          steps[index],
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Divider(color: colors.divider),
              const SizedBox(height: 20),
              Text(
                'المتطلبات',
                style: AppTextStyles.titleMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              for (final requirement in requirements)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(
                          Icons.circle,
                          size: 7,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          requirement,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'بالضغط على «التالي» ستنتقل لإدخال بيانات الترخيص.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}
