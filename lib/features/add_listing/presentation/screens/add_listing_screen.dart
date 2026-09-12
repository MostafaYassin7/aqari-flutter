import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_failure.dart';
import '../../data/add_listing_repository.dart';
import '../../domain/listing_payload.dart';
import '../../../my_listings/presentation/providers/my_listings_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/preview/ui_preview.dart';
import '../providers/add_listing_provider.dart';
import '../listing_ui_rules.dart';
import '../widgets/listing_flow_steps.dart';
import '../steps/step1_category.dart';
import '../steps/step5_details.dart';
import '../steps/step7_review.dart';
import '../steps/step2_media.dart';
import '../steps/step3_info.dart';
import '../steps/step4_features.dart';
import '../steps/step6_location.dart';

class AddListingScreen extends ConsumerStatefulWidget {
  final String? preset;
  const AddListingScreen({super.key, this.preset});
  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  String _step = 'role';
  String? _error;
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final n = ref.read(addListingProvider.notifier);
      if (ref.read(addListingProvider).propertyType.isNotEmpty) return;
      if (widget.preset == 'event_hall') {
        if (uiPreview) {
          n.selectType('event_hall', 'rent_short', 'قاعة مناسبات');
        } else {
          await _loadPreset();
        }
      }
      if (widget.preset == 'daily') n.selectType('', 'rent_short', '');
    });
  }

  bool _presetPending = false;
  bool _uncertain = false;
  Future<void> _loadPreset() async {
    setState(() => _presetPending = true);
    try {
      final categories = await ref.read(listingCategoriesProvider.future);
      final matches = categories
          .where(
            (c) =>
                c.isActive &&
                c.propertyType == 'event_hall' &&
                c.listingType == 'rent_short',
          )
          .toList();
      if (matches.length != 1) {
        throw const ApiFailure('فئة قاعات المناسبات غير متاحة. أعد المحاولة.');
      }
      if (!mounted) return;
      final c = matches.single;
      ref
          .read(addListingProvider.notifier)
          .selectType(
            c.propertyType,
            c.listingType,
            c.nameAr,
            categoryId: c.id,
          );
      setState(() {
        _presetPending = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = ApiFailure.fromError(e).message);
    }
  }

  Future<void> _prepareLicense(AddListingState s) async {
    if (s.value('licenseId').isNotEmpty ||
        ((s.role == 'owner' || s.role == 'agent') &&
            s.value('skipLicense') == 'true')) {
      return;
    }
    final id = await ref.read(addListingRepositoryProvider).prepareLicense(s);
    if (mounted) ref.read(addListingProvider.notifier).field('licenseId', id);
  }

  Future<void> _submit(AddListingState s) async {
    if (_checking || _uncertain) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final categories = await ref.read(listingCategoriesProvider.future);
      if (!categories.any(
        (c) =>
            c.id == s.categoryId &&
            c.isActive &&
            c.propertyType == s.propertyType &&
            c.listingType == s.listingType,
      )) {
        throw const ApiFailure('اختر فئة متاحة من القائمة.', {
          'categoryId': 'الفئة غير متاحة',
        });
      }
      if (s.rules.isEventHall && !ref.read(eventHallCreationEnabledProvider)) {
        throw const ApiFailure(
          'إضافة القاعات غير متاحة حتى اكتمال التحقق من الخدمة.',
        );
      }
      await _prepareLicense(s);
      if (!mounted) return;
      final current = ref.read(addListingProvider);
      final result = await ref
          .read(addListingRepositoryProvider)
          .create(listingPayload(current));
      if (!mounted) return;
      ref.invalidate(myListingsProvider);
      final status = result['status'];
      await previewResult(
        context,
        status == 'draft'
            ? 'تم حفظ المسودة'
            : status == 'pending'
            ? 'تم إرسال الإعلان للمراجعة'
            : 'تم إنشاء الإعلان',
        status == 'draft'
            ? 'يمكنك استكمال بيانات الترخيص من إعلاناتك.'
            : status == 'pending'
            ? 'سيظهر الإعلان بعد الموافقة عليه.'
            : 'تم حفظ الإعلان على الخادم.',
      );
      if (!mounted) return;
      ref.read(addListingProvider.notifier).reset();
      Navigator.of(context).pop();
    } catch (e) {
      final failure = ApiFailure.fromError(e);
      if (!mounted) return;
      setState(() {
        _uncertain = failure.mayHaveCommitted;
        _error =
            failure.message +
            (_uncertain
                ? '\nتحقق من إعلاناتك وطلبات الترخيص قبل إعادة الإرسال؛ قد يكون الطلب حُفظ.'
                : '');
        if (failure.fieldErrors.isNotEmpty) {
          _step = _stepForServerField(failure.fieldErrors.keys.first, s);
          _error = failure.fieldErrors.values.join('\n');
        }
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  String _stepForServerField(String field, AddListingState s) {
    if ({'categoryId', 'propertyType', 'listingType'}.contains(field)) {
      return 'category';
    }
    if (field == 'mediaUrls') return 'media';
    if ({
      'title',
      'totalPrice',
      'area',
      'description',
      'commissionPercent',
    }.contains(field)) {
      return 'info';
    }
    if ({
      'city',
      'district',
      'address',
      'latitude',
      'longitude',
    }.contains(field)) {
      return 'location';
    }
    if (s.rules.bookingFields.contains(field)) return 'booking';
    if (s.rules.detailFields.contains(field)) return 'details';
    if (s.rules.featureFields.contains(field)) return 'features';
    return 'license';
  }

  void _go(String step) => setState(() {
    _step = step;
    _error = null;
  });
  bool _checking = false;
  String _licenseScenario = 'valid';
  Future<void> _next(AddListingState s) async {
    if (_checking || _presetPending || _uncertain) return;
    final errors = listingStepErrors(s, _step);
    if (errors.isNotEmpty) {
      setState(() => _error = errors.values.join('\n'));
      return;
    }
    if (_step == 'review') {
      for (final step in s.steps.where((x) => x != 'review')) {
        final checks = listingStepErrors(s, step);
        if (checks.isNotEmpty) {
          _go(step);
          setState(() => _error = checks.values.join('\n'));
          return;
        }
      }
      if (!uiPreview) {
        await _submit(s);
        return;
      }
      final title = (s.role == 'owner' || s.role == 'agent')
          ? (s.value('skipLicense') == 'true'
                ? 'معاينة حفظ مسودة'
                : 'معاينة إرسال للمراجعة')
          : 'معاينة نشر الإعلان';
      await previewResult(
        context,
        title,
        'هذه معاينة فقط. لم يتم نشر إعلان أو إصدار ترخيص أو حفظ مسودة على الخادم.',
      );
      return;
    }
    if (_step == 'license' && (s.role == 'broker' || s.role == 'host')) {
      setState(() {
        _checking = true;
        _error = null;
      });
      if (!uiPreview) {
        try {
          await _prepareLicense(s);
        } catch (e) {
          if (mounted) {
            setState(() {
              _checking = false;
              _error = ApiFailure.fromError(e).message;
              _uncertain = ApiFailure.fromError(e).mayHaveCommitted;
            });
          }
          return;
        }
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      if (!mounted) return;
      setState(() => _checking = false);
      if (_licenseScenario != 'valid') {
        setState(
          () => _error = _licenseScenario == 'invalid'
              ? 'معاينة: رقم الترخيص غير صحيح أو منتهي الصلاحية'
              : 'معاينة: تعذر التحقق، يرجى المحاولة مجدداً',
        );
        return;
      }
    }
    _go(s.steps[s.steps.indexOf(_step) + 1]);
  }

  void _back(AddListingState s) {
    if (_checking) return;
    final i = s.steps.indexOf(_step);
    if (i <= 0) {
      Navigator.maybePop(context);
    } else {
      _go(s.steps[i - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(addListingProvider);
    final steps = s.steps;
    final current = steps.indexOf(_step);
    final page = switch (_step) {
      'category' => const Step1Category(),
      'details' => const Step5Details(key: ValueKey('details')),
      'booking' => const Step5Details(
        key: ValueKey('booking'),
        bookingSettings: true,
      ),
      'review' => Step7Review(onEdit: _go),
      'media' => const Step2Media(),
      'info' => const Step3Info(),
      'features' => const Step4Features(),
      'location' => const Step6Location(),
      _ => ListingFlowStep(_step, key: ValueKey(_step), onEdit: _go),
    };
    return PopScope(
      canPop: current == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back(s);
      },
      child: Scaffold(
        backgroundColor: context.appColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                currentStep: current,
                totalSteps: steps.length,
                stepLabels: steps.map((e) => listingStepLabels[e]!).toList(),
                onBack: () => _back(s),
              ),
              const PreviewNotice(),
              if (uiPreview &&
                  _step == 'license' &&
                  (s.role == 'broker' || s.role == 'host'))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    children:
                        {
                              'valid': 'معاينة القبول',
                              'invalid': 'غير صالح',
                              'error': 'تعذر التحقق',
                            }.entries
                            .map(
                              (e) => PreviewChoice(
                                e.value,
                                selected: _licenseScenario == e.key,
                                onTap: () =>
                                    setState(() => _licenseScenario = e.key),
                              ),
                            )
                            .toList(),
                  ),
                ),
              Expanded(
                child: AbsorbPointer(
                  absorbing: _checking || _presetPending,
                  child: page,
                ),
              ),
              if (_presetPending && _error != null)
                TextButton(
                  onPressed: () {
                    ref.invalidate(listingCategoriesProvider);
                    _loadPreset();
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              _BottomBar(
                currentStep: current,
                totalSteps: steps.length,
                canProceed:
                    !_checking &&
                    !_presetPending &&
                    !_uncertain &&
                    s.value('uploading') != 'true',
                onNext: () => _next(s),
              ),
            ],
          ),
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
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 20,
                  color: context.appColors.textPrimary,
                ),
                onPressed: onBack,
              ),
              Expanded(
                child: Text(
                  stepLabels[currentStep],
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${currentStep + 1} / $totalSteps',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: context.appColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
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
                    : context.appColors.divider,
                borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: context.appColors.divider),
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
      decoration: BoxDecoration(
        color: context.appColors.background,
        border: Border(top: BorderSide(color: context.appColors.divider)),
      ),
      child: ElevatedButton(
        onPressed: canProceed ? onNext : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: context.appColors.divider,
          minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          elevation: 0,
        ),
        child: Text(
          isLastStep
              ? (uiPreview ? 'معاينة النشر' : 'إرسال الإعلان')
              : 'التالي',
          style: AppTextStyles.bodyLarge.copyWith(
            color: canProceed
                ? AppColors.onPrimary
                : context.appColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
