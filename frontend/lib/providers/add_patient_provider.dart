import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/patient/add_patient_models.dart';
import 'package:frontend/services/patient_service.dart';

/// ============================================
/// PROVIDERS
/// ============================================

/// Main form state provider
final addPatientFormProvider =
    StateNotifierProvider<AddPatientNotifier, AddPatientFormState>(
  (ref) => AddPatientNotifier(),
);

final lastRegisteredFamilyProvider =
    StateProvider<RegisteredFamilySnapshot?>((ref) => null);

/// Computed: Current patient
final currentPatientProvider = Provider<PatientDataModel>((ref) {
  final state = ref.watch(addPatientFormProvider);
  return state.patients[state.currentPatientIndex];
});

/// Computed: Can proceed to next step
final canProceedToNextStepProvider = Provider<bool>((ref) {
  final state = ref.watch(addPatientFormProvider);
  final requiredMembers = int.tryParse(state.familyInfo.numberOfMembers) ?? 1;
  
  switch (state.step) {
    case 1:
      return state.familyInfo.headOfFamily.isNotEmpty &&
          state.familyInfo.numberOfMembers.isNotEmpty &&
          int.tryParse(state.familyInfo.numberOfMembers) != null &&
          int.parse(state.familyInfo.numberOfMembers) >= 1 &&
          state.familyInfo.familyAddress.isNotEmpty;
    case 2:
      return state.patients.length == requiredMembers &&
          state.patients.every(
            (p) =>
                p.patientName.trim().isNotEmpty &&
                p.age.trim().isNotEmpty &&
                int.tryParse(p.age.trim()) != null &&
                p.dateOfBirth.trim().isNotEmpty,
          );
    case 3:
      return true; // Can always save from step 3
    default:
      return false;
  }
});

/// ============================================
/// STATE NOTIFIER
/// ============================================
class RegisteredFamilySnapshot {
  final FamilyInfo familyInfo;
  final List<PatientDataModel> members;

  const RegisteredFamilySnapshot({
    required this.familyInfo,
    required this.members,
  });
}

class AddPatientNotifier extends StateNotifier<AddPatientFormState> {
  final PatientService _patientService = PatientService();

  AddPatientNotifier() : super(AddPatientFormState.initial());

  String? _calculateDobFromAge(String rawAge) {
    final parsedAge = int.tryParse(rawAge.trim());
    if (parsedAge == null || parsedAge < 0 || parsedAge > 130) {
      return null;
    }

    final birthYear = DateTime.now().year - parsedAge;
    final yearText = birthYear.toString().padLeft(4, '0');
    return '$yearText-01-01';
  }

  int _targetMemberCount() {
    final parsed = int.tryParse(state.familyInfo.numberOfMembers);
    if (parsed == null || parsed < 1) {
      return 1;
    }
    return parsed;
  }

  List<PatientDataModel> _buildPatientsForCount(int count) {
    if (count <= 0) {
      return [PatientDataModel.empty()];
    }

    final current = state.patients;
    if (current.length == count) {
      return current;
    }

    if (current.length > count) {
      return current.take(count).toList();
    }

    final updated = [...current];
    for (int i = current.length; i < count; i++) {
      updated.add(PatientDataModel.empty().copyWith(id: (i + 1).toString()));
    }
    return updated;
  }

  /// ===========================================
  /// NAVIGATION
  /// ===========================================
  void goToStep(int step) {
    state = state.copyWith(step: step);
  }

  void nextStep() {
    if (state.step < 3) {
      final canProceed = _validateCurrentStep();
      if (canProceed) {
        state = state.copyWith(
          step: state.step + 1,
          errorMessage: '',
          validationErrors: {},
        );
      } else {
        if (state.step == 1) {
          state = state.copyWith(
            errorMessage:
                'Please complete all required family information fields.',
          );
        } else if (state.step == 2) {
          final requiredMembers = _targetMemberCount();
          state = state.copyWith(
            errorMessage:
                'Please complete Name, Age and Date of Birth for all $requiredMembers member(s).',
          );
        }
      }
    }
  }

  void previousStep() {
    if (state.step > 1) {
      state = state.copyWith(step: state.step - 1);
    }
  }

