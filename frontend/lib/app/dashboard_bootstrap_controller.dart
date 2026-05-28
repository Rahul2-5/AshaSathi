import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../offline/family_sync_service.dart';
import '../offline/patient_sync_service.dart';
import '../offline/task_sync_service.dart';
import '../providers/family_provider.dart';
import '../providers/login_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/task_provider.dart';

class DashboardBootstrapState {
  final bool isBootstrapping;
  final bool isSyncing;
  final String? error;

  const DashboardBootstrapState({
    this.isBootstrapping = false,
    this.isSyncing = false,
    this.error,
  });

  DashboardBootstrapState copyWith({
    bool? isBootstrapping,
    bool? isSyncing,
    String? error,
  }) {
    return DashboardBootstrapState(
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      isSyncing: isSyncing ?? this.isSyncing,
      error: error ?? this.error,
    );
  }
}

final dashboardBootstrapProvider =
    StateNotifierProvider<DashboardBootstrapNotifier, DashboardBootstrapState>(
      DashboardBootstrapNotifier.new,
    );

class DashboardBootstrapNotifier extends StateNotifier<DashboardBootstrapState> {
  DashboardBootstrapNotifier(this.ref) : super(const DashboardBootstrapState());

  final Ref ref;

  final PatientSyncService _patientSyncService = PatientSyncService();
  final TaskSyncService _taskSyncService = TaskSyncService();
  final FamilySyncService _familySyncService = FamilySyncService();

  Future<void> bootstrapDashboard() async {
    if (state.isBootstrapping) return;
    state = state.copyWith(isBootstrapping: true, error: null);

    try {
      final token = await ref.read(loginProvider.notifier).getValidToken();
      if (token == null) {
        state = state.copyWith(isBootstrapping: false);
        return;
      }

      await Future.wait([
        ref.read(taskListProvider.notifier).loadTasks(token),
        ref.read(patientListProvider.notifier).loadPatients(token),
        ref.read(familyListProvider.notifier).loadFamilies(token),
      ]);

      await syncAll(token);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isBootstrapping: false);
    }
  }

  Future<void> syncAllIfPossible() async {
    final token = await ref.read(loginProvider.notifier).getValidToken();
    if (token == null) return;
    await syncAll(token);
  }

  Future<void> syncAll(String token) async {
    if (state.isSyncing) return;
    state = state.copyWith(isSyncing: true, error: null);

    try {
      final results = await Future.wait<Object>([
        _patientSyncService.sync(token),
        _taskSyncService.sync(token),
        _familySyncService.syncPendingFamilies(token),
      ]);

      final patientSynced = results[0] as bool;
      final taskSynced = results[1] as bool;
      final familySynced = results[2] as int;

      if (patientSynced) {
        await ref.read(patientListProvider.notifier).loadPatients(token);
      }

      if (taskSynced) {
        await ref.read(taskListProvider.notifier).loadTasks(token);
      }

      if (familySynced > 0) {
        await ref.read(familyListProvider.notifier).loadFamilies(token);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> refreshPatients() async {
    final token = await ref.read(loginProvider.notifier).getValidToken();
    if (token == null) return;
    await ref.read(patientListProvider.notifier).loadPatients(token);
  }
}