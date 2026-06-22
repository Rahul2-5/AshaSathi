# AshaSathi — Project Documentation

**Project Name:** AshaSathi: An Offline-First Healthcare Application with Agentic AI for ASHA Workers — Integrating Medical Vision Intelligence   
**Author:** Rahul Pramod Temkar  
**Version:** 2.0  
**Date:** June 2026  

---

## Table of Contents

1. [Scope of Project](#1-scope-of-project)
2. [Project Description and Limitations](#2-project-description-and-limitations)
3. [UML Diagrams — AI Prompts](#3-uml-diagrams--ai-prompts)
4. [Database](#4-database)
5. [Conclusion](#5-conclusion)
6. [Bibliography](#6-bibliography)

---

## 1. Scope of Project

### 1.1 Problem Statement

ASHA (Accredited Social Health Activist) workers in rural India are the frontline bridge between communities and the public health system. They operate in areas with unreliable or no internet connectivity, and currently rely on paper-based systems to record patient information — leading to:

- Missed vaccination schedules
- Inconsistent maternal and pregnancy care tracking
- Loss or corruption of critical health records
- Inability to aggregate data for health analytics

### 1.2 Project Objectives

AshaSathi aims to digitize and streamline the daily workflow of ASHA workers by providing:

1. **Offline-capable patient management** — Register and manage patient profiles entirely without internet.
2. **Family-unit tracking** — Group patients by household for accurate community health mapping.
3. **Medical document scanning (AI/OCR)** — Upload prescription photos and auto-extract medicines, lab results, and diagnoses using AI.
4. **Automatic data synchronization** — Sync all locally stored records to a central cloud backend when connectivity is restored.
5. **Multi-language support** — Interface available in English, Hindi, Tamil, Telugu, and Gujarati.
6. **Task management** — Assign and track health-related follow-up tasks for ASHA workers.

### 1.3 Target Users

| User Type | Role |
|-----------|------|
| ASHA Worker | Primary user — registers patients, uploads documents, tracks tasks |
| Health Supervisor | Reviews synced records from the backend |
| System Administrator | Manages user accounts and system configuration |

### 1.4 Project Boundaries (In-Scope vs Out-of-Scope)

| In-Scope | Out-of-Scope |
|----------|-------------|
| Patient & family registration | Telemedicine or video consultation |
| Offline SQLite storage | Billing or payment processing |
| AI-powered OCR for medical documents | Direct integration with government HMIS |
| JWT-based authentication (Google/GitHub OAuth) | Wearable device integration |
| Smart sync engine (pending → synced) | Predictive AI health risk scoring |
| Pregnancy & vaccination tracking | Real-time GPS location tracking |
| Multi-language localization | SMS/voice notification system |

---

## 2. Project Description and Limitations

### 2.1 System Overview

AshaSathi is a **three-tier system** composed of:

```
┌─────────────────────────────────────────────────┐
│              Flutter Mobile App                  │
│        (ASHA Worker Interface — Dart)            │
│  Riverpod state management · SQLite local store  │
└────────────────────┬────────────────────────────┘
                     │ REST API (HTTP/JSON)
                     │ (syncs only when online)
┌────────────────────▼────────────────────────────┐
│             Spring Boot Backend                  │
│    (Java 17 · JWT Auth · JPA · PostgreSQL)       │
│   Hosted on Heroku · Manages remote persistence  │
└────────────────────┬────────────────────────────┘
                     │ Internal HTTP call
┌────────────────────▼────────────────────────────┐
│           OCR Microservice (Python)              │
│  FastAPI · PaddleOCR · Google Gemini AI          │
│  Extracts text, medicines & lab results from     │
│  uploaded medical document photos                │
└─────────────────────────────────────────────────┘
```

### 2.2 Key Features

#### Authentication
- Username/password login with JWT token issuance
- Google and GitHub OAuth social login
- Persistent login via SharedPreferences token storage
- BCrypt password hashing

#### Patient & Family Management
- 3-step add-patient wizard:
  - Step 1: Family information (head of family, address, member count)
  - Step 2: Individual patient details (name, age, DOB, gender, caste, photo, phone)
  - Step 3: Medical information (10+ disease categories, pregnancy tracking, notes)
- Photo capture from camera or gallery
- Conditional pregnancy tracking fields for female patients

#### Offline-First Sync
- All writes go to SQLite first; records are flagged as `pending`
- `ConnectivityService` monitors network state in real time
- `DashboardBootstrapNotifier` / sync engine pushes pending records to backend when online
- Records marked `synced` after successful server acknowledgement
- Conflict-free sync: last-write-wins strategy

#### Medical Document Processing (AI/OCR)
- ASHA worker photographs a prescription or lab report in the app
- Image is uploaded to the OCR microservice
- Pipeline:
  1. `ImagePreprocessor` — deskew, denoise, contrast enhancement (OpenCV)
  2. `OCRService` — text extraction via PaddleOCR
  3. `GeminiService` — Gemini AI parses raw OCR text into structured JSON (medicines, lab results, diagnosis, follow-up date)
  4. `ConfidenceValidationService` — scores extraction quality and flags results for review
- Results displayed in the Medical Vision screen with confidence badges

#### App Settings & Localisation
- Theme mode toggle (dark / light)
- Language selector (English, Hindi, Tamil, Telugu, Gujarati)
- Settings persisted across app restarts

### 2.3 Technology Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Mobile Frontend | Flutter / Dart | 3.x |
| State Management | Riverpod (flutter_riverpod) | ^2.4.0 |
| Immutable Models | Freezed + freezed_annotation | ^2.4.0 |
| Local Database | SQLite (sqflite) | — |
| Backend Framework | Spring Boot | 3.x |
| Backend Language | Java | 17 |
| Backend ORM | Spring Data JPA / Hibernate | — |
| Remote Database | PostgreSQL (Heroku) | — |
| Authentication | JWT (jjwt) | — |
| OCR Engine | PaddleOCR | >=2.7.3 |
| AI Extraction | Google Gemini API | >=0.7.0 |
| OCR Service Framework | FastAPI | >=0.100.0 |
| Image Processing | OpenCV (cv2) | >=4.8.0 |
| HTTP Client (Python) | HTTPX | >=0.25.0 |

### 2.4 Limitations

| Limitation | Description |
|-----------|-------------|
| **No real-time sync** | Sync is triggered on connectivity change — not push/WebSocket-based; data is not live |
| **Single-device per ASHA worker** | No multi-device login support; SQLite state is device-local |
| **OCR accuracy** | PaddleOCR performs best on clean, high-contrast documents; blurry or handwritten prescriptions reduce accuracy |
| **Gemini API dependency** | Medical document extraction requires a live internet connection; no offline AI fallback |
| **No role-based dashboards** | Supervisors and admins must use the backend directly; no dedicated supervisor UI exists yet |
| **Disease data is unstructured** | Diseases are stored as a JSON string in a single column, not normalized — limits complex querying |
| **macOS & PWA icons not branded** | Icon assets still use Flutter default placeholder "F" logo |
| **No end-to-end encryption** | Patient data is transmitted over HTTPS but not end-to-end encrypted at rest in SQLite |
| **No automated tests** | Unit and integration test coverage is minimal; the test suite has one smoke test (`contextLoads`) |
| **Heroku cold start** | Heroku free/eco dynos sleep after inactivity; first API call after idle period has ~5–10 second delay |

---

## 3. UML Diagrams — AI Prompts

Use these prompts with an AI diagram generator (e.g., ChatGPT, Gemini, Claude, or PlantUML AI tools) to generate each diagram.

---

### 3.1 Use Case Diagram

**Prompt:**

> Generate a UML Use Case Diagram for a mobile healthcare application called "AshaSathi" targeting ASHA (Accredited Social Health Activist) workers in rural India.
>
> **Actors:**
> - ASHA Worker (primary)
> - System (automated background actor)
> - Gemini AI (external system)
> - Backend Server (external system)
>
> **Use Cases for ASHA Worker:**
> - Login (username/password or Google/GitHub OAuth)
> - Register Family (enter head of family, address, member count)
> - Add Patient (3-step wizard: family info → patient details → medical info)
> - View Patient List (on dashboard)
> - View Patient Details (family page)
> - Upload Medical Document (photo of prescription or lab report)
> - View Scan Results (medicines extracted, lab results, diagnosis, confidence badges)
> - Manage Tasks (view and update follow-up tasks)
> - Change App Language (English, Hindi, Tamil, Telugu, Gujarati)
> - Toggle Dark/Light Theme
>
> **Use Cases for System (automated):**
> - Save Data Offline (write to SQLite with "pending" status)
> - Detect Network Connectivity Change
> - Sync Pending Records to Backend
> - Mark Records as Synced
>
> **Use Cases for Gemini AI (external):**
> - Parse OCR Text into Structured Medical Data
> - Return medicines, lab results, diagnosis, follow-up date as JSON
>
> Include include/extend relationships where appropriate. For example:
> - "Add Patient" includes "Save Data Offline"
> - "Upload Medical Document" extends "View Scan Results"
> - "Sync Pending Records" includes "Detect Network Connectivity Change"

---

### 3.2 Class Diagram (Backend Entities)

**Prompt:**

> Generate a UML Class Diagram for the Spring Boot backend of "AshaSathi" healthcare application. Include only entity classes and their relationships.
>
> **Classes and attributes:**
>
> **User**
> - id: Long
> - username: String
> - email: String
> - password: String
> - provider: String
>
> **Family**
> - id: Long
> - headOfFamily: String
> - numberOfMembers: Integer
> - familyAddress: String
> - createdAt: LocalDateTime
> - updatedAt: LocalDateTime
>
> **FamilyPatient**
> - id: Long
> - patientName: String
> - age: Integer
> - dateOfBirth: String
> - gender: String
> - caste: String
> - address: String
> - phoneNumber: String
> - isPregnant: Boolean
> - monthsOfPregnancy: Integer
> - expectedDeliveryDate: String
> - photoPath: String
> - diseases: String (JSON)
> - declinedHealthInfo: Boolean
> - notes: String
> - createdAt: LocalDateTime
> - updatedAt: LocalDateTime
>
> **MedicalDocument**
> - id: Long
> - patientId: Long
> - imagePath: String
> - rawText: String
> - diagnosis: String
> - followUpDate: String
> - aiSummary: String
> - ashaActions: String
> - documentType: String
> - doctorName: String
> - hospitalName: String
> - processingStatus: Enum {PENDING, PROCESSING, COMPLETED, FAILED}
> - ocrConfidence: Double
> - createdAt: LocalDateTime
> - updatedAt: LocalDateTime
>
> **Medicine**
> - id: Long
> - medicineName: String
> - dosage: String
> - frequency: String
> - duration: String
> - verified: Boolean
> - matchedDrugName: String
> - matchScore: Integer
>
> **LabResult**
> - id: Long
> - testName: String
> - value: String
> - unit: String
> - severity: Enum {NORMAL, LOW, HIGH, CRITICAL}
> - referenceRange: String
>
> **DrugMaster**
> - id: Long
> - drugName: String
> - genericName: String
>
> **LabReferenceRange**
> - id: Long
> - testName: String
> - minValue: Double
> - maxValue: Double
> - unit: String
>
> **Task**
> - id: Long
> - title: String
> - description: String
> - status: String
> - createdDate: LocalDateTime
>
> **Relationships:**
> - Family has ONE-TO-MANY FamilyPatient (cascade ALL)
> - MedicalDocument has ONE-TO-MANY Medicine (cascade ALL)
> - MedicalDocument has ONE-TO-MANY LabResult (cascade ALL)
> - FamilyPatient references MedicalDocument via patientId (logical, not JPA foreign key)

---

### 3.3 Sequence Diagram — Add Patient with Offline Sync

**Prompt:**

> Generate a UML Sequence Diagram for the "Add Patient with Offline Sync" flow in the AshaSathi mobile application.
>
> **Participants (left to right):**
> 1. ASHA Worker (actor)
> 2. Flutter UI (Add Patient Wizard Screen)
> 3. AddPatientNotifier (Riverpod StateNotifier)
> 4. SQLite Database (local)
> 5. ConnectivityService
> 6. SyncEngine (DashboardBootstrapNotifier)
> 7. Spring Boot REST API (remote)
>
> **Flow:**
> 1. ASHA Worker fills in Step 1 (Family Info), Step 2 (Patient Details), Step 3 (Medical Info) in the wizard
> 2. ASHA Worker taps "Submit"
> 3. Flutter UI calls AddPatientNotifier.addPatient(payload)
> 4. AddPatientNotifier writes the family + patient record to SQLite with status = "pending"
> 5. SQLite returns success; UI shows success message
> 6. ConnectivityService detects internet is available (or fires on restore event)
> 7. ConnectivityService notifies SyncEngine
> 8. SyncEngine queries SQLite for all records with status = "pending"
> 9. SyncEngine calls POST /api/families on Spring Boot REST API with the pending payload
> 10. Spring Boot persists the record to PostgreSQL and returns 201 Created
> 11. SyncEngine updates SQLite record status from "pending" to "synced"
>
> Show alternate flow: If no connectivity at step 6, SyncEngine waits until ConnectivityService fires the "online" event.

---

### 3.4 Sequence Diagram — Medical Document OCR Pipeline

**Prompt:**

> Generate a UML Sequence Diagram for the "Medical Document OCR and AI Extraction" flow in the AshaSathi application.
>
> **Participants (left to right):**
> 1. ASHA Worker (actor)
> 2. Flutter Medical Vision Screen
> 3. Spring Boot MedicalDocumentController
> 4. MedicalDocumentService
> 5. OCR Microservice (FastAPI)
> 6. ImagePreprocessor (Python)
> 7. OCRService / PaddleOCR
> 8. GeminiService (Google Gemini AI)
> 9. ConfidenceValidationService
> 10. PostgreSQL Database
>
> **Flow:**
> 1. ASHA Worker photographs a medical document (prescription / lab report)
> 2. Flutter UI calls POST /api/medical-documents/upload with the image file
> 3. MedicalDocumentController receives the file and calls MedicalDocumentService.processDocument()
> 4. MedicalDocumentService sets document status = PROCESSING in PostgreSQL
> 5. MedicalDocumentService calls the OCR Microservice via HTTP POST with the image
> 6. ImagePreprocessor deskews, denoises, and enhances contrast of the image
> 7. OCRService runs PaddleOCR on the preprocessed image and returns raw text
> 8. GeminiService sends the raw text to the Gemini API with a structured extraction prompt
> 9. Gemini API returns JSON containing: medicines, lab results, diagnosis, follow-up date
> 10. ConfidenceValidationService scores the extraction quality (HIGH / MEDIUM / LOW)
> 11. OCR Microservice returns the structured response to MedicalDocumentService
> 12. MedicalDocumentService saves medicines, lab results, and document metadata to PostgreSQL
> 13. MedicalDocumentService sets document status = COMPLETED
> 14. Spring Boot returns the result to Flutter
> 15. Medical Vision Screen displays extracted data with confidence badges

---

### 3.5 Component / Architecture Diagram

**Prompt:**

> Generate a UML Component Diagram (or C4 Container Diagram) for the "AshaSathi" healthcare application system.
>
> **Components:**
>
> **Mobile App Container (Flutter)**
> - Authentication UI (login screen, OAuth buttons)
> - Dashboard & Navigation (main nav, drawer, routing)
> - Patient Management (add patient wizard, family detail page, patient list)
> - Medical Vision Screen (document upload, OCR results display)
> - App Settings (theme, language, locale)
> - Offline Data Store (SQLite via sqflite)
> - Sync Engine (connectivity monitor, sync queue)
> - HTTP Client (REST calls via http package)
>
> **Backend Container (Spring Boot)**
> - Auth Controller (POST /auth/login, POST /auth/signup)
> - Family Controller (POST /api/families, GET /api/families)
> - Patient Controller (GET /api/patients, DELETE /api/patients/{id})
> - Medical Document Controller (POST /api/medical-documents/upload, GET /api/medical-documents/patient/{id}, DELETE)
> - Task Controller
> - JWT Security Filter (JwtAuthenticationFilter, JwtUtil)
> - JPA Repositories (Family, FamilyPatient, MedicalDocument, Medicine, LabResult)
>
> **OCR Microservice Container (Python FastAPI)**
> - Upload Endpoint (POST /ocr/process)
> - Image Preprocessor (deskew, denoise, contrast)
> - PaddleOCR Engine
> - Gemini AI Service (structured extraction)
> - Parser Service (JSON clean-up and validation)
> - Confidence Validation Service
>
> **External Systems:**
> - PostgreSQL Database (Heroku)
> - Google Gemini API
> - Google OAuth Provider
> - GitHub OAuth Provider
>
> Show data flow arrows:
> - Flutter ↔ Spring Boot via HTTPS REST
> - Spring Boot → OCR Microservice via internal HTTP
> - OCR Microservice → Gemini API via HTTPS
> - Spring Boot ↔ PostgreSQL via JDBC
> - Flutter ↔ SQLite (local device)

---

### 3.6 Entity-Relationship (ER) Diagram

**Prompt:**

> Generate an Entity-Relationship (ER) Diagram for the AshaSathi backend database.
>
> **Tables and columns:**
>
> **users** (id PK, username, email, password, provider)
>
> **families** (id PK, head_of_family, number_of_members, family_address, created_at, updated_at)
>
> **family_patients** (id PK, family_id FK→families.id, patient_name, age, date_of_birth, gender, caste, address, phone_number, is_pregnant, months_of_pregnancy, expected_delivery_date, photo_path, diseases TEXT, declined_health_info, notes TEXT, created_at, updated_at)
>
> **medical_documents** (id PK, patient_id→family_patients.id (logical), image_path, raw_text TEXT, diagnosis, follow_up_date, ai_summary TEXT, asha_actions TEXT, document_type, doctor_name, hospital_name, processing_status ENUM, ocr_confidence, created_at, updated_at)
>
> **medicines** (id PK, document_id FK→medical_documents.id, medicine_name, dosage, frequency, duration, verified, matched_drug_name, match_score)
>
> **lab_results** (id PK, document_id FK→medical_documents.id, test_name, value, unit, severity ENUM, reference_range)
>
> **drug_master** (id PK, drug_name, generic_name)
>
> **lab_reference_ranges** (id PK, test_name, min_value, max_value, unit)
>
> **tasks** (id PK, title, description, status, created_date)
>
> **Relationships:**
> - families → family_patients: ONE-TO-MANY (one family has many patients)
> - family_patients → medical_documents: ONE-TO-MANY (logical, via patient_id)
> - medical_documents → medicines: ONE-TO-MANY
> - medical_documents → lab_results: ONE-TO-MANY
>
> Show crow's foot notation for cardinality. Highlight the fact that family_patients.diseases is denormalized JSON storage (not a separate table).

---

## 4. Database

### 4.1 Local Database (SQLite — On-Device)

Used by the Flutter app for offline-first operation. SQLite stores all records with a sync status flag.

**Key Tables:**

| Table | Purpose |
|-------|---------|
| `families` | Household records created by ASHA workers |
| `family_members` | Individual patients per household |
| `sync_queue` | Pending records waiting for network to sync |

**Sync Status Lifecycle:**

```
Record Created → status = "pending"
         ↓
Network Available → Sync Engine picks up pending records
         ↓
API call succeeds → status = "synced"
         ↓
API call fails → remains "pending", retried on next network event
```

---

### 4.2 Remote Database (PostgreSQL — Heroku)

Managed by the Spring Boot backend. All synced records from ASHA workers' devices are stored here.

#### Table: `families`

| Column | Type | Constraint |
|--------|------|-----------|
| id | BIGINT | PK, AUTO_INCREMENT |
| head_of_family | VARCHAR | NOT NULL |
| number_of_members | INTEGER | NOT NULL |
| family_address | TEXT | NOT NULL |
| created_at | TIMESTAMP | NOT NULL |
| updated_at | TIMESTAMP | NOT NULL |

#### Table: `family_patients`

| Column | Type | Constraint |
|--------|------|-----------|
| id | BIGINT | PK, AUTO_INCREMENT |
| family_id | BIGINT | FK → families.id |
| patient_name | VARCHAR | NOT NULL |
| age | INTEGER | NOT NULL |
| date_of_birth | VARCHAR | NOT NULL |
| gender | VARCHAR | NOT NULL |
| caste | VARCHAR | — |
| address | TEXT | — |
| phone_number | VARCHAR | — |
| is_pregnant | BOOLEAN | default false |
| months_of_pregnancy | INTEGER | — |
| expected_delivery_date | VARCHAR | — |
| photo_path | VARCHAR | — |
| diseases | TEXT | JSON string |
| declined_health_info | BOOLEAN | default false |
| notes | TEXT | — |
| created_at | TIMESTAMP | NOT NULL |
| updated_at | TIMESTAMP | NOT NULL |

#### Table: `medical_documents`

| Column | Type | Constraint |
|--------|------|-----------|
| id | BIGINT | PK, AUTO_INCREMENT |
| patient_id | BIGINT | Logical ref → family_patients.id |
| image_path | VARCHAR | — |
| raw_text | TEXT | OCR extracted text |
| diagnosis | VARCHAR | AI extracted |
| follow_up_date | VARCHAR | AI extracted |
| ai_summary | TEXT | Gemini summary |
| asha_actions | TEXT | Suggested actions |
| document_type | VARCHAR | e.g., prescription / lab report |
| doctor_name | VARCHAR | — |
| hospital_name | VARCHAR | — |
| processing_status | ENUM | PENDING / PROCESSING / COMPLETED / FAILED |
| ocr_confidence | DOUBLE | 0.0–1.0 |
| created_at | TIMESTAMP | NOT NULL |
| updated_at | TIMESTAMP | NOT NULL |

#### Table: `medicines`

| Column | Type | Constraint |
|--------|------|-----------|
| id | BIGINT | PK, AUTO_INCREMENT |
| document_id | BIGINT | FK → medical_documents.id |
| medicine_name | VARCHAR | NOT NULL |
| dosage | VARCHAR | — |
| frequency | VARCHAR | — |
| duration | VARCHAR | — |
| verified | BOOLEAN | NOT NULL, default false |
| matched_drug_name | VARCHAR | From DrugMaster lookup |
| match_score | INTEGER | Fuzzy match confidence |

#### Table: `lab_results`

| Column | Type | Constraint |
|--------|------|-----------|
| id | BIGINT | PK, AUTO_INCREMENT |
| document_id | BIGINT | FK → medical_documents.id |
| test_name | VARCHAR | NOT NULL |
| value | VARCHAR | — |
| unit | VARCHAR | — |
| severity | ENUM | NORMAL / LOW / HIGH / CRITICAL |
| reference_range | VARCHAR | — |

#### Table: `drug_master`

| Column | Type | Constraint |
|--------|------|-----------|
| id | BIGINT | PK, AUTO_INCREMENT |
| drug_name | VARCHAR | — |
| generic_name | VARCHAR | — |

**Purpose:** Reference table seeded at startup; used to fuzzy-match extracted medicine names for verification.

#### Table: `lab_reference_ranges`

| Column | Type | Constraint |
|--------|------|-----------|
| id | BIGINT | PK, AUTO_INCREMENT |
| test_name | VARCHAR | — |
| min_value | DOUBLE | — |
| max_value | DOUBLE | — |
| unit | VARCHAR | — |

**Purpose:** Reference table for flagging lab result severity (NORMAL / HIGH / LOW / CRITICAL).

### 4.3 Data Flow Summary

```
ASHA Worker input
      ↓
SQLite (device) — status: pending
      ↓ (on connectivity)
Spring Boot API → PostgreSQL — status: synced
      ↓ (on document upload)
OCR Microservice → Gemini AI
      ↓
medical_documents + medicines + lab_results tables
```

---

## 5. Conclusion

AshaSathi addresses a real and urgent need in India's rural healthcare system. ASHA workers — who are often the only trained health touchpoints in villages — are currently burdened with paper-based workflows that lead to data loss, missed follow-ups, and inconsistent patient tracking.

This project demonstrates that an **offline-first mobile architecture** can reliably replace paper-based workflows even under challenging connectivity conditions. By combining:

- **Flutter's cross-platform capability** for rapid mobile development
- **SQLite's embedded storage** for zero-dependency offline operation
- **Riverpod's reactive state management** for clean sync state propagation
- **Spring Boot's robust REST API** for secure remote persistence
- **PaddleOCR + Gemini AI** for intelligent medical document processing

...the system delivers a production-ready tool that is practical, scalable, and meaningful for grassroots healthcare.

Key technical achievements of the project include:
- A fully functional offline-first sync engine with automatic retry
- An AI-powered OCR pipeline capable of extracting structured medical data from prescription and lab report photos with confidence scoring
- Multi-language support spanning 5 Indian languages
- JWT-secured API with social OAuth login
- A 3-step guided wizard for frictionless patient registration

The project has known limitations — particularly around OCR accuracy on handwritten documents, the absence of a supervisor dashboard, and the lack of automated test coverage — which represent the clearest path for future work. The next major milestone is hardening the sync conflict resolution strategy and expanding the AI pipeline to support offline inference using locally-served models (Ollama integration is already stubbed in the codebase).

AshaSathi is ultimately a demonstration of how thoughtful system design, combined with modern AI tooling, can bring meaningful digital infrastructure to the communities that need it most.

---

## 6. Bibliography

### Frameworks and Libraries

| Technology | Reference |
|-----------|-----------|
| Flutter SDK | https://flutter.dev |
| Dart Language | https://dart.dev |
| Riverpod (State Management) | https://riverpod.dev |
| Freezed (Immutable Models) | https://pub.dev/packages/freezed |
| sqflite (SQLite for Flutter) | https://pub.dev/packages/sqflite |
| Spring Boot | https://spring.io/projects/spring-boot |
| Spring Data JPA | https://spring.io/projects/spring-data-jpa |
| Project Lombok | https://projectlombok.org |
| JJWT (Java JWT) | https://github.com/jwtk/jjwt |
| FastAPI | https://fastapi.tiangolo.com |
| PaddleOCR | https://github.com/PaddlePaddle/PaddleOCR |
| OpenCV (Python) | https://opencv.org |
| Google Generative AI SDK | https://ai.google.dev |
| HTTPX | https://www.python-httpx.org |

### Cloud and Infrastructure

| Service | Reference |
|---------|-----------|
| Heroku (Backend Hosting) | https://www.heroku.com |
| PostgreSQL | https://www.postgresql.org |

### Standards and Concepts Referenced

| Concept | Reference |
|---------|-----------|
| Offline-First Design Pattern | "Offline First" — hood.ie project (https://offlinefirst.org) |
| Eventual Consistency | Brewer, E. A. (2000). *Towards Robust Distributed Systems*. PODC Keynote |
| JWT Authentication Standard | RFC 7519 — JSON Web Token (https://datatracker.ietf.org/doc/html/rfc7519) |
| OWASP Mobile Security Guidelines | https://owasp.org/www-project-mobile-app-security |
| ASHA Worker Programme | Ministry of Health and Family Welfare, Government of India (https://nhm.gov.in/index1.php?lang=1&level=1&sublinkid=150&lid=226) |
| REST API Design | Fielding, R. T. (2000). *Architectural Styles and the Design of Network-based Software Architectures*. UC Irvine Doctoral Dissertation |
| OCR with PaddleOCR | Du, Y., et al. (2020). *PP-OCR: A Practical Ultra Lightweight OCR System*. arXiv:2009.09941 |

---

*Document generated: June 2026 | AshaSathi v2.0*
