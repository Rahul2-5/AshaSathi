import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/config/app_config.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:http/http.dart' as http;

import '../auth/cubit/login_cubit.dart';
import '../auth/cubit/patient_cubit.dart';
import '../offline/patient_offline_dao.dart';
import '../offline/patient_sync_service.dart';
import '../offline/connectivity_service.dart';

import 'patient_model.dart';

class PatientDetailPage extends StatefulWidget {
  final Patient patient;

  const PatientDetailPage({
    super.key,
    required this.patient,
  });

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  late Patient _patient;

  static String get baseUrl => AppConfig.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
        title: Text(
          context.l10n.tr('patient.details'),
          style: TextStyle(
            color: isDark ? const Color(0xFFE6EDF3) : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Patient',
            onPressed: _showEditPatientDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileSection(context),
            const SizedBox(height: 24),
            _infoCard(context),
            const SizedBox(height: 28),
            _deleteButton(context),
          ],
        ),
      ),
    );
  }

  // ================= PROFILE =================

  Widget _profileSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        CircleAvatar(
          radius: 55,
          backgroundColor:
              isDark ? const Color(0xFF2A3642) : Colors.grey.shade200,
          child: ClipOval(
            child: SizedBox(
              width: 110,
              height: 110,
              child: _buildPatientImage(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _patient.name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF111418),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _localizedGender(context, _patient.gender),
          style: TextStyle(
            color: isDark ? const Color(0xFF9EABB7) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientImage() {
    final path = _patient.photoPath;

    if (path == null || path.isEmpty) {
      return const Icon(Icons.person, size: 50, color: Colors.grey);
    }

    final normalizedPath = path.replaceAll('\\', '/');
    final isWindowsAbsolutePath = RegExp(r'^[A-Za-z]:[/\\]').hasMatch(path);

    if ((path.startsWith('/') || isWindowsAbsolutePath) && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover);
    }

    if (normalizedPath.startsWith('/uploads/') ||
        normalizedPath.contains('/uploads/')) {
      return Image.network("$baseUrl$normalizedPath", fit: BoxFit.cover);
    }

    return const Icon(Icons.broken_image);
  }

  // ================= INFO =================

  Widget _infoCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1A232C) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow(
              context,
              context.l10n.tr('patient.age'),
              context.l10n.tr('patient.ageYears', args: {'age': _patient.age.toString()}),
            ),
            _divider(),
            _infoRow(context, context.l10n.tr('patient.dateOfBirth'), _patient.dateOfBirth),
            _divider(),
            _infoRow(context, context.l10n.tr('patient.phone'), _patient.phoneNumber),
            _divider(),
            _infoRow(context, context.l10n.tr('patient.address'), _patient.address),
            _divider(),
            _infoRow(context, 'Caste', _patient.caste.isEmpty ? 'Not specified' : _patient.caste),
            _divider(),
            if (_patient.isPregnant) ...[
              _infoRow(context, 'Pregnancy Status', 'Pregnant'),
              _divider(),
              _infoRow(context, 'Months of Pregnancy', _patient.monthsOfPregnancy?.toString() ?? '—'),
              _divider(),
              _infoRow(context, 'Expected Delivery Date', _patient.expectedDeliveryDate ?? '—'),
              _divider(),
            ],
            if (_patient.medicalConditions.isNotEmpty) ...[
              _infoRow(context, 'Medical Conditions', _formatMedicalConditions(_patient.medicalConditions)),
              _divider(),
            ],
            _infoRow(
              context,
              'Description / Notes',
              _patient.description.trim().isEmpty
                  ? 'No notes added'
                  : _patient.description,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    String label,
    String value, {
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(label,
                style: TextStyle(
                    color: isDark
                        ? const Color(0xFFA6B3BF)
                        : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 5,
            child: Text(value,
                maxLines: maxLines,
                overflow: maxLines == 1 ? TextOverflow.ellipsis : TextOverflow.fade,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFFD5E1EB)
                      : const Color(0xFF111418),
                )),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(color: Colors.grey.shade300);

  String _localizedGender(BuildContext context, String raw) {
    final g = raw.trim().toLowerCase();
    if (g == 'male' || g == 'm') return context.l10n.tr('patient.male');
    if (g == 'female' || g == 'f') return context.l10n.tr('patient.female');
    return context.l10n.tr('patient.other');
  }

  String _formatMedicalConditions(List<String> conditionIds) {
    if (conditionIds.isEmpty) return 'None';
    
    final conditionLabels = {
      'bp': 'BP',
      'elephantiasis': 'Elephantiasis',
      'diabetes': 'Diabetes',
      'heart_disease': 'Heart Disease',
      'asthma': 'Asthma',
      'thyroid': 'Thyroid',
      'arthritis': 'Arthritis',
      'kidney_disease': 'Kidney Disease',
      'liver_disease': 'Liver Disease',
      'cancer': 'Cancer',
    };
    
    return conditionIds
        .map((id) => conditionLabels[id] ?? id)
        .join(', ');
  }

  Future<void> _showEditPatientDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: _patient.name);
    final ageController = TextEditingController(text: _patient.age.toString());
    final dobController = TextEditingController(text: _patient.dateOfBirth);
    final addressController = TextEditingController(text: _patient.address);
    final phoneController = TextEditingController(text: _patient.phoneNumber);
    final notesController = TextEditingController(text: _patient.description);
    var selectedGender = _patient.gender;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1B232C) : Colors.white;
    final fieldBg = isDark ? const Color(0xFF24303B) : const Color(0xFFF5F7FA);
    final labelColor = isDark ? const Color(0xFF9FB0BE) : const Color(0xFF637282);
    final textColor = isDark ? const Color(0xFFE4EDF5) : const Color(0xFF1B2026);
    const fieldGap = 12.0;

    InputDecoration sheetFieldDecoration(String label, {Widget? suffixIcon}) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor),
        floatingLabelStyle: TextStyle(color: labelColor),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );
    }

    Widget sectionLabel(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            color: isDark ? const Color(0xFF8FA3B3) : const Color(0xFF5F7283),
            fontSize: 12,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final updated = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> pickDob() async {
              final now = DateTime.now();
              final currentDob = DateTime.tryParse(dobController.text.trim()) ??
                  DateTime(now.year - 20, now.month, now.day);
              final picked = await showDatePicker(
                context: ctx,
                initialDate: currentDob.isAfter(now) ? now : currentDob,
                firstDate: DateTime(1900),
                lastDate: now,
              );
              if (picked == null) return;
              dobController.text =
                  "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 14,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF3A4754)
                                  : const Color(0xFFD2D9E0),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Edit Patient Details',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Update patient profile and notes',
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        sectionLabel('BASIC INFO'),
                        TextFormField(
                          controller: nameController,
                          style: TextStyle(color: textColor),
                          decoration: sheetFieldDecoration('Patient Name'),
                          validator: (v) =>
                              (v == null || v.trim().length < 2) ? 'Enter valid name' : null,
                        ),
                        const SizedBox(height: fieldGap),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: ageController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: textColor),
                                decoration: sheetFieldDecoration('Age'),
                                validator: (v) {
                                  final age = int.tryParse((v ?? '').trim());
                                  if (age == null || age < 1 || age > 130) {
                                    return 'Invalid age';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedGender,
                                dropdownColor: sheetBg,
                                style: TextStyle(color: textColor),
                                decoration: sheetFieldDecoration('Gender'),
                                items: const [
                                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setDialogState(() {
                                    selectedGender = v;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: fieldGap),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: dobController,
                                readOnly: true,
                                onTap: pickDob,
                                style: TextStyle(color: textColor),
                                decoration: sheetFieldDecoration(
                                  'Date of Birth',
                                  suffixIcon: Icon(
                                    Icons.calendar_today_outlined,
                                    color: labelColor,
                                  ),
                                ),
                                validator: (v) {
                                  final dt = DateTime.tryParse((v ?? '').trim());
                                  if (dt == null || dt.isAfter(DateTime.now())) {
                                    return 'Invalid DOB';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                style: TextStyle(color: textColor),
                                decoration: sheetFieldDecoration('Phone Number'),
                                validator: (v) =>
                                    RegExp(r'^\d{10}$').hasMatch((v ?? '').trim())
                                        ? null
                                        : 'Invalid phone',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        sectionLabel('ADDRESS'),
                        TextFormField(
                          controller: addressController,
                          maxLines: 2,
                          style: TextStyle(color: textColor),
                          decoration: sheetFieldDecoration('Address'),
                          validator: (v) =>
                              (v == null || v.trim().length < 5) ? 'Enter valid address' : null,
                        ),
                        const SizedBox(height: 16),
                        sectionLabel('NOTES'),
                        TextFormField(
                          controller: notesController,
                          minLines: 3,
                          maxLines: 3,
                          style: TextStyle(color: textColor),
                          decoration: sheetFieldDecoration('Description / Notes'),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  side: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF3C4B59)
                                        : const Color(0xFFD1D9E1),
                                  ),
                                ),
                                child: Text(context.l10n.tr('common.cancel')),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (!formKey.currentState!.validate()) return;
                                  Navigator.pop(ctx, {
                                    'name': nameController.text.trim(),
                                    'age': int.parse(ageController.text.trim()),
                                    'dateOfBirth': dobController.text.trim(),
                                    'gender': selectedGender,
                                    'address': addressController.text.trim(),
                                    'phoneNumber': phoneController.text.trim(),
                                    'description': notesController.text.trim(),
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  backgroundColor: const Color(0xFF0BAEB4),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (updated == null) return;
    await _saveUpdatedPatient(updated);
  }

  Future<void> _saveUpdatedPatient(Map<String, dynamic> updated) async {
    final token = context.read<LoginCubit>().state.token;
    final connectivity = ConnectivityService();
    final dao = PatientOfflineDao();
    final patientCubit = context.read<PatientCubit>();
    var updatedOnline = false;

    try {
      if (token != null && _patient.id != null && await connectivity.isOnline()) {
        final res = await http.put(
          Uri.parse('$baseUrl/api/patients/${_patient.id}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'patientName': updated['name'],
            'gender': updated['gender'],
            'age': updated['age'],
            'dateOfBirth': updated['dateOfBirth'],
            'address': updated['address'],
            'description': updated['description'],
            'phoneNumber': updated['phoneNumber'],
            'clientTempId': _patient.uuid,
            'photoPath': _patient.photoPath,
          }),
        );

        if (res.statusCode != 200) {
          throw Exception('Failed to update notes: ${res.statusCode}');
        }

        updatedOnline = true;
      }

      await dao.updatePatientByUuid(
        uuid: _patient.uuid,
        name: updated['name'],
        gender: updated['gender'],
        age: updated['age'],
        dateOfBirth: updated['dateOfBirth'],
        address: updated['address'],
        phoneNumber: updated['phoneNumber'],
        description: updated['description'],
        markPending: !updatedOnline,
        serverId: _patient.id,
      );
      await PatientSyncService().refreshSyncStatus();

      if (!mounted) return;
      setState(() {
        _patient = Patient(
          id: _patient.id,
          uuid: _patient.uuid,
          name: updated['name'],
          gender: updated['gender'],
          age: updated['age'],
          dateOfBirth: updated['dateOfBirth'],
          address: updated['address'],
          description: updated['description'],
          phoneNumber: updated['phoneNumber'],
          photoPath: _patient.photoPath,
        );
      });
      patientCubit.upsertPatient(_patient);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient details updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update patient details: $e')),
      );
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _hideLoadingDialog(BuildContext context) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  // ================= DELETE =================

  Widget _deleteButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade600,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      icon: const Icon(Icons.delete, color: Colors.white),
      label: Text(
        context.l10n.tr('patient.delete'),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      onPressed: () => _confirmDelete(context),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.tr('patient.delete')),
        content: Text(
          context.l10n.tr('patient.deleteConfirm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _showLoadingDialog(context);
              final shouldClosePage = await _deletePatient(context);
              if (!context.mounted) return;
              _hideLoadingDialog(context);
              if (shouldClosePage) {
                Navigator.pop(context, true);
              }
            },
            child: Text(context.l10n.tr('common.delete'),
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<bool> _deletePatient(BuildContext context) async {
    final token = context.read<LoginCubit>().state.token!;
    final dao = PatientOfflineDao();
    final connectivity = ConnectivityService();
    final patientCubit = context.read<PatientCubit>();

    debugPrint("Delete patient: id=${_patient.id}, uuid=${_patient.uuid}, online=${await connectivity.isOnline()}");

    // OFFLINE OR NOT YET SYNCED
    if (!await connectivity.isOnline() || _patient.id == null) {
      await dao.markDeletedByUuid(_patient.uuid);
      await PatientSyncService().refreshSyncStatus();

      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('patient.markedDeletion'))),
      );
      return true;
    }

    // ONLINE DELETE
    try {
      final url = "$baseUrl/api/patients/${_patient.id}";
      debugPrint("Attempting DELETE: $url");
      debugPrint("Patient ID: ${_patient.id}");
      debugPrint("Token: ${token.substring(0, 10)}...");

      final res = await http.delete(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("Delete response status: ${res.statusCode}");
      debugPrint("Delete response headers: ${res.headers}");
      debugPrint("Delete response body: ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 204 || res.statusCode == 201) {
        debugPrint("Delete successful! Removing from local storage...");
        // Hard delete from offline storage
        await dao.hardDeleteByUuid(_patient.uuid);
        await PatientSyncService().refreshSyncStatus();
        patientCubit.removePatientByUuid(_patient.uuid);

        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.tr('patient.deletedSuccessfully'))),
        );
        debugPrint("Returning to previous page...");
        return true;
      } else {
        debugPrint("Delete failed with status: ${res.statusCode}");
        // Delete failed, try offline
        await dao.markDeletedByUuid(_patient.uuid);
        await PatientSyncService().refreshSyncStatus();
        patientCubit.removePatientByUuid(_patient.uuid);

        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.tr(
                'patient.deleteFailedStatus',
                args: {'status': res.statusCode.toString()},
              ),
            ),
          ),
        );
        return true;
      }
    } catch (e, stackTrace) {
      debugPrint("Delete error: $e");
      debugPrint("Stack trace: $stackTrace");
      // fallback to offline delete
      await dao.markDeletedByUuid(_patient.uuid);
      await PatientSyncService().refreshSyncStatus();
      patientCubit.removePatientByUuid(_patient.uuid);

      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.tr('patient.errorDeleting', args: {'error': e.toString()}),
          ),
        ),
      );
      return true;
    }
  }

}
