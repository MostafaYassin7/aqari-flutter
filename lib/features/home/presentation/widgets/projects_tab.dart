import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/projects_provider.dart';
import 'project_card.dart';
import 'project_city_chips_row.dart';

/// Projects tab content — city chips + vertical project cards.
class ProjectsTab extends ConsumerWidget {
  const ProjectsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(filteredProjectsProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: ProjectCityChipsRow()),

        const SliverToBoxAdapter(
          child: Divider(
              height: 1, thickness: 1, color: AppColors.dividerLight),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        projects.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.apartment_outlined,
                          size: 64, color: AppColors.iconLight),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد مشاريع في هذه المدينة',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      ProjectCard(project: projects[index]),
                  childCount: projects.length,
                ),
              ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}
