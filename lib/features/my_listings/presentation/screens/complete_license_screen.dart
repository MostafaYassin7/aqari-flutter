import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/advertiser_types.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/parse_helpers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../add_listing/data/property_advertisement_license_repository.dart';
import '../../../../shared/utils/app_dialog.dart';
import '../providers/my_listings_provider.dart';

class CompleteLicenseScreen extends ConsumerStatefulWidget {
  final MyListing listing;
  const CompleteLicenseScreen({required this.listing, super.key});

  @override
  ConsumerState<CompleteLicenseScreen> createState() =>
      _CompleteLicenseScreenState();
}

class _CompleteLicenseScreenState
    extends ConsumerState<CompleteLicenseScreen> {
  String _advertiserType = AdvertiserType.owner;
  String _ownershipDocumentType = OwnershipDocumentType.electronicDeed;
  String _propertyOwnerIdType = PropertyOwnerIdType.nationalId;
  bool _isHijriCalendar = true;
  bool _isLoading = false;

  final Map<String, String?> _errors = {};

  final _ownershipDocNumCtrl = TextEditingController();
  final _ownerIdNumCtrl      = TextEditingController();
  final _ownerBirthDateCtrl  = TextEditingController();
  final _oneOfOwnersCtrl     = TextEditingController();
  final _powerOfAttorneyCtrl = TextEditingController();
  final _agentIdNumCtrl      = TextEditingController();
  final _agentBirthDateCtrl  = TextEditingController();

  String _ownerPhone = '';
  String _agentPhone = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phone = ref.read(authProvider).user?.phone ?? '';
      if (phone.isNotEmpty) {
        setState(() {
          _ownerPhone = phone;
          _agentPhone = phone;
        });
      }
    });
  }

  @override
  void dispose() {
    _ownershipDocNumCtrl.dispose();
    _ownerIdNumCtrl.dispose();
    _ownerBirthDateCtrl.dispose();
    _oneOfOwnersCtrl.dispose();
    _powerOfAttorneyCtrl.dispose();
    _agentIdNumCtrl.dispose();
    _agentBirthDateCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final errs = <String, String?>{};

    if (_ownershipDocNumCtrl.text.isEmpty) {
      errs['ownershipDocumentNumber'] = 'هذا الحقل مطلوب';
    }

    if (_propertyOwnerIdType == PropertyOwnerIdType.nationalId) {
      if (_ownerIdNumCtrl.text.isEmpty) {
        errs['ownerNationalIdNumber'] = 'هذا الحقل مطلوب';
      }
      if (_ownerBirthDateCtrl.text.isEmpty) {
        errs['propertyOwnerBirthDate'] = 'هذا الحقل مطلوب';
      }
    } else if (_propertyOwnerIdType ==
        PropertyOwnerIdType.commercialRegistration) {
      if (_ownerIdNumCtrl.text.isEmpty) {
        errs['ownerCommercialRegNumber'] = 'هذا الحقل مطلوب';
      }
    } else {
      if (_ownerIdNumCtrl.text.isEmpty) {
        errs['ownerUnifiedNumber'] = 'هذا الحقل مطلوب';
      }
    }

    if (_advertiserType == AdvertiserType.agent) {
      if (_powerOfAttorneyCtrl.text.isEmpty) {
        errs['powerOfAttorneyNumber'] = 'هذا الحقل مطلوب';
      }
      if (_agentIdNumCtrl.text.isEmpty) {
        errs['agentNationalIdNumber'] = 'هذا الحقل مطلوب';
      }
      if (_agentBirthDateCtrl.text.isEmpty) {
        errs['agentBirthDate'] = 'هذا الحقل مطلوب';
      }
    }

    setState(() => _errors.addAll(errs));
    return errs.isEmpty;
  }

  String? _toIsoDate(String text) {
    if (text.isEmpty) return null;
    final parts = text.split('/');
    if (parts.length != 3) return text;
    return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
  }

  Future<void> _onSubmit() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);
    try {
      final body = ParseHelpers.buildBody({
        'listingId': widget.listing.id,
        'advertiserType': _advertiserType,
        'ownershipDocumentType': _ownershipDocumentType,
        'ownershipDocumentNumber': _ownershipDocNumCtrl.text.isEmpty
            ? null
            : _ownershipDocNumCtrl.text,
        'propertyOwnerIdType': _propertyOwnerIdType,
        'ownerNationalIdNumber':
            _propertyOwnerIdType == PropertyOwnerIdType.nationalId
                ? (_ownerIdNumCtrl.text.isEmpty ? null : _ownerIdNumCtrl.text)
                : null,
        'ownerCommercialRegNumber':
            _propertyOwnerIdType == PropertyOwnerIdType.commercialRegistration
                ? (_ownerIdNumCtrl.text.isEmpty ? null : _ownerIdNumCtrl.text)
                : null,
        'ownerUnifiedNumber':
            _propertyOwnerIdType == PropertyOwnerIdType.unified700
                ? (_ownerIdNumCtrl.text.isEmpty ? null : _ownerIdNumCtrl.text)
                : null,
        'propertyOwnerBirthDate':
            _propertyOwnerIdType == PropertyOwnerIdType.nationalId
                ? _toIsoDate(_ownerBirthDateCtrl.text)
                : null,
        'isHijriCalendar': _isHijriCalendar,
        'propertyOwnerPhone': _ownerPhone.isEmpty ? null : _ownerPhone,
        'oneOfOwnersNationalId': _oneOfOwnersCtrl.text.isEmpty
            ? null
            : _oneOfOwnersCtrl.text,
        'powerOfAttorneyNumber': _advertiserType == AdvertiserType.agent
            ? (_powerOfAttorneyCtrl.text.isEmpty
                ? null
                : _powerOfAttorneyCtrl.text)
            : null,
        'agentNationalIdNumber': _advertiserType == AdvertiserType.agent
            ? (_agentIdNumCtrl.text.isEmpty ? null : _agentIdNumCtrl.text)
            : null,
        'agentBirthDate': _advertiserType == AdvertiserType.agent
            ? _toIsoDate(_agentBirthDateCtrl.text)
            : null,
        'agentPhone': _advertiserType == AdvertiserType.agent
            ? (_agentPhone.isEmpty ? null : _agentPhone)
            : null,
      });

      await PropertyAdvertisementLicenseRepository()
          .createOwnerAgentLicense(body);

      if (!mounted) return;
      await AppDialog.showInfo(
        context: context,
        title: 'تم إرسال بيانات الترخيص',
        message:
            'سيتم مراجعة بيانات الترخيص من قِبل فريقنا وسيتم نشر إعلانك فور الموافقة.',
        buttonText: 'حسناً',
      );
      if (!mounted) return;
      ref.invalidate(myListingsProvider);
      context.go(AppRoutes.myListings);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = (e.response?.data as Map?)?['message'] as String? ??
          e.message ??
          'حدث خطأ، يرجى المحاولة مجدداً';
      await AppDialog.showInfo(
        context: context,
        title: 'حدث خطأ',
        message: msg,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _ownerIdLabel(String idType) {
    switch (idType) {
      case PropertyOwnerIdType.commercialRegistration:
        return 'رقم السجل التجاري للمنشأة';
      case PropertyOwnerIdType.unified700:
        return 'الرقم الموحد 700 للمنشأة';
      default:
        return 'رقم الهوية الوطنية للمالك';
    }
  }

  String _ownerIdErrorKey(String idType) {
    switch (idType) {
      case PropertyOwnerIdType.commercialRegistration:
        return 'ownerCommercialRegNumber';
      case PropertyOwnerIdType.unified700:
        return 'ownerUnifiedNumber';
      default:
        return 'ownerNationalIdNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _advertiserType == AdvertiserType.owner;

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Directionality(
          textDirection: TextDirection.ltr,
          child: Platform.isIOS
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Icon(
                    CupertinoIcons.chevron_back,
                    color: AppColors.primary,
                    size: 28,
                  ),
                )
              : IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 20,
                    color: context.textPrimary,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
        ),
        title: Text(
          'إكمال بيانات الترخيص',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.divider),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // ── Role toggle: مالك / وكيل ──────────────────
                  _CLFieldLabel(label: 'أنت:', required: false),
                  const SizedBox(height: 8),
                  _CLTogglePills(
                    options: const [
                      _CLPillOption(label: 'مالك', value: AdvertiserType.owner),
                      _CLPillOption(
                          label: 'وكيل', value: AdvertiserType.agent),
                    ],
                    selected: _advertiserType,
                    onChanged: (v) => setState(() => _advertiserType = v),
                  ),

                  const SizedBox(height: 20),

                  // ── Ownership document type ───────────────────
                  _CLFieldLabel(
                    label: 'نوع الصك (وثيقة ملكية العقار)',
                    required: false,
                  ),
                  const SizedBox(height: 8),
                  _CLTogglePills(
                    options: const [
                      _CLPillOption(
                        label: 'صك إلكتروني / سجل عيني',
                        value: OwnershipDocumentType.electronicDeed,
                      ),
                      _CLPillOption(
                        label: 'غير ذلك',
                        value: OwnershipDocumentType.other,
                      ),
                    ],
                    selected: _ownershipDocumentType,
                    onChanged: (v) =>
                        setState(() => _ownershipDocumentType = v),
                  ),

                  const SizedBox(height: 20),

                  // ── Owner ID type ─────────────────────────────
                  _CLFieldLabel(label: 'نوع هوية المالك', required: true),
                  const SizedBox(height: 8),
                  _CLTogglePills(
                    options: const [
                      _CLPillOption(
                        label: 'هوية وطنية',
                        value: PropertyOwnerIdType.nationalId,
                      ),
                      _CLPillOption(
                        label: 'سجل تجاري',
                        value: PropertyOwnerIdType.commercialRegistration,
                      ),
                      _CLPillOption(
                        label: 'رقم موحد 700',
                        value: PropertyOwnerIdType.unified700,
                      ),
                    ],
                    selected: _propertyOwnerIdType,
                    onChanged: (v) {
                      setState(() {
                        _propertyOwnerIdType = v;
                        _errors.remove('ownerNationalIdNumber');
                        _errors.remove('ownerCommercialRegNumber');
                        _errors.remove('ownerUnifiedNumber');
                        _errors.remove('propertyOwnerBirthDate');
                      });
                      _ownerIdNumCtrl.clear();
                      _ownerBirthDateCtrl.clear();
                    },
                  ),

                  const SizedBox(height: 20),

                  // ── Ownership document number ──────────────────
                  _CLTextField(
                    label: 'رقم الصك أو رقم العقار أو رقم السجل العيني',
                    required: true,
                    controller: _ownershipDocNumCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    error: _errors['ownershipDocumentNumber'],
                    onChanged: (v) {
                      if (_errors.containsKey('ownershipDocumentNumber')) {
                        setState(
                            () => _errors.remove('ownershipDocumentNumber'));
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // ── Owner ID number ───────────────────────────
                  _CLTextField(
                    label: _ownerIdLabel(_propertyOwnerIdType),
                    required: true,
                    controller: _ownerIdNumCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    error: _errors[_ownerIdErrorKey(_propertyOwnerIdType)],
                    onChanged: (v) {
                      final key = _ownerIdErrorKey(_propertyOwnerIdType);
                      if (_errors.containsKey(key)) {
                        setState(() => _errors.remove(key));
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // ── Birth date (national_id only) ─────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _propertyOwnerIdType ==
                            PropertyOwnerIdType.nationalId
                        ? _CLBirthDateField(
                            key: const ValueKey('ownerBirthDate'),
                            label: 'تاريخ ميلاد المالك',
                            controller: _ownerBirthDateCtrl,
                            isHijri: _isHijriCalendar,
                            error: _errors['propertyOwnerBirthDate'],
                            onDateChanged: (v) {
                              if (_errors.containsKey('propertyOwnerBirthDate')) {
                                setState(() =>
                                    _errors.remove('propertyOwnerBirthDate'));
                              }
                            },
                            onHijriChanged: (v) =>
                                setState(() => _isHijriCalendar = v),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('noOwnerBirthDate')),
                  ),

                  const SizedBox(height: 16),

                  // ── Owner phone (read-only, مالك only) ────────
                  if (isOwner) ...[
                    _CLReadOnlyPhoneField(
                      label: 'رقم جوال المالك',
                      value: _ownerPhone,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── One of owners (optional) ──────────────────
                  _CLTextField(
                    label: 'رقم هوية أحد الملاك',
                    required: false,
                    hint: 'في حال وجود ملاك متعددين',
                    controller: _oneOfOwnersCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) {},
                  ),

                  // ── Agent-specific fields ─────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: !isOwner
                        ? Column(
                            key: const ValueKey('agentFields'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),
                              Divider(color: context.divider),
                              const SizedBox(height: 16),
                              _CLTextField(
                                label: 'رقم الوكالة الرسمية',
                                required: true,
                                hint: 'وكالة صادرة من وزارة العدل',
                                controller: _powerOfAttorneyCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                error: _errors['powerOfAttorneyNumber'],
                                onChanged: (v) {
                                  if (_errors
                                      .containsKey('powerOfAttorneyNumber')) {
                                    setState(() => _errors
                                        .remove('powerOfAttorneyNumber'));
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              _CLTextField(
                                label: 'رقم هوية الوكيل',
                                required: true,
                                controller: _agentIdNumCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                error: _errors['agentNationalIdNumber'],
                                onChanged: (v) {
                                  if (_errors
                                      .containsKey('agentNationalIdNumber')) {
                                    setState(() => _errors
                                        .remove('agentNationalIdNumber'));
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              _CLBirthDateField(
                                label: 'تاريخ ميلاد الوكيل',
                                controller: _agentBirthDateCtrl,
                                isHijri: _isHijriCalendar,
                                error: _errors['agentBirthDate'],
                                onDateChanged: (v) {
                                  if (_errors.containsKey('agentBirthDate')) {
                                    setState(
                                        () => _errors.remove('agentBirthDate'));
                                  }
                                },
                                onHijriChanged: (v) =>
                                    setState(() => _isHijriCalendar = v),
                              ),
                              const SizedBox(height: 16),
                              _CLReadOnlyPhoneField(
                                label: 'رقم جوال الوكيل',
                                value: _agentPhone,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(key: ValueKey('noAgentFields')),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Submit button ─────────────────────────────────────
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
              onPressed: _isLoading ? null : _onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: context.divider,
                minimumSize:
                    const Size(double.infinity, AppConstants.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'استمرار',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _CLPillOption {
  final String label;
  final String value;
  const _CLPillOption({required this.label, required this.value});
}

class _CLTogglePills extends StatelessWidget {
  final List<_CLPillOption> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _CLTogglePills({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: options.map((opt) {
          final isSelected = selected == opt.value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(
                  right: options.first == opt ? 0 : 4,
                  left: options.last == opt ? 0 : 4,
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : context.card,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusS),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : context.divider,
                  ),
                ),
                child: Text(
                  opt.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected
                        ? AppColors.white
                        : context.textSecondary,
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
        }).toList(),
      );
}

class _CLFieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _CLFieldLabel({required this.label, required this.required});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (required)
            Text(
              ' *',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.error),
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

class _CLTextField extends StatelessWidget {
  final String label;
  final bool required;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? error;
  final ValueChanged<String> onChanged;

  const _CLTextField({
    required this.label,
    required this.required,
    this.hint,
    required this.controller,
    required this.keyboardType,
    this.inputFormatters,
    this.error,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CLFieldLabel(label: label, required: required),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.bodySmall
                .copyWith(color: context.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodySmall
                  .copyWith(color: context.textHint),
              filled: true,
              fillColor: context.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(color: context.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(
                  color:
                      error != null ? AppColors.error : context.divider,
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

class _CLReadOnlyPhoneField extends StatelessWidget {
  final String label;
  final String value;
  const _CLReadOnlyPhoneField(
      {required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CLFieldLabel(label: label, required: false),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: context.divider,
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(color: context.divider),
            ),
            child: Text(
              value.isEmpty ? '—' : value,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
}

class _CLBirthDateField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool isHijri;
  final String? error;
  final ValueChanged<String> onDateChanged;
  final ValueChanged<bool> onHijriChanged;

  const _CLBirthDateField({
    super.key,
    required this.label,
    required this.controller,
    required this.isHijri,
    this.error,
    required this.onDateChanged,
    required this.onHijriChanged,
  });

  @override
  State<_CLBirthDateField> createState() => _CLBirthDateFieldState();
}

class _CLBirthDateFieldState extends State<_CLBirthDateField> {
  DateTime _pickerDate = DateTime(1990, 1, 1);

  void _showDatePicker() {
    DateTime tempDate = _pickerDate;
    final isDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoTheme(
        data: CupertinoThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light),
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color:
                isDark ? const Color(0xFF2C2C2E) : AppColors.white,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                            color: CupertinoColors.systemGrey),
                      ),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final formatted =
                            '${tempDate.day.toString().padLeft(2, '0')}/'
                            '${tempDate.month.toString().padLeft(2, '0')}/'
                            '${tempDate.year}';
                        widget.controller.text = formatted;
                        widget.onDateChanged(formatted);
                        setState(() => _pickerDate = tempDate);
                      },
                      child: const Text(
                        'تم',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _pickerDate,
                  maximumDate: DateTime.now(),
                  minimumDate: DateTime(1900),
                  onDateTimeChanged: (date) {
                    tempDate = date;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelRow() => Row(
        children: [
          GestureDetector(
            onTap: () => widget.onHijriChanged(!widget.isHijri),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'هجري',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: context.textPrimary),
                ),
                const SizedBox(width: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: widget.isHijri
                        ? AppColors.primary
                        : context.card,
                    borderRadius: BorderRadius.circular(
                        AppConstants.radiusS / 2),
                    border: Border.all(
                      color: widget.isHijri
                          ? AppColors.primary
                          : context.divider,
                      width: 1.5,
                    ),
                  ),
                  child: widget.isHijri
                      ? const Icon(Icons.check,
                          size: 14, color: AppColors.white)
                      : null,
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ' *',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.error),
              ),
              Text(
                widget.label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabelRow(),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _showDatePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(
                  color: widget.error != null
                      ? AppColors.error
                      : context.divider,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(CupertinoIcons.calendar,
                      size: 18, color: context.textHint),
                  Expanded(
                    child: Text(
                      widget.controller.text.isEmpty
                          ? (widget.isHijri
                              ? 'يوم/شهر/سنة (هجري)'
                              : 'يوم/شهر/سنة (ميلادي)')
                          : widget.controller.text,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: widget.controller.text.isEmpty
                            ? context.textHint
                            : context.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.error!,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.error),
              textAlign: TextAlign.right,
            ),
          ],
        ],
      );
    }

    // Android: text input with DD/MM/YYYY auto-formatter
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabelRow(),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CLDateInputFormatter(),
          ],
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.bodySmall
              .copyWith(color: context.textPrimary),
          decoration: InputDecoration(
            hintText: widget.isHijri
                ? 'يوم/شهر/سنة (هجري)'
                : 'يوم/شهر/سنة (ميلادي)',
            hintStyle: AppTextStyles.bodySmall
                .copyWith(color: context.textHint),
            filled: true,
            fillColor: context.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusM),
              borderSide: BorderSide(color: context.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusM),
              borderSide: BorderSide(
                color: widget.error != null
                    ? AppColors.error
                    : context.divider,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusM),
              borderSide: BorderSide(
                color: widget.error != null
                    ? AppColors.error
                    : AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
          onChanged: widget.onDateChanged,
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.error!,
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.error),
            textAlign: TextAlign.right,
          ),
        ],
      ],
    );
  }
}

class _CLDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length > 8) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
