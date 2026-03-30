import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/project.dart';
import '../../../home/data/listings_repository.dart';

class ProjectDetailsNotifier extends Notifier<AsyncValue<Project>> {
  final _repo = ListingsRepository();

  @override
  AsyncValue<Project> build() => const AsyncLoading();

  Future<void> load(String projectId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getProjectById(projectId));
  }
}

final projectDetailsProvider =
    NotifierProvider<ProjectDetailsNotifier, AsyncValue<Project>>(
  ProjectDetailsNotifier.new,
);
