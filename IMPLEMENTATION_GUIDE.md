# 🏥 Add Patient Wizard - Implementation Guide

## Overview

Complete production-ready implementation of a 3-step patient registration wizard for the ASHA Sathi healthcare app. Features multi-patient support, form validation, immutable state management, and Spring Boot backend integration.

---

## 📁 Project Structure

### Flutter (Frontend)

```
frontend/lib/
├── patient/
│   ├── patient_model.dart                    # Existing patient model
│   └── add_patient_models.dart              # NEW: Domain models for wizard
├── providers/
│   └── add_patient_provider.dart            # NEW: Riverpod state management
├── screens/
│   └── add_patient/
│       ├── add_patient_wizard_screen.dart   # NEW: Main wizard container
│       └── widgets/
│           ├── add_patient_step1.dart       # NEW: Family info step
│           ├── add_patient_step2.dart       # NEW: Patient details step
│           └── add_patient_step3.dart       # NEW: Medical info step
├── services/
│   └── patient_service.dart                 # UPDATED: Added family registration API
└── config/
    └── app_config.dart                      # Already exists - configure API base URL
```

### Spring Boot (Backend)

```
Backend/src/main/java/com/Rahul/AshaSathi/
├── entity/
│   ├── Family.java                          # NEW: Family entity
│   └── FamilyPatient.java                   # NEW: Patient entity
├── dto/
│   └── FamilyRegistrationDTO.java           # NEW: Request/Response DTOs
├── repository/
│   ├── FamilyRepository.java                # NEW: Family repository
│   └── FamilyPatientRepository.java         # NEW: Patient repository
├── service/
│   └── FamilyService.java                   # NEW: Business logic service
└── controller/
    └── FamilyController.java                # NEW: REST API endpoints
```

---

## 🚀 Setup Instructions

### Step 1: Update Flutter pubspec.yaml

Add these dependencies:

```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  freezed_annotation: ^2.4.0
  
dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.4.0
```

Run:
```bash
flutter pub get
dart run build_runner build
```

### Step 2: Configure API Base URL

Update `frontend/lib/config/app_config.dart`:

```dart
class AppConfig {
  static const String apiBaseUrl = 'http://your-server:8080';
  static const String patientsBaseUrl = '$apiBaseUrl/api/patients';
  // ... other config
}
```

### Step 3: Update Spring Boot Application

Ensure JPA auto-create is enabled in `application.properties`:

```properties
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
```

### Step 4: Database Initialization

The Spring Boot app will automatically create the following tables:

- `families` - Family records
- `family_patients` - Individual patient records within families

---

## 📱 UI/UX Flow

### Step 1: Family Information
- Input: Head of Family (required)
- Input: Number of Members (required, min 1)
- Input: Family Address (required)
- Checkbox: Same Address for All

✅ Validation enforced before moving to Step 2

### Step 2: Patient Details
- **Tabs**: Switch between family members
- **Add Button**: Add new family member
- **Fields per patient**:
  - Name (required)
  - Age (required)
  - DOB (required)
  - Gender (Female/Male/Other)
  - Caste
  - Phone Number
  - Address (conditional on "same address" setting)
  - Photo Upload (optional)
  - **Pregnancy Section** (Female only):
    - Months of pregnancy
    - Expected delivery date

✅ At least one patient required

### Step 3: Medical Information
- **Tabs**: Switch between patients
- **Privacy Checkbox**: Decline health info sharing
- **Disease Grid**: 10 selectable diseases
- **Notes Field**: Additional medical notes
- Disease selection disabled if privacy declined

---

## 🔄 State Management (Riverpod)

### Main Provider

```dart
final addPatientFormProvider = StateNotifierProvider<AddPatientNotifier, AddPatientFormState>
```

### State Structure

```dart
AddPatientFormState {
  int step,                          // 1, 2, or 3
  FamilyInfo familyInfo,
  List<PatientDataModel> patients,
  int currentPatientIndex,
  bool isLoading,
  String errorMessage,
  Map<String, String> validationErrors,
}
```

### Key Methods

```dart
// Navigation
notifier.nextStep()
notifier.previousStep()
notifier.goToStep(int)

// Family
notifier.updateFamilyInfo(...)

// Patients
notifier.addPatient()
notifier.removePatient(int index)
notifier.selectPatient(int index)
notifier.updatePatient(...)

// Medical
notifier.toggleDisease(String)
notifier.togglePrivacy()
notifier.updateNotes(String)

// Submission
Future<bool> submitRegistration(String token)
```

---

## 🌐 API Endpoints

### POST `/api/families`

