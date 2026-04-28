# Add Patient Screen - Component Architecture

## Component Hierarchy

```
AddPatientPageNew (ConsumerWidget)
│
├─ WillPopScope (Back button handling)
│  └─ Scaffold
│     │
│     ├─ SafeArea
│     │  │
│     │  ├─ _buildHeader()
│     │  │  ├─ Row (Hamburger + Title)
│     │  │  └─ Progress Bar
│     │  │     ├─ _buildProgressSegment (Step 1)
│     │  │     ├─ Divider
│     │  │     ├─ _buildProgressSegment (Step 2)
│     │  │     ├─ Divider
│     │  │     └─ _buildProgressSegment (Step 3)
│     │  │
│     │  ├─ Expanded (SingleChildScrollView)
│     │  │  └─ Conditional Step Widget
│     │  │     ├─ Step1FamilyInfo (if step == 1)
│     │  │     │  └─ _buildFormField() × 4
│     │  │     │     ├─ TextField × 2
│     │  │     │     ├─ TextArea
│     │  │     │     └─ Custom Checkbox
│     │  │     │
│     │  │     ├─ Step2PatientDetails (if step == 2)
│     │  │     │  ├─ _buildPatientTabs()
│     │  │     │  │  ├─ ElevatedButton × n patients
│     │  │     │  │  └─ Add Button (+)
│     │  │     │  │
│     │  │     │  └─ Form Card
│     │  │     │     ├─ _buildTextInput() × multiple
│     │  │     │     ├─ _buildGenderDropdown()
│     │  │     │     ├─ _buildDateInput()
│     │  │     │     ├─ _buildPregnancySection()
│     │  │     │     │  ├─ Custom Checkbox
│     │  │     │     │  ├─ Months Input
│     │  │     │     │  └─ Date Picker
│     │  │     │     ├─ _buildAddressSection()
│     │  │     │     │  ├─ Custom Checkbox
│     │  │     │     │  └─ Address TextArea
│     │  │     │     └─ Delete Button (conditional)
│     │  │     │
│     │  │     └─ Step3MedicalInfo (if step == 3)
│     │  │        ├─ _buildPatientTabs()
│     │  │        │  └─ ElevatedButton × n patients
│     │  │        │
│     │  │        └─ Form Card
│     │  │           ├─ _buildPrivacyCheckbox()
│     │  │           ├─ Warning Banner (conditional)
│     │  │           ├─ Disease Grid
│     │  │           │  └─ GestureDetector
│     │  │           │     └─ Container × 10 diseases
│     │  │           │        ├─ Icon (conditional)
│     │  │           │        └─ Text
│     │  │           ├─ Notes TextArea
│     │  │           └─ Summary container
│     │  │
│     │  └─ _buildNavigationButtons()
│     │     ├─ Error Message (conditional)
│     │     └─ Row
│     │        ├─ Back Button (ElevatedButton)
│     │        └─ Next/Save Button (ElevatedButton)
│     │
│     └─ Dialog (Loading state)
│        └─ CircularProgressIndicator
```

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│        AddPatientFormState (Riverpod)                  │
│                                                         │
│  ┌───────────────────────────────────────────────┐    │
│  │ step: 1|2|3                                  │    │
│  │ familyInfo: FamilyInfo                       │    │
│  │ patients: List<PatientDataModel>             │    │
│  │ currentPatientIndex: int                     │    │
│  │ validationErrors: Map<String, String>        │    │
│  │ isLoading: bool                              │    │
│  │ errorMessage: String                         │    │
│  └───────────────────────────────────────────────┘    │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┴───────────────┐
        │                            │
        ▼                            ▼
   ┌─────────────┐          ┌──────────────────────┐
   │ UI Widgets  │          │ AddPatientNotifier   │
   └─────────────┘          │ (StateNotifier)      │
        │                   │                      │
    Watch State             │ goToStep()           │
        │                   │ nextStep()           │
    Update UI               │ previousStep()       │
        ├─ Step 1           │                      │
        ├─ Step 2           │ updateFamilyInfo()   │
        └─ Step 3           │                      │
                            │ addPatient()         │
                            │ removePatient()      │
                            │ selectPatient()      │
                            │ updatePatient()      │
                            │                      │
                            │ toggleDisease()      │
                            │ togglePrivacy()      │
                            │ updateNotes()        │
                            │                      │
                            │ submitRegistration() │
                            └──────────────────────┘
                                    │
                                    ▼
                            ┌──────────────┐
                            │ PatientService
                            │ (Backend API)
                            └──────────────┘
```

## State Update Flow

```
User Interaction (e.g., Text Input)
│
└─→ Event Handler (onChanged, onClick, etc.)
    │
    └─→ ref.read(addPatientFormProvider.notifier).method()
        │
        └─→ AddPatientNotifier Method
            │
            ├─ Calculate new state
            ├─ Validate if needed
            └─ Call: state = state.copyWith(...)
                │
                └─→ Immutable update (Freezed)
                    │
                    └─→ Notify all watchers
                        │
                        └─→ Rebuild affected widgets
                            │
                            ├─ AddPatientPageNew
                            ├─ Step1/Step2/Step3
                            └─ Other watching widgets
