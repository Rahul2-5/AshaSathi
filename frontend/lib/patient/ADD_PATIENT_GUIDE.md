# Add Patient Screen - Implementation Guide

Following the ASHA Healthcare App Technical Documentation, this is a complete 3-step wizard implementation in Flutter.

## Overview

The Add Patient Screen is a multi-step form wizard that collects patient registration data in three stages:

1. **Step 1: Family Information** - Collect family-level data
2. **Step 2: Patient Details** - Manage multiple family members
3. **Step 3: Medical Information** - Record health conditions and preferences

## File Structure

```
frontend/lib/patient/
├── add_patient_page_new.dart          # Main wizard component
├── add_patient_models.dart            # Freezed data models
├── add_patient_models.freezed.dart    # Generated Freezed code
├── add_patient_models.g.dart          # Generated JSON serialization
└── widgets/
    ├── step1_family_info.dart         # Family information form
    ├── step2_patient_details.dart     # Patient management form
    └── step3_medical_info.dart        # Medical information form

frontend/lib/providers/
└── add_patient_provider.dart          # Riverpod state management
```

## Data Models

### FamilyInfo
```dart
FamilyInfo(
  headOfFamily: String,           // Head of family name
  numberOfMembers: String,        // Total family members
  familyAddress: String,          // Family address
  sameAddressForAll: bool,        // Use address for all members
)
```

### PatientDataModel
```dart
PatientDataModel(
  id: String,                     // Unique patient ID
  patientName: String,            // Patient full name
  age: String,                    // Age in years
  dateOfBirth: String,            // Birth date (YYYY-MM-DD)
  gender: String,                 // Female/Male/Other
  caste: String,                  // Caste information
  address: String,                // Patient address
  sameAsFamilyAddress: bool,      // Use family address
  phoneNumber: String,            // Contact number
  
  // Pregnancy fields (Female only)
  isPregnant: bool,               // Pregnancy status
  monthsOfPregnancy: String,      // Months (1-9)
  expectedDeliveryDate: String,   // Expected delivery date
  
  // Medical information
  diseases: Map<String, bool>,    // Disease selection flags
  declinedHealthInfo: bool,       // Privacy preference
  notes: String,                  // Additional notes
)
```

### AddPatientFormState
Manages the complete wizard state with validation and error tracking.

## State Management (Riverpod)

### Main Provider
```dart
final addPatientFormProvider = StateNotifierProvider<AddPatientNotifier, AddPatientFormState>
```

### Computed Providers
```dart
// Current patient being edited
final currentPatientProvider = Provider<PatientDataModel>

// Check if can proceed to next step
final canProceedToNextStepProvider = Provider<bool>
```

### Key Methods

**Navigation:**
- `nextStep()` - Proceed to next step with validation
- `previousStep()` - Go back to previous step
- `goToStep(int)` - Jump to specific step

**Family Info:**
- `updateFamilyInfo({...})` - Update family data

**Patient Management:**
- `addPatient()` - Add new family member
- `removePatient(index)` - Remove patient (min 1 required)
- `selectPatient(index)` - Switch active patient
- `updatePatient({...})` - Update patient fields

**Medical Info:**
- `toggleDisease(disease)` - Toggle disease selection
- `togglePrivacy()` - Toggle privacy preference (clears diseases)
- `updateNotes(notes)` - Update medical notes

**Submission:**
- `submitRegistration(token)` - Submit all data to backend

## UI Components

### Step 1: Family Information
- Head of Family name input
- Number of Members input
- Family Address textarea
- Same Address for All checkbox
- Form validation with error messages

### Step 2: Patient Details
- **Patient Manager:**
  - Tabs to switch between patients
  - + Button to add new patient
  
- **Patient Form:**
  - Patient Name input
  - Age + Gender (row layout)
  - Date of Birth (date picker)
  - **Pregnancy Section** (Female only):
    - Is Pregnant? checkbox
    - Months of Pregnancy input
    - Expected Delivery Date picker
  - Caste input
  - **Address Section:**
    - Same as family address checkbox
    - Individual address input (conditional)
  - Phone Number input
  - Delete button (if 2+ patients)

### Step 3: Medical Information
- **Patient Selector:** Tabs to switch between patients
- **Privacy Preference:**
  - "Patient prefers not to share" checkbox
  - Warning banner when declined
