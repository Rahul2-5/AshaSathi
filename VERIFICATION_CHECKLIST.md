# ✅ Integration Verification Checklist

Use this checklist to verify that everything is integrated correctly.

---

## 🔧 Prerequisites Setup

- [ ] Android Studio / VS Code with Flutter plugin installed
- [ ] Java 21+ installed for Spring Boot
- [ ] Maven 3.8+ installed
- [ ] Flutter SDK (latest stable)
- [ ] Git initialized for version control

---

## 📦 Dependency Installation

### Flutter
- [ ] Run `flutter pub get`
- [ ] Run `dart run build_runner build`
- [ ] No build_runner errors
- [ ] All dependencies resolved in pubspec.yaml

### Spring Boot
- [ ] `pom.xml` has JPA dependency
- [ ] `pom.xml` has Lombok dependency
- [ ] `pom.xml` has SQLite JDBC driver
- [ ] Run `mvn clean install` (no errors)

---

## 🗂️ File Verification

### Flutter Files Exist
- [ ] `frontend/lib/patient/add_patient_models.dart`
- [ ] `frontend/lib/providers/add_patient_provider.dart`
- [ ] `frontend/lib/screens/add_patient/add_patient_wizard_screen.dart`
- [ ] `frontend/lib/screens/add_patient/widgets/add_patient_step1.dart`
- [ ] `frontend/lib/screens/add_patient/widgets/add_patient_step2.dart`
- [ ] `frontend/lib/screens/add_patient/widgets/add_patient_step3.dart`
- [ ] `frontend/lib/services/patient_service.dart` (UPDATED)

### Spring Boot Files Exist
- [ ] `Backend/src/main/java/.../entity/Family.java`
- [ ] `Backend/src/main/java/.../entity/FamilyPatient.java`
- [ ] `Backend/src/main/java/.../dto/FamilyRegistrationDTO.java`
- [ ] `Backend/src/main/java/.../repository/FamilyRepository.java`
- [ ] `Backend/src/main/java/.../repository/FamilyPatientRepository.java`
- [ ] `Backend/src/main/java/.../service/FamilyService.java`
- [ ] `Backend/src/main/java/.../controller/FamilyController.java`

### Documentation Files Exist
- [ ] `IMPLEMENTATION_GUIDE.md`
- [ ] `DEPENDENCIES.md`
- [ ] `QUICK_REFERENCE.md`
- [ ] `IMPLEMENTATION_SUMMARY.md`

---

## 🔧 Configuration

### Flutter Configuration
- [ ] `app_config.dart` has correct `apiBaseUrl`
- [ ] `app_config.dart` has correct `patientsBaseUrl`
- [ ] Example: `http://localhost:8080` or your server URL

### Spring Boot Configuration
- [ ] `application.properties` updated with JPA settings
- [ ] SQLite database connection configured
- [ ] Logging level set appropriately
- [ ] CORS enabled for Flutter app domain

```properties
# Check these are present:
spring.jpa.hibernate.ddl-auto=update
spring.datasource.driver-class-name=org.sqlite.JDBC
```

---

## 🏗️ Build Verification

### Flutter Build
```bash
cd frontend
flutter pub get
dart run build_runner build
flutter analyze
```

Verify:
- [ ] No pub get errors
- [ ] No build_runner errors
- [ ] No analyzer warnings (related to our code)
- [ ] `add_patient_models.freezed.dart` generated
- [ ] `add_patient_models.g.dart` generated

### Spring Boot Build
```bash
cd Backend
mvn clean install -DskipTests
```

Verify:
- [ ] Build SUCCESS [100%]
- [ ] No compilation errors
- [ ] All dependencies downloaded
- [ ] JAR file created in target/

---

## 🚀 Runtime Verification

### Start Spring Boot Backend
```bash
cd Backend
mvn spring-boot:run
```

Verify:
- [ ] Application starts without errors
- [ ] Logs show "Started AshaSathi in X seconds"
- [ ] No security configuration errors
- [ ] Tomcat server listening on port 8080
- [ ] Database tables created (check with SQLite browser)

### Run Flutter App
```bash
cd frontend
flutter run
```

Verify:
- [ ] App launches without crashes
- [ ] No null pointer exceptions
- [ ] No missing imports
- [ ] Riverpod providers initialize
- [ ] No layout errors

---

## 🎯 Feature Testing

### Navigation
- [ ] Can open Add Patient Wizard screen
- [ ] Back button works from any step
- [ ] Progress indicator updates correctly
- [ ] Step numbers show (1/2/3)

### Step 1: Family Info
- [ ] Can type in "Head of Family" field
- [ ] Can type in "Number of Members" field
- [ ] Can type in "Family Address" field
- [ ] Checkbox toggles on click
- [ ] "Next" button enables with data
- [ ] Validation error shows for empty fields
- [ ] Cannot proceed without required fields

### Step 2: Patient Details
- [ ] Member tabs show correct count
- [ ] "+ Add" button creates new member
- [ ] Can switch between members via tabs
- [ ] All input fields accept text
- [ ] Pregnancy section shows for Female only
- [ ] Pregnancy section hides for Male
- [ ] Address field hidden when using family address
- [ ] Remove button shows only with 2+ patients
- [ ] Cannot delete when 1 patient remains

### Step 3: Medical Info
- [ ] Member tabs visible
- [ ] Privacy checkbox toggles
- [ ] Privacy warning banner shows when checked
- [ ] Disease chips are clickable
- [ ] Disease chips change color when selected
- [ ] Disease chips disabled when privacy checked
- [ ] Notes field accepts text

