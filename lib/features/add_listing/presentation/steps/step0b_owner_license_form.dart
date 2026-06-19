import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/advertiser_types.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'package:aqar_app/features/auth/presentation/providers/auth_provider.dart';
import '../providers/add_listing_provider.dart';

// ── Step 0b: معلومات الترخيص ──────────────────────────────────────────────────
//
// Dynamic license form for مالك (owner) and وكيل (agent).
// Fields shown change based on:
//   - advertiserType ('owner' vs 'agent')
//   - propertyOwnerIdType ('national_id' vs 'commercial_registration'/'unified_700')
//
// advertiserType is toggled at the top of this screen via مالك/وكيل pills.
// Used by: advertiserType = 'owner' or 'agent'

class Step0bOwnerLicenseForm extends ConsumerStatefulWidget {
  // Called when user taps "استمرار" and all required fields are valid
  final VoidCallback onNext;

  const Step0bOwnerLicenseForm({required this.onNext, super.key});

  @override
  ConsumerState<Step0bOwnerLicenseForm> createState() =>
      _Step0bOwnerLicenseFormState();
}

class _Step0bOwnerLicenseFormState
    extends ConsumerState<Step0bOwnerLicenseForm> {
  // Field error messages — keyed by field name, shown below the field in red
  final Map<String, String?> _errors = {};

  // Text controllers — pre-filled where needed
  final _ownershipDocNumCtrl    = TextEditingController();
  final _ownerIdNumCtrl         = TextEditingController();
  final _ownerBirthDateCtrl     = TextEditingController();
  final _commercialRegCtrl      = TextEditingController();
  final _oneOfOwnersCtrl        = TextEditingController();
  final _powerOfAttorneyCtrl    = TextEditingController();
  final _agentIdNumCtrl         = TextEditingController();
  final _agentBirthDateCtrl     = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill phone fields from logged-in user's profile — phone is read-only
    // so we only set it once if not already populated in provider state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(addListingProvider.notifier);
      final s = ref.read(addListingProvider);
      final userPhone = ref.read(authProvider).user?.phone ?? '';
      if (userPhone.isNotEmpty) {
        if (s.propertyOwnerPhone == null) {
          notifier.setLicenseField('propertyOwnerPhone', userPhone);
        }
        if (s.agentPhone == null) {
          notifier.setLicenseField('agentPhone', userPhone);
        }
      }
    });
  }

  @override
  void dispose() {
    _ownershipDocNumCtrl.dispose();
    _ownerIdNumCtrl.dispose();
    _ownerBirthDateCtrl.dispose();
    _commercialRegCtrl.dispose();
    _oneOfOwnersCtrl.dispose();
    _powerOfAttorneyCtrl.dispose();
    _agentIdNumCtrl.dispose();
    _agentBirthDateCtrl.dispose();
    super.dispose();
  }

  // Validates all required fields for the current advertiserType.
  // Returns true only when all required fields are non-empty.
  bool _validate(AddListingState s) {
    final errs = <String, String?>{};

    // Ownership document number — required for both owner and agent
    if (s.ownershipDocumentNumber == null ||
        s.ownershipDocumentNumber!.isEmpty) {
      errs['ownershipDocumentNumber'] = 'هذا الحقل مطلوب';
    }

    // Owner ID number — required for owner, agent, and broker
    if (s.propertyOwnerIdNumber == null || s.propertyOwnerIdNumber!.isEmpty) {
      errs['propertyOwnerIdNumber'] = 'هذا الحقل مطلوب';
    }

    // Birth date — only required when propertyOwnerIdType = 'national_id'
    if (s.propertyOwnerIdType == PropertyOwnerIdType.nationalId) {
      if (s.propertyOwnerBirthDate == null ||
          s.propertyOwnerBirthDate!.isEmpty) {
        errs['propertyOwnerBirthDate'] = 'هذا الحقل مطلوب';
      }
    }

    // Commercial registration — required when commercial entity
    if (s.propertyOwnerIdType == PropertyOwnerIdType.commercialRegistration ||
        s.propertyOwnerIdType == PropertyOwnerIdType.unified700) {
      if (s.establishmentCommercialRegNumber == null ||
          s.establishmentCommercialRegNumber!.isEmpty) {
        errs['establishmentCommercialRegNumber'] = 'هذا الحقل مطلوب';
      }
    }

    // Agent-specific required fields — only when advertiserType = 'agent'
    if (s.advertiserType == AdvertiserType.agent) {
      if (s.powerOfAttorneyNumber == null || s.powerOfAttorneyNumber!.isEmpty) {
        errs['powerOfAttorneyNumber'] = 'هذا الحقل مطلوب';
      }
      if (s.agentNationalIdNumber == null || s.agentNationalIdNumber!.isEmpty) {
        errs['agentNationalIdNumber'] = 'هذا الحقل مطلوب';
      }
      if (s.agentBirthDate == null || s.agentBirthDate!.isEmpty) {
        errs['agentBirthDate'] = 'هذا الحقل مطلوب';
      }
    }

    setState(() => _errors.addAll(errs));
    return errs.isEmpty;
  }

  void _onContinue() {
    final s = ref.read(addListingProvider);
    if (_validate(s)) widget.onNext();
  }

  // Shows the "إدخال البيانات لاحقاً" confirmation bottom sheet.
  // If confirmed: sets skipLicenseInfo = true and advances to Step 1 category.
  void _onSkipLater() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      builder: (_) => _SkipWarningSheet(
        onConfirm: () {
          Navigator.of(context).pop();
          ref
              .read(addListingProvider.notifier)
              .setLicenseField('skipLicenseInfo', true);
          widget.onNext();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(addListingProvider);
    final notifier = ref.read(addListingProvider.notifier);
    final isOwner = s.advertiserType == AdvertiserType.owner;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // ── Role toggle: مالك / وكيل ──────────────────
                // Lets user select whether they are مالك (owner) or وكيل (agent)
                // Changing this triggers AnimatedSwitcher on the agent fields below
                Text(
                  'أنت:',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 8),
                _TogglePills(
                  options: const [
                    _PillOption(label: 'مالك', value: AdvertiserType.owner),
                    _PillOption(label: 'وكيل', value: AdvertiserType.agent),
                  ],
                  selected: s.advertiserType,
                  onChanged: (v) => notifier.setAdvertiserType(v),
                ),

                const SizedBox(height: 20),

                // ── SECTION 1: نوع الصك ───────────────────────
                // نوع وثيقة الملكية — always shown for owner and agent
                _FieldLabel(
                  label: 'نوع الصك (وثيقة ملكية العقار)',
                  required: false,
                ),
                const SizedBox(height: 8),
                _TogglePills(
                  options: const [
                    _PillOption(
                      label: 'صك إلكتروني / سجل عيني',
                      value: OwnershipDocumentType.electronicDeed,
                    ),
                    _PillOption(
                      label: 'غير ذلك',
                      value: OwnershipDocumentType.other,
                    ),
                  ],
                  selected: s.ownershipDocumentType,
                  onChanged: (v) =>
                      notifier.setLicenseField('ownershipDocumentType', v),
                ),

                const SizedBox(height: 20),

                // ── SECTION 2: نوع هوية المالك ────────────────
                // propertyOwnerIdType — always shown; drives which fields appear below
                _FieldLabel(
                  label: 'نوع هوية المالك',
                  required: true,
                ),
                const SizedBox(height: 8),
                _TogglePills(
                  options: const [
                    _PillOption(
                      label: 'هوية وطنية',
                      value: PropertyOwnerIdType.nationalId,
                    ),
                    _PillOption(
                      label: 'سجل تجاري',
                      value: PropertyOwnerIdType.commercialRegistration,
                    ),
                    _PillOption(
                      label: 'رقم موحد 700',
                      value: PropertyOwnerIdType.unified700,
                    ),
                  ],
                  selected: s.propertyOwnerIdType,
                  onChanged: (v) {
                    // Clear birth date and commercial reg when type changes
                    // to avoid stale values being submitted
                    notifier.setLicenseField('propertyOwnerIdType', v);
                    notifier.setLicenseField('propertyOwnerBirthDate', null);
                    notifier.setLicenseField(
                        'establishmentCommercialRegNumber', null);
                    _ownerBirthDateCtrl.clear();
                    _commercialRegCtrl.clear();
                    setState(() {
                      _errors.remove('propertyOwnerBirthDate');
                      _errors.remove('establishmentCommercialRegNumber');
                    });
                  },
                ),

                const SizedBox(height: 20),

                // ── SECTION 3: Dynamic fields ─────────────────
                // رقم الصك / رقم العقار / رقم السجل العيني — required
                _FormTextField(
                  label: 'رقم الصك أو رقم العقار أو رقم السجل العيني',
                  required: true,
                  controller: _ownershipDocNumCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  error: _errors['ownershipDocumentNumber'],
                  onChanged: (v) {
                    notifier.setLicenseField(
                        'ownershipDocumentNumber', v.isEmpty ? null : v);
                    if (_errors.containsKey('ownershipDocumentNumber')) {
                      setState(() => _errors.remove('ownershipDocumentNumber'));
                    }
                  },
                ),

                const SizedBox(height: 16),

                // رقم هوية المالك — label changes based on propertyOwnerIdType
                _FormTextField(
                  label: _ownerIdLabel(s.propertyOwnerIdType),
                  required: true,
                  controller: _ownerIdNumCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  error: _errors['propertyOwnerIdNumber'],
                  onChanged: (v) {
                    notifier.setLicenseField(
                        'propertyOwnerIdNumber', v.isEmpty ? null : v);
                    if (_errors.containsKey('propertyOwnerIdNumber')) {
                      setState(() => _errors.remove('propertyOwnerIdNumber'));
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Dynamic: birth date or commercial reg number
                // AnimatedSwitcher fades between them when propertyOwnerIdType changes
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: s.propertyOwnerIdType == PropertyOwnerIdType.nationalId
                      ? _BirthDateField(
                          key: const ValueKey('birthDate'),
                          label: 'تاريخ ميلاد المالك',
                          controller: _ownerBirthDateCtrl,
                          isHijri: s.isHijriCalendar,
                          error: _errors['propertyOwnerBirthDate'],
                          onDateChanged: (v) {
                            notifier.setLicenseField(
                                'propertyOwnerBirthDate', v.isEmpty ? null : v);
                            if (_errors.containsKey('propertyOwnerBirthDate')) {
                              setState(() =>
                                  _errors.remove('propertyOwnerBirthDate'));
                            }
                          },
                          onHijriChanged: (v) =>
                              notifier.setLicenseField('isHijriCalendar', v),
                        )
                      : _FormTextField(
                          key: const ValueKey('commercialReg'),
                          label: 'رقم السجل التجاري للمنشأة',
                          required: true,
                          controller: _commercialRegCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          error: _errors['establishmentCommercialRegNumber'],
                          onChanged: (v) {
                            notifier.setLicenseField(
                                'establishmentCommercialRegNumber',
                                v.isEmpty ? null : v);
                            if (_errors.containsKey(
                                'establishmentCommercialRegNumber')) {
                              setState(() => _errors.remove(
                                  'establishmentCommercialRegNumber'));
                            }
                          },
                        ),
                ),

                const SizedBox(height: 16),

                // رقم جوال المالك — pre-filled, read-only appearance
                // Only shown for owner (not agent — agent shows their own phone below)
                if (isOwner) ...[
                  _ReadOnlyPhoneField(
                    label: 'رقم جوال المالك',
                    value: s.propertyOwnerPhone ?? '',
                  ),
                  const SizedBox(height: 16),
                ],

                // رقم هوية أحد الملاك — optional, when property has multiple owners
                _FormTextField(
                  label: 'رقم هوية أحد الملاك',
                  required: false,
                  hint: 'في حال وجود ملاك متعددين',
                  controller: _oneOfOwnersCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) => notifier.setLicenseField(
                      'oneOfOwnersNationalId', v.isEmpty ? null : v),
                ),

                // ── Agent-specific fields ─────────────────────
                // Shown only when advertiserType = 'agent'
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: !isOwner
                      ? Column(
                          key: const ValueKey('agentFields'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            const Divider(color: AppColors.dividerLight),
                            const SizedBox(height: 16),

                            // رقم الوكالة الرسمية — power of attorney number
                            // Issued by Saudi Ministry of Justice (وزارة العدل)
                            // Proves agent is legally authorized by the property owner
                            _FormTextField(
                              label: 'رقم الوكالة الرسمية',
                              required: true,
                              hint: 'وكالة صادرة من وزارة العدل',
                              controller: _powerOfAttorneyCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              error: _errors['powerOfAttorneyNumber'],
                              onChanged: (v) {
                                notifier.setLicenseField(
                                    'powerOfAttorneyNumber',
                                    v.isEmpty ? null : v);
                                if (_errors.containsKey('powerOfAttorneyNumber')) {
                                  setState(() =>
                                      _errors.remove('powerOfAttorneyNumber'));
                                }
                              },
                            ),

                            const SizedBox(height: 16),

                            // رقم هوية الوكيل — agent's own national ID
                            _FormTextField(
                              label: 'رقم هوية الوكيل',
                              required: true,
                              controller: _agentIdNumCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              error: _errors['agentNationalIdNumber'],
                              onChanged: (v) {
                                notifier.setLicenseField(
                                    'agentNationalIdNumber',
                                    v.isEmpty ? null : v);
                                if (_errors.containsKey('agentNationalIdNumber')) {
                                  setState(() =>
                                      _errors.remove('agentNationalIdNumber'));
                                }
                              },
                            ),

                            const SizedBox(height: 16),

                            // تاريخ ميلاد الوكيل — agent's birth date
                            _BirthDateField(
                              label: 'تاريخ ميلاد الوكيل',
                              controller: _agentBirthDateCtrl,
                              isHijri: s.isHijriCalendar,
                              error: _errors['agentBirthDate'],
                              onDateChanged: (v) {
                                notifier.setLicenseField(
                                    'agentBirthDate', v.isEmpty ? null : v);
                                if (_errors.containsKey('agentBirthDate')) {
                                  setState(
                                      () => _errors.remove('agentBirthDate'));
                                }
                              },
                              onHijriChanged: (v) =>
                                  notifier.setLicenseField('isHijriCalendar', v),
                            ),

                            const SizedBox(height: 16),

                            // رقم جوال الوكيل — agent's phone, pre-filled read-only
                            _ReadOnlyPhoneField(
                              label: 'رقم جوال الوكيل',
                              value: s.agentPhone ?? '',
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

        // ── Fixed bottom buttons ──────────────────────────────
        _BottomButtons(
          onContinue: _onContinue,
          onSkipLater: _onSkipLater,
        ),
      ],
    );
  }

  // رقم هوية المالك label depends on propertyOwnerIdType
  String _ownerIdLabel(String idType) {
    switch (idType) {
      case PropertyOwnerIdType.commercialRegistration:
        return 'رقم السجل التجاري';
      case PropertyOwnerIdType.unified700:
        return 'الرقم الموحد 700';
      default:
        return 'رقم الهوية الوطنية';
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _PillOption {
  final String label;
  final String value;
  const _PillOption({required this.label, required this.value});
}

// Two or three equal-width toggle pills (selected = orange, unselected = white/grey)
class _TogglePills extends StatelessWidget {
  final List<_PillOption> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _TogglePills({
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
                  color: isSelected ? AppColors.primary : AppColors.white,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusS),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.dividerLight,
                  ),
                ),
                child: Text(
                  opt.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected
                        ? AppColors.white
                        : AppColors.textSecondaryLight,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
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

// Field label with optional required asterisk
class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, required this.required});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (required)
            Text(
              ' *',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ],
      );
}

// Standard text field with optional error message below it
class _FormTextField extends StatelessWidget {
  final String label;
  final bool required;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? error;
  final ValueChanged<String> onChanged;

  const _FormTextField({
    super.key,
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
          _FieldLabel(label: label, required: required),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textHintLight),
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusM),
                borderSide: const BorderSide(color: AppColors.dividerLight),
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
                  color:
                      error != null ? AppColors.error : AppColors.primary,
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

// Read-only phone field with grey background (pre-filled from user profile)
class _ReadOnlyPhoneField extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyPhoneField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldLabel(label: label, required: false),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.dividerLight,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(color: AppColors.dividerLight),
            ),
            child: Text(
              value.isEmpty ? '—' : value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
}

// Birth date input with Hijri/Gregorian checkbox toggle
// Date format: DD/MM/YYYY entered as text
class _BirthDateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isHijri;
  final String? error;
  final ValueChanged<String> onDateChanged;
  final ValueChanged<bool> onHijriChanged;

  const _BirthDateField({
    super.key,
    required this.label,
    required this.controller,
    required this.isHijri,
    this.error,
    required this.onDateChanged,
    required this.onHijriChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label row: field label (right) + هجري checkbox (left)
          Row(
            children: [
              // هجري checkbox — Hijri calendar is the Saudi standard
              GestureDetector(
                onTap: () => onHijriChanged(!isHijri),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'هجري',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isHijri
                            ? AppColors.primary
                            : AppColors.white,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusS / 2),
                        border: Border.all(
                          color: isHijri
                              ? AppColors.primary
                              : AppColors.dividerLight,
                          width: 1.5,
                        ),
                      ),
                      child: isHijri
                          ? const Icon(Icons.check,
                              size: 14, color: AppColors.white)
                          : null,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Field label
              Row(
                mainAxisSize: MainAxisSize.min,
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
            ],
          ),

          const SizedBox(height: 6),

          // Date text input — format: DD/MM/YYYY
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _DateInputFormatter(),
            ],
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: isHijri ? 'يوم/شهر/سنة (هجري)' : 'يوم/شهر/سنة (ميلادي)',
              hintStyle: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textHintLight),
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
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
            onChanged: onDateChanged,
          ),

          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              error!,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
              textAlign: TextAlign.right,
            ),
          ],
        ],
      );
}

