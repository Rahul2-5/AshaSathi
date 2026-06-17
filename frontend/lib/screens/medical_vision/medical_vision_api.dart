import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/config/app_config.dart';
import 'package:frontend/providers/login_provider.dart';

/// Lightweight view of a scanned medical document, used by the history screen.
class MedicalDocSummary {
  final int id;
  final int? patientId;
  final String processingStatus;
  final String? diagnosis;
  final String? aiSummary;
  final double? ocrConfidence;
  final String? createdAt; // ISO string
  final int medicineCount;
  final int labCount;

  MedicalDocSummary({
    required this.id,
    required this.patientId,
    required this.processingStatus,
    required this.diagnosis,
    required this.aiSummary,
    required this.ocrConfidence,
    required this.createdAt,
    required this.medicineCount,
    required this.labCount,
  });

  factory MedicalDocSummary.fromJson(Map<String, dynamic> j) => MedicalDocSummary(
        id: j['id'] as int,
        patientId: j['patientId'] as int?,
        processingStatus: j['processingStatus'] ?? 'PENDING',
        diagnosis: j['diagnosis'],
        aiSummary: j['aiSummary'],
        ocrConfidence: (j['ocrConfidence'] as num?)?.toDouble(),
        createdAt: j['createdAt']?.toString(),
        medicineCount: (j['medicines'] as List?)?.length ?? 0,
        labCount: (j['labResults'] as List?)?.length ?? 0,
      );
}

/// Fetches every scanned medical document (newest first) for the history screen.
final medicalDocumentsProvider =
    FutureProvider.autoDispose<List<MedicalDocSummary>>((ref) async {
  final token = await ref.read(loginProvider.notifier).getValidToken();
  if (token == null || token.isEmpty) {
    throw Exception('Session expired. Please login again.');
  }

  final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/medical-documents');
  final resp = await http
      .get(uri, headers: {'Authorization': 'Bearer $token'})
      .timeout(const Duration(seconds: 20));

  if (resp.statusCode != 200) {
    throw Exception('Failed to load documents (${resp.statusCode})');
  }

  final List data = jsonDecode(resp.body);
  return data
      .map((e) => MedicalDocSummary.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Assigns a scanned document to a patient, or clears the assignment when
/// [patientId] is null ("just a test — don't assign to anyone").
Future<void> assignDocumentToPatient(
  String token,
  int docId,
  int? patientId,
) async {
  final uri =
      Uri.parse('${AppConfig.apiBaseUrl}/api/medical-documents/$docId/assign');
  final resp = await http
      .patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'patientId': patientId}),
      )
      .timeout(const Duration(seconds: 20));

  if (resp.statusCode != 200) {
    throw Exception('Failed to assign patient (${resp.statusCode})');
  }
}
