import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/presentation/widgets/listing_card.dart';
import '../providers/search_provider.dart';
import '../widgets/search_filter_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _adQueryController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _adQueryController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(searchModeProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(context, mode),
      body: mode == 0
          ? const _FilterSearchBody()
          : _AdPhoneSearchBody(controller: _adQueryController),
    );
  }

  AppBar _buildAppBar(BuildContext context, int mode) {
    return AppBar(
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimaryLight, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'البحث',
        style: AppTextStyles.titleLarge.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
        ),
      ),
      centerTitle: true,
      actions: [
        if (mode == 0)
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune_rounded,
                    color: AppColors.textPrimaryLight, size: 22),
                if (_hasActiveFilters())
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
    );
  }

  bool _hasActiveFilters() {
    final pr = ref.read(priceRangeProvider);
    final types = ref.read(selectedPropertyTypesProvider);
    final beds = ref.read(bedroomsFilterProvider);
    final amen = ref.read(selectedAmenitiesProvider);
    return pr.min > PriceRangeNotifier.kMin ||
        pr.max < PriceRangeNotifier.kMax ||
        types.isNotEmpty ||
        beds >= 0 ||
        amen.isNotEmpty;
  }
}

// ── Tab switcher ──────────────────────────────────────────────────────────────

class _TabSwitcher extends ConsumerWidget {
  const _TabSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(searchModeProvider);

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceM, vertical: AppConstants.spaceS),
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Row(
        children: [
          _Tab(
              label: 'بحث بالفلاتر',
              selected: mode == 0,
              onTap: () =>
                  ref.read(searchModeProvider.notifier).select(0)),
          _Tab(
              label: 'رقم الإعلان أو الهاتف',
              selected: mode == 1,
              onTap: () =>
                  ref.read(searchModeProvider.notifier).select(1)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color:
                  selected ? AppColors.white : AppColors.transparent,
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusS),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.textPrimaryLight
                      : AppColors.textSecondaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
}

// ── Filter Search body ────────────────────────────────────────────────────────

class _FilterSearchBody extends ConsumerWidget {
  const _FilterSearchBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider);

    return CustomScrollView(
      slivers: [
        // Tab switcher
        const SliverToBoxAdapter(child: _TabSwitcher()),

        // Form
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category picker
                _PickerField(
                  label: 'فئة العقار',
                  value: ref.watch(searchCategoryProvider),
                  hint: 'اختر الفئة',
                  icon: Icons.category_rounded,
                  onTap: () =>
                      _showCategorySheet(context, ref),
                ),
                const SizedBox(height: 10),

                // City picker
                _PickerField(
                  label: 'المدينة',
                  value: ref.watch(searchCityProvider),
                  hint: 'اختر المدينة',
                  icon: Icons.location_city_rounded,
                  onTap: () => _showCitySheet(context, ref),
                ),
                const SizedBox(height: 10),

                // District dropdown
                _DistrictDropdown(),
                const SizedBox(height: 10),

                // Marketing only toggle
                _MarketingToggle(),
                const SizedBox(height: 16),

                // Search button
                ElevatedButton(
                  onPressed: () {
                    // Results are reactive — just unfocus and scroll
                    FocusScope.of(context).unfocus();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(
                        double.infinity, AppConstants.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusM),
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
                const SizedBox(height: 20),

                // Results header
                if (results.isNotEmpty)
                  Text(
                    '${results.length} نتيجة',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (results.isEmpty)
                  _EmptyState(),
              ],
            ),
          ),
        ),

        // Results list
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

  void _showCategorySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXL)),
      ),
      builder: (_) => _CategorySheet(
        selected: ref.read(searchCategoryProvider),
        onSelect: (v) {
          ref.read(searchCategoryProvider.notifier).select(v);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showCitySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundLight,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXL)),
      ),
      builder: (_) => _CitySheet(
        selected: ref.read(searchCityProvider),
        onSelect: (v) {
          ref.read(searchCityProvider.notifier).select(v);
          ref.read(searchDistrictProvider.notifier).select(null);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

// ── Ad / Phone Search body ────────────────────────────────────────────────────

class _AdPhoneSearchBody extends ConsumerWidget {
  final TextEditingController controller;
  const _AdPhoneSearchBody({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _TabSwitcher()),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Input field
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimaryLight),
                  decoration: InputDecoration(
                    hintText: 'أدخل رقم الإعلان أو رقم الهاتف',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHintLight),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textSecondaryLight),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusM),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Search button
                ElevatedButton(
                  onPressed: () => FocusScope.of(context).unfocus(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(
                        double.infinity, AppConstants.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusM),
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

                const Spacer(),

                // Illustration hint
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.manage_search_rounded,
                          size: 72,
                          color: AppColors.dividerLight),
                      const SizedBox(height: 12),
                      Text(
                        'ابحث برقم الإعلان أو رقم الهاتف\nللعثور على عقار محدد',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reusable picker field ─────────────────────────────────────────────────────

class _PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(color: AppColors.dividerLight),
              ),
              child: Row(
                children: [
                  Icon(icon,
                      size: 18,
                      color: AppColors.textSecondaryLight),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value ?? hint,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: value != null
                            ? AppColors.textPrimaryLight
                            : AppColors.textHintLight,
                      ),
                    ),
                  ),
                  if (value != null)
                    GestureDetector(
                      onTap: () {},
                      child: const Icon(Icons.close_rounded,
                          size: 16,
                          color: AppColors.textSecondaryLight),
                    )
                  else
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.textSecondaryLight),
                ],
              ),
            ),
          ),
        ],
      );
}