```

## Widget State Flow

```
Step 1: Family Information
├─ User fills "Head of Family"
│  └─ updateFamilyInfo(headOfFamily: value)
│     └─ state = state.copyWith(familyInfo: ...)
│
├─ User clicks "Next"
│  └─ nextStep() → validation check
│     ├─ validateFamilyInfo()
│     ├─ If valid: setStep(2)
│     └─ If invalid: show errors
│
└─ Rendered UI updates


Step 2: Patient Details  
├─ User fills patient name
│  └─ updatePatient(patientName: value)
│
├─ User selects Gender
│  └─ updatePatient(gender: value)
│     └─ If not Female: isPregnant = false
│
├─ User clicks "+"
│  └─ addPatient()
│     ├─ Create new PatientDataModel
│     ├─ Append to patients list
│     └─ Set currentPatientIndex to new patient
│
├─ User clicks member tab
│  └─ selectPatient(index)
│     └─ state = state.copyWith(currentPatientIndex: index)
│
└─ User clicks "Remove"
   └─ removePatient(index)
      ├─ Filter out patient
      └─ Adjust index if needed


Step 3: Medical Information
├─ User clicks disease chip
│  └─ toggleDisease(diseaseKey)
│     └─ Update diseases map
│
├─ User toggles privacy
│  └─ togglePrivacy()
│     ├─ Set declinedHealthInfo = !current
│     └─ If true: Clear all diseases
│
├─ User types notes
│  └─ updateNotes(text)
│
└─ User clicks "Save"
   └─ submitRegistration(token)
      ├─ Validate all data
      ├─ Format payload
      ├─ Send to API
      └─ Handle response
```

## Provider Dependency Tree

```
addPatientFormProvider (StateNotifierProvider)
│
├─ Provides: AddPatientFormState
│  └─ Used by all widgets
│
├─ currentPatientProvider (Computed Provider)
│  └─ Watches: addPatientFormProvider
│  └─ Returns: PatientDataModel
│  └─ Used by: Step2, Step3 widgets
│
└─ canProceedToNextStepProvider (Computed Provider)
   └─ Watches: addPatientFormProvider
   └─ Returns: bool
   └─ Used by: Navigation button (disabled state)
```

## Form Validation Hierarchy

```
Form Validation
│
├─ Step 1: beforeNextStep() → validateFamilyInfo()
│  ├─ headOfFamily: not empty
│  ├─ numberOfMembers: numeric, >= 1
│  └─ familyAddress: not empty
│
├─ Step 2: beforeNextStep() → validatePatients()
│  └─ For each patient:
│     ├─ patientName: not empty
│     ├─ age: numeric
│     └─ dateOfBirth: not empty
│
└─ Step 3: beforeSubmit() → submitRegistration()
   └─ Auto-pass (flexible medical data)
      └─ Format and send to API
```

## Conditional Rendering Logic

```
Pregnancy Section
└─ if (currentPatient.gender == 'Female')
   └─ Show checkbox + input fields (if isPregnant)

Address Input
└─ if (!currentPatient.sameAsFamilyAddress)
   └─ Show address textarea

Disease Grid
└─ if (currentPatient.declinedHealthInfo)
   └─ Opacity 40% + IgnorePointer (disable)

Warning Banner
└─ if (currentPatient.declinedHealthInfo)
   └─ Show orange warning message

Delete Button
└─ if (state.patients.length > 1)
   └─ Show delete button

Add Patient Tab
└─ Always show (unlimited patients)
```

## Error Handling Flow

```
Form Submission
│
├─ Validation
│  ├─ If invalid: Show errors in UI
│  └─ If valid: Proceed
│
├─ API Call
│  ├─ Set isLoading = true
│  ├─ Send request
│  └─ Set isLoading = false
│
└─ Response Handling
   ├─ Success (200)
   │  ├─ Show success snackbar
   │  └─ Reset form / Navigate
   │
   └─ Error (400, 500, etc.)
      ├─ Update errorMessage
      ├─ Show error snackbar
      └─ Keep form for retry
```

## Key Component Props/Parameters

```
Step1FamilyInfo
├─ state (from watch)
├─ familyInfo (from state)
├─ errors (from state.validationErrors)
└─ ref (for updates)

Step2PatientDetails
├─ state (from watch)
├─ currentPatient (from computed provider)
├─ familyInfo (from state)
└─ ref (for updates)

Step3MedicalInfo
├─ state (from watch)
├─ currentPatient (from computed provider)
└─ ref (for updates)
```

---

This architecture ensures:
✓ Clear separation of concerns  
✓ Unidirectional data flow  
✓ Easy to test each component  
✓ Scalable and maintainable  
✓ Proper state isolation  
✓ Efficient re-rendering  
