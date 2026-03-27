import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // Navigate to home when social sign-in completes
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.step == AuthStep.authenticated) {
        context.go(AppRoutes.home);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Top bar ──────────────────────────────
                _TopBar(),

                // ── Scrollable content ───────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),

                        // Logo
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.home_rounded,
                              color: AppColors.primary,
                              size: 36,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Title
                        Text(
                          'أهلاً بك في عقار',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'سجّل دخولك أو أنشئ حساباً جديداً',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── Phone button ──────────────────
                        ElevatedButton.icon(
                          onPressed: auth.isLoading
                              ? null
                              : () => context.go(AppRoutes.phoneInput),
                          icon: const Icon(Icons.phone_rounded, size: 20),
                          label: const Text('متابعة برقم الهاتف'),
                        ),

                        const SizedBox(height: 20),

                        // ── Divider "أو" ──────────────────
                        const _OrDivider(),

                        const SizedBox(height: 20),

                        // ── Google button ─────────────────
                        OutlinedButton(
                          onPressed: auth.isLoading
                              ? null
                              : () =>
                                  ref.read(authProvider.notifier).socialSignIn(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _GoogleIcon(),
                              const SizedBox(width: 10),
                              const Text('متابعة بـ Google'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Apple button ──────────────────
                        OutlinedButton(
                          onPressed: auth.isLoading
                              ? null
                              : () =>
                                  ref.read(authProvider.notifier).socialSignIn(),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.apple, size: 22),
                              SizedBox(width: 10),
                              Text('متابعة بـ Apple'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // ── Terms of service ─────────────────────
                const _TermsText(),
                const SizedBox(height: 16),
              ],
            ),

            // ── Full-screen loading overlay ───────────────
            if (auth.isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: AppColors.overlay,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: IconButton(
        icon: const Icon(Icons.close_rounded),
        color: AppColors.textPrimaryLight,
        onPressed: () {
          context.go(AppRoutes.onboarding);
        },
      ),
    );
  }
}

// ── "أو" divider ──────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.dividerLight)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'أو',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.dividerLight)),
      ],
    );
  }
}

// ── Google "G" icon ───────────────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4285F4),
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ── Terms text ────────────────────────────────────────────────────────────────

class _TermsText extends StatelessWidget {
  const _TermsText();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text.rich(
        TextSpan(
          text: 'بالمتابعة أنت توافق على ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
          children: [
            TextSpan(
              text: 'شروط الخدمة',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimaryLight,
                decoration: TextDecoration.underline,
              ),
            ),
            const TextSpan(text: ' و'),
            TextSpan(
              text: ' سياسة الخصوصية',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimaryLight,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