- **Disease Selection Grid:**
  - 10 diseases in 2-column grid:
    - BP, Elephantiasis, Diabetes, Heart Disease
    - Asthma, Thyroid, Arthritis, Kidney
    - Liver, Cancer
  - Select/deselect with visual feedback
  - Grayed out when privacy declined
- **Notes Textarea:** Additional medical notes
- **Summary Section:** Shows selection count and status

## Features

### Multi-Patient Management
- Add/remove family members
- Switch between patients with tabs
- Auto-select newly added patient
- Prevent deletion of last patient
- Default patient has basic template

### Conditional Rendering
- Pregnancy section only for Female gender
- Address input hidden if using family address
- Delete button hidden if only 1 patient
- Disease grid disabled if privacy declined

### Data Validation
Step 1 (Family Info):
- Head of family: Required
- Number of members: Required, minimum 1
- Family address: Required

Step 2 (Patient Details):
- Patient name: Required for all
- Age: Required, must be numeric
- Date of birth: Required

Step 3 (Medical Info):
- No required fields (optional health data)

### Smart Logic
- Gender change resets pregnancy fields
- Privacy toggle clears disease selections
- Proper address resolution (family vs individual)
- Integer parsing for numeric fields
- State immutability throughout

## Color Scheme (Based on Documentation)

```dart
Primary Accent (Active):      #14b8a6 (Teal)
Secondary Accent (Error):     #f97316 (Orange)
Pregnancy Accent:             #ec4899 (Pink)
Delete/Danger:                #ef4444 (Red)
Background Primary:           #0f1419 (Dark Navy)
Card Background:              #1f2937 (Dark Gray)
Border Color:                 Gray 700
Loading Overlay:              Transparent dark
```

## Navigation Integration

To integrate with your app's navigation:

```dart
// In your navigation setup
MaterialPageRoute(
  builder: (context) => const AddPatientPageNew(),
)

// Or with named routes
Navigator.pushNamed(context, '/add-patient');
```

## API Integration

The wizard collects data according to this structure:

```json
{
  "familyInfo": {
    "headOfFamily": "string",
    "numberOfMembers": number,
    "familyAddress": "string"
  },
  "patients": [
    {
      "patientName": "string",
      "age": number,
      "dateOfBirth": "YYYY-MM-DD",
      "gender": "Female|Male|Other",
      "caste": "string",
      "address": "string",
      "phoneNumber": "string",
      "isPregnant": boolean,
      "monthsOfPregnancy": number | null,
      "expectedDeliveryDate": "string" | null,
      "diseases": {
        "bp": boolean,
        "elephantiasis": boolean,
        // ... etc
      },
      "declinedHealthInfo": boolean,
      "notes": "string"
    }
  ]
}
```

## Error Handling

- Form validation shows errors per field
- Network errors shown in custom dialog
- Success/failure snackbars with feedback
- Loading state prevents duplicate submissions

## Best Practices Implemented

✓ Immutable state with Freezed  
✓ Proper state management with Riverpod  
✓ Unidirectional data flow  
✓ Conditional rendering based on state  
✓ Input validation before progression  
✓ Responsive grid layout  
✓ Touch-friendly button sizing (48+ dp)  
✓ Clear visual hierarchy  
✓ Dark mode support  
✓ Accessibility considerations  

## Testing Checklist

- [ ] Step 1: Can fill family info and proceed
- [ ] Step 2: Can add/remove patients
- [ ] Step 2: Pregnancy section appears for females
- [ ] Step 2: Delete button works (2+ patients)
- [ ] Step 3: Disease selection works
- [ ] Step 3: Privacy toggle clears diseases
- [ ] Step 3: Notes field updates
- [ ] Navigation: Back button works at each step
- [ ] Validation: Cannot proceed with empty required fields
- [ ] Submission: Data formats correctly for API
- [ ] UI: All colors match design spec
- [ ] UI: Responsive on different screen sizes

## Future Enhancements

- [ ] Photo upload for patient
- [ ] Offline data persistence
- [ ] Form autosave drafts
- [ ] Undo/redo functionality
- [ ] Multi-language support
- [ ] Print patient summary
- [ ] QR code generation for patient ID
