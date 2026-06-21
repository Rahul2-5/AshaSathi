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
  final String? documentType;
  final String? diagnosis;
  final String? doctorName;
  final String? hospitalName;
  final String? aiSummary;
  final String? ashaActions;
  final double? ocrConfidence;
  final String? createdAt; // ISO string
  final int medicineCount;
  final int labCount;
  final bool hasCritical;

  MedicalDocSummary({
    required this.id,
    required this.patientId,
    required this.processingStatus,
    this.documentType,
    required this.diagnosis,
    this.doctorName,
    this.hospitalName,
    required this.aiSummary,
    this.ashaActions,
    required this.ocrConfidence,
    required this.createdAt,
    required this.medicineCount,
    required this.labCount,
    required this.hasCritical,
  });

  factory MedicalDocSummary.fromJson(Map<String, dynamic> j) {
    final labs = j['labResults'] as List? ?? [];
    return MedicalDocSummary(
      id: j['id'] as int,
      patientId: j['patientId'] as int?,
      processingStatus: j['processingStatus'] ?? 'PENDING',
      documentType: j['documentType'],
      diagnosis: j['diagnosis'],
      doctorName: j['doctorName'],
      hospitalName: j['hospitalName'],
      aiSummary: j['aiSummary'],
      ashaActions: j['ashaActions'],
      ocrConfidence: (j['ocrConfidence'] as num?)?.toDouble(),
      createdAt: j['createdAt']?.toString(),
      medicineCount: (j['medicines'] as List?)?.length ?? 0,
      labCount: labs.length,
      hasCritical: labs.any((l) => l['severity'] == 'CRITICAL'),
    );
  }
}

/// Fetches full detail of a single document by id (for the detail bottom sheet).
Future<Map<String, dynamic>?> fetchDocumentDetail(String token, int docId) async {
  final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/medical-documents/$docId');
  final resp = await http
      .get(uri, headers: {'Authorization': 'Bearer $token'})
      .timeout(const Duration(seconds: 15));
  if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
  return null;
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

// ─── Abnormal lab highlight (non-NORMAL results) ──────────────────────────────

class LabHighlight {
  final String testName, value, unit, severity;
  const LabHighlight({
    required this.testName,
    required this.value,
    required this.unit,
    required this.severity,
  });
}

/// Richer model used by the Patient Detail page to show key insights.
class PatientDocHighlight {
  final int id;
  final String processingStatus;
  final String? diagnosis;
  final String? aiSummary;
  final String? followUpDate;
  final double? ocrConfidence;
  final String? createdAt;
  final List<String> medicineNames;
  final List<LabHighlight> abnormalLabs;

  const PatientDocHighlight({
    required this.id,
    required this.processingStatus,
    this.diagnosis,
    this.aiSummary,
    this.followUpDate,
    this.ocrConfidence,
    this.createdAt,
    required this.medicineNames,
    required this.abnormalLabs,
  });

  factory PatientDocHighlight.fromJson(Map<String, dynamic> j) {
    final meds = (j['medicines'] as List? ?? [])
        .map((m) => (m['medicineName'] as String?) ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    final labs = (j['labResults'] as List? ?? [])
        .where((l) =>
            const ['CRITICAL', 'HIGH', 'LOW'].contains(l['severity']))
        .map((l) => LabHighlight(
              testName: l['testName'] ?? '',
              value: l['value'] ?? '',
              unit: l['unit'] ?? '',
              severity: l['severity'] ?? '',
            ))
        .toList();
    return PatientDocHighlight(
      id: j['id'] as int,
      processingStatus: j['processingStatus'] ?? 'PENDING',
      diagnosis: j['diagnosis'],
      aiSummary: j['aiSummary'],
      followUpDate: j['followUpDate'],
      ocrConfidence: (j['ocrConfidence'] as num?)?.toDouble(),
      createdAt: j['createdAt']?.toString(),
      medicineNames: List<String>.from(meds),
      abnormalLabs: List<LabHighlight>.from(labs),
    );
  }
}

/// Fetches completed medical documents for a specific patient (newest first).
final patientMedicalDocsProvider =
    FutureProvider.family<List<PatientDocHighlight>, int>((ref, patientId) async {
  final token = await ref.read(loginProvider.notifier).getValidToken();
  if (token == null || token.isEmpty) return [];

  final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/medical-documents/patient/$patientId');
  final resp = await http
      .get(uri, headers: {'Authorization': 'Bearer $token'})
      .timeout(const Duration(seconds: 15));

  if (resp.statusCode != 200) return [];

  final List data = jsonDecode(resp.body);
  return data
      .map((e) => PatientDocHighlight.fromJson(e as Map<String, dynamic>))
      .where((d) => d.processingStatus == 'COMPLETED')
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