// Auto-formats date input as DD/MM/YYYY while typing
class _DateInputFormatter extends TextInputFormatter {
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

// Bottom action buttons — fixed at bottom of the license form
class _BottomButtons extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onSkipLater;
  const _BottomButtons({
    required this.onContinue,
    required this.onSkipLater,
  });

  @override
  Widget build(BuildContext context) => Container(
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
            // Primary — "استمرار"
            ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(
                    double.infinity, AppConstants.buttonHeight),
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

            // Secondary — "إدخال البيانات لاحقاً" (saves listing as DRAFT)
            OutlinedButton(
              onPressed: onSkipLater,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(
                    double.infinity, AppConstants.buttonHeight),
                side: const BorderSide(color: AppColors.dividerLight),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusM),
                ),
              ),
              child: Text(
                'إدخال البيانات لاحقاً',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

// Warning bottom sheet shown when user taps "إدخال البيانات لاحقاً"
// Reminds user that listing will be saved as DRAFT (not published) until
// license information is completed
class _SkipWarningSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _SkipWarningSheet(
      {required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppConstants.spaceM,
          AppConstants.spaceL,
          AppConstants.spaceM,
          AppConstants.spaceM + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 30),
            ),

            const SizedBox(height: 16),

            Text(
              'تنبيه',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'لن يتم نشر إعلانك حتى تكتمل بيانات الترخيص.\nسيتم حفظ إعلانك كمسودة.',
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: onConfirm,
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
                'حسناً، أكمل لاحقاً',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 10),

            OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                minimumSize:
                    const Size(double.infinity, AppConstants.buttonHeight),
                side: const BorderSide(color: AppColors.dividerLight),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusM),
                ),
              ),
              child: Text(
                'إلغاء',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}
