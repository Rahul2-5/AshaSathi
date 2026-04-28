# React to Flutter Implementation Mapping

This document maps the React/Tailwind implementation from the technical documentation to the Flutter implementation.

## Architecture Mapping

| React (Documentation) | Flutter Implementation |
|---|---|
| React SPA with useState | Flutter ConsumerWidget with Riverpod StateNotifier |
| Client-side state management | AddPatientFormState with addPatientFormProvider |
| Component hierarchy | Widget hierarchy with reusable step widgets |
| Conditional rendering | if-statements in build methods |
| Event handlers | onChanged, onClick callbacks → StateNotifier methods |
| Props & state lifting | ref.watch() for accessing state, ref.read() for updates |

## State Management Mapping

### React
```jsx
const [step, setStep] = useState(1);
const [familyInfo, setFamilyInfo] = useState({...});
const [patients, setPatients] = useState([...]);

const updateFamilyInfo = (field, value) => {
  setFamilyInfo({...familyInfo, [field]: value});
};
```

### Flutter
```dart
// State in AddPatientFormState
final int step;
final FamilyInfo familyInfo;
final List<PatientDataModel> patients;

// Update in AddPatientNotifier
void updateFamilyInfo({String? headOfFamily, ...}) {
  state = state.copyWith(
    familyInfo: state.familyInfo.copyWith(headOfFamily: headOfFamily)
  );
}
```

## UI Component Mapping

### Progress Indicator

**React:**
```jsx
{/* 3 progress bars */}
<div className={step >= 1 ? 'bg-teal' : 'bg-gray'} />
<div className={step >= 2 ? 'bg-teal' : 'bg-gray'} />
<div className={step >= 3 ? 'bg-teal' : 'bg-gray'} />
```

**Flutter:**
```dart
_buildProgressSegment(
  currentStep >= 1,
  'Family',
  index: 1,
)
// Wraps in Container with Colors, Text labels
```

### Form Input

**React:**
```jsx
<input
  value={familyInfo.headOfFamily}
  onChange={(e) => setFamilyInfo({...familyInfo, headOfFamily: e.target.value})}
  className="bg-dark border-gray focus:border-teal focus:ring-teal"
/>
```

**Flutter:**
```dart
TextField(
  controller: TextEditingController(text: familyInfo.headOfFamily),
  onChanged: (value) {
    ref.read(addPatientFormProvider.notifier).updateFamilyInfo(
      headOfFamily: value,
    );
  },
  decoration: InputDecoration(
    fillColor: Color(0xFF0f1419),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade700),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF14b8a6), width: 2),
    ),
  ),
)
```

### Disease Chip Selection

**React:**
```jsx
{currentPatient.diseases.bp && (
  <CheckIcon className="checkmark-icon" />
)}
<span>BP</span>

// In onClick:
handleDiseaseToggle('bp') // Toggles in state
```

**Flutter:**
```dart
GestureDetector(
  onTap: () {
    ref.read(addPatientFormProvider.notifier).toggleDisease('bp');
  },
  child: Container(
    decoration: BoxDecoration(
      color: isSelected ? Color(0xFF14b8a6) : Color(0xFF0f1419),
      border: Border.all(color: ...),
    ),
    child: Row(
      children: [
        if (isSelected)
          Icon(Icons.check, color: Colors.white, size: 16),
        Text('BP'),
      ],
    ),
  ),
)
```

### Pregnancy Section

**React:**
```jsx
{currentPatient.gender === 'Female' && (
  <div>
    <input type="checkbox" checked={isPregnant} onChange={...} />
    {currentPatient.isPregnant && (
      <>
        <input placeholder="Months" />
        <input placeholder="Delivery date" />
      </>
    )}
  </div>
)}
```

**Flutter:**
```dart
if (currentPatient.gender == 'Female')
  Column(
    children: [
      GestureDetector(
        onTap: () {
          ref.read(addPatientFormProvider.notifier).updatePatient(
            isPregnant: !patient.isPregnant,
          );
        },
        child: Container(
          padding: ...,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFec4899)),
                  color: patient.isPregnant 
                    ? Color(0xFFec4899) 
                    : Colors.transparent,
                ),
                child: patient.isPregnant
                  ? Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
              ),
              Text('Is Pregnant?'),
            ],
          ),
        ),
      ),
      if (patient.isPregnant)
        Column(
          children: [
            _buildTextInput(...),
            _buildDateInput(...),
          ],
        ),
    ],
  ),
```

