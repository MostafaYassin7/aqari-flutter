import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/add_listing_provider.dart';
import '../steps/step0_role_service.dart';
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
  bool _isPublishing = false;

  static const int _totalSteps = 8;

  static const _stepLabels = [
    'إضافة إعلان',
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
    if (_currentStep == 0) {
      final service = ref.read(addListingProvider).selectedService;
      if (service == 'marketing_request') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ميزة طلب التسويق قادمة قريباً',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            ),
            backgroundColor: AppColors.textPrimaryLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
          ),
        );
        return;
      }
    }
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
        return true; // role & service always have defaults
      case 1:
        return s.category != null;
      case 2:
        return s.photos.isNotEmpty;
      case 3:
        return s.price.isNotEmpty &&
            s.area.isNotEmpty &&
            s.description.isNotEmpty;
      case 4:
        return s.features.isNotEmpty;
      case 5:
        return true;
      case 6:
        return s.address.isNotEmpty;
      case 7:
        return true;
      default:
        return true;
    }
  }

  Future<void> _publish() async {
    if (_isPublishing) return;
    setState(() => _isPublishing = true);

    final s = ref.read(addListingProvider);

    try {
      // 1. Upload local photos → get back server URLs
      final List<String> uploadedUrls = [];
      final localPaths = s.photos.where((p) => p.startsWith('/')).toList();
      final existingUrls = s.photos.where((p) => !p.startsWith('/')).toList();

      if (localPaths.isNotEmpty) {
        final formData = FormData.fromMap({
          'files': await Future.wait(
            localPaths.map((path) async => await MultipartFile.fromFile(
                  path,
                  filename: path.split('/').last,
                )),
          ),
        });
        final uploadRes = await apiClient.post(
          ApiEndpoints.mediaUpload,
          data: formData,
        );
        final urls = (uploadRes.data as List).map((e) => e.toString()).toList();
        uploadedUrls.addAll(urls);
      }

      final allPhotoUrls = [...existingUrls, ...uploadedUrls];

      // 2. Create the listing
      await apiClient.post(ApiEndpoints.listings, data: {
        'categoryId': s.category,
        'photos': allPhotoUrls,
        'price': double.tryParse(s.price) ?? 0,
        'area': double.tryParse(s.area) ?? 0,
        'isResidential': s.isResidential,
        'hasCommission': s.hasCommission,
        'commissionPercent': double.tryParse(s.commissionPercent) ?? 0,
        'description': s.description,
        'features': s.features.toList(),
        'bedrooms': s.bedrooms,
        'livingRooms': s.livingRooms,
        'bathrooms': s.bathrooms,
        if (s.facade != null) 'facade': s.facade,
        if (s.streetWidth.isNotEmpty) 'streetWidth': double.tryParse(s.streetWidth),
        if (s.floorNumber.isNotEmpty) 'floorNumber': int.tryParse(s.floorNumber),
        if (s.propertyAge.isNotEmpty) 'propertyAge': int.tryParse(s.propertyAge),
        'isFurnished': s.isFurnished,
        'hasKitchen': s.hasKitchen,
        'hasExtraUnit': s.hasExtraUnit,
        'hasCarEntrance': s.hasCarEntrance,
        'hasElevator': s.hasElevator,
        'address': s.address,
        'location': {'lat': s.lat, 'lng': s.lng},
        'role': s.selectedRole,
      });

      if (!mounted) return;
      _showSuccessDialog();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'حدث خطأ، يرجى المحاولة مجدداً'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
              onForward: _currentStep == 0 ? _next : null,
            ),

            // ── Step pages ───────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  const Step0RoleService(),
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
              canProceed: _canProceed(formState) && !_isPublishing,
              isPublishing: _isPublishing,
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
  final VoidCallback? onForward;

  const _TopBar({
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    required this.onBack,
    this.onForward,
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
              if (onForward != null)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 20, color: AppColors.textPrimaryLight),
                  onPressed: onForward,
                )
              else
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
            totalSteps,
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
  final bool isPublishing;
  final VoidCallback onNext;

  const _BottomBar({
    required this.currentStep,
    required this.totalSteps,
    required this.canProceed,
    required this.isPublishing,
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
        child: isPublishing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.white,
                ),
              )
            : Text(
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
