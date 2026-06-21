import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/patient/patient_model.dart';
import 'package:frontend/providers/login_provider.dart';
import 'package:frontend/providers/patient_provider.dart';
import 'package:frontend/screens/medical_vision/medical_vision_api.dart';
import 'package:frontend/constants/app_colors.dart';

/// Lists every scanned medical document with its AI summary, status, date and
/// the patient it was assigned to. Tap a card to see the full detail.
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
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF14B8A6))),
                  error: (e, _) => _errorState('$e', isDark),
                  data: (docs) => docs.isEmpty
                      ? _emptyState(isDark)
                      : RefreshIndicator(
                          color: const Color(0xFF14B8A6),
                          onRefresh: () async =>
                              ref.invalidate(medicalDocumentsProvider),
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 100),
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

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _header(bool isDark) {
    final docsAsync = ref.watch(medicalDocumentsProvider);
    final count = docsAsync.valueOrNull?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: isDark
                    ? const Color(0xFFE0EAF3)
                    : const Color(0xFF1D232B)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Scan History',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFE8EEF3)
                              : const Color(0xFF171A1F),
                        )),
                    if (count > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('$count',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.accentCyan
                                    : AppColors.teal)),
                      ),
                    ],
                  ],
                ),
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
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh_rounded,
                color: isDark
                    ? const Color(0xFFE0EAF3)
                    : const Color(0xFF1D232B)),
          ),
        ],
      ),
    );
  }

  // ── Document card ─────────────────────────────────────────────────────────

  Widget _docCard(MedicalDocSummary doc, bool isDark) {
    final patients = ref.watch(patientListProvider).patients;
    final assignee = _assigneeLabel(doc.patientId, patients);
    final statusColor = _statusColor(doc.processingStatus);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: doc.processingStatus == 'COMPLETED'
              ? () => _openDetail(doc, isDark)
              : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.75),
              border: Border.all(
                  color: doc.hasCritical
                      ? const Color(0xFFDC2626).withValues(alpha: 0.4)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.2))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: assignee + status ──────────────────────────────
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
                    if (doc.hasCritical)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(Icons.crisis_alert_rounded,
                            size: 16, color: const Color(0xFFDC2626)),
                      ),
                    _statusBadge(doc.processingStatus, statusColor),
                  ],
                ),

                // ── Date + document type ────────────────────────────────────
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(_formatDate(doc.createdAt),
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF8294A4)
                                : const Color(0xFF8693A0))),
                    if (doc.documentType != null) ...[
                      const SizedBox(width: 8),
                      _typeChip(doc.documentType!, isDark),
                    ],
                  ],
                ),

                // ── Doctor / hospital ───────────────────────────────────────
                if ((doc.doctorName ?? '').isNotEmpty ||
                    (doc.hospitalName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    [
                      if ((doc.doctorName ?? '').isNotEmpty) doc.doctorName!,
                      if ((doc.hospitalName ?? '').isNotEmpty)
                        doc.hospitalName!,
                    ].join(' · '),
                    style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? const Color(0xFF9FB0C0)
                            : const Color(0xFF667384)),
                  ),
                ],

                // ── Diagnosis ───────────────────────────────────────────────
                if ((doc.diagnosis ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(doc.diagnosis!,
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFD5E1EB)
                              : const Color(0xFF1D232B))),
                ],

                // ── AI summary (truncated to 3 lines) ───────────────────────
                if ((doc.aiSummary ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(doc.aiSummary!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          height: 1.45,
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFFBFCBDA)
                              : const Color(0xFF3A5060))),
                ] else if (doc.processingStatus == 'COMPLETED') ...[
                  const SizedBox(height: 6),
                  Text('No summary available.',
                      style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? const Color(0xFF8294A4)
                              : const Color(0xFF8693A0))),
                ],

                // ── Chips row ───────────────────────────────────────────────
                const SizedBox(height: 10),
                Row(
                  children: [
                    _chip('${doc.medicineCount} medicines', isDark),
                    const SizedBox(width: 8),
                    _chip('${doc.labCount} labs', isDark),
                    if (doc.ocrConfidence != null) ...[
                      const SizedBox(width: 8),
                      _chip(
                          'OCR ${(doc.ocrConfidence! * 100).toStringAsFixed(0)}%',
                          isDark),
                    ],
                    const Spacer(),
                    if (doc.processingStatus == 'COMPLETED')
                      Icon(Icons.chevron_right_rounded,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF8294A4)
                              : const Color(0xFF8693A0)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Full-detail bottom sheet ──────────────────────────────────────────────

  Future<void> _openDetail(MedicalDocSummary doc, bool isDark) async {
    HapticFeedback.lightImpact();
    final token = await ref.read(loginProvider.notifier).getValidToken();
    if (token == null || !mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        doc: doc,
        token: token,
        isDark: isDark,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _assigneeLabel(int? patientId, List<Patient> patients) {
    if (patientId == null) return 'Not assigned (test)';
    for (final p in patients) {
      if (p.id == patientId) return p.name;
    }
    return 'Patient #$patientId';
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(_statusLabel(status),
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _typeChip(String type, bool isDark) {
    final label = type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: AppColors.teal.withValues(alpha: isDark ? 0.15 : 0.10),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.accentCyan : AppColors.teal)),
    );
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
            color: isDark
                ? const Color(0xFF44566A)
                : const Color(0xFFAEBAC5)),
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

// ─── Full-detail bottom sheet ─────────────────────────────────────────────────

class _DetailSheet extends StatefulWidget {
  final MedicalDocSummary doc;
  final String token;
  final bool isDark;

  const _DetailSheet({
    required this.doc,
    required this.token,
    required this.isDark,
  });

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await fetchDocumentDetail(widget.token, widget.doc.id);
      if (!mounted) return;
      setState(() {
        _detail = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0E1A26) : const Color(0xFFF7FBFF),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // drag handle
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            // sheet header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
              child: Row(
                children: [
                  const Icon(Icons.description_rounded,
                      color: Color(0xFF14B8A6), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Scan Detail',
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFFE8EEF3)
                                : const Color(0xFF171A1F))),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        color: isDark
                            ? const Color(0xFF9FB0C0)
                            : const Color(0xFF667384)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF14B8A6)))
                  : _error != null
                      ? Center(
                          child: Text('Failed to load: $_error',
                              style: const TextStyle(
                                  color: Color(0xFFEF4444))))
                      : _body(controller, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(ScrollController controller, bool isDark) {
    final d = _detail!;
    final medicines = d['medicines'] as List? ?? [];
    final labs = d['labResults'] as List? ?? [];
    final summary = (d['aiSummary'] as String? ?? '').trim();
    final ashaActions = (d['ashaActions'] as String? ?? '').trim();
    final actions = ashaActions.isNotEmpty
        ? ashaActions.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : <String>[];
    final hasCritical = labs.any((l) => l['severity'] == 'CRITICAL');

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // ── Meta row ─────────────────────────────────────────────────────
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (d['documentType'] != null)
              _badge(_docTypeLabel(d['documentType']),
                  AppColors.teal, isDark),
            if ((d['ocrConfidence'] as num?) != null)
              _badge(
                  'OCR ${((d['ocrConfidence'] as num) * 100).toStringAsFixed(0)}%',
                  _confColor(d['ocrConfidence'] as double),
                  isDark),
            if ((d['doctorName'] as String? ?? '').isNotEmpty)
              _badge(d['doctorName']!, const Color(0xFF8B5CF6), isDark),
            if ((d['hospitalName'] as String? ?? '').isNotEmpty)
              _badge(d['hospitalName']!, const Color(0xFF0EA5E9), isDark),
          ],
        ),
        const SizedBox(height: 12),

        // ── Diagnosis ─────────────────────────────────────────────────────
        if ((d['diagnosis'] as String? ?? '').isNotEmpty) ...[
          _sectionLabel('Diagnosis', Icons.medical_information_rounded,
              isDark),
          const SizedBox(height: 6),
          _infoBox(d['diagnosis']!, isDark),
          const SizedBox(height: 14),
        ],

        // ── Follow-up ─────────────────────────────────────────────────────
        if ((d['followUpDate'] as String? ?? '').isNotEmpty) ...[
          _sectionLabel('Follow-up Date', Icons.event_rounded, isDark),
          const SizedBox(height: 6),
          _infoBox(d['followUpDate']!, isDark),
          const SizedBox(height: 14),
        ],

        // ── Critical alert ────────────────────────────────────────────────
        if (hasCritical) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.6)),
              color: const Color(0xFFDC2626)
                  .withValues(alpha: isDark ? 0.15 : 0.08),
            ),
            child: Row(
              children: [
                const Icon(Icons.crisis_alert_rounded,
                    color: Color(0xFFDC2626), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'CRITICAL lab values present — review immediately',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFFFF8A80)
                            : const Color(0xFF991B1B)),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── AI Summary ────────────────────────────────────────────────────
        if (summary.isNotEmpty) ...[
          Row(
            children: [
              _sectionLabel(
                  'AI Clinical Summary', Icons.summarize_rounded, isDark),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: summary));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Summary copied'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2)),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.copy_rounded,
                      size: 15,
                      color: isDark
                          ? const Color(0xFF9FB0C0)
                          : const Color(0xFF667384)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _infoBox(summary, isDark),
          const SizedBox(height: 14),
        ],

        // ── ASHA Actions ──────────────────────────────────────────────────
        if (actions.isNotEmpty) ...[
          _sectionLabel(
              'ASHA Action Items', Icons.checklist_rounded, isDark),
          const SizedBox(height: 8),
          ...actions.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(top: 1, right: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF8B5CF6))),
                        ),
                      ),
                      Expanded(
                        child: Text(e.value,
                            style: TextStyle(
                                height: 1.45,
                                color: isDark
                                    ? const Color(0xFFBFCBDA)
                                    : const Color(0xFF3A5060))),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 6),
        ],

        // ── Medicines ─────────────────────────────────────────────────────
        if (medicines.isNotEmpty) ...[
          _sectionLabel(
              'Medicines (${medicines.length})',
              Icons.medication_rounded,
              isDark),
          const SizedBox(height: 8),
          ...medicines.map((m) => _medicineRow(m, isDark)),
          const SizedBox(height: 6),
        ],

        // ── Lab Results ───────────────────────────────────────────────────
        if (labs.isNotEmpty) ...[
          _sectionLabel(
              'Lab Results (${labs.length})',
              Icons.biotech_rounded,
              isDark),
          const SizedBox(height: 8),
          ...labs.map((l) => _labRow(l, isDark)),
        ],
      ],
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _sectionLabel(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: isDark ? AppColors.accentCyan : AppColors.teal),
        const SizedBox(width: 6),
        Text(title,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isDark
                    ? const Color(0xFFE8EEF3)
                    : const Color(0xFF171A1F))),
      ],
    );
  }

  Widget _infoBox(String text, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Text(text,
          style: TextStyle(
              height: 1.5,
              color: isDark
                  ? const Color(0xFFBFCBDA)
                  : const Color(0xFF3A5060))),
    );
  }

  Widget _badge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.2)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? color.withValues(alpha: 0.9)
                  : color.withValues(alpha: 0.85))),
    );
  }

  Widget _medicineRow(Map<String, dynamic> m, bool isDark) {
    final verified = m['verified'] == true;
    final score = m['matchScore'] as int? ?? 0;
    Color borderColor;
    if (verified) {
      borderColor = const Color(0xFF22C55E);
    } else if (score >= 70) {
      borderColor = const Color(0xFFF59E0B);
    } else {
      borderColor = const Color(0xFFEF4444);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.45)),
        color: borderColor.withValues(alpha: isDark ? 0.07 : 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(m['medicineName'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                    verified ? 'Verified' : (score >= 70 ? '$score%' : 'Unknown'),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: borderColor)),
              ),
            ],
          ),
          if ((m['dosage'] as String? ?? '').isNotEmpty ||
              (m['frequency'] as String? ?? '').isNotEmpty ||
              (m['duration'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if ((m['dosage'] as String? ?? '').isNotEmpty)
                  _miniChip('${m['dosage']}', isDark),
                if ((m['frequency'] as String? ?? '').isNotEmpty)
                  _miniChip('${m['frequency']}', isDark),
                if ((m['duration'] as String? ?? '').isNotEmpty)
                  _miniChip('${m['duration']}', isDark),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _labRow(Map<String, dynamic> l, bool isDark) {
    final severity = l['severity'] as String? ?? 'NORMAL';
    Color color;
    IconData icon;
    switch (severity) {
      case 'CRITICAL':
        color = const Color(0xFFDC2626);
        icon = Icons.warning_rounded;
        break;
      case 'HIGH':
        color = const Color(0xFFEF4444);
        icon = Icons.arrow_upward_rounded;
        break;
      case 'LOW':
        color = const Color(0xFFF59E0B);
        icon = Icons.arrow_downward_rounded;
        break;
      default:
        color = const Color(0xFF22C55E);
        icon = Icons.check_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        color: color.withValues(alpha: isDark ? 0.07 : 0.04),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l['testName'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if ((l['referenceRange'] as String? ?? '').isNotEmpty)
                  Text('Ref: ${l['referenceRange']}',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF9FB0C0)
                              : const Color(0xFF667384))),
              ],
            ),
          ),
          Text('${l['value'] ?? ''} ${l['unit'] ?? ''}'.trim(),
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 10, color: color),
                const SizedBox(width: 3),
                Text(severity,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

  String _docTypeLabel(String? type) {
    if (type == null) return '';
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Color _confColor(double conf) {
    if (conf >= 0.90) return const Color(0xFF22C55E);
    if (conf >= 0.75) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
