# Quick Reference - Add Patient Wizard

## 🔌 Integration in Your App

### 1. Add to Navigation Routes

```dart
// In your navigation.dart or routes.dart

import 'package:frontend/screens/add_patient/add_patient_wizard_screen.dart';

class AppRoutes {
  static const String addPatient = '/add-patient';
  
  // In your route map
  static Map<String, WidgetBuilder> routes = {
    addPatient: (context) => const AddPatientWizardScreen(),
  };
}

// Or use named navigation:
Navigator.pushNamed(context, AppRoutes.addPatient);

// Or direct navigation:
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const AddPatientWizardScreen()),
);
```

### 2. Access State in Other Screens

```dart
// Watch state changes
final state = ref.watch(addPatientFormProvider);

// Get current patient
final currentPatient = ref.watch(currentPatientProvider);

// Check if can proceed
final canProceed = ref.watch(canProceedToNextStepProvider);

// Access notifier for updates
final notifier = ref.read(addPatientFormProvider.notifier);
```

### 3. Submit with Auth Token

```dart
// In your auth provider/service
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

// In wizard submission (update the token)
final token = ref.read(authProvider).token;
final success = await notifier.submitRegistration(token);
```

---

## 📝 Common Tasks

### Add a Validation Rule

1. **Update validation method** in `add_patient_provider.dart`:

```dart
bool _validateFamilyInfo() {
  final errors = <String, String>{};
  
  // ... existing validations
  
  // Add new validation
  if (state.familyInfo.numberOfMembers.contains(' ')) {
    errors['numberOfMembers'] = 'No spaces allowed';
  }
  
  state = state.copyWith(validationErrors: errors);
  return errors.isEmpty;
}
```

2. **Display error** in the step widget:

```dart
_buildInputField(
  label: 'Head of Family *',
  value: familyInfo.headOfFamily,
  onChanged: (value) {
    notifier.updateFamilyInfo(headOfFamily: value);
  },
  errorText: state.validationErrors['headOfFamily'], // Shows validation error
)
```

### Add a New Disease

1. **Update disease list** in `add_patient_step3.dart`:

```dart
static const List<Map<String, String>> diseases = [
  // ... existing diseases
  {'key': 'newDisease', 'label': 'New Disease Name'},
];
```

2. **Add to model default** in `add_patient_models.dart`:

```dart
factory PatientDataModel.empty() => PatientDataModel(
  // ... other fields
  diseases: {
    // ... existing
    'newDisease': false,
  },
)
```

### Customize Colors

1. **Find color constants** in UI widgets

2. **Update hex codes**:

```dart
// Example: Change primary color from teal to blue
const Color(0xFF14b8a6)  // Teal
const Color(0xFF0ea5e9)  // New Blue
```

---

## 🧠 State Management Patterns

### Pattern 1: Update Single Field

```dart
notifier.updatePatient(
  patientName: 'John Doe'
  // Other fields unchanged
);
```

### Pattern 2: Conditional Update

```dart
if (currentPatient.gender == 'Female') {
  notifier.updatePatient(isPregnant: true);
}
```

### Pattern 3: List Manipulation

```dart
// Add to list
notifier.addPatient();

// Remove from list
notifier.removePatient(index);

// Select specific item
notifier.selectPatient(index);
```

### Pattern 4: Complex Toggle

```dart
void toggleDisease(String disease) {
  // Reads current state
  final current = ref.read(addPatientFormProvider);
  
  // Creates new instance with updated disease
  notifier.toggleDisease(disease);
  
  // State automatically updates all listeners
}
```

---

## 🐛 Debugging

### Enable Logging

```dart
// In main.dart
import 'package:flutter/foundation.dart';

void main() {
  // Enable detailed logging
  debugPrint = (String? message, {int? wrapWidth}) {
    print('LOG: $message');
  };
  
  runApp(const MyApp());
}
```

### Print State Changes

```dart
// In provider, add debugging
class AddPatientNotifier extends StateNotifier<AddPatientFormState> {
  void updateFamilyInfo(...) {
    // ... existing code
    
    // Debug print
    debugPrint('Family info updated: ${state.familyInfo}');
    
    state = state.copyWith(...);
  }
}
```

### Watch Variables in Real-time