**Request**:
```json
{
  "familyInfo": {
    "headOfFamily": "John Doe",
    "numberOfMembers": 4,
    "familyAddress": "123 Main St, Village Name"
  },
  "patients": [
    {
      "patientName": "John Doe",
      "age": 45,
      "dateOfBirth": "1978-05-15",
      "gender": "Male",
      "caste": "General",
      "address": "123 Main St, Village Name",
      "phoneNumber": "9876543210",
      "isPregnant": false,
      "monthsOfPregnancy": null,
      "expectedDeliveryDate": null,
      "photoPath": null,
      "diseases": {
        "bp": true,
        "diabetes": false,
        ...
      },
      "declinedHealthInfo": false,
      "notes": "Patient has controlled BP"
    }
  ]
}
```

**Response (201 Created)**:
```json
{
  "familyId": 1,
  "message": "Family registered successfully",
  "patientCount": 1,
  "status": "SUCCESS"
}
```

### GET `/api/families/{id}`

Retrieve family details with all associated patients.

---

## ✨ Key Features

### 1. Immutable State Updates
All state updates use immutable patterns:
```dart
state = state.copyWith(
  patients: state.patients
      .asMap()
      .entries
      .map((e) => e.key == index ? updated : e.value)
      .toList()
);
```

### 2. Conditional Rendering
- Pregnancy section shows only for Female gender
- Disease selection disabled when privacy is declined
- Delete button shows only if > 1 patient
- Address input shows only if not using family address

### 3. Form Validation
- Required field validation
- Type validation (age must be number)
- Minimum value checks
- Custom validation messages

### 4. Address Inheritance
If "same address for all" is true, all patients automatically use family address.

### 5. Disease Management
10 selectable diseases with JSON serialization to backend:
- BP
- Elephantiasis
- Diabetes
- Heart Disease
- Asthma
- Thyroid
- Arthritis
- Kidney
- Liver
- Cancer

---

## 🛠️ Integration Steps

### 1. Add to Navigation

Update your navigation service to include:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AddPatientWizardScreen(),
  ),
);
```

### 2. Handle Authentication

Update the submission call to use your auth token:
```dart
final token = ref.read(authTokenProvider); // Your auth provider
final success = await notifier.submitRegistration(token);
```

### 3. Show Success/Error

The wizard already handles:
- Loading state with overlay
- Error messages with snackbars
- Form validation errors
- Network timeouts

---

## 📝 Database Schema

### families table
```sql
CREATE TABLE families (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  head_of_family VARCHAR(255) NOT NULL,
  number_of_members INT NOT NULL,
  family_address TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### family_patients table
```sql
CREATE TABLE family_patients (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  family_id BIGINT NOT NULL,
  patient_name VARCHAR(255) NOT NULL,
  age INT NOT NULL,
  date_of_birth VARCHAR(255) NOT NULL,
  gender VARCHAR(50) NOT NULL,
  caste VARCHAR(255),
  address TEXT,
  phone_number VARCHAR(20),
  is_pregnant BOOLEAN DEFAULT false,
  months_of_pregnancy INT,
  expected_delivery_date VARCHAR(255),
  photo_path VARCHAR(500),
  diseases TEXT,
  declined_health_info BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (family_id) REFERENCES families(id) ON DELETE CASCADE
);
```

---

## 🎨 Theming

All colors are consistent with existing app theme:

```dart
Primary Accent (Teal):     #14b8a6
Secondary (Gray):         #1f2937
Background (Dark Navy):   #0f1419
Privacy Warning (Orange): #f97316
Pregnancy Accent (Pink):  #ec4899
Delete Button (Red):      #ef4444
```

---

## 🧪 Testing

### Unit Tests for State Management

```dart
test('addPatient should create new patient', () {
  final state = AddPatientFormState.initial();
  final notifier = AddPatientNotifier();
  notifier.addPatient();
  expect(notifier.state.patients.length, 2);
});

test('togglePrivacy should clear diseases', () {
  notifier.togglePrivacy();
  expect(notifier.currentPatient.diseases.values.every((v) => !v), true);
});
```

### API Testing

```bash
# Register family
curl -X POST http://localhost:8080/api/families \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d @payload.json
```

---

## 📊 Performance Considerations

- ✅ Uses immutable updates for safe state changes
- ✅ Efficient list filtering with `.where()` and `.map()`  
- ✅ Single source of truth with Riverpod
- ✅ Network call timeout (30 seconds)
- ✅ Proper error handling and user feedback

---

## 🔐 Security

- ✅ JWT token-based authentication required
- ✅ Role-based access (@PreAuthorize annotations)
- ✅ Input validation on frontend and backend
- ✅ CORS properly configured
- ✅ SQL injection prevention (JPA parameterized queries)

---

## 📞 Support

For implementation questions:

1. Check the **State Management** section
2. Review the **API Endpoints** documentation
3. Follow the **Integration Steps** guide
4. See **Database Schema** for persistence details

---

**Version**: 1.0  
**Last Updated**: April 6, 2026  
**Status**: Production Ready ✅
