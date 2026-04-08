import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/patient/patient_model.dart';

void main() {
  group('Patient Model Tests - All Possible Outcomes', () {
    /// ==================== BASIC PATIENT SCENARIOS ====================
    group('Basic Patient Creation', () {
      test('Create patient with minimal required fields', () {
        final patient = Patient(
          uuid: 'uuid-001',
          name: 'John Doe',
          gender: 'Male',
          age: 25,
          dateOfBirth: '1999-01-15',
          address: '123 Main Street',
          phoneNumber: '9876543210',
        );

        expect(patient.uuid, 'uuid-001');
        expect(patient.name, 'John Doe');
        expect(patient.gender, 'Male');
        expect(patient.age, 25);
        expect(patient.id, isNull);
        expect(patient.description, '');
        expect(patient.isPregnant, false);
      });

      test('Create patient with all fields populated', () {
        final diseases = {'Diabetes': true, 'Hypertension': false, 'Anemia': true};
        final patient = Patient(
          id: 1,
          uuid: 'uuid-002',
          name: 'Jane Smith',
          gender: 'Female',
          age: 32,
          dateOfBirth: '1992-06-20',
          address: '456 Oak Avenue, Apartment 5B',
          phoneNumber: '9123456789',
          description: 'Patient with medical history',
          caste: 'General',
          isPregnant: true,
          monthsOfPregnancy: 6,
          expectedDeliveryDate: '2026-07-15',
          declinedHealthInfo: false,
          diseases: diseases,
          photoPath: '/path/to/photo.jpg',
        );

        expect(patient.id, 1);
        expect(patient.uuid, 'uuid-002');
        expect(patient.isPregnant, true);
        expect(patient.monthsOfPregnancy, 6);
        expect(patient.diseases.length, 3);
        expect(patient.diseases['Diabetes'], true);
        expect(patient.diseases['Anemia'], true);
        expect(patient.diseases['Hypertension'], false);
      });
    });

    /// ==================== GENDER VARIATIONS ====================
    group('Gender Variations', () {
      test('Patient with Male gender', () {
        final patient = Patient(
          uuid: 'uuid-male-001',
          name: 'Raj Kumar',
          gender: 'Male',
          age: 45,
          dateOfBirth: '1978-03-10',
          address: 'Village Road',
          phoneNumber: '9876543210',
        );

        expect(patient.gender, 'Male');
        expect(patient.isPregnant, false);
      });

      test('Patient with Female gender', () {
        final patient = Patient(
          uuid: 'uuid-female-001',
          name: 'Priya Sharma',
          gender: 'Female',
          age: 28,
          dateOfBirth: '1996-11-22',
          address: 'City Center',
          phoneNumber: '8765432109',
        );

        expect(patient.gender, 'Female');
      });

      test('Patient with Other gender', () {
        final patient = Patient(
          uuid: 'uuid-other-001',
          name: 'Alex Johnson',
          gender: 'Other',
          age: 30,
          dateOfBirth: '1994-05-08',
          address: 'Downtown',
          phoneNumber: '7654321098',
        );

        expect(patient.gender, 'Other');
      });
    });

    /// ==================== PREGNANCY SCENARIOS ====================
    group('Pregnancy Status Scenarios', () {
      test('Non-pregnant female patient', () {
        final patient = Patient(
          uuid: 'uuid-preg-001',
          name: 'Anjali Desai',
          gender: 'Female',
          age: 35,
          dateOfBirth: '1989-07-14',
          address: '789 Park Lane',
          phoneNumber: '9988776655',
          isPregnant: false,
        );

        expect(patient.isPregnant, false);
        expect(patient.monthsOfPregnancy, isNull);
        expect(patient.expectedDeliveryDate, '');
      });

      test('Pregnant patient with 3 months pregnancy', () {
        final patient = Patient(
          uuid: 'uuid-preg-002',
          name: 'Meera Nair',
          gender: 'Female',
          age: 26,
          dateOfBirth: '1998-02-19',
          address: 'Hospital Road',
          phoneNumber: '9123456788',
          isPregnant: true,
          monthsOfPregnancy: 3,
          expectedDeliveryDate: '2026-12-15',
        );

        expect(patient.isPregnant, true);
        expect(patient.monthsOfPregnancy, 3);
        expect(patient.expectedDeliveryDate, '2026-12-15');
      });

      test('Pregnant patient at full term (9 months)', () {
        final patient = Patient(
          uuid: 'uuid-preg-003',
          name: 'Deepika Verma',
          gender: 'Female',
          age: 29,
          dateOfBirth: '1995-12-05',
          address: 'Maternity Wing',
          phoneNumber: '8765432190',
          isPregnant: true,
          monthsOfPregnancy: 9,
          expectedDeliveryDate: '2026-04-15',
        );

        expect(patient.isPregnant, true);
        expect(patient.monthsOfPregnancy, 9);
      });

      test('Pregnant patient without monthsOfPregnancy', () {
        final patient = Patient(
          uuid: 'uuid-preg-004',
          name: 'Neha Singh',
          gender: 'Female',
          age: 24,
          dateOfBirth: '2000-09-11',
          address: 'Clinic Street',
          phoneNumber: '7654321987',
          isPregnant: true,
          expectedDeliveryDate: '2026-10-20',
        );

        expect(patient.isPregnant, true);
        expect(patient.monthsOfPregnancy, isNull);
      });
    });

    /// ==================== HEALTH INFO & DISEASES ====================
    group('Health Information and Diseases', () {
      test('Patient with health info shared and no diseases', () {
        final patient = Patient(
          uuid: 'uuid-health-001',
          name: 'Arjun Patel',
          gender: 'Male',
          age: 40,
          dateOfBirth: '1984-04-03',
          address: 'Healthy Community',
          phoneNumber: '9876543212',
          declinedHealthInfo: false,
          diseases: const {},
        );

        expect(patient.declinedHealthInfo, false);
        expect(patient.diseases.length, 0);
        expect(patient.activeDiseaseLabels.length, 0);
      });

      test('Patient with health info declined', () {
        final patient = Patient(
          uuid: 'uuid-health-002',
          name: 'Rahul Gupta',
          gender: 'Male',
          age: 55,
          dateOfBirth: '1968-11-17',
          address: 'Privacy Lane',
          phoneNumber: '8765432211',
          declinedHealthInfo: true,
        );

        expect(patient.declinedHealthInfo, true);
      });

      test('Patient with single disease (Diabetes)', () {
        final diseases = {'Diabetes': true};
        final patient = Patient(
          uuid: 'uuid-disease-001',
          name: 'Suresh Kumar',
          gender: 'Male',
          age: 50,
          dateOfBirth: '1974-08-20',
          address: 'Medical District',
          phoneNumber: '9988776654',
          diseases: diseases,
        );

        expect(patient.diseases.length, 1);
        expect(patient.diseases['Diabetes'], true);
        expect(patient.activeDiseaseLabels, ['Diabetes']);
      });

      test('Patient with multiple diseases', () {
        final diseases = {
          'Diabetes': true,
          'Hypertension': true,
          'Asthma': true,
          'Anemia': false,
        };
        final patient = Patient(
          uuid: 'uuid-disease-002',
          name: 'Kavita Reddy',
          gender: 'Female',
          age: 48,
          dateOfBirth: '1976-02-14',
          address: 'Medical Complex',
          phoneNumber: '9123456787',
          diseases: diseases,
        );

        expect(patient.diseases.length, 4);
        expect(patient.activeDiseaseLabels.length, 3);
        expect(patient.activeDiseaseLabels, contains('Diabetes'));
        expect(patient.activeDiseaseLabels, contains('Hypertension'));
        expect(patient.activeDiseaseLabels, contains('Asthma'));
        expect(patient.activeDiseaseLabels, isNot(contains('Anemia')));
      });

      test('Patient with all possible disease combinations', () {
        final diseases = {
          'Diabetes': true,
          'Hypertension': true,
          'Asthma': true,
          'HeartDisease': true,
          'Anemia': true,
          'Tuberculosis': false,
          'Cancer': false,
        };
        final patient = Patient(
          uuid: 'uuid-disease-003',
          name: 'Ramesh Sharma',
          gender: 'Male',
          age: 62,
          dateOfBirth: '1962-01-08',
          address: 'Hospital Lane',
          phoneNumber: '8765432198',
          diseases: diseases,
        );

        expect(patient.diseases.length, 7);
        expect(patient.activeDiseaseLabels.length, 5);
      });
    });

    /// ==================== AGE VARIATIONS ====================
    group('Age Variations and Edge Cases', () {
      test('Very young patient (1 year old)', () {
        final patient = Patient(
          uuid: 'uuid-age-001',
          name: 'Baby Infant',
          gender: 'Female',
          age: 1,
          dateOfBirth: '2025-02-15',
          address: 'Hospital',
          phoneNumber: '9876543200',
        );

        expect(patient.age, 1);
      });

      test('Child patient (5 years old)', () {
        final patient = Patient(
          uuid: 'uuid-age-002',
          name: 'Child Kumar',
          gender: 'Male',
          age: 5,
          dateOfBirth: '2021-04-10',
          address: 'School Area',
          phoneNumber: '9876543201',
        );

        expect(patient.age, 5);
      });

      test('Teenager patient (16 years old)', () {
        final patient = Patient(
          uuid: 'uuid-age-003',
          name: 'Teen Johnson',
          gender: 'Female',
          age: 16,
          dateOfBirth: '2010-07-22',
          address: 'Teen Area',
          phoneNumber: '9876543202',
        );

        expect(patient.age, 16);
      });

      test('Adult patient (30 years old)', () {
        final patient = Patient(
          uuid: 'uuid-age-004',
          name: 'Adult Williams',
          gender: 'Male',
          age: 30,
          dateOfBirth: '1996-03-14',
          address: 'Adult Area',
          phoneNumber: '9876543203',
        );

        expect(patient.age, 30);
      });

      test('Senior patient (75 years old)', () {
        final patient = Patient(
          uuid: 'uuid-age-005',
          name: 'Senior Brown',
          gender: 'Female',
          age: 75,
          dateOfBirth: '1950-09-28',
          address: 'Senior Home',
          phoneNumber: '9876543204',
        );

        expect(patient.age, 75);
      });

      test('Very old patient (95 years old)', () {
        final patient = Patient(
          uuid: 'uuid-age-006',
          name: 'Elder Davis',
          gender: 'Male',
          age: 95,
          dateOfBirth: '1930-12-01',
          address: 'Care Center',
          phoneNumber: '9876543205',
        );

        expect(patient.age, 95);
      });
    });

    /// ==================== ADDRESS VARIATIONS ====================
    group('Address Variations', () {
      test('Address with single line', () {
        final patient = Patient(
          uuid: 'uuid-addr-001',
          name: 'Simple Address',
          gender: 'Male',
          age: 30,
          dateOfBirth: '1994-05-15',
          address: 'Village',
          phoneNumber: '9876543210',
        );

        expect(patient.address, 'Village');
      });

      test('Address with full street details', () {
        final patient = Patient(
          uuid: 'uuid-addr-002',
          name: 'Full Address',
          gender: 'Female',
          age: 28,
          dateOfBirth: '1996-08-20',
          address: '45 Oak Street, Apartment 3B, Downtown District, City Center 400001',
          phoneNumber: '9876543210',
        );

        expect(patient.address.isNotEmpty, true);
        expect(patient.address.length, greaterThan(20));
      });

      test('Address with special characters', () {
        final patient = Patient(
          uuid: 'uuid-addr-003',
          name: 'Special Chars Address',
          gender: 'Male',
          age: 35,
          dateOfBirth: '1989-12-10',
          address: "45-A, O'Brien St., Cross-Roads, New-Delhi (UT) - 110001",
          phoneNumber: '9876543210',
        );

        expect(patient.address.contains('-'), true);
        expect(patient.address.contains("'"), true);
      });

      test('Address with multilingual characters', () {
        final patient = Patient(
          uuid: 'uuid-addr-004',
          name: 'Multilingual Address',
          gender: 'Female',
          age: 32,
          dateOfBirth: '1992-06-18',
          address: 'नई दिल्ली, 123/456, मेन स्ट्रीट',
          phoneNumber: '9876543210',
        );

        expect(patient.address.isNotEmpty, true);
      });
    });

    /// ==================== PHONE NUMBER VARIATIONS ====================
    group('Phone Number Variations', () {
      test('Standard 10-digit phone number', () {
        final patient = Patient(
          uuid: 'uuid-phone-001',
          name: 'Phone User',
          gender: 'Male',
          age: 30,
          dateOfBirth: '1994-05-15',
          address: 'Phone Street',
          phoneNumber: '9876543210',
        );

        expect(patient.phoneNumber.length, 10);
        expect(patient.phoneNumber, '9876543210');
      });

      test('Phone number with leading zeros', () {
        final patient = Patient(
          uuid: 'uuid-phone-002',
          name: 'Phone with Zeros',
          gender: 'Female',
          age: 28,
          dateOfBirth: '1996-08-20',
          address: 'Phone Lane',
          phoneNumber: '0123456789',
        );

        expect(patient.phoneNumber, '0123456789');
      });

      test('Phone number with all same digits', () {
        final patient = Patient(
          uuid: 'uuid-phone-003',
          name: 'Same Digit Phone',
          gender: 'Male',
          age: 35,
          dateOfBirth: '1989-12-10',
          address: 'Repetitive Street',
          phoneNumber: '9999999999',
        );

        expect(patient.phoneNumber, '9999999999');
      });
    });

    /// ==================== DESCRIPTION/NOTES VARIATIONS ====================
    group('Description and Notes', () {
      test('Empty description', () {
        final patient = Patient(
          uuid: 'uuid-desc-001',
          name: 'No Notes',
          gender: 'Male',
          age: 30,
          dateOfBirth: '1994-05-15',
          address: 'Quiet Street',
          phoneNumber: '9876543210',
          description: '',
        );

        expect(patient.description, '');
      });

      test('Short description', () {
        final patient = Patient(
          uuid: 'uuid-desc-002',
          name: 'Brief Notes',
          gender: 'Female',
          age: 28,
          dateOfBirth: '1996-08-20',
          address: 'Note Lane',
          phoneNumber: '9876543210',
          description: 'Patient is stable',
        );

        expect(patient.description, 'Patient is stable');
      });

      test('Long multi-line description', () {
        final patient = Patient(
          uuid: 'uuid-desc-003',
          name: 'Detailed Notes',
          gender: 'Male',
          age: 45,
          dateOfBirth: '1979-03-22',
          address: 'Comprehensive Lane',
          phoneNumber: '9876543210',
          description:
              'Patient presents with multiple health concerns including diabetes management and hypertension control. '
              'Requires regular monitoring. Has family history of heart disease. '
              'Lifestyle modifications recommended including diet and exercise.',
        );

        expect(patient.description.length, greaterThan(100));
        expect(patient.description.contains('diabetes'), true);
      });

      test('Description with special characters', () {
        final patient = Patient(
          uuid: 'uuid-desc-004',
          name: 'Special Notes',
          gender: 'Female',
          age: 35,
          dateOfBirth: '1989-11-08',
          address: 'Special Street',
          phoneNumber: '9876543210',
          description: r'Patient: A.K.Sharma (DOB: 1989-11-08) - BP: 120/80, Weight: 65kg @#$',
        );

        expect(patient.description.contains(':'), true);
        expect(patient.description.contains('@'), true);
      });
    });

    /// ==================== CASTE FIELD VARIATIONS ====================
    group('Caste Field Variations', () {
      test('Caste field - General', () {
        final patient = Patient(
          uuid: 'uuid-caste-001',
          name: 'General Category',
          gender: 'Male',
          age: 30,
          dateOfBirth: '1994-05-15',
          address: 'General Street',
          phoneNumber: '9876543210',
          caste: 'General',
        );

        expect(patient.caste, 'General');
      });

      test('Caste field - OBC', () {
        final patient = Patient(
          uuid: 'uuid-caste-002',
          name: 'OBC Category',
          gender: 'Female',
          age: 28,
          dateOfBirth: '1996-08-20',
          address: 'OBC Lane',
          phoneNumber: '9876543210',
          caste: 'OBC',
        );

        expect(patient.caste, 'OBC');
      });

      test('Caste field - SC/ST', () {
        final patient = Patient(
          uuid: 'uuid-caste-003',
          name: 'SC Category',
          gender: 'Male',
          age: 35,
          dateOfBirth: '1989-12-10',
          address: 'SC Street',
          phoneNumber: '9876543210',
          caste: 'SC',
        );

        expect(patient.caste, 'SC');
      });

      test('Caste field - Empty', () {
        final patient = Patient(
          uuid: 'uuid-caste-004',
          name: 'No Caste',
          gender: 'Female',
          age: 32,
          dateOfBirth: '1992-06-18',
          address: 'No Preference Lane',
          phoneNumber: '9876543210',
          caste: '',
        );

        expect(patient.caste, '');
      });
    });

    /// ==================== PHOTO PATH VARIATIONS ====================
    group('Photo Path Variations', () {
      test('Patient without photo', () {
        final patient = Patient(
          uuid: 'uuid-photo-001',
          name: 'No Photo',
          gender: 'Male',
          age: 30,
          dateOfBirth: '1994-05-15',
          address: 'No Photo Street',
          phoneNumber: '9876543210',
          photoPath: null,
        );

        expect(patient.photoPath, isNull);
      });

      test('Patient with local file path', () {
        final patient = Patient(
          uuid: 'uuid-photo-002',
          name: 'Local Photo',
          gender: 'Female',
          age: 28,
          dateOfBirth: '1996-08-20',
          address: 'Local Photo Lane',
          phoneNumber: '9876543210',
          photoPath: '/storage/emulated/0/DCIM/IMG_001.jpg',
        );

        expect(patient.photoPath, isNotNull);
        expect(patient.photoPath, contains('jpg'));
      });

      test('Patient with server upload path', () {
        final patient = Patient(
          uuid: 'uuid-photo-003',
          name: 'Server Photo',
          gender: 'Male',
          age: 35,
          dateOfBirth: '1989-12-10',
          address: 'Server Photo Street',
          phoneNumber: '9876543210',
          photoPath: '/uploads/patients/1/photo_2026_04_08.jpg',
        );

        expect(patient.photoPath, contains('/uploads/'));
      });

      test('Patient with URL photo path', () {
        final patient = Patient(
          uuid: 'uuid-photo-004',
          name: 'URL Photo',
          gender: 'Female',
          age: 32,
          dateOfBirth: '1992-06-18',
          address: 'URL Photo Lane',
          phoneNumber: '9876543210',
          photoPath: 'https://api.example.com/patients/1/photo.jpg',
        );

        expect(patient.photoPath, contains('http'));
      });

      test('Patient with Windows path', () {
        final patient = Patient(
          uuid: 'uuid-photo-005',
          name: 'Windows Photo',
          gender: 'Male',
          age: 40,
          dateOfBirth: '1984-02-28',
          address: 'Windows Path Street',
          phoneNumber: '9876543210',
          photoPath: 'C:\\Users\\Photos\\patient_001.jpg',
        );

        expect(patient.photoPath, contains('\\'));
      });
    });

    /// ==================== SERVER ID VARIATIONS ====================
    group('Server ID Variations', () {
      test('Offline patient (no server ID)', () {
        final patient = Patient(
          uuid: 'uuid-001',
          name: 'Offline Patient',
          gender: 'Male',
          age: 30,
          dateOfBirth: '1994-05-15',
          address: 'Offline Area',
          phoneNumber: '9876543210',
          id: null,
        );

        expect(patient.id, isNull);
        expect(patient.uuid, isNotEmpty);
      });

      test('Online patient with server ID', () {
        final patient = Patient(
          id: 1,
          uuid: 'uuid-001',
          name: 'Online Patient',
          gender: 'Female',
          age: 28,
          dateOfBirth: '1996-08-20',
          address: 'Online Area',
          phoneNumber: '9876543210',
        );

        expect(patient.id, 1);
        expect(patient.uuid, 'uuid-001');
      });

      test('Patient with large server ID', () {
        final patient = Patient(
          id: 999999,
          uuid: 'uuid-large',
          name: 'Large ID Patient',
          gender: 'Male',
          age: 35,
          dateOfBirth: '1989-12-10',
          address: 'Large ID Street',
          phoneNumber: '9876543210',
        );

        expect(patient.id, 999999);
      });
    });

    /// ==================== JSON PARSING ====================
    group('JSON Parsing and Serialization', () {
      test('Parse basic JSON from backend', () {
        final json = {
          'id': 1,
          'uuid': 'uuid-json-001',
          'patientName': 'JSON Patient',
          'gender': 'Male',
          'age': 30,
          'dateOfBirth': '1994-05-15',
          'address': 'JSON Lane',
          'phoneNumber': '9876543210',
          'description': 'Test Patient',
          'caste': 'General',
          'isPregnant': false,
          'declinedHealthInfo': false,
          'diseases': {},
          'photoPath': null,
        };

        final patient = Patient.fromJson(json);

        expect(patient.id, 1);
        expect(patient.uuid, 'uuid-json-001');
        expect(patient.name, 'JSON Patient');
        expect(patient.diseases.length, 0);
      });

      test('Parse JSON with diseases as map', () {
        final json = {
          'id': 2,
          'uuid': 'uuid-json-002',
          'patientName': 'Disease Patient',
          'gender': 'Female',
          'age': 32,
          'dateOfBirth': '1992-06-18',
          'address': 'Medical Lane',
          'phoneNumber': '9876543210',
          'diseases': {
            'Diabetes': true,
            'Hypertension': true,
            'Asthma': false,
          },
        };

        final patient = Patient.fromJson(json);

        expect(patient.diseases.length, 3);
        expect(patient.diseases['Diabetes'], true);
        expect(patient.activeDiseaseLabels.length, 2);
      });

      test('Parse JSON with diseases as JSON string', () {
        final json = {
          'id': 3,
          'uuid': 'uuid-json-003',
          'patientName': 'String Disease Patient',
          'gender': 'Male',
          'age': 40,
          'dateOfBirth': '1984-02-14',
          'address': 'Hospital Road',
          'phoneNumber': '9876543210',
          'diseases': '{"Diabetes": true, "Anemia": false}',
        };

        final patient = Patient.fromJson(json);

        expect(patient.diseases.length, greaterThan(0));
      });

      test('Parse JSON with missing optional fields', () {
        final json = {
          'id': 4,
          'uuid': 'uuid-json-004',
          'patientName': 'Minimal JSON',
          'gender': 'Female',
          'age': 25,
          'dateOfBirth': '2000-01-01',
          'address': '123 Street',
          'phoneNumber': '9876543210',
        };

        final patient = Patient.fromJson(json);

        expect(patient.description, '');
        expect(patient.caste, '');
        expect(patient.isPregnant, false);
        expect(patient.declinedHealthInfo, false);
      });

      test('Parse JSON with pregnant info', () {
        final json = {
          'id': 5,
          'uuid': 'uuid-json-005',
          'patientName': 'Pregnant Patient',
          'gender': 'Female',
          'age': 28,
          'dateOfBirth': '1996-08-20',
          'address': 'Maternity Lane',
          'phoneNumber': '9876543210',
          'isPregnant': true,
          'monthsOfPregnancy': 6,
          'expectedDeliveryDate': '2026-10-20',
        };

        final patient = Patient.fromJson(json);

        expect(patient.isPregnant, true);
        expect(patient.monthsOfPregnancy, 6);
        expect(patient.expectedDeliveryDate, '2026-10-20');
      });
    });

    /// ==================== COMPOUND SCENARIOS ====================
    group('Compound Real-World Scenarios', () {
      test('Scenario 1: Healthy young child', () {
        final patient = Patient(
          id: 10,
          uuid: 'uuid-scenario-01',
          name: 'Arjun Nair',
          gender: 'Male',
          age: 8,
          dateOfBirth: '2018-03-15',
          address: 'School Street, Zone A',
          phoneNumber: '9876501234',
          description: 'Regular checkup',
          caste: 'General',
          isPregnant: false,
          declinedHealthInfo: false,
          diseases: const {},
          photoPath: null,
        );

        expect(patient.age, 8);
        expect(patient.activeDiseaseLabels.length, 0);
        expect(patient.isPregnant, false);
      });

      test('Scenario 2: Pregnant mother with complications', () {
        final diseases = {
          'Gestational Diabetes': true,
          'Hypertension': true,
        };
        final patient = Patient(
          id: 11,
          uuid: 'uuid-scenario-02',
          name: 'Priya Gupta',
          gender: 'Female',
          age: 31,
          dateOfBirth: '1993-12-08',
          address: 'Medical Complex, Ward 5',
          phoneNumber: '9123456712',
          description:
              'Pregnant with complications. Gestational diabetes and hypertension detected. Requires weekly monitoring.',
          caste: 'General',
          isPregnant: true,
          monthsOfPregnancy: 7,
          expectedDeliveryDate: '2026-06-15',
          declinedHealthInfo: false,
          diseases: diseases,
          photoPath: '/uploads/patients/11/pregnancy.jpg',
        );

        expect(patient.isPregnant, true);
        expect(patient.activeDiseaseLabels.length, 2);
        expect(patient.monthsOfPregnancy, 7);
      });

      test('Scenario 3: Senior patient with chronic diseases', () {
        final diseases = {
          'Diabetes': true,
          'Hypertension': true,
          'HeartDisease': true,
          'Arthritis': true,
        };
        final patient = Patient(
          id: 12,
          uuid: 'uuid-scenario-03',
          name: 'Ramesh Sharma',
          gender: 'Male',
          age: 72,
          dateOfBirth: '1952-09-20',
          address: 'Senior Care Home, Block B',
          phoneNumber: '8765432912',
          description:
              'Senior citizen with multiple chronic conditions. On regular medication for diabetes, BP, and heart condition. '
              'Requires daily monitoring and medications refill every 2 weeks.',
          caste: 'OBC',
          isPregnant: false,
          declinedHealthInfo: false,
          diseases: diseases,
          photoPath: 'https://api.hospital.com/patients/12/photo.jpg',
        );

        expect(patient.age, 72);
        expect(patient.activeDiseaseLabels.length, 4);
        expect(patient.diseases['Diabetes'], true);
      });

      test('Scenario 4: Patient who declined health information', () {
        final patient = Patient(
          id: 13,
          uuid: 'uuid-scenario-04',
          name: 'John Doe',
          gender: 'Male',
          age: 55,
          dateOfBirth: '1968-07-12',
          address: 'Private Lane',
          phoneNumber: '9876543450',
          caste: '',
          declinedHealthInfo: true,
          diseases: const {},
        );

        expect(patient.declinedHealthInfo, true);
      });

      test('Scenario 5: Offline patient (not yet synced)', () {
        final diseases = {'Anemia': true};
        final patient = Patient(
          uuid: 'uuid-scenario-05-offline',
          name: 'New Patient',
          gender: 'Female',
          age: 22,
          dateOfBirth: '2002-11-30',
          address: 'Rural Village, Block C',
          phoneNumber: '7654345678',
          description: 'New patient registered offline',
          isPregnant: false,
          diseases: diseases,
          photoPath: '/storage/emulated/0/DCIM/IMG_2026_04_08_123456.jpg',
        );

        expect(patient.id, isNull);
        expect(patient.uuid, isNotEmpty);
        expect(patient.activeDiseaseLabels.length, 1);
      });
    });

    /// ==================== EDGE CASES & ERROR HANDLING ====================
    group('Edge Cases and Error Handling', () {
      test('Patient with empty name (should not crash)', () {
        expect(
          () {
            Patient(
              uuid: 'uuid-edge-001',
              name: '',
              gender: 'Male',
              age: 30,
              dateOfBirth: '1994-05-15',
              address: 'Some Address',
              phoneNumber: '9876543210',
            );
          },
          isNot(throwsException),
        );
      });

      test('Patient with very long name', () {
        final longName =
            'Dr. Ramakrishnan Venkataraman Subramaniam Bhattacharya Shanmughasundaram';
        final patient = Patient(
          uuid: 'uuid-edge-002',
          name: longName,
          gender: 'Male',
          age: 40,
          dateOfBirth: '1984-02-14',
          address: 'Long Name Street',
          phoneNumber: '9876543210',
        );

        expect(patient.name, longName);
        expect(patient.name.length, greaterThan(50));
      });

      test('Patient with zero age (edge case)', () {
        final patient = Patient(
          uuid: 'uuid-edge-003',
          name: 'Newborn',
          gender: 'Female',
          age: 0,
          dateOfBirth: '2026-04-08',
          address: 'Hospital',
          phoneNumber: '9876543210',
        );

        expect(patient.age, 0);
      });

      test('Patient with negative age (should not crash)', () {
        expect(
          () {
            Patient(
              uuid: 'uuid-edge-004',
              name: 'Test',
              gender: 'Male',
              age: -5,
              dateOfBirth: '1994-05-15',
              address: 'Address',
              phoneNumber: '9876543210',
            );
          },
          isNot(throwsException),
        );
      });

      test('Patient with extremely high age', () {
        final patient = Patient(
          uuid: 'uuid-edge-005',
          name: 'Ancient',
          gender: 'Male',
          age: 150,
          dateOfBirth: '1876-01-01',
          address: 'Old Street',
          phoneNumber: '9876543210',
        );

        expect(patient.age, 150);
      });

      test('Patient with diseases map containing various values', () {
        final diseases = {
          'Diabetes': true,
          'Hypertension': false,
          'Asthma': false,
        };

        expect(
          () {
            Patient(
              uuid: 'uuid-edge-006',
              name: 'Null Test',
              gender: 'Male',
              age: 30,
              dateOfBirth: '1994-05-15',
              address: 'Null Street',
              phoneNumber: '9876543210',
              diseases: diseases,
            );
          },
          isNot(throwsException),
        );
      });

      test('Parse JSON with missing patientName field throws error', () {
        final json = {
          'id': 99,
          'uuid': 'uuid-json-missing',
          'gender': 'Male',
          'age': 30,
          'dateOfBirth': '1994-05-15',
          'address': 'Test Address',
          'phoneNumber': '9876543210',
        };

        expect(
          () {
            Patient.fromJson(json);
          },
          throwsA(isA<Error>()),
        );
      });
    });
  });
}
