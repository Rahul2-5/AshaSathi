import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../auth/cubit/login_cubit.dart';
import '../offline/patient_offline_dao.dart';
import '../offline/connectivity_service.dart';

import 'patient_model.dart';

class PatientDetailPage extends StatelessWidget {
  final Patient patient;

  const PatientDetailPage({
    super.key,
    required this.patient,
  });

  static const String baseUrl = "http://10.0.2.2:8080";

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
          "Patient Details",
          style: TextStyle(
            color: isDark ? const Color(0xFFE6EDF3) : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
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
          patient.name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF111418),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          patient.gender,
          style: TextStyle(
            color: isDark ? const Color(0xFF9EABB7) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientImage() {
    final path = patient.photoPath;

    if (path == null || path.isEmpty) {
      return const Icon(Icons.person, size: 50, color: Colors.grey);
    }

    if (path.startsWith('/') && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover);
    }

    if (path.startsWith('/uploads/')) {
      return Image.network("$baseUrl$path", fit: BoxFit.cover);
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
            _infoRow(context, "Age", "${patient.age} years"),
            _divider(),
            _infoRow(context, "Date of Birth", patient.dateOfBirth),
            _divider(),
            _infoRow(context, "Phone", patient.phoneNumber),
            _divider(),
            _infoRow(context, "Address", patient.address),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
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
      label: const Text(
        "Delete Patient",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      onPressed: () => _confirmDelete(context),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Patient"),
        content: const Text(
          "This will delete the patient. You can sync later if offline.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deletePatient(context);
            },
            child: const Text("Delete",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePatient(BuildContext context) async {
  final token = context.read<LoginCubit>().state.token!;
  final dao = PatientOfflineDao();
  final connectivity = ConnectivityService();

  debugPrint("Delete patient: id=${patient.id}, uuid=${patient.uuid}, online=${await connectivity.isOnline()}");

  //  OFFLINE OR NOT YET SYNCED
  if (!await connectivity.isOnline() || patient.id == null) {
    await dao.markDeletedByUuid(patient.uuid);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Patient marked for deletion (will sync when online)")),
    );
    Navigator.pop(context, true);
    return;
  }

  // 🟢 ONLINE DELETE
  try {
    final url = "$baseUrl/api/patients/${patient.id}";
    debugPrint("Attempting DELETE: $url");
    debugPrint("Patient ID: ${patient.id}");
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
      await dao.hardDeleteByUuid(patient.uuid);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Patient deleted successfully")),
      );
      debugPrint("Returning to previous page...");
      Navigator.pop(context, true);
    } else {
      debugPrint("Delete failed with status: ${res.statusCode}");
      // Delete failed, try offline
      await dao.markDeletedByUuid(patient.uuid);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: ${res.statusCode}. Will sync later")),
      );
      Navigator.pop(context, true);
    }
  } catch (e, stackTrace) {
    debugPrint("Delete error: $e");
    debugPrint("Stack trace: $stackTrace");
    // fallback to offline delete
    await dao.markDeletedByUuid(patient.uuid);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error deleting: $e. Will sync later")),
    );
    Navigator.pop(context, true);
  }
}

}
