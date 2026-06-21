import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../providers/add_listing_provider.dart';

class Step0RoleService extends ConsumerWidget {
  const Step0RoleService({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addListingProvider);
    final notifier = ref.read(addListingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceM,
        vertical: AppConstants.spaceS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Section 1: Who are you? ───────────────────────
          Text(
            'هل أنت؟',
            style: AppTextStyles.headlineMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _RoleCard(
                label: 'مالك / وكيل',
                icon: Icons.home_work_rounded,
                isSelected: state.selectedRole == 'owner',
                onTap: () => notifier.setRole('owner'),
              ),
              const SizedBox(width: 10),
              _RoleCard(
                label: 'مسوق',
                icon: Icons.business_center_rounded,
                isSelected: state.selectedRole == 'marketer',
                onTap: () => notifier.setRole('marketer'),
              ),
              const SizedBox(width: 10),
              _RoleCard(
                label: 'مضيف',
                icon: Icons.vpn_key_rounded,
                isSelected: state.selectedRole == 'host',
                onTap: () => notifier.setRole('host'),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Section 2: What are you listing? ─────────────
          Text(
            'ما الذي تحاول الإعلان؟',
            style: AppTextStyles.headlineMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _ServiceCard(
            title: 'إضافة إعلان عقاري',
            subtitle: 'اعرض عقارك للبيع أو الإيجار في منصة عقار',
            iconWidget: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.white,
                size: 28,
              ),
            ),
            isSelected: state.selectedService == 'listing',
            onTap: () => notifier.setService('listing'),
          ),

          const SizedBox(height: 12),

          _ServiceCard(
            title: 'طلب تسويق عقار',
            subtitle: 'اطلب من الوسطاء العقاريين تسويق عقارك',
            iconWidget: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: context.divider,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: context.textSecondary,
                size: 24,
              ),
            ),
            isSelected: state.selectedService == 'marketing_request',
            onTap: () => notifier.setService('marketing_request'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Role card (horizontal row of 3) ──────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : context.divider,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: context.shadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? AppColors.primary
                    : context.textSecondary,
              ),
              SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : context.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Service card (full-width vertical stack) ──────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget iconWidget;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.iconWidget,
    required this.isSelected,
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
          color: isSelected ? AppColors.primaryLight : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          // In RTL: first child appears on right (text), last on left (icon)
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            iconWidget,
          ],
        ),
      ),
    );
  }
}