  /// ===========================================
  /// FAMILY INFO
  /// ===========================================
  void updateFamilyInfo({
    String? headOfFamily,
    String? numberOfMembers,
    String? familyAddress,
    bool? sameAddressForAll,
  }) {
    final nextNumberOfMembers = numberOfMembers ?? state.familyInfo.numberOfMembers;
    final parsedCount = int.tryParse(nextNumberOfMembers);
    final sanitizedCount = (parsedCount == null || parsedCount < 1) ? 1 : parsedCount;
    final updatedPatients = _buildPatientsForCount(sanitizedCount);
    var newIndex = state.currentPatientIndex;
    if (newIndex >= updatedPatients.length) {
      newIndex = updatedPatients.length - 1;
    }

    state = state.copyWith(
      familyInfo: state.familyInfo.copyWith(
        headOfFamily: headOfFamily ?? state.familyInfo.headOfFamily,
        numberOfMembers: sanitizedCount.toString(),
        familyAddress: familyAddress ?? state.familyInfo.familyAddress,
        sameAddressForAll: sameAddressForAll ?? state.familyInfo.sameAddressForAll,
      ),
      patients: updatedPatients,
      currentPatientIndex: newIndex,
    );
  }

  /// ===========================================
  /// PATIENT MANAGEMENT
  /// ===========================================
  void addPatient() {
    final maxMembers = _targetMemberCount();
    if (state.patients.length >= maxMembers) {
      return;
    }

    final newPatient = PatientDataModel.empty().copyWith(
      id: (state.patients.length + 1).toString(),
    );
    
    final updatedPatients = [...state.patients, newPatient];
    
    state = state.copyWith(
      patients: updatedPatients,
      currentPatientIndex: updatedPatients.length - 1,
    );
  }

  void removePatient(int index) {
    if (state.patients.length > 1) {
      final updatedPatients = state.patients
          .asMap()
          .entries
          .where((e) => e.key != index)
          .map((e) => e.value)
          .toList();
      
      var newIndex = state.currentPatientIndex;
      if (newIndex >= updatedPatients.length) {
        newIndex = updatedPatients.length - 1;
      }
      
      state = state.copyWith(
        patients: updatedPatients,
        currentPatientIndex: newIndex,
      );
    }
  }

  void selectPatient(int index) {
    state = state.copyWith(currentPatientIndex: index);
  }

  void updatePatient({
    String? patientName,
    String? age,
    String? dateOfBirth,
    String? gender,
    String? caste,
    String? address,
    bool? sameAsFamilyAddress,
    String? phoneNumber,
    bool? isPregnant,
    String? monthsOfPregnancy,
    String? expectedDeliveryDate,
    String? photoPath,
  }) {
    final currentIndex = state.currentPatientIndex;
    final currentPatient = state.patients[currentIndex];
    final hasExplicitDobInput = dateOfBirth != null;
    final autoDobFromAge =
      (age != null && !hasExplicitDobInput) ? _calculateDobFromAge(age) : null;
    final resolvedDob = hasExplicitDobInput
      ? dateOfBirth
      : autoDobFromAge ?? currentPatient.dateOfBirth;
    
    // Reset pregnancy if gender changed to non-Female
    bool? newIsPregnant = isPregnant;
    if (gender != null && gender != 'Female') {
      newIsPregnant = false;
    }
    
    // Reset pregnancy fields if isPregnant changed to false
    String newMonths = monthsOfPregnancy ?? currentPatient.monthsOfPregnancy;
    String newDeliveryDate = expectedDeliveryDate ?? currentPatient.expectedDeliveryDate;
    
    if (newIsPregnant == false) {
      newMonths = '1';
      newDeliveryDate = '';
    }
    
    final updated = currentPatient.copyWith(
      patientName: patientName ?? currentPatient.patientName,
      age: age ?? currentPatient.age,
      dateOfBirth: resolvedDob,
      gender: gender ?? currentPatient.gender,
      caste: caste ?? currentPatient.caste,
      address: address ?? currentPatient.address,
      sameAsFamilyAddress: sameAsFamilyAddress ?? currentPatient.sameAsFamilyAddress,
      phoneNumber: phoneNumber ?? currentPatient.phoneNumber,
      isPregnant: newIsPregnant ?? currentPatient.isPregnant,
      monthsOfPregnancy: newMonths,
      expectedDeliveryDate: newDeliveryDate,
      photoPath: photoPath ?? currentPatient.photoPath,
    );
    
    final updatedPatients = state.patients
        .asMap()
        .entries
        .map((e) => e.key == currentIndex ? updated : e.value)
        .toList();
    
    state = state.copyWith(patients: updatedPatients);
  }

  /// ===========================================
  /// MEDICAL INFO
  /// ===========================================
  void toggleDisease(String disease) {
    final currentIndex = state.currentPatientIndex;
    final currentPatient = state.patients[currentIndex];
    
    final updatedDiseases = Map<String, bool>.from(currentPatient.diseases);
    updatedDiseases[disease] = !(updatedDiseases[disease] ?? false);
    
    final updated = currentPatient.copyWith(diseases: updatedDiseases);
    
    final updatedPatients = state.patients
        .asMap()
        .entries
        .map((e) => e.key == currentIndex ? updated : e.value)
        .toList();
    
    state = state.copyWith(patients: updatedPatients);
  }

