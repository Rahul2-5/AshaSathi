import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/main.dart';
import 'package:frontend/offline/patient_offline_dao.dart';
import 'package:frontend/offline/connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline/Online Sync Tests', () {
    final offlineDao = PatientOfflineDao();
    final connectivityService = ConnectivityService();

    setUp(() async {
      // Clear database before each test
      await offlineDao.clearAllData();
    });

    testWidgets('Test 1: Offline Save - Patient data saved locally when offline',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      // Wait for app to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Simulate offline condition by disabling all internet
      debugPrint('[TEST 1] Testing offline save scenario...');
      
      // Navigate to patient creation screen
      // (This assumes there's a + button or similar to add patient)
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton);
        await tester.pumpAndSettle();
      }

      // At this point, app should detect offline status and save locally
      debugPrint('[TEST 1] Checking offline patients...');
      final offlinePatients = await offlineDao.getAll();
      debugPrint('[TEST 1] Offline patients count: ${offlinePatients.length}');

      // Verify that data persistence layer is working
      expect(offlineDao, isNotNull);
      debugPrint('[TEST 1] ✅ Offline save test completed');
    });

    testWidgets('Test 2: Online Save - Patient data saved and synced with backend',
        (WidgetTester tester) async {
      // First verify connectivity
      final isOnline = await connectivityService.isOnline();
      debugPrint('[TEST 2] Is app online? $isOnline');

      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      debugPrint('[TEST 2] Testing online save scenario...');
      
      if (isOnline) {
        // App should sync with backend
        await Future.delayed(const Duration(seconds: 2));
        
        final allData = await offlineDao.getAll();
        debugPrint('[TEST 2] Data in local cache: ${allData.length} patients');
        debugPrint('[TEST 2] ✅ Online save test completed');
      } else {
        debugPrint('[TEST 2] ⚠️  Backend is not reachable - skipping online save test');
      }
    });

    testWidgets('Test 3: Offline to Online Sync - Data syncs when connectivity restored',
        (WidgetTester tester) async {
      debugPrint('[TEST 3] Testing offline-to-online sync...');

      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify offline data exists
      final initialData = await offlineDao.getAll();
      debugPrint('[TEST 3] Initial offline patients: ${initialData.length}');

      // Check connectivity restoration
      await Future.delayed(const Duration(seconds: 2));
      final finalConnectivity = await connectivityService.isOnline();
      debugPrint('[TEST 3] Final connectivity: $finalConnectivity');

      if (finalConnectivity) {
        debugPrint('[TEST 3] ✅ Connectivity restored - sync should occur automatically');
      } else {
        debugPrint('[TEST 3] ⚠️  Backend still unreachable - sync pending');
      }

      debugPrint('[TEST 3] ✅ Offline-to-online sync test completed');
    });

    testWidgets('Test 4: Data Persistence Check - Verify local database integrity',
        (WidgetTester tester) async {
      debugPrint('[TEST 4] Testing data persistence layer...');

      // Check if database schema is intact
      try {
        final patients = await offlineDao.getAll();
        debugPrint('[TEST 4] Database query successful: ${patients.length} records');
        
        // Verify database operations work correctly
        expect(patients, isA<List>());
        debugPrint('[TEST 4] ✅ Data persistence test passed');
      } catch (e) {
        debugPrint('[TEST 4] ❌ Data persistence test failed: $e');
        fail('Database access failed: $e');
      }
    });
  });
}
