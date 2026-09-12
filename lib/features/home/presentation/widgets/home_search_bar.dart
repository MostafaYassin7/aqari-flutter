import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../search/presentation/providers/search_provider.dart';
import '../../../event_halls/presentation/event_halls_ui.dart';

/// Airbnb-style collapsed search pill at the top of the home feed.
/// Tapping navigates to the full Search screen.
class HomeSearchBar extends ConsumerWidget {
  final String subtitle;
  final int currentTab;

  const HomeSearchBar({
    this.subtitle = 'المدينة  ·  الفئة  ·  المزيد من الفلاتر',
    this.currentTab = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        if (currentTab == 3) {
          showHallFilters(context);
          return;
        }
        ref.read(searchTabProvider.notifier).select(currentTab);
        context.push(AppRoutes.search);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: context.appColors.card,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: context.appColors.divider),
          boxShadow: [
            BoxShadow(
              color: context.appColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Search icon
            const Icon(
              Icons.search_rounded,
              color: AppColors.primary,
              size: 22,
            ),

            const SizedBox(width: 12),

            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'أين تريد؟',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Filter button
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.appColors.divider),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 16,
                color: context.appColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