  void togglePrivacy() {
    final currentIndex = state.currentPatientIndex;
    final currentPatient = state.patients[currentIndex];
    
    final newDeclined = !currentPatient.declinedHealthInfo;
    
    // Clear diseases if declining
    final updatedDiseases = newDeclined
        ? currentPatient.diseases.map((k, v) => MapEntry(k, false))
        : currentPatient.diseases;
    
    final updated = currentPatient.copyWith(
      declinedHealthInfo: newDeclined,
      diseases: updatedDiseases,
    );
    
    final updatedPatients = state.patients
        .asMap()
        .entries
        .map((e) => e.key == currentIndex ? updated : e.value)
        .toList();
    
    state = state.copyWith(patients: updatedPatients);
  }

  void updateNotes(String notes) {
    final currentIndex = state.currentPatientIndex;
    final currentPatient = state.patients[currentIndex];
    
    final updated = currentPatient.copyWith(notes: notes);
    
    final updatedPatients = state.patients
        .asMap()
        .entries
        .map((e) => e.key == currentIndex ? updated : e.value)
        .toList();
    
    state = state.copyWith(patients: updatedPatients);
  }

  /// ===========================================
  /// VALIDATION HELPERS
  /// ===========================================
  String? _validateHeadOfFamily(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Head of family name is required';
    if (v.length < 2) return 'Name must be at least 2 characters';
    if (v.length > 100) return 'Name cannot exceed 100 characters';
    return null;
  }

  String? _validateNumberOfMembers(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Number of members is required';
    final num = int.tryParse(v);
    if (num == null || num < 1 || num > 20) {
      return 'Family size must be between 1 and 20';
    }
    return null;
  }

  String? _validateFamilyAddress(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Family address is required';
    if (v.length < 5) return 'Address must be at least 5 characters';
    if (v.length > 500) return 'Address is too long';
    return null;
  }

