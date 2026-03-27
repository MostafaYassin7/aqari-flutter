import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

// ── Country model ─────────────────────────────────────────────────────────────

class _Country {
  final String name;
  final String code;
  final String flag;

  const _Country({required this.name, required this.code, required this.flag});
}

const _kCountries = [
  _Country(name: 'السعودية', code: '+966', flag: '🇸🇦'),
  _Country(name: 'الإمارات', code: '+971', flag: '🇦🇪'),
  _Country(name: 'الكويت', code: '+965', flag: '🇰🇼'),
  _Country(name: 'البحرين', code: '+973', flag: '🇧🇭'),
  _Country(name: 'قطر', code: '+974', flag: '🇶🇦'),
  _Country(name: 'عُمان', code: '+968', flag: '🇴🇲'),
  _Country(name: 'الأردن', code: '+962', flag: '🇯🇴'),
  _Country(name: 'مصر', code: '+20', flag: '🇪🇬'),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();
  _Country _selected = _kCountries.first;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  bool get _isValid => _phoneController.text.trim().length >= 9;

  Future<void> _send() async {
    if (!_isValid) return;
    await ref.read(authProvider.notifier).sendOtp(
          phone: _phoneController.text.trim(),
          countryCode: _selected.code,
        );
    if (mounted) context.go(AppRoutes.otp);
  }

  void _showCountryPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CountryPickerSheet(
        selected: _selected,
        onPick: (c) {
          setState(() => _selected = c);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go(AppRoutes.login),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // ── Title ─────────────────────────────────
              Text(
                'أدخل رقم هاتفك',
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'سنرسل لك رمز تحقق للتأكيد',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),

              const SizedBox(height: 36),

              // ── Phone row ─────────────────────────────
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    // Country code picker
                    GestureDetector(
                      onTap: _showCountryPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 15),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.dividerLight),
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.surfaceLight,
                        ),
                        child: Row(
                          children: [
                            Text(_selected.flag,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 6),
                            Text(
                              _selected.code,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 18, color: AppColors.iconLight),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Phone number field
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          hintText: '5XXXXXXXX',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textHintLight,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Phone hint
              Text(
                'مثال: ${_selected.code} 5XXXXXXXX',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),

              const Spacer(),

              // ── Send button ───────────────────────────
              ElevatedButton(
                onPressed: (_isValid && !auth.isLoading) ? _send : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isValid ? AppColors.primary : AppColors.surfaceLight,
                  foregroundColor:
                      _isValid ? AppColors.white : AppColors.textHintLight,
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : const Text('إرسال رمز التحقق'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Country picker bottom sheet ───────────────────────────────────────────────

class _CountryPickerSheet extends StatelessWidget {
  final _Country selected;
  final ValueChanged<_Country> onPick;

  const _CountryPickerSheet({required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.dividerLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'اختر رمز الدولة',
            style: AppTextStyles.headlineSmall,
          ),
        ),
        const Divider(height: 1, color: AppColors.dividerLight),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _kCountries.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppColors.dividerLight),
          itemBuilder: (_, i) {
            final c = _kCountries[i];
            final isSelected = c.code == selected.code;
            return ListTile(
              onTap: () => onPick(c),
              leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
              title: Text(c.name, style: AppTextStyles.titleMedium),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.code,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_rounded,
                        color: AppColors.primary, size: 20),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
