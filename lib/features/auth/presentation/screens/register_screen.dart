import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool? _isOwner; // null = not selected yet

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty && _isOwner != null;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    await ref.read(authProvider.notifier).completeRegistration(
          name: _nameController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          isOwner: _isOwner!,
        );
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('أكمل ملفك الشخصي',
            style: AppTextStyles.headlineSmall),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      Text(
                        'آخر خطوة قبل بدء التصفح',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Name field ────────────────────
                      _FieldLabel(label: 'الاسم الكامل', required: true),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'أدخل اسمك الكامل',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'الاسم مطلوب'
                            : null,
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 20),

                      // ── Email field ───────────────────
                      _FieldLabel(label: 'البريد الإلكتروني', required: false),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          hintText: 'example@email.com',
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Role selector ─────────────────
                      Text(
                        'كيف ستستخدم عقار؟',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'اختر الوصف الأنسب لك',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          children: [
                            Expanded(
                              child: _RoleCard(
                                icon: Icons.search_rounded,
                                title: 'أريد التصفح',
                                subtitle: 'شراء، إيجار\nأو استكشاف العقارات',
                                selected: _isOwner == false,
                                onTap: () =>
                                    setState(() => _isOwner = false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _RoleCard(
                                icon: Icons.business_center_rounded,
                                title: 'مالك أو وسيط',
                                subtitle: 'أبيع، أؤجّر\nأو أدير عقارات',
                                selected: _isOwner == true,
                                onTap: () =>
                                    setState(() => _isOwner = true),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Error ─────────────────────────
                      if (auth.error != null) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            auth.error!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // ── Submit button ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: ElevatedButton(
                  onPressed: (_canSubmit && !auth.isLoading) ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSubmit
                        ? AppColors.primary
                        : AppColors.surfaceLight,
                    foregroundColor: _canSubmit
                        ? AppColors.white
                        : AppColors.textHintLight,
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white),
                          ),
                        )
                      : const Text('إنشاء الحساب'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Field label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _FieldLabel({required this.label, required this.required});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.titleMedium,
        ),
        if (required)
          Text(
            ' *',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.error),
          ),
      ],
    );
  }
}

// ── Role selection card ───────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.dividerLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color:
                      selected ? AppColors.primary : AppColors.iconLight,
                  size: 28,
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                color: selected
                    ? AppColors.primary
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: selected
                    ? AppColors.primaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
