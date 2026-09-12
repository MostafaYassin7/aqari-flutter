import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/listing.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../home/presentation/widgets/listing_card.dart';
import '../../../home/presentation/widgets/project_card.dart';
import '../providers/search_provider.dart';
import '../widgets/search_filter_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryController = TextEditingController();
  final _adQueryController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;

  static const _tabHints = [
    'ابحث عن عقار...',
    'ابحث عن مشروع...',
    'ابحث عن إيجار يومي...',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    _adQueryController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).set(value.trim());
    });
  }

  void _onQuerySubmitted(String value) {
    _debounce?.cancel();
    ref.read(searchQueryProvider.notifier).set(value.trim());
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(searchModeProvider);
    final hasFilters = ref.watch(hasActiveFiltersProvider);
    final tab = ref.watch(searchTabProvider);

    final tabLabels = ['عقارات', 'مشاريع', 'إيجار يومي'];

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: context.appColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'بحث ${tabLabels[tab]}',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (mode == 0 && tab != 1)
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: context.appColors.textPrimary,
                    size: 22,
                  ),
                  if (hasFilters)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => showSearchFilterSheet(context),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: tab == 1
          ? _buildProjectsSearchBody()
          : (mode == 0
                ? _buildFilterSearchBody(tab)
                : _AdPhoneSearchBody(controller: _adQueryController)),
    );
  }

  // ── Projects search body (city + status only) ───────────────────────
  Widget _buildProjectsSearchBody() {
    final asyncResults = ref.watch(projectSearchResultsProvider);
    final results = asyncResults.value ?? <dynamic>[];

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          ref.read(projectSearchResultsProvider.notifier).loadMore();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── City + Status chip row ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _FilterChip(
                    label: _cityDisplayName(ref.watch(searchCityProvider)),
                    icon: Icons.location_city_rounded,
                    active: ref.watch(searchCityProvider) != null,
                    onTap: () => _showCitySheet(context),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: _statusDisplayName(
                      ref.watch(searchProjectStatusProvider),
                    ),
                    icon: Icons.construction_rounded,
                    active: ref.watch(searchProjectStatusProvider) != null,
                    onTap: () => _showStatusSheet(context),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Divider(
              height: 1,
              thickness: 1,
              color: context.appColors.divider,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          if (!asyncResults.isLoading && results.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Text(
                  '${results.length} نتيجة',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.appColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          if (asyncResults.isLoading && results.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (!asyncResults.isLoading && results.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => ProjectCard(project: results[i]),
                childCount: results.length,
              ),
            ),

          if (asyncResults.isLoading && results.isNotEmpty)
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

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ── Listings search body (filter search with query) ────────────────

  Widget _buildFilterSearchBody(int tab) {
    final asyncResults = ref.watch(searchResultsProvider);
    final results = asyncResults.value ?? <dynamic>[];

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          ref.read(searchResultsProvider.notifier).loadMore();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Tab switcher ─────────────────────────────────
          const SliverToBoxAdapter(child: _TabSwitcher()),

          // ── Query text field ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _queryController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                onChanged: _onQueryChanged,
                onSubmitted: _onQuerySubmitted,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: context.appColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: _tabHints[tab],
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: context.appColors.textHint,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: context.appColors.textSecondary,
                  ),
                  suffixIcon: ValueListenableBuilder(
                    valueListenable: _queryController,
                    builder: (_, value, __) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: context.appColors.textSecondary,
                        ),
                        onPressed: () {
                          _queryController.clear();
                          _debounce?.cancel();
                          ref.read(searchQueryProvider.notifier).set('');
                        },
                      );
                    },
                  ),
                  filled: true,
                  fillColor: context.appColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
          ),

          // ── City + PropertyType chip row ──────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _FilterChip(
                    label: _cityDisplayName(ref.watch(searchCityProvider)),
                    icon: Icons.location_city_rounded,
                    active: ref.watch(searchCityProvider) != null,
                    onTap: () => _showCitySheet(context),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: _propertyTypeDisplayName(
                      ref.watch(searchPropertyTypeProvider),
                    ),
                    icon: Icons.home_work_rounded,
                    active: ref.watch(searchPropertyTypeProvider) != null,
                    onTap: () => _showPropertyTypeSheet(context),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Divider(
              height: 1,
              thickness: 1,
              color: context.appColors.divider,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Results header ────────────────────────────────
          if (!asyncResults.isLoading && results.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Text(
                  '${results.length} نتيجة',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.appColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // ── Loading state ─────────────────────────────────
          if (asyncResults.isLoading && results.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          // ── Empty state ───────────────────────────────────
          else if (!asyncResults.isLoading && results.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(),
            )
          // ── Results list ──────────────────────────────────
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => ListingCard(listing: results[i]),
                childCount: results.length,
              ),
            ),

          // ── Load more indicator ───────────────────────────
          if (asyncResults.isLoading && results.isNotEmpty)
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

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  String _cityDisplayName(String? city) {
    if (city == null) return 'المدينة';
    return cityArabicNames[city] ?? city;
  }

  String _propertyTypeDisplayName(String? type) {
    if (type == null) return 'نوع العقار';
    return propertyTypeArabicNames[type] ?? type;
  }

  static const _statusArabic = {'ready': 'جاهز', 'off_plan': 'على الخارطة'};

  String _statusDisplayName(String? status) {
    if (status == null) return 'حالة المشروع';
    return _statusArabic[status] ?? status;
  }

  void _showCitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      builder: (_) => _OptionSheet(
        title: 'اختر المدينة',
        options: countries,
        displayName: (v) => cityArabicNames[v] ?? v,
        selected: ref.read(searchCityProvider),
        onSelect: (v) {
          ref.read(searchCityProvider.notifier).select(v);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showPropertyTypeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      builder: (_) => _OptionSheet(
        title: 'اختر نوع العقار',
        options: propertyTypes,
        displayName: (v) => propertyTypeArabicNames[v] ?? v,
        selected: ref.read(searchPropertyTypeProvider),
        onSelect: (v) {
          ref.read(searchPropertyTypeProvider.notifier).select(v);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showStatusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      builder: (_) => _OptionSheet(
        title: 'حالة المشروع',
        options: const ['ready', 'off_plan'],
        displayName: (v) => _statusArabic[v] ?? v,
        selected: ref.read(searchProjectStatusProvider),
        onSelect: (v) {
          ref.read(searchProjectStatusProvider.notifier).select(v);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : context.appColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active ? AppColors.primary : context.appColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? AppColors.white : context.appColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: active ? AppColors.white : context.appColors.textPrimary,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Option sheet (reusable for city / property type) ──────────────────────────

class _OptionSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String Function(String) displayName;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _OptionSheet({
    required this.title,
    required this.options,
    required this.displayName,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appColors.divider,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: context.appColors.divider),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            children: [
              _OptionTile(
                label: 'الكل',
                selected: selected == null,
                onTap: () => onSelect(null),
              ),
              ...options.map(
                (o) => _OptionTile(
                  label: displayName(o),
                  selected: selected == o,
                  onTap: () => onSelect(o),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    title: Text(
      label,
      style: AppTextStyles.bodyMedium.copyWith(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        color: selected ? AppColors.primary : context.appColors.textPrimary,
      ),
    ),
    trailing: selected
        ? const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
            size: 20,
          )
        : null,
    onTap: onTap,
  );
}

// ── Tab switcher ──────────────────────────────────────────────────────────────

class _TabSwitcher extends ConsumerWidget {
  const _TabSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(searchModeProvider);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceM,
        vertical: AppConstants.spaceS,
      ),
      height: 44,
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'بحث بالفلاتر',
            selected: mode == 0,
            onTap: () => ref.read(searchModeProvider.notifier).select(0),
          ),
          _Tab(
            label: 'رقم الإعلان أو الهاتف',
            selected: mode == 1,
            onTap: () => ref.read(searchModeProvider.notifier).select(1),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected ? context.appColors.card : AppColors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: context.appColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? context.appColors.textPrimary
                  : context.appColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ),
  );
}

// ── Ad / Phone Search body ────────────────────────────────────────────────────

class _AdPhoneSearchBody extends ConsumerStatefulWidget {
  final TextEditingController controller;
  const _AdPhoneSearchBody({required this.controller});

  @override
  ConsumerState<_AdPhoneSearchBody> createState() => _AdPhoneSearchBodyState();
}

class _AdPhoneSearchBodyState extends ConsumerState<_AdPhoneSearchBody> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(referenceQueryProvider.notifier).set(value.trim());
    });
  }

  void _onSearch() {
    _debounce?.cancel();
    ref
        .read(referenceQueryProvider.notifier)
        .set(widget.controller.text.trim());
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final asyncResults = ref.watch(referenceSearchProvider);
    final results = asyncResults.value ?? <Listing>[];
    final query = ref.watch(referenceQueryProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: _TabSwitcher()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: widget.controller,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  onChanged: _onChanged,
                  onSubmitted: (_) => _onSearch(),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'أدخل رقم الإعلان أو رقم الهاتف',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: context.appColors.textHint,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: context.appColors.textSecondary,
                    ),
                    suffixIcon: ValueListenableBuilder(
                      valueListenable: widget.controller,
                      builder: (_, value, __) {
                        if (value.text.isEmpty) return const SizedBox.shrink();
                        return IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: context.appColors.textSecondary,
                          ),
                          onPressed: () {
                            widget.controller.clear();
                            _debounce?.cancel();
                            ref.read(referenceQueryProvider.notifier).set('');
                          },
                        );
                      },
                    ),
                    filled: true,
                    fillColor: context.appColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _onSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(
                      double.infinity,
                      AppConstants.buttonHeight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'بحث',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!asyncResults.isLoading && results.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '${results.length} نتيجة',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.appColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (asyncResults.isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (query.isNotEmpty && results.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _EmptyState())
        else if (query.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.manage_search_rounded,
                    size: 72,
                    color: context.appColors.divider,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ابحث برقم الإعلان أو رقم الهاتف\nللعثور على عقار محدد',
                    textAlign: TextAlign.center,
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
              (_, i) => ListingCard(listing: results[i]),
              childCount: results.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.search_off_rounded,
          size: 64,
          color: context.appColors.divider,
        ),
        const SizedBox(height: 12),
        Text(
          'لا توجد نتائج',
          style: AppTextStyles.bodyLarge.copyWith(
            color: context.appColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'جرّب تغيير الفلاتر للعثور على عقارات',
          style: AppTextStyles.bodySmall.copyWith(
            color: context.appColors.textHint,
          ),
        ),
      ],
    ),
  );
}
