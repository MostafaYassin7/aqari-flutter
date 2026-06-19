import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/advertiser_types.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/parse_helpers.dart';
import '../providers/add_listing_provider.dart';
import '../steps/step0_role_service.dart';
import '../steps/step0a_owner_info_screen.dart';
import '../steps/step0b_owner_license_form.dart';
import '../steps/step0c_broker_license_form.dart';
import '../steps/step1_category.dart';
import '../steps/step2_media.dart';
import '../steps/step3_info.dart';
import '../steps/step4_features.dart';
import '../steps/step5_details.dart';
import '../steps/step6_location.dart';
import '../steps/step7_review.dart';
import '../../data/property_advertisement_license_repository.dart';

class AddListingScreen extends ConsumerStatefulWidget {
  const AddListingScreen({super.key});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isPublishing = false;

  // ── Step list helpers ─────────────────────────────────────────────────────

  // Number of license-specific steps prepended before the 7 listing steps.
  // This offset is used by _canProceed and _isLicenseStep.
  int _licenseOffset(String advertiserType) {
    if (advertiserType == AdvertiserType.owner ||
        advertiserType == AdvertiserType.agent) {
      return 2; // step0a + step0b
    }
    if (advertiserType == AdvertiserType.broker) {
      return 1; // step0c
    }
    return 0; // host — no license screens
  }

  // Total step count for the given role:
  //   1 (role/service) + licenseOffset + 7 (category → review)
  int _totalSteps(String advertiserType) =>
      1 + _licenseOffset(advertiserType) + 7;

  // Step labels array — length must equal _totalSteps
  List<String> _stepLabels(String advertiserType) {
    const listingLabels = [
      'النوع',
      'الصور',
      'المعلومات',
      'المميزات',
      'التفاصيل',
      'الموقع',
      'المراجعة',
    ];
    if (advertiserType == AdvertiserType.owner ||
        advertiserType == AdvertiserType.agent) {
      return [
        'إضافة إعلان',
        'نشر وترخيص الإعلان',
        'معلومات الترخيص',
        ...listingLabels,
      ];
    }
    if (advertiserType == AdvertiserType.broker) {
      return ['إضافة إعلان', 'معلومات الترخيص', ...listingLabels];
    }
    // host
    return ['إضافة إعلان', ...listingLabels];
  }

  // Builds the step widget list based on current advertiserType.
  // Step 0 (role/service) is always first.
  // License steps come next (none for host).
  // Then the 8 listing steps (category → review).
  List<Widget> _buildSteps(String advertiserType) {
    final isOwnerOrAgent = advertiserType == AdvertiserType.owner ||
        advertiserType == AdvertiserType.agent;

    final listingSteps = <Widget>[
      const Step1Category(),
      const Step2Media(),
      const Step3Info(),
      const Step4Features(),
      const Step5Details(),
      const Step6Location(),
      Step7Review(onEdit: _goToStep),
    ];

    if (isOwnerOrAgent) {
      return [
        const Step0RoleService(),
        Step0aOwnerInfoScreen(onNext: _next),   // step0a: info/explanation
        Step0bOwnerLicenseForm(onNext: _next),  // step0b: owner/agent license form
        ...listingSteps,
      ];
    }

    if (advertiserType == AdvertiserType.broker) {
      return [
        const Step0RoleService(),
        Step0cBrokerLicenseForm(onNext: _next), // step0c: broker license form
        ...listingSteps,
      ];
    }

    // host — no license screens
    return [const Step0RoleService(), ...listingSteps];
  }

