import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/patient/patient_model.dart';
import 'package:frontend/providers/patient_provider.dart';
import 'package:frontend/screens/medical_vision/medical_vision_api.dart';

/// Bottom sheet that lets the user assign a scanned document to a registered
/// patient, or mark it as a one-off test ("don't assign to anyone").
///
/// Returns true if the assignment (including the explicit "don't assign" choice)
/// succeeded, null if the user dismissed the sheet without choosing.
Future<bool?> showPatientAssignSheet({
  required BuildContext context,
  required int docId,
  required String token,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PatientAssignSheet(docId: docId, token: token),
  );
}

class _PatientAssignSheet extends ConsumerStatefulWidget {
  final int docId;
  final String token;
  const _PatientAssignSheet({required this.docId, required this.token});

  @override
  ConsumerState<_PatientAssignSheet> createState() => _PatientAssignSheetState();
}

class _PatientAssignSheetState extends ConsumerState<_PatientAssignSheet> {
  String _query = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Ensure the patient list is loaded for the picker.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(patientListProvider);
      if (state.patients.isEmpty && !state.loading) {
        ref.read(patientListProvider.notifier).loadPatients(widget.token);
      }
    });
  }

  Future<void> _assign(int? patientId) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await assignDocumentToPatient(widget.token, widget.docId, patientId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Could not save: $e'),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(patientListProvider);
    final patients = _filter(state.patients);

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0E1A26) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.assignment_ind_rounded,
                      color: Color(0xFF14B8A6)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Whose report is this?',
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFFE8EEF3)
                                : const Color(0xFF171A1F))),
                  ),
                ],
              ),
            ),

            // ── "Don't assign" option ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _submitting ? null : () => _assign(null),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.science_outlined,
                          color: Color(0xFFF59E0B)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Don't assign — just a test",
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFFE8EEF3)
                                        : const Color(0xFF171A1F))),
                            Text('Save the scan without linking it to a patient',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? const Color(0xFF9FB0C0)
                                        : const Color(0xFF667384))),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFFF59E0B)),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Row(
                children: [
                  Text('Or assign to a patient',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF9FB0C0)
                              : const Color(0xFF667384))),
                ],
              ),
            ),

            // ── Search ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search patients…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Patient list ───────────────────────────────────────────────
            Flexible(
              child: state.loading && patients.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(),
                    )
                  : patients.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(28),
                          child: Text(
                              state.patients.isEmpty
                                  ? 'No registered patients yet.'
                                  : 'No patients match "$_query".',
                              style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF9FB0C0)
                                      : const Color(0xFF667384))),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                          itemCount: patients.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (_, i) =>
                              _patientTile(patients[i], isDark),
                        ),
            ),
            if (_submitting)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        ),
      ),
    );
  }

  List<Patient> _filter(List<Patient> all) {
    // Only patients with a server id can be assigned (FK needs the backend id).
    final assignable = all.where((p) => p.id != null);
    if (_query.trim().isEmpty) return assignable.toList();
    final q = _query.toLowerCase();
    return assignable
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.phoneNumber.toLowerCase().contains(q))
        .toList();
  }

  Widget _patientTile(Patient p, bool isDark) {
    return ListTile(
      onTap: _submitting ? null : () => _assign(p.id),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: CircleAvatar(
        backgroundColor: AppColors.teal.withValues(alpha: 0.15),
        child: Text(
          p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
          style: const TextStyle(
              color: Color(0xFF14B8A6), fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(p.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${p.gender}, ${p.age} yrs'
          '${p.phoneNumber.isNotEmpty ? ' · ${p.phoneNumber}' : ''}'),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