  String? _validatePatientName(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Patient name is required';
    if (v.length < 2) return 'Name must be at least 2 characters';
    if (v.length > 100) return 'Name cannot exceed 100 characters';
    if (!RegExp(r'^[a-zA-Z\s]').hasMatch(v)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  String? _validateAge(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Age is required';
    
    final age = int.tryParse(v);
    if (age == null) return 'Please enter a valid number for age';
    
    // Validate realistic age limits
    if (age < 0) {
      return 'Age cannot be negative';
    }
    
    if (age > 150) {
      return 'Age seems too high. Please verify (max 150)';
    }
    
    // Warn for unlikely but possible ages
    if (age > 130) {
      return 'Age is over 130. Please verify this is correct';
    }
    
    // Age 0 is valid (newborns)
    return null;
  }

  String? _validateDateOfBirth(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Date of birth is required';
    final parsed = DateTime.tryParse(v);
    if (parsed == null) return 'Invalid date format';
    if (parsed.isAfter(DateTime.now())) return 'Date of birth cannot be in the future';
    return null;
  }

  String? _validatePhone(String value) {
    final v = value.trim();
    if (v.isEmpty) return null; // Phone is optional
    if (!RegExp(r'^\d{10}$').hasMatch(v)) {
      return 'Phone must be exactly 10 digits';
    }
    return null;
  }

  String? _validateAddress(String value) {
    final v = value.trim();
    if (v.isEmpty) return null; // Optional when using family address
    if (v.length < 5) return 'Address must be at least 5 characters';
    if (v.length > 500) return 'Address is too long';
    return null;
  }

  String? _validateMonthsOfPregnancy(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Months of pregnancy is required';
    final months = int.tryParse(v);
    if (months == null || months < 1 || months > 9) {
      return 'Months must be between 1 and 9';
    }
    return null;
  }

  String? _validateExpectedDeliveryDate(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Expected delivery date is required';
    final parsed = DateTime.tryParse(v);
    if (parsed == null) return 'Invalid date format';
    if (parsed.isBefore(DateTime.now())) {
      return 'Expected delivery date must be in the future';
    }
    return null;
  }

  /// ===========================================
  /// VALIDATION & SUBMISSION
  /// ===========================================
  bool _validateCurrentStep() {
    switch (state.step) {
      case 1:
        return _validateFamilyInfo();
      case 2:
        return _validatePatients();
      case 3:
        return true;
      default:
        return false;
    }
  }

  bool _validateFamilyInfo() {
    final errors = <String, String>{};
    
    final headOfFamilyError = _validateHeadOfFamily(state.familyInfo.headOfFamily);
    if (headOfFamilyError != null) errors['headOfFamily'] = headOfFamilyError;
    
    final numMembersError = _validateNumberOfMembers(state.familyInfo.numberOfMembers);
    if (numMembersError != null) errors['numberOfMembers'] = numMembersError;
    
    final addressError = _validateFamilyAddress(state.familyInfo.familyAddress);
    if (addressError != null) errors['familyAddress'] = addressError;
    
    state = state.copyWith(
      validationErrors: errors,
      errorMessage: errors.isEmpty
          ? ''
          : 'Please complete all required family information fields.',
    );
    return errors.isEmpty;
  }

  bool _validatePatients() {
    final errors = <String, String>{};
    final requiredMembers = _targetMemberCount();

    if (state.patients.length != requiredMembers) {
      errors['patients_count'] =
          'Please add details for all $requiredMembers family members';
    }
    
    for (int i = 0; i < state.patients.length; i++) {
      final patient = state.patients[i];
      
      final nameError = _validatePatientName(patient.patientName);
      if (nameError != null) errors['patient_${i}_name'] = nameError;
      
      final ageError = _validateAge(patient.age);
      if (ageError != null) errors['patient_${i}_age'] = ageError;
      
      final dobError = _validateDateOfBirth(patient.dateOfBirth);
      if (dobError != null) errors['patient_${i}_dob'] = dobError;
      
      // Phone validation only if family uses individual addresses
      if (!state.familyInfo.sameAddressForAll) {
        final addressError = _validateAddress(patient.address);
        if (addressError != null) errors['patient_${i}_address'] = addressError;
      }

      // Phone number validation
      final phoneError = _validatePhone(patient.phoneNumber);
      if (phoneError != null) errors['patient_${i}_phone'] = phoneError;
      
      // Pregnancy field validation
      if (patient.isPregnant) {
        final monthsError = _validateMonthsOfPregnancy(patient.monthsOfPregnancy);
        if (monthsError != null) errors['patient_${i}_months'] = monthsError;
        
        final deliveryDateError = _validateExpectedDeliveryDate(patient.expectedDeliveryDate);
        if (deliveryDateError != null) errors['patient_${i}_delivery'] = deliveryDateError;
      }
    }
    
    state = state.copyWith(
      validationErrors: errors,
      errorMessage: errors.isEmpty
          ? ''
          : 'Please complete all required fields correctly.',
    );
    return errors.isEmpty;
  }

  Future<bool> submitRegistration(String token) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: '');
      
      // Resolve addresses for patients
      final resolvedPatients = state.patients.map((patient) {
        final finalAddress = patient.sameAsFamilyAddress
            ? state.familyInfo.familyAddress
            : patient.address;
        
        return patient.copyWith(address: finalAddress);
      }).toList();
      
      // Format payload
      final payload = {
        'familyInfo': {
          'headOfFamily': state.familyInfo.headOfFamily,
          'numberOfMembers': int.parse(state.familyInfo.numberOfMembers),
          'familyAddress': state.familyInfo.familyAddress,
        },
        'patients': resolvedPatients
            .map((p) => <String, dynamic>{
              'patientName': p.patientName,
              'age': int.parse(p.age),
              'dateOfBirth': p.dateOfBirth,
              'gender': p.gender,
              'caste': p.caste,
              'address': p.address,
              'phoneNumber': p.phoneNumber,
              'isPregnant': p.isPregnant,
              'monthsOfPregnancy':
                  p.isPregnant ? int.parse(p.monthsOfPregnancy) : null,
              'expectedDeliveryDate':
                  p.isPregnant ? p.expectedDeliveryDate : null,
              'photoPath': p.photoPath,
              'diseases': p.diseases,
              'declinedHealthInfo': p.declinedHealthInfo,
              'notes': p.notes,
            })
            .toList(),
      };
      
      // Submit to backend
      final success = await _patientService.submitFamilyRegistration(
        payload,
        token,
      );
      
      if (success) {
        _lastRegisteredFamily = RegisteredFamilySnapshot(
          familyInfo: state.familyInfo,
          members: resolvedPatients,
        );

        // Reset form
        state = AddPatientFormState.initial();
        return true;
      } else {
        state = state.copyWith(
          errorMessage: 'Failed to submit registration. Please try again.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error: ${e.toString()}',
      );
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: '');
  }

  void reset() {
    state = AddPatientFormState.initial();
  }

  RegisteredFamilySnapshot? _lastRegisteredFamily;

  RegisteredFamilySnapshot? consumeLastRegisteredFamily() {
    return _lastRegisteredFamily;
  }
}