  // Returns true when the current step is a license step that manages
  // its own bottom buttons (so the shared _BottomBar should be hidden)
  bool _isLicenseStep(String advertiserType) {
    final offset = _licenseOffset(advertiserType);
    if (offset == 0) return false;
    // Step indices 1..offset are the license steps
    return _currentStep >= 1 && _currentStep <= offset;
  }

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
    // Gate: "طلب تسويق" is not yet supported — show coming soon
    if (_currentStep == 0) {
      final service = ref.read(addListingProvider).selectedService;
      if (service == 'marketing_request') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ميزة طلب التسويق قادمة قريباً',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.white),
            ),
            backgroundColor: AppColors.textPrimaryLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusM),
            ),
          ),
        );
        return;
      }
    }

    final role = ref.read(addListingProvider).advertiserType;
    final total = _totalSteps(role);

    if (_currentStep < total - 1) {
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
    if (_currentStep == 0) return true;
    // Listing steps are at absolute index (1 + offset) .. (total - 1)
    // Map them to logical index 1..8 matching original step logic
    final idx = _currentStep - _licenseOffset(s.advertiserType);
    switch (idx) {
      case 1:
        return s.category != null;
      case 2:
        return s.photos.isNotEmpty;
      case 3:
        return s.title.isNotEmpty &&
            s.price.isNotEmpty &&
            s.area.isNotEmpty &&
            s.description.isNotEmpty;
      case 4:
        return s.features.isNotEmpty;
      case 5:
        return true;
      case 6:
        return s.city.isNotEmpty;
      case 7:
        return true;
      default:
        return true;
    }
  }

  // ── Publish logic ─────────────────────────────────────────────────────────

  Future<void> _publish() async {
    if (_isPublishing) return;
    setState(() => _isPublishing = true);

    final s = ref.read(addListingProvider);

    try {
      // Upload local photos first (shared across all cases)
      final allPhotoUrls = await _uploadPhotos(s.photos);

      if (s.advertiserType == AdvertiserType.host) {
        // ── CASE 1: مضيف — no license required ────────────────
        // POST /listings directly; backend sets status = PUBLISHED
        await _createListing(s, allPhotoUrls, licenseId: null);
        if (!mounted) return;
        _showSuccessDialog();
      } else if (s.skipLicenseInfo) {
        // ── CASE 4: إدخال البيانات لاحقاً ─────────────────────
        // POST /listings without licenseId; backend sets status = DRAFT
        await _createListing(s, allPhotoUrls, licenseId: null);
        if (!mounted) return;
        _showDraftMessage();
      } else if (s.advertiserType == AdvertiserType.owner ||
          s.advertiserType == AdvertiserType.agent) {
        // ── CASE 2: مالك أو وكيل — create license then listing ─
        final licenseBody = ParseHelpers.buildBody({
          'advertiserType': s.advertiserType,
          'ownershipDocumentType': s.ownershipDocumentType,
          'ownershipDocumentNumber': s.ownershipDocumentNumber,
          'propertyOwnerIdType': s.propertyOwnerIdType,
          'propertyOwnerIdNumber': s.propertyOwnerIdNumber,
          'propertyOwnerBirthDate': s.propertyOwnerBirthDate,
          'isHijriCalendar': s.isHijriCalendar,
          'propertyOwnerPhone': s.propertyOwnerPhone,
          'oneOfOwnersNationalId': s.oneOfOwnersNationalId,
          'establishmentCommercialRegNumber':
              s.establishmentCommercialRegNumber,
          // Agent-only fields — null for owner, stripped by buildBody
          'powerOfAttorneyNumber': s.powerOfAttorneyNumber,
          'agentNationalIdNumber': s.agentNationalIdNumber,
          'agentBirthDate': s.agentBirthDate,
          'agentPhone': s.agentPhone,
        });

        final licenseId = await PropertyAdvertisementLicenseRepository()
            .createLicense(licenseBody);

        await _createListing(s, allPhotoUrls, licenseId: licenseId);
        if (!mounted) return;
        _showPendingDialog();
      } else if (s.advertiserType == AdvertiserType.broker) {
        // ── CASE 3: مسوق عقاري — broker license then listing ───
        final licenseBody = ParseHelpers.buildBody({
          'advertiserType': AdvertiserType.broker,
          'falLicenseNumber': s.falLicenseNumber,
          'brokerageContractNumber': s.brokerageContractNumber,
          'propertyOwnerIdType': s.propertyOwnerIdType,
          'propertyOwnerIdNumber': s.propertyOwnerIdNumber,
        });

        final licenseId = await PropertyAdvertisementLicenseRepository()
            .createLicense(licenseBody);

        await _createListing(s, allPhotoUrls, licenseId: licenseId);
        if (!mounted) return;
        _showPendingDialog();
      }
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

  // Uploads any local file paths to GCP and returns all final CDN URLs
  Future<List<String>> _uploadPhotos(List<String> photos) async {
    final localPaths = photos
        .where((p) => p.startsWith('/') || p.startsWith('file://'))
        .toList();
    final existingUrls = photos
        .where((p) => !p.startsWith('/') && !p.startsWith('file://'))
        .toList();

    if (localPaths.isEmpty) return existingUrls;

    final formData = FormData.fromMap({
      'files': await Future.wait(
        localPaths.map(
          (path) async => MultipartFile.fromFile(
            path,
            filename: path.split('/').last,
          ),
        ),
      ),
    });

    final uploadRes = await apiClient.post(
      ApiEndpoints.mediaUpload,
      data: formData,
      queryParameters: {'folder': 'listings'},
    );

    final urls = ((uploadRes.data as Map)['urls'] as List)
        .map((e) => e.toString())
        .toList();

    return [...existingUrls, ...urls];
  }

  // Builds and sends POST /listings with listing fields + optional licenseId
  Future<void> _createListing(
    AddListingState s,
    List<String> photoUrls, {
    required String? licenseId,
  }) async {
    bool hasFeature(String name) => s.features.contains(name);

    await apiClient.post(ApiEndpoints.listings, data: {
      'title': s.title,
      'categoryId': s.categoryId,
      'propertyType': s.propertyType,
      'listingType': s.listingType,
      'mediaUrls': photoUrls,
      'totalPrice': double.tryParse(s.price) ?? 0,
      'area': double.tryParse(s.area) ?? 0,
      'usageType': s.isResidential ? 'residential' : 'commercial',
      'commission': s.hasCommission,
      if (s.hasCommission && s.commissionPercent.isNotEmpty)
        'commissionPercent': double.tryParse(s.commissionPercent) ?? 0,
      'description': s.description,
      'bedrooms': s.bedrooms,
      'livingRooms': s.livingRooms,
      'bathrooms': s.bathrooms,
      if (s.facade != null) 'facade': s.facade,
      if (s.streetWidth.isNotEmpty)
        'streetWidth': double.tryParse(s.streetWidth),
      if (s.floorNumber.isNotEmpty) 'floor': int.tryParse(s.floorNumber),
      if (s.propertyAge.isNotEmpty)
        'propertyAge': int.tryParse(s.propertyAge),
      'isFurnished': s.isFurnished,
      'hasKitchen': s.hasKitchen || hasFeature('مطبخ راكب'),
      'hasExtraUnit': s.hasExtraUnit || hasFeature('غرفة سائق'),
      'hasCarEntrance': s.hasCarEntrance || hasFeature('موقف سيارة'),
      'hasElevator': s.hasElevator,
      'hasWater': hasFeature('ماء'),
      'hasElectricity': hasFeature('كهرباء'),
      'hasSewage': hasFeature('صرف صحي'),
      'hasPrivateRoof': hasFeature('سطح خاص'),
      'isInVilla': hasFeature('داخل فيلا'),
      'hasTwoEntrances': hasFeature('مدخلين'),
      'hasSpecialEntrance': hasFeature('مدخل خاص'),
      'city': s.city,
      if (s.district.isNotEmpty) 'district': s.district,
      'latitude': s.lat,
      'longitude': s.lng,
      if (s.address.isNotEmpty) 'address': s.address,
      // licenseId is null for host and skipLicenseInfo cases — omitted by if
      if (licenseId != null) 'licenseId': licenseId,
    });
  }

  // ── Result dialogs ────────────────────────────────────────────────────────

  // Case 1 (host): listing published immediately
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
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondaryLight),
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
                    color: AppColors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // Cases 2 & 3 (owner / agent / broker): license pending admin review
  void _showPendingDialog() {
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
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.access_time_rounded,
                  color: AppColors.warning, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'تم إرسال طلبك',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 8),
            Text(
              'تم حفظ إعلانك وسيتم مراجعة بيانات الترخيص من قِبل فريقنا.\nسيتم نشر إعلانك فور الموافقة على الترخيص.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondaryLight),
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
              context.go(AppRoutes.myListings);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(160, 44),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusM)),
            ),
            child: Text('حسناً',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // Case 4 (skipLicenseInfo): listing saved as DRAFT
  void _showDraftMessage() {
    ref.read(addListingProvider.notifier).reset();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم حفظ إعلانك كمسودة. أكمل بيانات الترخيص من صفحة إعلاناتي لنشر إعلانك.',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.textPrimaryLight,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
      ),
    );
    context.go(AppRoutes.myListings);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(addListingProvider);
    final advertiserType = formState.advertiserType;

    // When role changes, reset page controller to step 0
    ref.listen<String>(
      addListingProvider.select((s) => s.advertiserType),
      (prev, next) {
        if (prev != next) {
          setState(() => _currentStep = 0);
          _pageController.jumpToPage(0);
        }
      },
    );

    final steps     = _buildSteps(advertiserType);
    final labels    = _stepLabels(advertiserType);
    final total     = steps.length;
    final isLicense = _isLicenseStep(advertiserType);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────
            _TopBar(
              currentStep: _currentStep,
              totalSteps: total,
              stepLabels: labels,
              onBack: _back,
              onForward: _currentStep == 0 ? _next : null,
            ),

            // ── Step pages ───────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: steps,
              ),
            ),

            // ── Bottom action bar ─────────────────────────────
            // Hidden for license steps — those screens manage their own buttons
            if (!isLicense)
              _BottomBar(
                currentStep: _currentStep,
                totalSteps: total,
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
    final label = currentStep < stepLabels.length
        ? stepLabels[currentStep]
        : '';

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
                  label,
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
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
        border: Border(top: BorderSide(color: AppColors.dividerLight)),
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
