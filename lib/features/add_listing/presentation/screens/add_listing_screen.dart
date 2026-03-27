import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/add_listing_provider.dart';
import '../steps/step1_category.dart';
import '../steps/step2_media.dart';
import '../steps/step3_info.dart';
import '../steps/step4_features.dart';
import '../steps/step5_details.dart';
import '../steps/step6_location.dart';
import '../steps/step7_review.dart';

class AddListingScreen extends ConsumerStatefulWidget {
  const AddListingScreen({super.key});

  @override
  ConsumerState<AddListingScreen> createState() =>
      _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  static const int _totalSteps = 7;

  static const _stepLabels = [
    'النوع',
    'الصور',
    'المعلومات',
    'المميزات',
    'التفاصيل',
    'الموقع',
    'المراجعة',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      _goToStep(_currentStep + 1);
    } else {
      _publish();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  bool _canProceed(AddListingState s) {
    switch (_currentStep) {
      case 0:
        return s.category != null;
      case 1:
        return s.photos.isNotEmpty;
      case 2:
        return s.price.isNotEmpty &&
            s.area.isNotEmpty &&
            s.description.isNotEmpty;
      case 3:
        return s.features.isNotEmpty;
      case 4:
        return true;
      case 5:
        return s.address.isNotEmpty;
      case 6:
        return true;
      default:
        return true;
    }
  }

  void _publish() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'تم نشر إعلانك!',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم مراجعة إعلانك وظهوره خلال 24 ساعة.',
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              ref.read(addListingProvider.notifier).reset();
              Navigator.of(context).pop();
              context.go(AppRoutes.home);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(160, 44),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusM)),
            ),
            child: Text('الرئيسية',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch so bottom bar reactively rebuilds when form state changes
    final formState = ref.watch(addListingProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────
            _TopBar(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              stepLabels: _stepLabels,
              onBack: _back,
            ),

            // ── Step pages ───────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  const Step1Category(),
                  const Step2Media(),
                  const Step3Info(),
                  const Step4Features(),
                  const Step5Details(),
                  const Step6Location(),
                  Step7Review(onEdit: _goToStep),
                ],
              ),
            ),

            // ── Bottom action bar ─────────────────────────────
            _BottomBar(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              canProceed: _canProceed(formState),
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar with progress ─────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final VoidCallback onBack;

  const _TopBar({
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep + 1) / totalSteps;

    return Column(
      children: [
        // Icon + step label row
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    size: 20, color: AppColors.textPrimaryLight),
                onPressed: onBack,
              ),
              Expanded(
                child: Text(
                  stepLabels[currentStep],
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
              Text(
                '${currentStep + 1} / $totalSteps',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceM),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(AppConstants.radiusCircle),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.dividerLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary),
            ),
          ),
        ),

        // Step dots
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            7,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == currentStep ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i <= currentStep
                    ? AppColors.primary
                    : AppColors.dividerLight,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusCircle),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.dividerLight),
      ],
    );
  }
}

// ── Bottom action bar ─────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool canProceed;
  final VoidCallback onNext;

  const _BottomBar({
    required this.currentStep,
    required this.totalSteps,
    required this.canProceed,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == totalSteps - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spaceM,
        AppConstants.spaceS,
        AppConstants.spaceM,
        AppConstants.spaceS + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        border:
            Border(top: BorderSide(color: AppColors.dividerLight)),
      ),
      child: ElevatedButton(
        onPressed: canProceed ? onNext : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.dividerLight,
          minimumSize:
              const Size(double.infinity, AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          elevation: 0,
        ),
        child: Text(
          isLastStep ? 'نشر الإعلان' : 'التالي',
          style: AppTextStyles.bodyLarge.copyWith(
            color: canProceed
                ? AppColors.white
                : AppColors.textSecondaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
