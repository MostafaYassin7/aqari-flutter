import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/advertiser_types.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../providers/add_listing_provider.dart';

// ── Step 0c: إضافة إعلان جديد (Broker license form) ─────────────────────────
//
// License form specifically for licensed brokers (مسوق عقاري).
// Simpler than the owner form — broker provides their own existing license
// numbers rather than ownership documents.
//
// Required fields:
//   falLicenseNumber        — رقم رخصة فال (from الهيئة العامة للعقار)
//   brokerageContractNumber — رقم عقد الوساطة (registered on rega platform)
//   propertyOwnerIdType     — نوع هوية المالك
//   propertyOwnerIdNumber   — رقم هوية المالك
//
// Used by: advertiserType = 'broker' ONLY

class Step0cBrokerLicenseForm extends ConsumerStatefulWidget {
  // Called when user taps "التالي" and all required fields are valid
  final VoidCallback onNext;

  const Step0cBrokerLicenseForm({required this.onNext, super.key});

  @override
  ConsumerState<Step0cBrokerLicenseForm> createState() =>
      _Step0cBrokerLicenseFormState();
}

class _Step0cBrokerLicenseFormState
    extends ConsumerState<Step0cBrokerLicenseForm> {
  final Map<String, String?> _errors = {};

  final _falLicenseCtrl         = TextEditingController();
  final _brokerageContractCtrl  = TextEditingController();
  final _ownerIdNumCtrl         = TextEditingController();

  @override
  void dispose() {
    _falLicenseCtrl.dispose();
    _brokerageContractCtrl.dispose();
    _ownerIdNumCtrl.dispose();
    super.dispose();
  }

  bool _validate(AddListingState s) {
    final errs = <String, String?>{};

    // رقم رخصة فال — required for broker
    if (s.falLicenseNumber == null || s.falLicenseNumber!.isEmpty) {
      errs['falLicenseNumber'] = 'هذا الحقل مطلوب';
    }

    // رقم عقد الوساطة — required for broker
    if (s.brokerageContractNumber == null ||
        s.brokerageContractNumber!.isEmpty) {
      errs['brokerageContractNumber'] = 'هذا الحقل مطلوب';
    }

    // رقم هوية المالك — required for all advertiserTypes
    if (s.propertyOwnerIdNumber == null || s.propertyOwnerIdNumber!.isEmpty) {
      errs['propertyOwnerIdNumber'] = 'هذا الحقل مطلوب';
    }

    setState(() => _errors.addAll(errs));
    return errs.isEmpty;
  }

  void _onNext() {
    final s = ref.read(addListingProvider);
    if (_validate(s)) widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(addListingProvider);
    final notifier = ref.read(addListingProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Illustration placeholder
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.business_center_rounded,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Info text explaining broker requirements
                Text(
                  'لإضافة إعلان كمسوق عقاري، يجب أن يكون لديك ترخيص إعلان صادر من الهيئة العامة للعقار وعقد وساطة مسجل مع مالك العقار',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // ── Field 1: رقم رخصة فال ────────────────────
                // رقم رخصة فال — FAL brokerage license number
                // Issued by General Real Estate Authority (الهيئة العامة للعقار)
                // Required: YES for broker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // "ما هو ترخيص الإعلان؟" — info link (placeholder)
                    GestureDetector(
                      onTap: () {}, // placeholder — no action for now
                      child: Text(
                        'ما هو ترخيص الإعلان؟',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.info,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.info,
                        ),
                      ),
                    ),
                    // Label with required asterisk
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ' *',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.error),
                        ),
                        Text(
                          'رقم رخصة فال',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _NumberField(
                  controller: _falLicenseCtrl,
                  error: _errors['falLicenseNumber'],
                  onChanged: (v) {
                    notifier.setLicenseField(
                        'falLicenseNumber', v.isEmpty ? null : v);
                    if (_errors.containsKey('falLicenseNumber')) {
                      setState(() => _errors.remove('falLicenseNumber'));
                    }
                  },
                ),

                const SizedBox(height: 16),

                // ── Field 2: رقم عقد الوساطة ─────────────────
                // رقم عقد الوساطة — brokerage contract number
                // Registered by broker with property owner on rega platform
                // eservicesredp.rega.gov.sa
                // Required: YES for broker
                _LabeledNumberField(
                  label: 'رقم عقد الوساطة',
                  hint:
                      'رقم العقد المسجل مع المالك على منصة الهيئة العامة للعقار',
                  controller: _brokerageContractCtrl,
                  error: _errors['brokerageContractNumber'],
                  onChanged: (v) {
                    notifier.setLicenseField(
                        'brokerageContractNumber', v.isEmpty ? null : v);
                    if (_errors.containsKey('brokerageContractNumber')) {
                      setState(
                          () => _errors.remove('brokerageContractNumber'));
                    }
                  },
                ),

                const SizedBox(height: 16),

                // ── Field 3: نوع هوية مالك العقار ────────────
                // propertyOwnerIdType — broker must also verify owner identity type
                // Required: YES
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      ' *',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.error),
                    ),
                    Text(
                      'نوع هوية مالك العقار',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _OwnerIdTypePills(
                  selected: s.propertyOwnerIdType,
                  onChanged: (v) {
                    notifier.setLicenseField('propertyOwnerIdType', v);
                    notifier.setLicenseField('propertyOwnerIdNumber', null);
                    _ownerIdNumCtrl.clear();
                    setState(() => _errors.remove('propertyOwnerIdNumber'));
                  },
                ),

                const SizedBox(height: 16),

                // ── Field 4: رقم هوية المالك ─────────────────
                // Label changes based on propertyOwnerIdType
                // Required: YES for broker
                _LabeledNumberField(
                  label: _ownerIdLabel(s.propertyOwnerIdType),
                  controller: _ownerIdNumCtrl,
                  error: _errors['propertyOwnerIdNumber'],
                  onChanged: (v) {
                    notifier.setLicenseField(
                        'propertyOwnerIdNumber', v.isEmpty ? null : v);
                    if (_errors.containsKey('propertyOwnerIdNumber')) {
                      setState(() => _errors.remove('propertyOwnerIdNumber'));
                    }
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // ── Fixed bottom button ───────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(
            AppConstants.spaceM,
            AppConstants.spaceS,
            AppConstants.spaceM,
            AppConstants.spaceS + MediaQuery.of(context).padding.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.backgroundLight,
            border: Border(top: BorderSide(color: AppColors.dividerLight)),
          ),
          child: ElevatedButton(
            onPressed: _onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize:
                  const Size(double.infinity, AppConstants.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              elevation: 0,
            ),
            child: Text(
              'التالي',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _ownerIdLabel(String idType) {
    switch (idType) {
      case PropertyOwnerIdType.commercialRegistration:
        return 'رقم السجل التجاري';
      case PropertyOwnerIdType.unified700:
        return 'الرقم الموحد 700';
      default:
        return 'رقم هوية المالك';
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;
  final String? hint;

  const _NumberField({
    required this.controller,
    this.error,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textPrimaryLight),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textHintLight),
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusM),
                borderSide:
                    const BorderSide(color: AppColors.dividerLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(
                  color: error != null
                      ? AppColors.error
                      : AppColors.dividerLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(
                  color: error != null
                      ? AppColors.error
                      : AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: onChanged,
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              error!,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.error),
              textAlign: TextAlign.right,
            ),
          ],
        ],
      );
}

class _LabeledNumberField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;

  const _LabeledNumberField({
    required this.label,
    this.hint,
    required this.controller,
    this.error,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                ' *',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.error),
              ),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _NumberField(
            controller: controller,
            hint: hint,
            error: error,
            onChanged: onChanged,
          ),
        ],
      );
}

// Three-pill selector for نوع هوية مالك العقار
class _OwnerIdTypePills extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _OwnerIdTypePills(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _pill('هوية وطنية', PropertyOwnerIdType.nationalId),
          const SizedBox(width: 6),
          _pill('سجل تجاري', PropertyOwnerIdType.commercialRegistration),
          const SizedBox(width: 6),
          _pill('رقم موحد 700', PropertyOwnerIdType.unified700),
        ],
      );

  Widget _pill(String label, String value) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
            border: Border.all(
              color:
                  isSelected ? AppColors.primary : AppColors.dividerLight,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isSelected
                  ? AppColors.white
                  : AppColors.textSecondaryLight,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
