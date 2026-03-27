import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../../../map/presentation/widgets/map_toggle_button.dart';
import '../../../map/presentation/widgets/map_view.dart';
import '../providers/home_provider.dart';
import '../widgets/category_chips_row.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/listing_card.dart';
import '../widgets/daily_rent_tab.dart';
import '../widgets/projects_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentTab = 0;

  static const _subtitles = [
    'المدينة  ·  الفئة  ·  المزيد من الفلاتر',
    'المدينة  ·  نوع المشروع',
    'المدينة  ·  التاريخ  ·  عدد الضيوف',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_currentTab != _tabController.index) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Search bar (subtitle adapts per tab) ──────
            HomeSearchBar(subtitle: _subtitles[_currentTab]),

            // ── Tab bar ───────────────────────────────────
            TabBar(
              controller: _tabController,
              labelStyle: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondaryLight,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: AppColors.dividerLight,
              tabs: const [
                Tab(text: 'عقارات'),
                Tab(text: 'مشاريع'),
                Tab(text: 'إيجار يومي'),
              ],
            ),

            // ── Tab views ─────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _RealEstateTab(),
                  const ProjectsTab(),
                  const DailyRentTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

// ── Real Estate tab ───────────────────────────────────────────────────────────

class _RealEstateTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMapMode = ref.watch(
        mapProvider.select((s) => s.viewMode == MapViewMode.map));

    return Stack(
      children: [
        // ── Content: list or map ─────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isMapMode
              ? const MapView(key: ValueKey('map'))
              : _ListContent(key: const ValueKey('list')),
        ),

        // ── Toggle pill button — bottom center ───────────────────────
        const Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(child: MapToggleButton()),
        ),
      ],
    );
  }
}

// ── List content (extracted so AnimatedSwitcher can swap it) ──────────────────

class _ListContent extends ConsumerWidget {
  const _ListContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(filteredListingsProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: CategoryChipsRow()),

        const SliverToBoxAdapter(
          child: Divider(
              height: 1, thickness: 1, color: AppColors.dividerLight),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        listings.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.home_work_outlined,
                          size: 64, color: AppColors.iconLight),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد عقارات في هذه الفئة',
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
                      ListingCard(listing: listings[index]),
                  childCount: listings.length,
                ),
              ),

        // Extra bottom padding so the last card clears the toggle pill.
        const SliverToBoxAdapter(child: SizedBox(height: 72)),
      ],
    );
  }
}
