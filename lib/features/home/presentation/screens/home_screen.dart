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
import '../widgets/country_chips_row.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/listing_card.dart';
import '../widgets/daily_rent_tab.dart';
import '../widgets/projects_tab.dart';
import '../../../event_halls/presentation/event_halls_ui.dart';

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
    'المدينة  ·  السعر  ·  قاعات المناسبات',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      backgroundColor: context.appColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Search bar (subtitle adapts per tab) ──────
            HomeSearchBar(
              subtitle: _subtitles[_currentTab],
              currentTab: _currentTab,
            ),

            // ── Tab bar ───────────────────────────────────
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: context.appColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: context.appColors.divider,
              tabs: const [
                Tab(text: 'عقارات'),
                Tab(text: 'مشاريع'),
                Tab(text: 'إيجار يومي'),
                Tab(text: 'قاعات المناسبات'),
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
                  const EventHallsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        addPreset: _currentTab == 3
            ? 'event_hall'
            : _currentTab == 2
            ? 'daily'
            : null,
      ),
    );
  }
}

// ── Real Estate tab ───────────────────────────────────────────────────────────

class _RealEstateTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMapMode = ref.watch(
      mapProvider.select((s) => s.viewMode == MapViewMode.map),
    );

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
    final isLoading = ref.watch(listingsIsLoadingProvider);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          ref.read(listingsNotifierProvider.notifier).loadMore();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: CountryChipsRow(cityProvider: selectedCityProvider),
          ),

          SliverToBoxAdapter(
            child: CategoryChipsRow(
              propertyTypeProvider: selectedPropertyTypeProvider,
            ),
          ),

          SliverToBoxAdapter(
            child: Divider(
              height: 1,
              thickness: 1,
              color: context.appColors.divider,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          if (isLoading && listings.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (listings.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.home_work_outlined,
                      size: 64,
                      color: context.appColors.icon,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد عقارات في هذه الفئة',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => ListingCard(listing: listings[index]),
                childCount: listings.length,
              ),
            ),

          if (isLoading && listings.isNotEmpty)
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

          // Extra bottom padding so the last card clears the toggle pill.
          const SliverToBoxAdapter(child: SizedBox(height: 72)),
        ],
      ),
    );
  }
}