```dart
// In widget
@override
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(addPatientFormProvider);
  
  // Auto-triggered whenever state changes
  ref.listen(addPatientFormProvider, (previous, next) {
    if (previous?.step != next.step) {
      debugPrint('Step changed: ${previous?.step} → ${next.step}');
    }
  });
  
  return ...
}
```

---

## 🔄 Advanced: Custom Hooks

### Create a Hook for Address Resolution

```dart
extension AddressExtension on PatientDataModel {
  String getResolvedAddress(String familyAddress, bool sameAsFamily) {
    return sameAsFamily ? familyAddress : address;
  }
}

// Usage
final resolvedAddress = patient.getResolvedAddress(
  familyInfo.familyAddress,
  patient.sameAsFamilyAddress,
);
```

### Create a Hook for Validation

```dart
extension ValidationExtension on AddPatientFormState {
  bool isStep1Valid() {
    return familyInfo.headOfFamily.isNotEmpty &&
        familyInfo.numberOfMembers.isNotEmpty &&
        familyInfo.familyAddress.isNotEmpty;
  }
  
  bool isStep2Valid() {
    return patients.every((p) => p.patientName.isNotEmpty);
  }
}

// Usage
if (state.isStep1Valid()) {
  notifier.nextStep();
}
```

---

## 🌐 Backend Integration Examples

### Fetch from Backend

```dart
// Add to patient_service.dart
Future<Family> getFamilyByID(String familyId, String token) async {
  try {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/families/$familyId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return Family.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load family');
  } catch (e) {
    debugPrint('Error fetching family: $e');
    rethrow;
  }
}

// Create provider
final familyProvider = FutureProvider.family<Family, String>((ref, familyId) async {
  final service = ref.watch(patientServiceProvider);
  final token = ref.watch(authTokenProvider);
  return service.getFamilyByID(familyId, token);
});
```

### Handle Errors

```dart
Future<bool> submitWithErrorHandling(String token) async {
  try {
    final success = await submitRegistration(token);
    
    if (!success) {
      state = state.copyWith(
        errorMessage: 'Submission failed. Please try again.',
      );
      return false;
    }
    
    return true;
  } on TimeoutException {
    state = state.copyWith(
      errorMessage: 'Request timed out. Check your internet connection.',
    );
    return false;
  } on SocketException {
    state = state.copyWith(
      errorMessage: 'No internet connection.',
    );
    return false;
  } catch (e) {
    state = state.copyWith(
      errorMessage: 'Unexpected error: ${e.toString()}',
    );
    return false;
  }
}
```

---

## 📊 Performance Tips

### 1. Memoize Expensive Computations

```dart
final expensiveComputationProvider = Provider((ref) {
  final state = ref.watch(addPatientFormProvider);
  
  // This is only recomputed when state changes
  return state.patients
      .where((p) => p.isPregnant)
      .length;
});
```

### 2. Use Selector for Fine-grained Listening

```dart
// Only listen to specific field changes
final currentPatientNameProvider = Provider((ref) {
  return ref.watch(
    addPatientFormProvider.select((state) => 
      state.patients[state.currentPatientIndex].patientName
    ),
  );
});
```

### 3. Lazy Load Resources

```dart
// Load photos only when needed
if (showPhotos) {
  _loadPatientPhotos();
}
```

---

## ✅ Testing Checklist

- [ ] All form fields accept input
- [ ] Validation errors display correctly
- [ ] Can add/remove patients
- [ ] Pregnancy section shows/hides correctly
- [ ] Address inheritance works
- [ ] Privacy toggle clears diseases
- [ ] Can submit with valid data
- [ ] Error handling works
- [ ] Loading state displays
- [ ] Success message shows
- [ ] Navigator pops after success
- [ ] Back button works on each step
- [ ] Form resets after submission

---

## 📞 Troubleshooting

### Issue: "Provider not found" error

**Solution**: Ensure you're inside a `ProviderScope` widget at app root:

```dart
void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### Issue: State not updating

**Solution**: Make sure you're using `state = state.copyWith(...)` not direct assignment:

```dart
// ❌ Wrong
state.patients.add(newPatient);

// ✅ Correct
state = state.copyWith(
  patients: [...state.patients, newPatient]
);
```

### Issue: Photo not loading

**Solution**: Check AppConfig.apiBaseUrl is correct

### Issue: API returns 401 Unauthorized

**Solution**: Verify JWT token is valid and includes required scopes

---

**Next Steps**: Review IMPLEMENTATION_GUIDE.md for full documentation
