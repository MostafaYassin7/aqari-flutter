import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/projects_provider.dart';
import 'project_card.dart';
import 'country_chips_row.dart';

/// Projects tab content — city chips + vertical project cards + pagination.
class ProjectsTab extends ConsumerStatefulWidget {
  const ProjectsTab({super.key});

  @override
  ConsumerState<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends ConsumerState<ProjectsTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(projectsNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncProjects = ref.watch(projectsNotifierProvider);
    final projects = ref.watch(filteredProjectsProvider);

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: CountryChipsRow(cityProvider: selectedProjectCityProvider),
        ),

        const SliverToBoxAdapter(
          child: Divider(
            height: 1,
            thickness: 1,
            color: AppColors.dividerLight,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Loading state
        if (asyncProjects.isLoading && projects.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (projects.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.apartment_outlined,
                    size: 64,
                    color: AppColors.iconLight,
                  ),
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
        else ...[
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => ProjectCard(project: projects[index]),
              childCount: projects.length,
            ),
          ),
          // Loading more indicator
          if (asyncProjects.isLoading && projects.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}