### Form Submission
- [ ] "Save Patient Data" button is tappable
- [ ] Loading overlay shows during submission
- [ ] Success message displays on 201 response
- [ ] Form resets after success
- [ ] Navigator pops after success
- [ ] Error message shows on failure
- [ ] Can retry after failure

---

## 🔌 API Testing

### Backend Health Check
```bash
curl http://localhost:8080/api/families/health
```
Expected: `"Family API is running"`

### Submit Family Registration
```bash
curl -X POST http://localhost:8080/api/families \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "familyInfo": {
      "headOfFamily": "John Doe",
      "numberOfMembers": 1,
      "familyAddress": "123 Main St"
    },
    "patients": [{
      "patientName": "John Doe",
      "age": 45,
      "dateOfBirth": "1978-05-15",
      "gender": "Male",
      "caste": "General",
      "address": "123 Main St",
      "phoneNumber": "9876543210",
      "isPregnant": false,
      "diseases": {"bp": false, "diabetes": false},
      "declinedHealthInfo": false,
      "notes": ""
    }]
  }'
```

Verify:
- [ ] Response status 201 Created
- [ ] Response includes familyId
- [ ] Response status is "SUCCESS"
- [ ] Family created in database
- [ ] Patient records created

### Get Family Details
```bash
curl http://localhost:8080/api/families/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

Verify:
- [ ] Response 200 OK
- [ ] Includes family information
- [ ] Includes patient list

---

## 🔐 Security Testing

- [ ] API returns 401 without token
- [ ] Invalid token rejected
- [ ] Expired token rejected
- [ ] Only authorized roles can access
- [ ] SQL injection attempts blocked
- [ ] XSS payloads handled safely
- [ ] CORS headers present

---

## 🗄️ Database Verification

### Check Tables Created
Using SQLite Browser or SQLite CLI:

```sql
-- List all tables
.tables

-- Check families table
PRAGMA table_info(families);
PRAGMA table_info(family_patients);

-- Insert test data
INSERT INTO families (head_of_family, number_of_members, family_address)
VALUES ('Test Family', 1, 'Test Address');

-- Verify data
SELECT * FROM families;
SELECT * FROM family_patients;
```

Verify:
- [ ] `families` table exists with correct columns
- [ ] `family_patients` table exists with correct columns
- [ ] Timestamps are set correctly
- [ ] Foreign key relationship works
- [ ] Data persists after app restart

---

## 📊 Performance Testing

- [ ] App doesn't lag when scrolling Step 2/3
- [ ] Disease selection responds immediately
- [ ] Tab switching is smooth
- [ ] Form submission completes in < 5 seconds
- [ ] No memory leaks when adding/removing patients
- [ ] All images load without delay

---

## 🐛 Error Handling Testing

### Network Errors
- [ ] Display appropriate message when offline
- [ ] Handle timeout gracefully
- [ ] Show retry option after failure
- [ ] Maintain form data on network error

### Form Errors
- [ ] Validation errors clear when user fixes
- [ ] Multiple validation errors show simultaneously
- [ ] Error text is readable and helpful
- [ ] Required field indicators are clear

### Server Errors
- [ ] 500 error shows friendly message
- [ ] Duplicate submission prevented
- [ ] No data loss on error

---

## 🎨 UI/UX Testing

- [ ] Colors match design specification
- [ ] Text is legible on all backgrounds
- [ ] Tap targets > 44px (accessibility)
- [ ] No text overflow in labels
- [ ] Input fields have proper spacing
- [ ] Progress indicator updates visually
- [ ] Loading state is apparent
- [ ] Success/error states are clear

---

## 📱 Responsive Testing

Test on different devices:

- [ ] Mobile portrait (375x667)
- [ ] Mobile landscape
- [ ] Tablet (600x800)
- [ ] Large tablet (1000x1200)

Verify:
- [ ] Layout adapts properly
- [ ] No horizontal scrolling
- [ ] Text remainsreadable
- [ ] Buttons are still tappable
- [ ] Images scale appropriately

---

## 🔄 Data Flow Testing

### Complete Registration Flow
1. [ ] Start at Step 1
2. [ ] Fill family info
3. [ ] Move to Step 2
4. [ ] Fill patient info
5. [ ] Add additional patient
6. [ ] Move to Step 3
7. [ ] Fill medical info
8. [ ] Submit form
9. [ ] See success message
10. [ ] Verify data in backend database

---

## 📚 Documentation Check

- [ ] IMPLEMENTATION_GUIDE.md is clear
- [ ] Code comments explain complex logic
- [ ] API endpoints documented
- [ ] Database schema documented
- [ ] Configuration instructions present
- [ ] Error scenarios documented
- [ ] No broken links in docs

---

## 🚀 Go-Live Checklist

Before deploying to production:

- [ ] All tests passing
- [ ] Security audit completed
- [ ] Database backups implemented
- [ ] Error logging configured
- [ ] Analytics tracking added
- [ ] API rate limiting configured
- [ ] HTTPS/SSL certificate ready
- [ ] Staging environment tested
- [ ] Production database initialized
- [ ] Rollback plan documented
- [ ] Team trained on system
- [ ] Support documentation ready

---

## 📝 Sign-Off

| Item | Owner | Date | Notes |
|------|-------|------|-------|
| Development Complete | | | |
| Testing Complete | | | |
| Code Review | | | |
| Security Review | | | |
| Performance OK | | | |
| Documentation Done | | | |
| Production Ready | | | |

---

**Date Completed**: _______________  
**Completed By**: _______________  
**Any Issues**: _______________  

✅ **All checks passed! Ready for production deployment.**
