import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/app_loading_indicator.dart';
import '../../data/property_advertisement_license_repository.dart';
import '../providers/add_listing_provider.dart';

// ── Step 0d: ترخيص المضيف (Host tourism license validation) ──────────────────
//
// Validates the host's Ministry of Tourism license via the backend.
// On success: stores licenseId in provider and proceeds to step 1.
// On failure: shows error under the field and stays on screen.
//
// Used by: advertiserType = 'host' ONLY

class Step0dHostLicenseForm extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const Step0dHostLicenseForm({required this.onNext, super.key});

  @override
  ConsumerState<Step0dHostLicenseForm> createState() =>
      _Step0dHostLicenseFormState();
}

class _Step0dHostLicenseFormState
    extends ConsumerState<Step0dHostLicenseForm> {
  final _licenseCtrl = TextEditingController();
  String? _fieldError;

  @override
  void dispose() {
    _licenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    final s        = ref.read(addListingProvider);
    final notifier = ref.read(addListingProvider.notifier);

    if (mounted) setState(() => _fieldError = null);

    // Local validation
    if (s.hostTourismLicenseNumber == null ||
        s.hostTourismLicenseNumber!.isEmpty) {
      if (mounted) {
        setState(() => _fieldError = 'رقم رخصة وزارة السياحة مطلوب');
      }
      return;
    }

    notifier.setIsValidatingLicense(true);

    try {
      final result = await PropertyAdvertisementLicenseRepository()
          .validateHostLicense(
        tourismLicenseNumber: s.hostTourismLicenseNumber!,
      );

      if (result['isValid'] == true) {
        notifier.setLicenseId(result['licenseId'] as String);
        notifier.setIsValidatingLicense(false);
        widget.onNext();
      } else {
        notifier.setIsValidatingLicense(false);
        if (mounted) {
          setState(() => _fieldError = result['message'] as String? ??
              'رقم الرخصة غير صحيح، يرجى التحقق والمحاولة مرة أخرى');
        }
      }
    } catch (_) {
      notifier.setIsValidatingLicense(false);
      if (mounted) setState(() => _fieldError = 'حدث خطأ، يرجى المحاولة مرة أخرى');
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
                          'لإضافة إعلان إيجار يومي على منصة عقار يجب أن يكون لديك ترخيص صادر من وزارة السياحة السعودية',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
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
                      // FIELD 1: رقم رخصة وزارة السياحة
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            ' *',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.error),
                          ),
                          Text(
                            'رقم رخصة وزارة السياحة',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _licenseCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textPrimaryLight),
                        decoration: InputDecoration(
                          hintText: 'أدخل رقم الرخصة',
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
                              color: _fieldError != null
                                  ? AppColors.error
                                  : AppColors.dividerLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusM),
                            borderSide: BorderSide(
                              color: _fieldError != null
                                  ? AppColors.error
                                  : AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: notifier.setHostTourismLicenseNumber,
                      ),
                      if (_fieldError != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _fieldError!,
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
          decoration: const BoxDecoration(
            color: AppColors.backgroundLight,
            border: Border(top: BorderSide(color: AppColors.dividerLight)),
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
