import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/patient/patient_model.dart';
import 'package:frontend/services/patient_service.dart';

// ==================== PATIENT STATE ====================
class PatientListState {
  final bool loading;
  final List<Patient> patients;
  final String? error;

  PatientListState({
    this.loading = false,
    this.patients = const [],
    this.error,
  });

  PatientListState copyWith({
    bool? loading,
    List<Patient>? patients,
    String? error,
  }) {
    return PatientListState(
      loading: loading ?? this.loading,
      patients: patients ?? this.patients,
      error: error ?? this.error,
    );
  }
}

// ==================== PATIENT SERVICE PROVIDER ====================
final patientServiceProvider = Provider<PatientService>((ref) {
  return PatientService();
});

// ==================== PATIENT LIST NOTIFIER ====================
class PatientListNotifier extends StateNotifier<PatientListState> {
  final PatientService patientService;

  PatientListNotifier(this.patientService) : super(PatientListState());

  // 📥 Load all patients
  Future<void> loadPatients(String token) async {
    state = state.copyWith(loading: true);

    try {
      final patients = await patientService.getPatients(token);
      state = PatientListState(loading: false, patients: patients);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  // ➕ Insert or update a patient
  void upsertPatient(Patient updated) {
    final current = List<Patient>.from(state.patients);
    final index = current.indexWhere((p) => p.uuid == updated.uuid);

    if (index >= 0) {
      current[index] = updated;
    } else {
      current.insert(0, updated);
    }

    state = PatientListState(loading: false, patients: current);
  }

  // ❌ Remove patient by UUID
  void removePatientByUuid(String uuid) {
    final current = state.patients.where((p) => p.uuid != uuid).toList();
    state = PatientListState(loading: false, patients: current);
  }

  // 🗑️ Delete patient
  Future<void> deletePatient({
    required int patientId,
    required String token,
  }) async {
    try {
      await patientService.deletePatient(patientId: patientId, token: token);
      // Remove from local list
      removePatientByUuid(patientId.toString());
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // 🔄 Refresh patients
  Future<void> refreshPatients(String token) async {
    await loadPatients(token);
  }
}

// ==================== PATIENT LIST PROVIDER ====================
final patientListProvider =
    StateNotifierProvider<PatientListNotifier, PatientListState>((ref) {
  final patientService = ref.watch(patientServiceProvider);
  return PatientListNotifier(patientService);
});

// ==================== FILTERED PATIENTS PROVIDER ====================
final filteredPatientsProvider = Provider<List<Patient>>((ref) {
  final patientState = ref.watch(patientListProvider);
  return patientState.patients;
});

// ==================== PATIENT SEARCH PROVIDER ====================
final patientSearchProvider = StateNotifierProvider<SearchNotifier, String>((ref) {
  return SearchNotifier();
});

class SearchNotifier extends StateNotifier<String> {
  SearchNotifier() : super('');

  void updateSearch(String query) {
    state = query;
  }

  void clearSearch() {
    state = '';
  }
}

// ==================== PATIENT FILTER PROVIDER ====================
final patientFilterProvider =
    StateNotifierProvider<FilterNotifier, PatientFilter>((ref) {
  return FilterNotifier();
});

class PatientFilter {
  final String? gender;
  final String? ageRange;
  final String sortBy;

  PatientFilter({
    this.gender,
    this.ageRange,
    this.sortBy = 'newest',
  });

  PatientFilter copyWith({
    String? gender,
    String? ageRange,
    String? sortBy,
  }) {
    return PatientFilter(
      gender: gender ?? this.gender,
      ageRange: ageRange ?? this.ageRange,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class FilterNotifier extends StateNotifier<PatientFilter> {
  FilterNotifier() : super(PatientFilter());

  void updateGender(String? gender) {
    state = state.copyWith(gender: gender);
  }

  void updateAgeRange(String? ageRange) {
    state = state.copyWith(ageRange: ageRange);
  }

  void updateSort(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void resetFilter() {
    state = PatientFilter();
  }
}

// ==================== FILTERED & SEARCHED PATIENTS PROVIDER ====================
final searchedAndFilteredPatientsProvider = Provider<List<Patient>>((ref) {
  final patients = ref.watch(patientListProvider).patients;
  final searchQuery = ref.watch(patientSearchProvider);
  final filter = ref.watch(patientFilterProvider);

  var filtered = patients;

  // Apply search
  if (searchQuery.isNotEmpty) {
    filtered = filtered
        .where((p) =>
            p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            p.phoneNumber.contains(searchQuery))
        .toList();
  }

  // Apply gender filter
  if (filter.gender != null) {
    filtered = filtered.where((p) => p.gender == filter.gender).toList();
  }

  // Apply age range filter
  if (filter.ageRange != null) {
    final ageRangeParts = filter.ageRange!.split('-');
    final minAge = int.parse(ageRangeParts[0]);
    final maxAge = int.parse(ageRangeParts[1]);
    filtered = filtered
        .where((p) => p.age >= minAge && p.age <= maxAge)
        .toList();
  }

  // Apply sorting
  switch (filter.sortBy) {
    case 'nameAZ':
      filtered.sort((a, b) => a.name.compareTo(b.name));
      break;
    case 'oldest':
      filtered.sort((a, b) => a.age.compareTo(b.age));
      break;
    case 'newest':
    default:
      // Keep original order (most recent first)
      break;
  }

  return filtered;
});
