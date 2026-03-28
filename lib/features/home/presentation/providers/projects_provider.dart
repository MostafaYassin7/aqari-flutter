import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/project.dart';
import '../../data/listings_repository.dart';

// ── City filter (English value, same as other tabs) ───────────────────────────

class SelectedProjectCityNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? city) => state = city;
}

final selectedProjectCityProvider =
    NotifierProvider<SelectedProjectCityNotifier, String?>(
      SelectedProjectCityNotifier.new,
    );

// ── Projects async loader with server-side filters ────────────────────────────

class ProjectsNotifier extends AsyncNotifier<List<Project>> {
  final _repo = ListingsRepository();
  int _page = 1;
  bool hasMore = true;

  @override
  Future<List<Project>> build() {
    _page = 1;
    hasMore = true;
    final city = ref.watch(selectedProjectCityProvider);
    return _repo.getProjects(page: _page, limit: 20, city: city);
  }

  Future<void> loadMore() async {
    if (!hasMore) return;
    final current = state.value;
    if (current == null) return;
    _page++;
    final city = ref.read(selectedProjectCityProvider);
    final newItems = await _repo.getProjects(
      page: _page,
      limit: 20,
      city: city,
    );
    if (newItems.length < 20) hasMore = false;
    state = AsyncData([...current, ...newItems]);
  }

  Future<void> refresh() async {
    _page = 1;
    hasMore = true;
    final city = ref.read(selectedProjectCityProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.getProjects(page: _page, limit: 20, city: city),
    );
  }
}

final projectsNotifierProvider =
    AsyncNotifierProvider<ProjectsNotifier, List<Project>>(
      ProjectsNotifier.new,
    );

// ── Convenience providers ─────────────────────────────────────────────────────

final filteredProjectsProvider = Provider<List<Project>>((ref) {
  return ref
      .watch(projectsNotifierProvider)
      .when(
        data: (data) => data,
        loading: () => <Project>[],
        error: (_, __) => <Project>[],
      );
});

// ── Favorited projects ────────────────────────────────────────────────────────

class FavoritedProjectsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String id) {
    if (state.contains(id)) {
      state = Set.from(state)..remove(id);
    } else {
      state = Set.from(state)..add(id);
    }
    // Fire-and-forget API call
    ListingsRepository().toggleFavorite(targetId: id);
  }
}

final favoritedProjectsProvider =
    NotifierProvider<FavoritedProjectsNotifier, Set<String>>(
      FavoritedProjectsNotifier.new,
    );