### Patient Tabs

**React:**
```jsx
{patients.map((patient, index) => (
  <button
    onClick={() => setCurrentPatientIndex(index)}
    className={currentPatientIndex === index ? 'bg-teal' : 'bg-gray'}
  >
    Member {index + 1}
  </button>
))}
<button onClick={() => addPatient()}>+ Add</button>
```

**Flutter:**
```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      ...List.generate(
        state.patients.length,
        (index) {
          final isActive = state.currentPatientIndex == index;
          return ElevatedButton(
            onPressed: () {
              ref.read(addPatientFormProvider.notifier).selectPatient(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Color(0xFF14b8a6) : Color(0xFF1f2937),
            ),
            child: Text('Member ${index + 1}'),
          );
        },
      ),
      ElevatedButton.icon(
        onPressed: () {
          ref.read(addPatientFormProvider.notifier).addPatient();
        },
        icon: Icon(Icons.add),
        label: Text('+'),
      ),
    ],
  ),
)
```

## Validation Mapping

### React
```jsx
const validateStep1 = () => {
  const canProceed = familyInfo.headOfFamily &&
                     familyInfo.numberOfMembers &&
                     familyInfo.familyAddress;
  setStep(canProceed ? 2 : 1);
};
```

### Flutter
```dart
final canProceedToNextStepProvider = Provider<bool>((ref) {
  final state = ref.watch(addPatientFormProvider);
  
  switch (state.step) {
    case 1:
      return state.familyInfo.headOfFamily.isNotEmpty &&
          state.familyInfo.numberOfMembers.isNotEmpty &&
          int.tryParse(state.familyInfo.numberOfMembers) != null &&
          int.parse(state.familyInfo.numberOfMembers) >= 1 &&
          state.familyInfo.familyAddress.isNotEmpty;
    // ... etc
  }
});
```

## Navigation Flow Mapping

### React
```jsx
// Simple state change
onClick={() => setStep(2)}

// Validation before proceed
const nextStep = () => {
  if (validateStep1()) {
    setStep(2);
  }
};
```

### Flutter
```dart
// Next button
onPressed: canProceed
  ? () => ref.read(addPatientFormProvider.notifier).nextStep()
  : null,

// In NotifierProvider.nextStep()
void nextStep() {
  if (state.step < 3) {
    final canProceed = _validateCurrentStep();
    if (canProceed) {
      state = state.copyWith(step: state.step + 1);
    }
  }
}

// Back button
onPressed: () {
  ref.read(addPatientFormProvider.notifier).previousStep();
}
```

## Conditional Logic Mapping

### React
```jsx
// Show based on gender
{currentPatient.gender === 'Female' && <PregnancySection />}

// Show based on address preference
{!currentPatient.sameAsFamilyAddress && <AddressInput />}

// Show based on patient count
{patients.length > 1 && <DeleteButton />}

// Disable based on privacy
<div className={currentPatient.declinedHealthInfo ? 'opacity-40 pointer-events-none' : ''}>
  {/* Disease grid */}
</div>
```

### Flutter
```dart
// Show based on gender
if (currentPatient.gender == 'Female')
  _buildPregnancySection(...),

// Show based on address preference
if (!currentPatient.sameAsFamilyAddress)
  _buildTextInput(...),

// Show based on patient count
if (state.patients.length > 1)
  ElevatedButton(...),

// Disable based on privacy
Opacity(
  opacity: currentPatient.declinedHealthInfo ? 0.4 : 1.0,
  child: IgnorePointer(
    ignoring: currentPatient.declinedHealthInfo,
    child: GridView(...),
  ),
)
```

## Smart Logic Mapping

### Gender Change Resets Pregnancy

**React:**
```jsx
onChange={(e) => updatePatient(index, {
  gender: e.target.value,
  isPregnant: e.target.value === 'Female' ? currentPatient.isPregnant : false
})}
```

**Flutter:**
```dart
void updatePatient({
  String? gender,
  // ...
}) {
  final currentPatient = state.patients[currentIndex];
  
  bool? newIsPregnant = isPregnant;
  if (gender != null && gender != 'Female') {
    newIsPregnant = false;
  }
  
  // Apply update
}
```

### Privacy Toggle Clears Diseases

