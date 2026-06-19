import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

// ── Step 0a: نشر وترخيص الإعلان ──────────────────────────────────────────────
//
// Informational screen explaining the licensing process to owners and agents.
// Shown AFTER Step 0 role selection and BEFORE the license form (step0b).
// Used by: advertiserType = 'owner' or 'agent'

class Step0aOwnerInfoScreen extends StatelessWidget {
  // Called when user taps "استمرار" — advances to step0b (license form)
  final VoidCallback onNext;

  const Step0aOwnerInfoScreen({required this.onNext, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // ── Info banner ───────────────────────────────
                // "الترخيص من خلال عقار يعفي من عمولة البيع أو التأجير"
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(25),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusM),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'الترخيص من خلال عقار يعفي من عمولة البيع أو التأجير',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 22,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Main card ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppConstants.spaceM),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusL),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 12,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Illustration placeholder
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.home_work_rounded,
                          size: 56,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'يقوم عقار بإصدار ترخيص إعلان للملاك والوكلاء',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),
                      const Divider(color: AppColors.dividerLight),
                      const SizedBox(height: 16),

                      // ── Steps section ─────────────────────
                      _SectionHeader(label: 'الخطوات:'),
                      const SizedBox(height: 10),
                      _BulletPoint(
                        text:
                            'إضافة معلومات المالك/الوكيل ووثيقة الملكية للعقار',
                      ),
                      _BulletPoint(text: 'إضافة معلومات الإعلان'),
                      _BulletPoint(
                        text:
                            'سداد رسوم الإعلان، مع العلم أن الإعلانات معفاة من عمولة البيع أو التأجير',
                      ),
                      _BulletPoint(
                        text:
                            'الموافقة على عقد الوساطة من المالك/الوكيل في منصة الهيئة العامة للعقار',
                      ),

                      const SizedBox(height: 16),
                      const Divider(color: AppColors.dividerLight),
                      const SizedBox(height: 16),

                      // ── Requirements section ──────────────
                      _SectionHeader(label: 'المتطلبات:'),
                      const SizedBox(height: 10),
                      _BulletPoint(text: 'وثيقة ملكية وهوية فعالة'),
                      _BulletPoint(text: 'سداد رسوم الإعلان'),
                      _BulletPoint(
                        text:
                            'الموافقة على عقد الوساطة في منصة الهيئة العامة للعقار',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // ── Fixed bottom ──────────────────────────────────────
        _BottomSection(onNext: onNext),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) => Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Text(
          label,
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
      );
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                  height: 1.5,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.textSecondaryLight,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
}

class _BottomSection extends StatelessWidget {
  final VoidCallback onNext;
  const _BottomSection({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary — "استمرار" → proceed to step0b
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize:
                  const Size(double.infinity, AppConstants.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusM),
              ),
              elevation: 0,
            ),
            child: Text(
              'استمرار',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Info link — placeholder, no action
          GestureDetector(
            onTap: () {}, // placeholder — no action for now
            child: Text(
              'تعرف على ترخيص الإعلان وعقد الوساطة',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.info,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
