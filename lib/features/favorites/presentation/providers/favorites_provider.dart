import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/listing.dart';
import '../../../home/data/listings_repository.dart';

// ── Favorites async loader from API with pagination ───────────────────────────

class ApiFavoritesNotifier extends AsyncNotifier<List<Listing>> {
  final _repo = ListingsRepository();
  int _page = 1;
  bool hasMore = true;

  @override
  Future<List<Listing>> build() {
    _page = 1;
    hasMore = true;
    return _repo.getFavorites(page: _page, limit: 20);
  }

  Future<void> loadMore() async {
    if (!hasMore) return;
    final current = state.value;
    if (current == null) return;
    _page++;
    final newItems = await _repo.getFavorites(page: _page, limit: 20);
    if (newItems.length < 20) hasMore = false;
    state = AsyncData([...current, ...newItems]);
  }

  Future<void> refresh() async {
    _page = 1;
    hasMore = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.getFavorites(page: _page, limit: 20),
    );
  }
}

final apiFavoritesProvider =
    AsyncNotifierProvider<ApiFavoritesNotifier, List<Listing>>(
      ApiFavoritesNotifier.new,
    );
