# Quick Start Guide - Add Patient Screen

## 🚀 Getting Started

### Step 1: Migration from Old Implementation

The new implementation is in `add_patient_page_new.dart`. To use it:

1. **Update your navigation routes:**

```dart
// In your main navigation file
import 'package:frontend/patient/add_patient_page_new.dart';

// Replace old route:
// MaterialPageRoute(builder: (context) => const AddPatientPage());

// With new route:
MaterialPageRoute(builder: (context) => const AddPatientPageNew());
```

2. **Update any navigation calls:**

```dart
// Old
Navigator.push(context, MaterialPageRoute(body: AddPatientPage()));

// New
Navigator.push(context, MaterialPageRoute(builder: (context) => AddPatientPageNew()));
```

### Step 2: Verify Dependencies

Ensure you have these in `pubspec.yaml`:

```yaml
dependencies:
  flutter_riverpod: ^2.0.0
  freezed_annotation: ^2.0.0
  intl: ^0.18.0

dev_dependencies:
  build_runner: ^2.0.0
  freezed: ^2.0.0
  json_serializable: ^6.0.0
```

### Step 3: Generate Code

If you haven't already, regenerate Freezed models:

```bash
# In the frontend directory
flutter pub run build_runner build
```

## 📱 Testing the Implementation

### Basic Flow Test

1. **Start the app** and navigate to Add Patient
2. **Step 1: Fill Family Info**
   - Enter family head name
   - Set number of members
   - Enter address
   - Click "Next"

3. **Step 2: Add Patient Details**
   - Fill primary patient information
   - Toggle "Is Pregnant?" if female
   - Click "+" to add another member
   - Click "Next"

4. **Step 3: Medical Information**
   - Select 2-3 diseases
   - Toggle privacy preference
   - Add notes
   - Click "Save Patient Data"

### Edge Cases to Test

```dart
// Test 1: Remove patient (should work if 2+ patients)
- Add 2 members
- Delete one
- Verify current patient auto-adjusts

// Test 2: Gender change resets pregnancy
- Step 2, Female patient
- Check "Is Pregnant?"
- Change to "Male"
- Verify pregnancy unchecked

// Test 3: Privacy toggle clears diseases
- Step 3, select diseases
- Check privacy preference
- Verify all diseases unchecked

// Test 4: Address inheritance
- Step 2, check "Same as family address"
- Uncheck and enter custom address
- Verify both options work

// Test 5: Form validation
- Try to proceed without required fields
- Verify error messages appear
```

## 🎨 UI Testing

### Color Verification

Open the UI and verify colors match:

```
Header background:        #1f2937
Form cards:              #1f2937
Input backgrounds:       #0f1419
Active buttons:          #14b8a6
Text (primary):          White
Text (secondary):        #d1d5db
Disabled opacity:        40%
```

### Responsive Design

Test on multiple screen sizes:
- Mobile (375px width)
- Tablet (600px width)
- Desktop (1024px width)

All elements should be readable and buttons accessible (48dp+ height).

## 🔗 Integration with Backend

### 1. Update PatientService

Ensure `submitFamilyRegistration` exists:

```dart
// In services/patient_service.dart
Future<bool> submitFamilyRegistration(
  Map<String, dynamic> payload,
  String token,
) async {
  // Implementation
  return true; // or false on error
}
```

### 2. Token Retrieval

Update the submit handler in `add_patient_page_new.dart`:

```dart
Future<void> _handleSubmit(
  BuildContext context,
  WidgetRef ref,
  AddPatientFormState state,
) async {
  // Replace 'your_token' with actual token from auth
  final token = ref.read(authProvider)?.token ?? '';
  
  // Rest stays the same...
}
```

### 3. API Endpoint

Ensure your backend accepts:

```
POST /api/families
Authorization: Bearer {token}
Content-Type: application/json

{
  "familyInfo": {...},
  "patients": [...]
}
```

## 📋 Success Criteria

✅ All three steps render correctly  
✅ Navigation between steps works  
✅ Add/remove patients works  
✅ Form validation prevents invalid data  
✅ Conditional fields show/hide properly  
✅ Data persists while navigating  
✅ Submit sends correct payload format  
✅ Error messages display on failure  
✅ Loading indicator shows during submission  
✅ UI matches design specifications  

## 🐛 Debugging

### Enable Debug Logging

Add this to see state changes:

```dart
// In add_patient_provider.dart, in AddPatientNotifier
@override
void addListener(VoidCallback listener) {
  super.addListener(() {
    print('State updated: ${state.step}');
    listener();
  });
}
```

### Check Form State

Print current state:

```dart
// In any widget
final state = ref.watch(addPatientFormProvider);
debugPrint('Current step: ${state.step}');
debugPrint('Patients: ${state.patients.length}');
debugPrint('Validation errors: ${state.validationErrors}');
```

## 📚 Architecture Overview

```
┌─────────────────────────────────────────┐
│    AddPatientPageNew (Main Wizard)      │
│  - Manages step navigation              │
│  - Handles submission                   │
└────────────┬────────────────────────────┘
             │
      ┌──────┴──────┐
      │ Riverpod    │
      │ Provider    │
      └──────┬──────┘
             │
  ┌──────────┼──────────┐
  │          │          │
Step1    Step2       Step3
│          │          │
└──────────┴──────────┘
         │
    ┌────┴────┐
    │ Models  │
    │(Freezed)│
    └─────────┘
```

## 🎯 Next Steps

1. **Deploy to test server**
   ```bash
   flutter run
   ```

2. **Test with real backend**
   - Update API endpoint
   - Verify token auth
   - Check payload format

3. **Monitor errors**
   - Check console logs
   - Monitor backend logs
   - Verify data in database

4. **Gather feedback**
   - UX testing
   - Performance metrics
   - Error scenarios

## 📞 Support

For issues, check:
- Form validation messages
- Network request logs
- State management debug output
- Flutter DevTools (Riverpod inspector)

## ✨ Tips

- Use `flutter run -d chrome` for web debugging
- Use DevTools for state inspection
- Check `patient_service.dart` for API calls
- Review official Riverpod docs: https://riverpod.dev
- Check Freezed docs: https://pub.dev/packages/freezed
