import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/patient/patient_model.dart';
import 'package:frontend/providers/login_provider.dart';
import 'package:frontend/providers/patient_provider.dart';
import 'package:frontend/screens/medical_vision/medical_vision_api.dart';

/// Lists every scanned medical document with its AI summary, status, date and
/// the patient it was assigned to (or "Not assigned" for one-off tests).
class MedicalVisionHistoryScreen extends ConsumerStatefulWidget {
  const MedicalVisionHistoryScreen({super.key});

  @override
  ConsumerState<MedicalVisionHistoryScreen> createState() =>
      _MedicalVisionHistoryScreenState();
}

class _MedicalVisionHistoryScreenState
    extends ConsumerState<MedicalVisionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load patients so we can show names next to each scan.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = ref.read(patientListProvider);
      if (state.patients.isEmpty && !state.loading) {
        final token = await ref.read(loginProvider.notifier).getValidToken();
        if (token != null && token.isNotEmpty) {
          ref.read(patientListProvider.notifier).loadPatients(token);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final docsAsync = ref.watch(medicalDocumentsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0B1120), Color(0xFF0E1A26), Color(0xFF091018)]
                : const [Color(0xFFE8F8F5), Color(0xFFF0F4FF), Color(0xFFF7FBFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(isDark),
              Expanded(
                child: docsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _errorState('$e', isDark),
                  data: (docs) => docs.isEmpty
                      ? _emptyState(isDark)
                      : RefreshIndicator(
                          onRefresh: () async =>
                              ref.invalidate(medicalDocumentsProvider),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: docs.length,
                            itemBuilder: (_, i) => _docCard(docs[i], isDark),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 18,
                color:
                    isDark ? const Color(0xFFE0EAF3) : const Color(0xFF1D232B)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scan History',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFE8EEF3)
                          : const Color(0xFF171A1F),
                    )),
                Text('All AI-analysed documents',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF9FB0C0)
                          : const Color(0xFF667384),
                    )),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ref.invalidate(medicalDocumentsProvider),
            icon: Icon(Icons.refresh_rounded,
                color:
                    isDark ? const Color(0xFFE0EAF3) : const Color(0xFF1D232B)),
          ),
        ],
      ),
    );
  }

  Widget _docCard(MedicalDocSummary doc, bool isDark) {
    final patients = ref.watch(patientListProvider).patients;
    final assignee = _assigneeLabel(doc.patientId, patients);
    final statusColor = _statusColor(doc.processingStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.7),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assignee + status row
          Row(
            children: [
              Icon(
                  doc.patientId == null
                      ? Icons.science_outlined
                      : Icons.person_rounded,
                  size: 18,
                  color: doc.patientId == null
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF14B8A6)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(assignee,
                    style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFE8EEF3)
                            : const Color(0xFF171A1F))),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel(doc.processingStatus),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(_formatDate(doc.createdAt),
              style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF8294A4)
                      : const Color(0xFF8693A0))),

          if (doc.diagnosis != null && doc.diagnosis!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(doc.diagnosis!,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFD5E1EB)
                        : const Color(0xFF1D232B))),
          ],

          if (doc.aiSummary != null && doc.aiSummary!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(doc.aiSummary!,
                style: TextStyle(
                    height: 1.45,
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFFBFCBDA)
                        : const Color(0xFF3A5060))),
          ] else if (doc.processingStatus == 'COMPLETED') ...[
            const SizedBox(height: 8),
            Text('No summary available.',
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? const Color(0xFF8294A4)
                        : const Color(0xFF8693A0))),
          ],

          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _chip('${doc.medicineCount} medicines', isDark),
              _chip('${doc.labCount} lab results', isDark),
              if (doc.ocrConfidence != null)
                _chip('OCR ${(doc.ocrConfidence! * 100).toStringAsFixed(0)}%',
                    isDark),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _assigneeLabel(int? patientId, List<Patient> patients) {
    if (patientId == null) return 'Not assigned (test)';
    for (final p in patients) {
      if (p.id == patientId) return p.name;
    }
    return 'Patient #$patientId';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'COMPLETED':
        return 'Completed';
      case 'FAILED':
        return 'Failed';
      case 'PROCESSING':
        return 'Processing';
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return const Color(0xFF22C55E);
      case 'FAILED':
        return const Color(0xFFEF4444);
      case 'PROCESSING':
        return const Color(0xFF0EA5E9);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}  '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Widget _chip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.05),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? const Color(0xFFB0C4D3)
                  : const Color(0xFF4A5568))),
    );
  }

  Widget _emptyState(bool isDark) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.history_toggle_off_rounded,
            size: 56,
            color: isDark ? const Color(0xFF44566A) : const Color(0xFFAEBAC5)),
        const SizedBox(height: 12),
        Center(
          child: Text('No scans yet',
              style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFC4D2DF)
                      : const Color(0xFF55636F))),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text('Analysed documents will appear here.',
              style: TextStyle(
                  color: isDark
                      ? const Color(0xFF8294A4)
                      : const Color(0xFF8693A0))),
        ),
      ],
    );
  }

  Widget _errorState(String msg, bool isDark) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Center(
            child: Icon(Icons.error_outline_rounded,
                size: 48, color: Color(0xFFEF4444))),
        const SizedBox(height: 12),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(msg,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark
                        ? const Color(0xFF9FB0C0)
                        : const Color(0xFF667384))),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => ref.invalidate(medicalDocumentsProvider),
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}
