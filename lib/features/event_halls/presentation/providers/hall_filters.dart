import 'package:flutter_riverpod/flutter_riverpod.dart';

class HallFilters {
  final String city;
  final double? min, max, areaFrom, areaTo;
  const HallFilters({
    this.city = '',
    this.min,
    this.max,
    this.areaFrom,
    this.areaTo,
  });
}

class HallFilterNotifier extends Notifier<HallFilters> {
  @override
  HallFilters build() => const HallFilters();
  void set(HallFilters f) => state = f;
}

final hallFiltersProvider = NotifierProvider<HallFilterNotifier, HallFilters>(
  HallFilterNotifier.new,
);
