import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../patient/family_model.dart';
import '../services/patient_service.dart';

class FamilyListState {
  final bool loading;
  final List<FamilyRecord> families;
  final String? error;

  FamilyListState({
    this.loading = false,
    this.families = const [],
    this.error,
  });

  FamilyListState copyWith({
    bool? loading,
    List<FamilyRecord>? families,
    String? error,
  }) {
    return FamilyListState(
      loading: loading ?? this.loading,
      families: families ?? this.families,
      error: error ?? this.error,
    );
  }
}

final familyListProvider =
    StateNotifierProvider<FamilyListNotifier, FamilyListState>((ref) {
  final patientService = ref.watch(familyPatientServiceProvider);
  return FamilyListNotifier(patientService);
});

final familyPatientServiceProvider = Provider<PatientService>((ref) {
  return PatientService();
});

class FamilyListNotifier extends StateNotifier<FamilyListState> {
  final PatientService patientService;

  FamilyListNotifier(this.patientService) : super(FamilyListState());

  // 📥 Initialize: Service handles offline caching automatically
  // Calling this routes through the service which loads cached + pending families if offline
  Future<void> initialize(String token) async {
    await loadFamilies(token);
  }

  // 📥 Load all families (service handles offline logic)
  Future<void> loadFamilies(String token) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final families = await patientService.getFamilies(token);
      state = FamilyListState(loading: false, families: families);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> deleteFamily({
    required int familyId,
    required String token,
  }) async {
    final previous = state.families;
    state = state.copyWith(
      families: previous.where((family) => family.id != familyId).toList(),
      error: null,
    );

    final success = await patientService.deleteFamily(
      familyId: familyId,
      token: token,
    );

    if (!success) {
      state = state.copyWith(
        families: previous,
        error: 'Failed to delete family.',
      );
      return false;
    }

    return true;
  }
}