**React:**
```jsx
onClick={() => {
  const newDeclined = !currentPatient.declinedHealthInfo;
  updatePatient({
    declinedHealthInfo: newDeclined,
    diseases: newDeclined ? {
      bp: false,
      diabetes: false,
      // ... all false
    } : currentPatient.diseases
  });
}}
```

**Flutter:**
```dart
void togglePrivacy() {
  final currentPatient = state.patients[currentIndex];
  final newDeclined = !currentPatient.declinedHealthInfo;
  
  final updatedDiseases = newDeclined
    ? currentPatient.diseases.map((k, v) => MapEntry(k, false))
    : currentPatient.diseases;
  
  final updated = currentPatient.copyWith(
    declinedHealthInfo: newDeclined,
    diseases: updatedDiseases,
  );
  
  // Apply update
}
```

## API Submission Mapping

### React
```jsx
const handleSubmit = () => {
  const payload = {
    familyInfo: {...familyInfo},
    patients: patients.map(p => ({
      ...p,
      address: p.sameAsFamilyAddress ? familyInfo.familyAddress : p.address
    }))
  };
  
  fetch('/api/families', {
    method: 'POST',
    body: JSON.stringify(payload)
  })
  .then(response => response.json())
  .then(data => alert('Success!'))
  .catch(error => alert('Error!'));
};
```

### Flutter
```dart
Future<bool> submitRegistration(String token) async {
  try {
    state = state.copyWith(isLoading: true, errorMessage: '');
    
    final resolvedPatients = state.patients.map((patient) {
      final finalAddress = patient.sameAsFamilyAddress
        ? state.familyInfo.familyAddress
        : patient.address;
      return patient.copyWith(address: finalAddress);
    }).toList();
    
    final payload = {
      'familyInfo': {...},
      'patients': resolvedPatients.map((p) => {...}).toList(),
    };
    
    final success = await _patientService.submitFamilyRegistration(
      payload,
      token,
    );
    
    if (success) {
      state = AddPatientFormState.initial();
      return true;
    } else {
      state = state.copyWith(errorMessage: 'Failed to submit');
      return false;
    }
  } catch (e) {
    state = state.copyWith(errorMessage: 'Error: ${e.toString()}');
    return false;
  } finally {
    state = state.copyWith(isLoading: false);
  }
}
```

## Color Scheme Mapping

| Element | React (Tailwind) | Flutter |
|---------|--|--|
| Primary Accent | `#14b8a6` | `Color(0xFF14b8a6)` |
| Secondary Accent | `#f97316` | `Color(0xFFF97316)` |
| Pregnancy Accent | `#ec4899` | `Color(0xFFec4899)` |
| Delete/Danger | `#ef4444` | `Color(0xFFef4444)` |
| Background | `#0f1419` | `Color(0xFF0f1419)` |
| Card Background | `#1f2937` | `Color(0xFF1f2937)` |
| Gray Border | `gray-700` | `Colors.grey.shade700` |

## Key Differences

| Aspect | React | Flutter |
|--------|-------|---------|
| **State Hook** | useState | StateNotifier + Riverpod |
| **Re-render** | Automatic on state change | Watches trigger rebuild |
| **Immutability** | Spread operator | Freezed.copyWith() |
| **Props** | Passed down tree | Watched from provider |
| **Validation** | In handlers or useEffect | Computed providers |
| **DOM Elements** | JSX tags | Widget classes |
| **Styling** | Tailwind classes | Flutter properties |
| **Date Picker** | HTML input | showDatePicker dialog |
| **Lists** | .map() in JSX | GridView/ListView builders |

## Summary

The Flutter implementation maintains the exact same:
- ✓ 3-step wizard flow
- ✓ State management structure
- ✓ Validation logic
- ✓ Conditional rendering patterns
- ✓ Multi-item management (patients)
- ✓ Smart data transformations
- ✓ API payload format
- ✓ Color scheme
- ✓ Component hierarchy

But adapted for Flutter's paradigms:
- Uses Riverpod instead of React useState
- Uses Freezed for immutable models instead of plain objects
- Uses Widgets instead of JSX components
- Uses showDatePicker instead of HTML date input
- Uses GridView instead of CSS Grid
- Uses TextEditingController pattern for inputs

---

This mapping ensures developers familiar with the React implementation can quickly understand the Flutter equivalent.
