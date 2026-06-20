# Graph Report - d:/Flutter_Projects/AshaSathi  (2026-06-20)

## Corpus Check
- 256 files · ~176,655 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1369 nodes · 1651 edges · 81 communities detected
- Extraction: 94% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 70 edges (avg confidence: 0.84)
- Token cost: 2,224 input · 1,462 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Offline Data Sync Layer|Offline Data Sync Layer]]
- [[_COMMUNITY_App Settings & Shell|App Settings & Shell]]
- [[_COMMUNITY_Patient Detail UI|Patient Detail UI]]
- [[_COMMUNITY_Dashboard & Bootstrap|Dashboard & Bootstrap]]
- [[_COMMUNITY_Family API & Services|Family API & Services]]
- [[_COMMUNITY_Add Patient Wizard (Docs)|Add Patient Wizard (Docs)]]
- [[_COMMUNITY_Navigation & Routing|Navigation & Routing]]
- [[_COMMUNITY_App Theme & Styling|App Theme & Styling]]
- [[_COMMUNITY_Authentication UI|Authentication UI]]
- [[_COMMUNITY_Linux Desktop Build|Linux Desktop Build]]
- [[_COMMUNITY_Medical Documents Backend|Medical Documents Backend]]
- [[_COMMUNITY_Medical Vision Screen|Medical Vision Screen]]
- [[_COMMUNITY_Add Patient State Management|Add Patient State Management]]
- [[_COMMUNITY_Family Details & Colors|Family Details & Colors]]
- [[_COMMUNITY_OCR Response Models|OCR Response Models]]
- [[_COMMUNITY_Patient Registration Step 2|Patient Registration Step 2]]
- [[_COMMUNITY_Windows Desktop Build|Windows Desktop Build]]
- [[_COMMUNITY_Signup & Auth State|Signup & Auth State]]
- [[_COMMUNITY_JWT Auth & Security|JWT Auth & Security]]
- [[_COMMUNITY_Gemini AI Integration|Gemini AI Integration]]
- [[_COMMUNITY_Backend App & AI Clients|Backend App & AI Clients]]
- [[_COMMUNITY_Task Management|Task Management]]
- [[_COMMUNITY_Patient Sync & Conflicts|Patient Sync & Conflicts]]
- [[_COMMUNITY_Medical Document DTOs|Medical Document DTOs]]
- [[_COMMUNITY_Splash Screen|Splash Screen]]
- [[_COMMUNITY_Branding & App Identity|Branding & App Identity]]
- [[_COMMUNITY_Linux Desktop Runner|Linux Desktop Runner]]
- [[_COMMUNITY_Android Splash Assets|Android Splash Assets]]
- [[_COMMUNITY_OCR Service Dependencies|OCR Service Dependencies]]
- [[_COMMUNITY_iOS App Icons (Small)|iOS App Icons (Small)]]
- [[_COMMUNITY_OCR Service Core|OCR Service Core]]
- [[_COMMUNITY_OCR Parser Service|OCR Parser Service]]
- [[_COMMUNITY_iOS Launch Assets|iOS Launch Assets]]
- [[_COMMUNITY_iOSmacOS AppDelegate|iOS/macOS AppDelegate]]
- [[_COMMUNITY_Android Splash Branding|Android Splash Branding]]
- [[_COMMUNITY_Patient Form Data Models|Patient Form Data Models]]
- [[_COMMUNITY_macOS Desktop Runner|macOS Desktop Runner]]
- [[_COMMUNITY_Windows Runner Core|Windows Runner Core]]
- [[_COMMUNITY_App Icons & OAuth Assets|App Icons & OAuth Assets]]
- [[_COMMUNITY_Platform Test Runners|Platform Test Runners]]
- [[_COMMUNITY_Patient Form Validation|Patient Form Validation]]
- [[_COMMUNITY_Ollama AI Service|Ollama AI Service]]
- [[_COMMUNITY_Placeholder Patient Avatars|Placeholder Patient Avatars]]
- [[_COMMUNITY_Patient Profile Photos|Patient Profile Photos]]
- [[_COMMUNITY_Spring Security Config|Spring Security Config]]
- [[_COMMUNITY_iOS Debug Utilities|iOS Debug Utilities]]
- [[_COMMUNITY_Medical Condition Model|Medical Condition Model]]
- [[_COMMUNITY_Task Data Model|Task Data Model]]
- [[_COMMUNITY_OCR Image Preprocessor|OCR Image Preprocessor]]
- [[_COMMUNITY_Async Processing Config|Async Processing Config]]
- [[_COMMUNITY_Family Entity|Family Entity]]
- [[_COMMUNITY_Family-Patient Entity|Family-Patient Entity]]
- [[_COMMUNITY_Medical Document Entity|Medical Document Entity]]
- [[_COMMUNITY_Android Plugin Registry|Android Plugin Registry]]
- [[_COMMUNITY_iOS Plugin Registry|iOS Plugin Registry]]
- [[_COMMUNITY_UI Dimensions Constants|UI Dimensions Constants]]
- [[_COMMUNITY_Family Data Model|Family Data Model]]
- [[_COMMUNITY_Shared Patient Stock Photos|Shared Patient Stock Photos]]
- [[_COMMUNITY_Family Details DTO|Family Details DTO]]
- [[_COMMUNITY_Family Info DTO|Family Info DTO]]
- [[_COMMUNITY_Family-Patient Response DTO|Family-Patient Response DTO]]
- [[_COMMUNITY_Family Registration Request DTO|Family Registration Request DTO]]
- [[_COMMUNITY_Family Registration Response DTO|Family Registration Response DTO]]
- [[_COMMUNITY_Patient Data DTO|Patient Data DTO]]
- [[_COMMUNITY_Drug Master Entity|Drug Master Entity]]
- [[_COMMUNITY_Lab Reference Range Entity|Lab Reference Range Entity]]
- [[_COMMUNITY_Lab Result Entity|Lab Result Entity]]
- [[_COMMUNITY_Medicine Entity|Medicine Entity]]
- [[_COMMUNITY_Android Main Activity|Android Main Activity]]
- [[_COMMUNITY_App Config|App Config]]
- [[_COMMUNITY_Sync Status Model|Sync Status Model]]
- [[_COMMUNITY_Input Validation|Input Validation]]
- [[_COMMUNITY_Cartoon Patient Avatars|Cartoon Patient Avatars]]
- [[_COMMUNITY_Web Splash Screens|Web Splash Screens]]
- [[_COMMUNITY_OCR Confidence Rationale|OCR Confidence Rationale]]
- [[_COMMUNITY_OCR Confidence Rationale 2|OCR Confidence Rationale 2]]
- [[_COMMUNITY_OCR Confidence Rationale 3|OCR Confidence Rationale 3]]
- [[_COMMUNITY_Gemini Service Rationale|Gemini Service Rationale]]
- [[_COMMUNITY_Image Preprocessor Rationale|Image Preprocessor Rationale]]
- [[_COMMUNITY_Parser Service Rationale|Parser Service Rationale]]
- [[_COMMUNITY_iOS Icon Variants (50-76px)|iOS Icon Variants (50-76px)]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter_riverpod/flutter_riverpod.dart` - 32 edges
2. `package:flutter/material.dart` - 29 edges
3. `dart:convert` - 17 edges
4. `package:frontend/localization/app_localizations.dart` - 16 edges
5. `AshaSathi Flutter App (frontend)` - 16 edges
6. `Patient Module README` - 14 edges
7. `MedicalDocumentService` - 12 edges
8. `package:google_fonts/google_fonts.dart` - 12 edges
9. `package:frontend/constants/app_colors.dart` - 12 edges
10. `_` - 12 edges

## Surprising Connections (you probably didn't know these)
- `POST /api/families Endpoint` --references--> `Spring Boot Backend`  [INFERRED]
  frontend/lib/patient/ADD_PATIENT_GUIDE.md → Backend/HELP.md
- `App Background Image (Blank/Empty)` --conceptually_related_to--> `AshaSathi Brand Logo`  [INFERRED]
  Frontend/android/app/src/main/res/drawable/background.png → frontend/android/app/src/main/res/drawable-hdpi/android12splash.png
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  frontend\linux\runner\my_application.cc → frontend\linux\flutter\generated_plugin_registrant.cc
- `main()` --calls--> `my_application_new()`  [INFERRED]
  frontend\linux\runner\main.cc → frontend\linux\runner\my_application.cc
- `OnCreate()` --calls--> `RegisterPlugins()`  [INFERRED]
  frontend\windows\runner\flutter_window.cpp → frontend\windows\flutter\generated_plugin_registrant.cc

## Hyperedges (group relationships)
- **Real photograph patient profile group - adult male** —  [INFERRED]
- **Cartoon avatar patient profile group - young male** —  [INFERRED]
- **Pixel art placeholder patient profile group** —  [INFERRED]
- **All AshaSathi Splash Screen Assets** —  [INFERRED]
- **AshaSathi Brand Identity Assets** —  [CONFIRMED 0.98]
- **Social OAuth Login Button Icons** —  [CONFIRMED 0.96]
- **iOS Launch Screen Visual Composition** —  [EXPLICIT 0.96]
- **macOS App Icon Size Set (Flutter Default)** —  [EXPLICIT 0.97]
- **All Flutter Default Icon Assets** —  [INFERRED 0.97]
- **AshaSathi Web Dark Splash â€” All Densities** —  [INFERRED 0.99]

## Communities

### Community 0 - "Offline Data Sync Layer"
Cohesion: 0.02
Nodes (95): app_database_offline.dart, ../config/app_config.dart, connectivity_service.dart, _addColumnIfMissing, AppDatabaseOffline, _createFamilyTables, openDatabase, ConnectivityService (+87 more)

### Community 1 - "App Settings & Shell"
Cohesion: 0.02
Nodes (95): AppLocaleNotifier, AppThemeModeNotifier, Locale, _serialize, AshaSathiApp, build, MaterialApp, MaterialPageRoute (+87 more)

### Community 2 - "Patient Detail UI"
Cohesion: 0.03
Nodes (73): build, _buildGlassAppBar, _buildPatientImage, Column, _confirmDelete, Container, _deleteButton, Exception (+65 more)

### Community 3 - "Dashboard & Bootstrap"
Cohesion: 0.03
Nodes (72): copyWith, DashboardBootstrapNotifier, DashboardBootstrapState, syncAll, build, _buildRecentPatientsSkeleton, _buildTaskSkeletonSliver, Center (+64 more)

### Community 4 - "Family API & Services"
Cohesion: 0.03
Nodes (41): FamilyController, build, _buildFilters, _buildFiltersHeader, _buildGlassAppBar, _buildOrb, _buildPatientsList, _buildPatientsSkeletonList (+33 more)

### Community 5 - "Add Patient Wizard (Docs)"
Cohesion: 0.05
Nodes (52): addPatientFormProvider (StateNotifierProvider), AddPatientFormState, AddPatientNotifier (StateNotifier), Add Patient Screen (3-Step Wizard), POST /api/families Endpoint, canProceedToNextStepProvider (Computed Provider), currentPatientProvider (Computed Provider), Disease Selection Grid (10 diseases) (+44 more)

### Community 6 - "Navigation & Routing"
Cohesion: 0.04
Nodes (50): ../app/app_settings_controller.dart, AddPatientPageNew, AlertDialog, build, _buildAppBarTitle, _buildAppBarTitleWithLogout, _buildDrawer, _buildFamilyLoadingSkeleton (+42 more)

### Community 7 - "App Theme & Styling"
Cohesion: 0.04
Nodes (46): app/app_shell.dart, AppPageTransitionsBuilder, AppScrollBehavior, BouncingScrollPhysics, buildDarkTheme, buildLightTheme, buildOverscrollIndicator, FadeTransition (+38 more)

### Community 8 - "Authentication UI"
Cohesion: 0.04
Nodes (47): Align, BorderSide, build, _buildGlassField, _buildGlassLogo, _buildGoogleButton, _buildLabel, _buildLoginButton (+39 more)

### Community 9 - "Linux Desktop Build"
Cohesion: 0.05
Nodes (48): Linux Application ID: com.example.frontend, Linux Binary Name: frontend, GTK+ 3.0 Dependency (Linux), Linux CMakeLists (Root Project Config), Linux Flutter CMakeLists (Flutter Build Steps), GIO 2.0 Dependency (Linux), GLib 2.0 Dependency (Linux), libflutter_linux_gtk.so (Flutter Linux Library) (+40 more)

### Community 10 - "Medical Documents Backend"
Cohesion: 0.06
Nodes (17): MedicalDocumentController, _AddPatientFormState, DeepCollectionEquality, EqualUnmodifiableListView, EqualUnmodifiableMapView, _FamilyInfo, identical, _PatientDataModel (+9 more)

### Community 11 - "Medical Vision Screen"
Cohesion: 0.05
Nodes (41): _actionButton, build, _buildConfidenceBadge, _buildConfirmButton, _buildDiagnosisCard, _buildHeader, _buildImagePicker, _buildLabResultsSection (+33 more)

### Community 12 - "Add Patient State Management"
Cohesion: 0.05
Nodes (38): addPatient, AddPatientNotifier, clearError, goToStep, nextStep, previousStep, RegisteredFamilySnapshot, removePatient (+30 more)

### Community 13 - "Family Details & Colors"
Cohesion: 0.05
Nodes (37): add_patient_models.dart, ../app/dashboard_bootstrap_controller.dart, ../constants/app_colors.dart, build, Column, Container, _detailItem, FamilyDetailsPage (+29 more)

### Community 14 - "OCR Response Models"
Cohesion: 0.09
Nodes (29): BaseModel, Enum, ConfidenceLevel, GeminiParseResponse, LabTestSchema, MedicalDataExtraction, MedicineSchema, OCRExtractionResponse (+21 more)

### Community 15 - "Patient Registration Step 2"
Cohesion: 0.06
Nodes (30): build, _buildAddressSection, _buildDateInput, _buildGenderDropdown, _buildPatientTabs, _buildPhotoPicker, _buildPregnancyMonthCounter, _buildPregnancySection (+22 more)

### Community 16 - "Windows Desktop Build"
Cohesion: 0.11
Nodes (19): RegisterPlugins(), FlutterWindow(), OnCreate(), Create(), Destroy(), EnableFullDpiSupportIfAvailable(), GetClientArea(), GetThisFromHandle() (+11 more)

### Community 17 - "Signup & Auth State"
Cohesion: 0.08
Nodes (23): AuthService, copyWith, reset, SignupNotifier, SignupState, clearError, clearSearch, copyWith (+15 more)

### Community 18 - "JWT Auth & Security"
Cohesion: 0.14
Nodes (5): HerokuDataSourceConfig, substring, JwtUtil, OncePerRequestFilter, JwtAuthenticationFilter

### Community 19 - "Gemini AI Integration"
Cohesion: 0.14
Nodes (17): Path, GeminiService, _load_prompt(), _loads_lenient(), _normalize_extraction(), Called once at application startup., POST to Gemini REST API with retry logic.          Tries each model in GEMINI_MO, Load a prompt file from disk and cache it in memory. (+9 more)

### Community 20 - "Backend App & AI Clients"
Cohesion: 0.12
Nodes (10): AshaSathiApplication, CommandLineRunner, MedicalDataSeeder, AppLocalizations, _AppLocalizationsDelegate, isSupported, of, shouldReload (+2 more)

### Community 21 - "Task Management"
Cohesion: 0.1
Nodes (19): TaskOfflineEntity, AddTaskPage, _AddTaskPageState, build, _chipSelectedColor, Color, dispose, _fieldDecoration (+11 more)

### Community 22 - "Patient Sync & Conflicts"
Cohesion: 0.11
Nodes (18): PatientOfflineService, build, _ConflictCard, Container, _fieldRow, Icon, initState, _loadConflicts (+10 more)

### Community 23 - "Medical Document DTOs"
Cohesion: 0.12
Nodes (16): DocumentResponse, ExtractedLabTest, ExtractedMedicine, GeminiLabTest, GeminiMedicalData, GeminiMedicine, GeminiParseRequest, GeminiParseResponse (+8 more)

### Community 24 - "Splash Screen"
Cohesion: 0.12
Nodes (15): build, _buildOrb, Column, Container, dispose, initState, _LoadingDots, Padding (+7 more)

### Community 25 - "Branding & App Identity"
Cohesion: 0.18
Nodes (16): macOS App Icon 512px (Flutter Default), macOS App Icon 64px (Flutter Default), AshaSathi Brand Identity Logo, Branding Inconsistency: Icons vs Splash, Flutter Default App Icon, macOS App Icon Set, Progressive Web App (PWA) Icon Set, Web Dark Mode Splash Screen Set (+8 more)

### Community 26 - "Linux Desktop Runner"
Cohesion: 0.14
Nodes (4): fl_register_plugins(), main(), my_application_activate(), my_application_new()

### Community 27 - "Android Splash Assets"
Cohesion: 0.23
Nodes (14): Android 12 Splash (Night, MDPI), Android 12 Splash (Night, XHDPI), Android 12 Splash (Night, XXHDPI), Android 12 Splash (Night, XXXHDPI), Android 12 Splash (Light, XHDPI), Android 12 Splash (Light, XXHDPI), Android 12 Splash (Light, XXXHDPI), AshaSathi Logo Design (+6 more)

### Community 28 - "OCR Service Dependencies"
Cohesion: 0.21
Nodes (13): OCR Benchmark Result (init=2.8s), FastAPI (>=0.100.0), Google Generative AI SDK (>=0.7.0), HTTPX HTTP Client (>=0.25.0), NumPy (>=1.24.0), OpenCV Python (>=4.8.0.0), PaddleOCR (>=2.7.3), PaddlePaddle (>=2.6.0) (+5 more)

### Community 29 - "iOS App Icons (Small)"
Cohesion: 0.2
Nodes (10): AshaSathi iOS App Icon 20x20 @1x, AshaSathi iOS App Icon 20x20 @2x, AshaSathi iOS App Icon 20x20 @3x, AshaSathi iOS App Icon 29x29 @1x, AshaSathi iOS App Icon 29x29 @2x, AshaSathi iOS App Icon 29x29 @3x, AshaSathi iOS App Icon 40x40 @1x, AshaSathi iOS App Icon 40x40 @2x (+2 more)

### Community 30 - "OCR Service Core"
Cohesion: 0.28
Nodes (4): OCRService, Run PaddleOCR extraction on the preprocessed image., Initializes the PaddleOCR model once during application startup.         Ensures, Applies image preprocessing to improve OCR accuracy and speed.         1. Valida

### Community 31 - "OCR Parser Service"
Cohesion: 0.28
Nodes (4): ParserService, Cleans markdown wrappers, whitespace, or trailing garbage from the AI response., Performs basic heuristic repairs on slightly malformed JSON strings.         - F, Parses raw text from the AI response, cleans/repairs it, and ensures it conforms

### Community 32 - "iOS Launch Assets"
Cohesion: 0.28
Nodes (9): AshaSathi Brand Identity, Flutter Framework Default Placeholder Icon, AshaSathi iOS App Icon (83.5x83.5@2x), iOS Launch Screen Background, AshaSathi iOS Launch Image @2x, AshaSathi iOS Launch Image @3x, AshaSathi iOS Launch Image (1x / 2x / 3x), macOS App Icon 1024px (Flutter Default) (+1 more)

### Community 33 - "iOS/macOS AppDelegate"
Cohesion: 0.29
Nodes (2): FlutterAppDelegate, AppDelegate

### Community 34 - "Android Splash Branding"
Cohesion: 0.43
Nodes (7): AshaSathi Brand Logo, App Background Image (Blank/Empty), AshaSathi Android 12 Splash Logo (HDPI), AshaSathi Splash Screen Logo (HDPI), AshaSathi Android 12 Splash Logo (MDPI), AshaSathi Splash Screen Logo (MDPI), AshaSathi Android 12 Splash Logo Night/HDPI

### Community 35 - "Patient Form Data Models"
Cohesion: 0.33
Nodes (5): AddPatientFormState, FamilyInfo, PatientDataModel, PatientRegistrationPayload, package:freezed_annotation/freezed_annotation.dart

### Community 36 - "macOS Desktop Runner"
Cohesion: 0.33
Nodes (3): RegisterGeneratedPlugins(), NSWindow, MainFlutterWindow

### Community 37 - "Windows Runner Core"
Cohesion: 0.47
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 38 - "App Icons & OAuth Assets"
Cohesion: 0.53
Nodes (6): AshaSathi Main App Icon (AshaIcon), GitHub Social Login Button Icon, Google Social Login Button Icon, AshaSathi Android App Launcher Icon, AshaSathi Flutter Splash Screen (splash1), AshaSathi Splash Screen Brand Logo

### Community 39 - "Platform Test Runners"
Cohesion: 0.4
Nodes (2): RunnerTests, XCTestCase

### Community 40 - "Patient Form Validation"
Cohesion: 0.4
Nodes (4): AddPatientFormData, copyWith, isValidForPatientStep, package:frontend/patient/medical_model.dart

### Community 41 - "Ollama AI Service"
Cohesion: 0.4
Nodes (2): OllamaService, Sends a generation request to the local Ollama server, requesting raw JSON text.

### Community 42 - "Placeholder Patient Avatars"
Cohesion: 0.4
Nodes (5): Patient 11 Profile Photo, Patient 19 Profile Photo, Patient 21 Profile Photo, Patient 23 Profile Photo, Patient 25 Profile Photo

### Community 43 - "Patient Profile Photos"
Cohesion: 0.6
Nodes (5): AshaSathi Patient Profile System, Patient 3 Profile Photo (Pixelated Green Game Character), Patient 4 Profile Photo (Young Adult Male), Patient 5 Profile Photo (Pixelated Green Game Character), Patient 6 Profile Photo (Young Adult Male)

### Community 44 - "Spring Security Config"
Cohesion: 0.5
Nodes (1): SecurityConfig

### Community 45 - "iOS Debug Utilities"
Cohesion: 0.5
Nodes (2): handle_new_rx_page(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.

### Community 46 - "Medical Condition Model"
Cohesion: 0.5
Nodes (3): copyWith, MedicalCondition, PatientMedicalInfo

### Community 47 - "Task Data Model"
Cohesion: 0.5
Nodes (3): _fromBackendStatus, TaskModel, _toBackendStatus

### Community 48 - "OCR Image Preprocessor"
Cohesion: 0.5
Nodes (2): ImagePreprocessor, Standalone image preprocessing pipeline optimised for medical document OCR.

### Community 49 - "Async Processing Config"
Cohesion: 0.67
Nodes (1): AsyncConfig

### Community 50 - "Family Entity"
Cohesion: 0.67
Nodes (1): Family

### Community 51 - "Family-Patient Entity"
Cohesion: 0.67
Nodes (1): FamilyPatient

### Community 52 - "Medical Document Entity"
Cohesion: 0.67
Nodes (1): MedicalDocument

### Community 53 - "Android Plugin Registry"
Cohesion: 0.67
Nodes (1): GeneratedPluginRegistrant

### Community 54 - "iOS Plugin Registry"
Cohesion: 0.67
Nodes (2): GeneratedPluginRegistrant, -registerWithRegistry

### Community 55 - "UI Dimensions Constants"
Cohesion: 0.67
Nodes (2): AppRadius, AppSpacing

### Community 56 - "Family Data Model"
Cohesion: 0.67
Nodes (2): FamilyMemberRecord, FamilyRecord

### Community 57 - "Shared Patient Stock Photos"
Cohesion: 1.0
Nodes (3): Patient 1 Profile Photo, Patient 20 Profile Photo, Patient 24 Profile Photo

### Community 58 - "Family Details DTO"
Cohesion: 1.0
Nodes (1): FamilyDetailsResponseDTO

### Community 59 - "Family Info DTO"
Cohesion: 1.0
Nodes (1): FamilyInfoDTO

### Community 60 - "Family-Patient Response DTO"
Cohesion: 1.0
Nodes (1): FamilyPatientResponseDTO

### Community 61 - "Family Registration Request DTO"
Cohesion: 1.0
Nodes (1): FamilyRegistrationRequest

### Community 62 - "Family Registration Response DTO"
Cohesion: 1.0
Nodes (1): FamilyRegistrationResponse

### Community 63 - "Patient Data DTO"
Cohesion: 1.0
Nodes (1): PatientDataDTO

### Community 64 - "Drug Master Entity"
Cohesion: 1.0
Nodes (1): DrugMaster

### Community 65 - "Lab Reference Range Entity"
Cohesion: 1.0
Nodes (1): LabReferenceRange

### Community 66 - "Lab Result Entity"
Cohesion: 1.0
Nodes (1): LabResult

### Community 67 - "Medicine Entity"
Cohesion: 1.0
Nodes (1): Medicine

### Community 68 - "Android Main Activity"
Cohesion: 1.0
Nodes (1): MainActivity

### Community 69 - "App Config"
Cohesion: 1.0
Nodes (1): AppConfig

### Community 70 - "Sync Status Model"
Cohesion: 1.0
Nodes (1): SyncStatusOffline

### Community 71 - "Input Validation"
Cohesion: 1.0
Nodes (1): Appvalidator

### Community 72 - "Cartoon Patient Avatars"
Cohesion: 1.0
Nodes (2): Patient 22 Profile Photo, Patient 2 Profile Photo

### Community 73 - "Web Splash Screens"
Cohesion: 1.0
Nodes (2): Web Splash Screen Dark Mode, Web Splash Screen Light Mode

### Community 88 - "OCR Confidence Rationale"
Cohesion: 1.0
Nodes (1): Classify a single confidence score.

### Community 89 - "OCR Confidence Rationale 2"
Cohesion: 1.0
Nodes (1): Add a 'confidence_level' key to each segment dict.         Input  : [{"text": ".

### Community 90 - "OCR Confidence Rationale 3"
Cohesion: 1.0
Nodes (1): Compute a single document-level confidence score.         Uses a weighted mean (

### Community 91 - "Gemini Service Rationale"
Cohesion: 1.0
Nodes (1): Ensure the extracted dict always conforms to the expected schema.

### Community 92 - "Image Preprocessor Rationale"
Cohesion: 1.0
Nodes (1): Apply the full preprocessing pipeline to the image at file_path.         Returns

### Community 93 - "Parser Service Rationale"
Cohesion: 1.0
Nodes (1): Creates the prompt for the Llama 3.1 model based on Phase 4 requirements.

### Community 94 - "iOS Icon Variants (50-76px)"
Cohesion: 1.0
Nodes (1): iOS App Icon Density Variants (50-76px)

## Knowledge Gaps
- **852 isolated node(s):** `FamilyDetailsResponseDTO`, `FamilyInfoDTO`, `FamilyPatientResponseDTO`, `FamilyRegistrationRequest`, `FamilyRegistrationResponse` (+847 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `iOS/macOS AppDelegate`** (7 nodes): `FlutterAppDelegate`, `AppDelegate.swift`, `AppDelegate.swift`, `AppDelegate`, `.application()`, `.applicationShouldTerminateAfterLastWindowClosed()`, `.applicationSupportsSecureRestorableState()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Platform Test Runners`** (5 nodes): `RunnerTests.swift`, `RunnerTests.swift`, `RunnerTests`, `.testExample()`, `XCTestCase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Ollama AI Service`** (5 nodes): `ollama_service.py`, `OllamaService`, `.generate_json()`, `.__init__()`, `Sends a generation request to the local Ollama server, requesting raw JSON text.`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Spring Security Config`** (4 nodes): `SecurityConfig.java`, `SecurityConfig`, `.passwordEncoder()`, `.securityFilterChain()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `iOS Debug Utilities`** (4 nodes): `handle_new_rx_page()`, `__lldb_init_module()`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `flutter_lldb_helper.py`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `OCR Image Preprocessor`** (4 nodes): `image_preprocessor.py`, `ImagePreprocessor`, `preprocess()`, `Standalone image preprocessing pipeline optimised for medical document OCR.`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Async Processing Config`** (3 nodes): `AsyncConfig.java`, `AsyncConfig`, `.medicalProcessingExecutor()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Family Entity`** (3 nodes): `Family.java`, `Family`, `.onUpdate()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Family-Patient Entity`** (3 nodes): `FamilyPatient.java`, `FamilyPatient`, `.onUpdate()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Medical Document Entity`** (3 nodes): `MedicalDocument.java`, `MedicalDocument`, `.preUpdate()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Android Plugin Registry`** (3 nodes): `GeneratedPluginRegistrant.java`, `GeneratedPluginRegistrant`, `.registerWith()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `iOS Plugin Registry`** (3 nodes): `GeneratedPluginRegistrant.m`, `GeneratedPluginRegistrant`, `-registerWithRegistry`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `UI Dimensions Constants`** (3 nodes): `AppRadius`, `AppSpacing`, `app_dimensions.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Family Data Model`** (3 nodes): `FamilyMemberRecord`, `FamilyRecord`, `family_model.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Family Details DTO`** (2 nodes): `FamilyDetailsResponseDTO.java`, `FamilyDetailsResponseDTO`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Family Info DTO`** (2 nodes): `FamilyInfoDTO.java`, `FamilyInfoDTO`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Family-Patient Response DTO`** (2 nodes): `FamilyPatientResponseDTO.java`, `FamilyPatientResponseDTO`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Family Registration Request DTO`** (2 nodes): `FamilyRegistrationRequest.java`, `FamilyRegistrationRequest`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Family Registration Response DTO`** (2 nodes): `FamilyRegistrationResponse.java`, `FamilyRegistrationResponse`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Patient Data DTO`** (2 nodes): `PatientDataDTO.java`, `PatientDataDTO`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Drug Master Entity`** (2 nodes): `DrugMaster.java`, `DrugMaster`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Lab Reference Range Entity`** (2 nodes): `LabReferenceRange.java`, `LabReferenceRange`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Lab Result Entity`** (2 nodes): `LabResult.java`, `LabResult`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Medicine Entity`** (2 nodes): `Medicine.java`, `Medicine`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Android Main Activity`** (2 nodes): `MainActivity.kt`, `MainActivity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `App Config`** (2 nodes): `AppConfig`, `app_config.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sync Status Model`** (2 nodes): `SyncStatusOffline`, `sync_status_offline.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Input Validation`** (2 nodes): `Appvalidator`, `app_validator.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Cartoon Patient Avatars`** (2 nodes): `Patient 22 Profile Photo`, `Patient 2 Profile Photo`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Web Splash Screens`** (2 nodes): `Web Splash Screen Dark Mode`, `Web Splash Screen Light Mode`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `OCR Confidence Rationale`** (1 nodes): `Classify a single confidence score.`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `OCR Confidence Rationale 2`** (1 nodes): `Add a 'confidence_level' key to each segment dict.         Input  : [{"text": ".`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `OCR Confidence Rationale 3`** (1 nodes): `Compute a single document-level confidence score.         Uses a weighted mean (`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Gemini Service Rationale`** (1 nodes): `Ensure the extracted dict always conforms to the expected schema.`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Image Preprocessor Rationale`** (1 nodes): `Apply the full preprocessing pipeline to the image at file_path.         Returns`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Parser Service Rationale`** (1 nodes): `Creates the prompt for the Llama 3.1 model based on Phase 4 requirements.`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `iOS Icon Variants (50-76px)`** (1 nodes): `iOS App Icon Density Variants (50-76px)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter_riverpod/flutter_riverpod.dart` connect `App Settings & Shell` to `Offline Data Sync Layer`, `Patient Detail UI`, `Dashboard & Bootstrap`, `Family API & Services`, `Navigation & Routing`, `App Theme & Styling`, `Authentication UI`, `Medical Vision Screen`, `Add Patient State Management`, `Family Details & Colors`, `Patient Registration Step 2`, `Signup & Auth State`, `Task Management`, `Patient Sync & Conflicts`, `Splash Screen`?**
  _High betweenness centrality (0.132) - this node is a cross-community bridge._
- **Why does `package:flutter/material.dart` connect `App Settings & Shell` to `Patient Detail UI`, `Dashboard & Bootstrap`, `Family API & Services`, `Navigation & Routing`, `App Theme & Styling`, `Authentication UI`, `Medical Vision Screen`, `Family Details & Colors`, `Patient Registration Step 2`, `Backend App & AI Clients`, `Task Management`, `Patient Sync & Conflicts`, `Splash Screen`?**
  _High betweenness centrality (0.130) - this node is a cross-community bridge._
- **Why does `substring` connect `JWT Auth & Security` to `Offline Data Sync Layer`?**
  _High betweenness centrality (0.066) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `AshaSathi Flutter App (frontend)` (e.g. with `Offline-First Sync Strategy` and `Add Patient Screen (3-Step Wizard)`) actually correct?**
  _`AshaSathi Flutter App (frontend)` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `FamilyDetailsResponseDTO`, `FamilyInfoDTO`, `FamilyPatientResponseDTO` to the rest of the system?**
  _852 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Offline Data Sync Layer` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `App Settings & Shell` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._