import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/project.dart';
import '../../data/listings_repository.dart';

// ── City chips ────────────────────────────────────────────────────────────────

const List<String> projectCities = [
  'الكل',
  'الرياض',
  'جدة',
  'مكة',
  'نيوم',
  'الدمام',
  'العُلا',
];

class SelectedProjectCityNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final selectedProjectCityProvider =
    NotifierProvider<SelectedProjectCityNotifier, int>(
        SelectedProjectCityNotifier.new);

// ── Projects async loader ─────────────────────────────────────────────────────

class ProjectsNotifier extends AsyncNotifier<List<Project>> {
  final _repo = ListingsRepository();

  @override
  Future<List<Project>> build() => _repo.getProjects();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getProjects());
  }
}

final projectsNotifierProvider =
    AsyncNotifierProvider<ProjectsNotifier, List<Project>>(
        ProjectsNotifier.new);

// ── Filtered projects (synchronous, derived from async state) ─────────────────

final filteredProjectsProvider = Provider<List<Project>>((ref) {
  final idx = ref.watch(selectedProjectCityProvider);
  final projects = ref.watch(projectsNotifierProvider).when(
    data: (data) => data,
    loading: () => <Project>[],
    error: (_, __) => <Project>[],
  );
  if (idx == 0) return projects;
  final city = projectCities[idx];
  return projects.where((p) => p.city == city).toList();
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
  }
}

final favoritedProjectsProvider =
    NotifierProvider<FavoritedProjectsNotifier, Set<String>>(
        FavoritedProjectsNotifier.new);
