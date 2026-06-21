import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/app_loading_indicator.dart';
import '../../data/property_advertisement_license_repository.dart';
import '../providers/add_listing_provider.dart';

// ── Step 0c: ترخيص المسوق العقاري (Broker license validation) ────────────────
//
// Validates the broker's REGA ad license via the backend (REGA API integration).
// On success: stores licenseId in provider and proceeds to step 1.
// On failure: shows error under field 1 and stays on screen.
//
// Used by: advertiserType = 'broker' ONLY

class Step0cBrokerLicenseForm extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const Step0cBrokerLicenseForm({required this.onNext, super.key});

  @override
  ConsumerState<Step0cBrokerLicenseForm> createState() =>
      _Step0cBrokerLicenseFormState();
}

class _Step0cBrokerLicenseFormState
    extends ConsumerState<Step0cBrokerLicenseForm> {
  final _adLicenseCtrl = TextEditingController();
  final _ownerIdCtrl   = TextEditingController();
  String? _ownerIdError;

  @override
  void dispose() {
    _adLicenseCtrl.dispose();
    _ownerIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    final s        = ref.read(addListingProvider);
    final notifier = ref.read(addListingProvider.notifier);

    notifier.clearLicenseValidationError();
    if (mounted) setState(() => _ownerIdError = null);

    // Local validation — field 1
    if (s.brokerAdLicenseNumber == null || s.brokerAdLicenseNumber!.isEmpty) {
      notifier.setLicenseValidationError('رقم ترخيص الإعلان مطلوب');
      return;
    }

    // Local validation — field 3
    if (s.brokerOwnerIdNumber == null || s.brokerOwnerIdNumber!.isEmpty) {
      if (mounted) setState(() => _ownerIdError = 'رقم الهوية مطلوب');
      return;
    }

    notifier.setIsValidatingLicense(true);

    try {
      final result = await PropertyAdvertisementLicenseRepository()
          .validateBrokerLicense(
        adLicenseNumber: s.brokerAdLicenseNumber!,
        ownerIdType:     s.brokerOwnerIdType,
        ownerIdNumber:   s.brokerOwnerIdNumber!,
      );

      if (result['isValid'] == true) {
        notifier.setLicenseId(result['licenseId'] as String);
        notifier.setIsValidatingLicense(false);
        widget.onNext();
      } else {
        notifier.setIsValidatingLicense(false);
        notifier.setLicenseValidationError(
          result['message'] as String? ??
              'رقم ترخيص الإعلان غير صحيح، يرجى التحقق والمحاولة مرة أخرى',
        );
      }
    } catch (_) {
      notifier.setIsValidatingLicense(false);
      notifier.setLicenseValidationError('حدث خطأ، يرجى المحاولة مرة أخرى');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s        = ref.watch(addListingProvider);
    final notifier = ref.read(addListingProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // ── Info card ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8EC),
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'لإضافة إعلان على منصة عقار يجب أن يكون لديك ترخيص إعلان صادر من الهيئة العامة للعقار',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.textSecondary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Form card ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // FIELD 1: رقم ترخيص الإعلان
                      const _FieldLabel(label: 'رقم ترخيص الإعلان'),
                      const SizedBox(height: 6),
                      _LicenseTextField(
                        controller: _adLicenseCtrl,
                        hint: 'أدخل رقم الترخيص',
                        hasError: s.licenseValidationError != null,
                        onChanged: notifier.setBrokerAdLicenseNumber,
                      ),
                      if (s.licenseValidationError != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          s.licenseValidationError!,
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.error),
                          textAlign: TextAlign.right,
                        ),
                      ],

                      const SizedBox(height: 16),

                      // FIELD 2: نوع هوية مالك العقار (two-pill toggle)
                      const _FieldLabel(label: 'نوع هوية مالك العقار'),
                      const SizedBox(height: 8),
                      _TwoPillToggle(
                        selected: s.brokerOwnerIdType,
                        onChanged: (v) {
                          notifier.setBrokerOwnerIdType(v);
                          _ownerIdCtrl.clear();
                          if (mounted) setState(() => _ownerIdError = null);
                        },
                      ),

                      const SizedBox(height: 16),

                      // FIELD 3: رقم هوية المالك (label changes with type)
                      _FieldLabel(
                        label: s.brokerOwnerIdType == 'commercial_registration'
                            ? 'رقم السجل التجاري للمنشأة'
                            : 'رقم الهوية الوطنية للمالك',
                      ),
                      const SizedBox(height: 6),
                      _LicenseTextField(
                        controller: _ownerIdCtrl,
                        hint: 'أدخل الرقم هنا',
                        hasError: _ownerIdError != null,
                        onChanged: notifier.setBrokerOwnerIdNumber,
                      ),
                      if (_ownerIdError != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _ownerIdError!,
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.error),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ],
                  ),
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
          decoration: BoxDecoration(
            color: context.background,
            border: Border(top: BorderSide(color: context.divider)),
          ),
          child: ElevatedButton(
            onPressed: s.isValidatingLicense ? null : _onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.7),
              minimumSize:
                  const Size(double.infinity, AppConstants.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              elevation: 0,
            ),
            child: s.isValidatingLicense
                ? const AppLoadingIndicator(size: 24, color: AppColors.white)
                : Text(
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
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            ' *',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
        ],
      );
}

class _LicenseTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _LicenseTextField({
    required this.controller,
    required this.hint,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
        style: AppTextStyles.bodySmall
            .copyWith(color: context.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppTextStyles.bodySmall.copyWith(color: context.textHint),
          filled: true,
          fillColor: context.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            borderSide: BorderSide(color: context.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            borderSide: BorderSide(
              color: hasError ? AppColors.error : context.divider,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            borderSide: BorderSide(
              color: hasError ? AppColors.error : AppColors.primary,
              width: 1.5,
            ),
          ),
        ),
        onChanged: onChanged,
      );
}

// Two-pill toggle: هوية وطنية (right in RTL) | سجل تجاري (left in RTL)
class _TwoPillToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _TwoPillToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _pill('هوية وطنية', 'national_id', context),           // first = visual RIGHT in RTL
          const SizedBox(width: 8),
          _pill('سجل تجاري', 'commercial_registration', context), // second = visual LEFT in RTL
        ],
      );

  Widget _pill(String label, String value, BuildContext context) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : context.divider,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isSelected ? AppColors.white : context.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