// ── District dropdown ─────────────────────────────────────────────────────────

class _DistrictDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(searchCityProvider);
    final selected = ref.watch(searchDistrictProvider);
    final districts = getDistrictsForCity(city);

    if (districts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الحي',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(color: AppColors.dividerLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('اختر الحي',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textHintLight)),
              ),
              isExpanded: true,
              icon: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondaryLight),
              ),
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusM),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('الكل',
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondaryLight)),
                  ),
                ),
                ...districts.map((d) => DropdownMenuItem<String>(
                      value: d,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14),
                        child: Text(d,
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimaryLight)),
                      ),
                    )),
              ],
              onChanged: (v) =>
                  ref.read(searchDistrictProvider.notifier).select(v),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Marketing toggle ──────────────────────────────────────────────────────────

class _MarketingToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(marketingOnlyProvider);

    return GestureDetector(
      onTap: () => ref.read(marketingOnlyProvider.notifier).toggle(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: AppColors.dividerLight),
        ),
        child: Row(
          children: [
            Icon(Icons.campaign_rounded,
                size: 18, color: AppColors.textSecondaryLight),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'طلبات التسويق فقط',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimaryLight),
              ),
            ),
            Switch(
              value: on,
              onChanged: (_) =>
                  ref.read(marketingOnlyProvider.notifier).toggle(),
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category sheet ────────────────────────────────────────────────────────────

class _CategorySheet extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;
  const _CategorySheet({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle + title (fixed header)
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppConstants.spaceM, AppConstants.spaceM,
              AppConstants.spaceM, AppConstants.spaceS),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.dividerLight,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusCircle),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('اختر الفئة',
                  style: AppTextStyles.titleLarge
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.dividerLight),

        // Scrollable list fills remaining sheet height
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom +
                  AppConstants.spaceM,
            ),
            children: [
              _CategoryTile(
                label: 'الكل',
                selected: selected == null,
                onTap: () => onSelect(null),
              ),
              ...searchPropertyTypes.map((t) => _CategoryTile(
                    label: t,
                    selected: selected == t,
                    onTap: () => onSelect(t),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryTile(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        title: Text(label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w400,
              color: selected
                  ? AppColors.primary
                  : AppColors.textPrimaryLight,
            )),
        trailing: selected
            ? const Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 20)
            : null,
        onTap: onTap,
      );
}

// ── City sheet (searchable) ───────────────────────────────────────────────────

class _CitySheet extends StatefulWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;
  const _CitySheet({required this.selected, required this.onSelect});

  @override
  State<_CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends State<_CitySheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = searchCities
        .where((c) => c.contains(_query))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppConstants.spaceM, AppConstants.spaceM,
            AppConstants.spaceM, 0),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusCircle),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('اختر المدينة',
                style: AppTextStyles.titleLarge
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'بحث...',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textHintLight),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondaryLight, size: 20),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusM),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: ctrl,
                children: [
                  _CategoryTile(
                    label: 'كل المدن',
                    selected: widget.selected == null,
                    onTap: () => widget.onSelect(null),
                  ),
                  ...filtered.map((c) => _CategoryTile(
                        label: c,
                        selected: widget.selected == c,
                        onTap: () => widget.onSelect(c),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off_rounded,
                  size: 64, color: AppColors.dividerLight),
              const SizedBox(height: 12),
              Text('لا توجد نتائج',
                  style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('جرّب تغيير الفلاتر للعثور على عقارات',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHintLight)),
            ],
          ),
        ),
      );
}
