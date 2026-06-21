import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../providers/add_listing_provider.dart';
import 'city_mappings.dart';

class Step6Location extends ConsumerStatefulWidget {
  const Step6Location({super.key});

  @override
  ConsumerState<Step6Location> createState() => _Step6LocationState();
}

class _Step6LocationState extends ConsumerState<Step6Location> {
  late TextEditingController _districtCtrl;
  late TextEditingController _addressCtrl;

  GoogleMapController? _mapController;
  // Tracks the camera center while the user drags; committed on onCameraIdle.
  LatLng? _pendingCenter;

  @override
  void initState() {
    super.initState();
    final s = ref.read(addListingProvider);
    _districtCtrl = TextEditingController(text: s.district);
    _addressCtrl = TextEditingController(text: s.address);
  }

  @override
  void dispose() {
    _districtCtrl.dispose();
    _addressCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _showCitySheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: _PickerSheet(
          title: 'اختر المدينة',
          items: cities
              .map((c) => _PickerItem(label: c.ar, value: c.en))
              .toList(),
          onSelected: (value) {
            ref.read(addListingProvider.notifier).setCity(value);
            ref.read(addListingProvider.notifier).setDistrict('');
            _districtCtrl.clear();
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(addListingProvider);
    final initialPos = CameraPosition(
      target: LatLng(s.lat, s.lng),
      zoom: 14,
    );

    return Column(
      children: [
        // ── Header ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppConstants.spaceM, AppConstants.spaceS,
              AppConstants.spaceM, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أين يقع العقار؟',
                style: AppTextStyles.headlineMedium
                    .copyWith(color: context.textPrimary),
              ),
              SizedBox(height: 4),
              Text(
                'حرّك الخريطة لتثبيت الدبوس على الموقع الصحيح',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: context.textSecondary),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // ── Interactive map with center pin ───────────────────
        Expanded(
          child: Stack(
            children: [
              // Real Google Map — Directionality(ltr) needed so UiKitView
              // touch-forwarding works correctly inside the RTL page context.
              Directionality(
                textDirection: TextDirection.ltr,
                child: GoogleMap(
                  initialCameraPosition: initialPos,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (ctrl) => _mapController = ctrl,
                  onCameraMove: (pos) => _pendingCenter = pos.target,
                  onCameraIdle: () {
                    final center = _pendingCenter;
                    if (center != null) {
                      ref.read(addListingProvider.notifier).setLocation(
                            center.latitude,
                            center.longitude,
                          );
                    }
                  },
                ),
              ),

              // Fixed center pin (the map moves beneath it)
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_pin,
                      color: AppColors.primary,
                      size: 48,
                    ),
                    // Shadow dot under the pin base
                    SizedBox(
                      width: 8,
                      height: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.overlay,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // "My location" shortcut — bottom-end corner
              PositionedDirectional(
                bottom: 12,
                end: 12,
                child: _MapFab(
                  icon: Icons.my_location_rounded,
                  onTap: () {
                    // Snap back to the default city centre when tapped
                    _mapController?.animateCamera(
                      CameraUpdate.newCameraPosition(initialPos),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ── Address inputs ────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppConstants.spaceM),
          decoration: BoxDecoration(
            color: context.background,
            border: Border(top: BorderSide(color: context.divider)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── City picker ────────────────────────────────
              Text(
                'المدينة *',
                style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary),
              ),
              const SizedBox(height: 8),
              _PickerTile(
                icon: Icons.location_city_rounded,
                hint: 'اختر المدينة',
                value: s.city.isEmpty ? null : cityArLabel(s.city),
                onTap: _showCitySheet,
              ),
              const SizedBox(height: 10),

              // ── District ───────────────────────────────────
              Text(
                'الحي (اختياري)',
                style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary),
              ),
              const SizedBox(height: 8),
              _DistrictField(
                cityEn: s.city,
                controller: _districtCtrl,
                onChanged: (v) =>
                    ref.read(addListingProvider.notifier).setDistrict(v),
              ),
              const SizedBox(height: 10),

              // ── Address ────────────────────────────────────
              Text(
                'العنوان التفصيلي (اختياري)',
                style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _addressCtrl,
                onChanged: (v) =>
                    ref.read(addListingProvider.notifier).setAddress(v),
                style: AppTextStyles.bodyMedium
                    .copyWith(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: 'مثال: شارع الملك فهد، بجانب المول',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: context.textHint),
                  prefixIcon: const Icon(Icons.location_on_rounded,
                      color: AppColors.primary, size: 20),
                  filled: true,
                  fillColor: context.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    borderSide: BorderSide(color: context.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    borderSide: BorderSide(color: context.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── FAB for map actions ───────────────────────────────────────────────────────

class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapFab({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          boxShadow: [
            BoxShadow(
              color: context.shadow,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: context.textPrimary),
      ),
    );
  }
}

// ── District field — bottom sheet if city has predefined list, text otherwise ──

class _DistrictField extends StatefulWidget {
  final String cityEn;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _DistrictField({
    required this.cityEn,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<_DistrictField> createState() => _DistrictFieldState();
}

class _DistrictFieldState extends State<_DistrictField> {
  static const _other = 'Other';
  String? _selected;

  @override
  void initState() {
    super.initState();
    _syncSelected();
  }

  @override
  void didUpdateWidget(_DistrictField old) {
    super.didUpdateWidget(old);
    if (old.cityEn != widget.cityEn) _syncSelected();
  }

  void _syncSelected() {
    final districts = districtsByCity[widget.cityEn] ?? [];
    final current = widget.controller.text;
    final match = districts.any((d) => d.en == current);
    _selected = (match && current.isNotEmpty) ? current : null;
  }

  List<DistrictEntry> get _list => districtsByCity[widget.cityEn] ?? [];

  bool get _hasDropdown => _list.isNotEmpty;

  String? get _selectedArLabel {
    if (_selected == null || _selected == _other) return null;
    final match = _list.firstWhere(
      (d) => d.en == _selected,
      orElse: () => DistrictEntry(_selected!, _selected!),
    );
    return match.ar;
  }

  void _showDistrictSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: _PickerSheet(
          title: 'اختر الحي',
          items: [
            ..._list.map((d) => _PickerItem(label: d.ar, value: d.en)),
            const _PickerItem(label: 'أخرى', value: _other),
          ],
          onSelected: (value) {
            setState(() => _selected = value);
            if (value != _other) {
              widget.controller.text = value;
              widget.onChanged(value);
            } else {
              widget.controller.clear();
              widget.onChanged('');
            }
          },
        ),
      ),
    );
  }

  InputDecoration get _inputDeco => InputDecoration(
        prefixIcon: const Icon(Icons.map_rounded,
            color: AppColors.primary, size: 20),
        filled: true,
        fillColor: context.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: context.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: context.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    if (!_hasDropdown) {
      return TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        style: AppTextStyles.bodyMedium
            .copyWith(color: context.textPrimary),
        decoration: _inputDeco.copyWith(
          hintText: 'e.g. Al Olaya',
          hintStyle: AppTextStyles.bodyMedium
              .copyWith(color: context.textHint),
        ),
      );
    }

    final showTextFallback = _selected == _other;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PickerTile(
          icon: Icons.map_rounded,
          hint: 'اختر الحي',
          value: _selectedArLabel,
          onTap: _showDistrictSheet,
        ),
        if (showTextFallback) ...[
          SizedBox(height: 8),
          TextField(
            controller: widget.controller,
            onChanged: widget.onChanged,
            autofocus: true,
            style: AppTextStyles.bodyMedium
                .copyWith(color: context.textPrimary),
            decoration: _inputDeco.copyWith(
              hintText: 'e.g. Al Murabba',
              hintStyle: AppTextStyles.bodyMedium
                  .copyWith(color: context.textHint),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Shared picker tile (looks like a filled text field) ───────────────────────

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String hint;
  final String? value;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.hint,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: context.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                hasValue ? value! : hint,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: hasValue
                      ? context.textPrimary
                      : context.textHint,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: context.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared bottom sheet picker ────────────────────────────────────────────────

class _PickerItem {
  final String label;
  final String value;
  const _PickerItem({required this.label, required this.value});
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<_PickerItem> items;
  final ValueChanged<String> onSelected;

  const _PickerSheet({
    required this.title,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Container(
          decoration: BoxDecoration(
            color: context.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: context.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: context.divider),
              // Items
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: context.divider),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onSelected(item.value);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            item.label,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: context.textPrimary),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: bottomPad),
            ],
          ),
        ),
      ),
    );
  }
}
