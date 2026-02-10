import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../auth/cubit/login_cubit.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text("Patient Details"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileSection(),
            const SizedBox(height: 24),
            _infoCard(),
            const SizedBox(height: 28),
            _deleteButton(context),
          ],
        ),
      ),
    );
  }

  // ================= PROFILE =================

  Widget _profileSection() {
    return Column(
      children: [
        CircleAvatar(
          radius: 55,
          backgroundColor: Colors.grey.shade200,
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
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          patient.gender,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// 🔥 SAFE IMAGE HANDLER (OFFLINE + ONLINE)
Widget _buildPatientImage() {
  final path = patient.photoPath;

  if (path == null || path.isEmpty) {
    return const Icon(Icons.person, size: 50, color: Colors.grey);
  }

  // 🔴 LOCAL FILE (offline / cached)
  if (path.startsWith('/') && File(path).existsSync()) {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image),
    );
  }

  // 🟢 BACKEND IMAGE ONLY (uploads)
  if (path.startsWith('/uploads/')) {
    return Image.network(
      "$baseUrl$path",
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image),
    );
  }

  // ❌ Anything else → fallback
  return const Icon(Icons.broken_image);
}



  // ================= INFO CARD =================

  Widget _infoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow("Age", "${patient.age} years"),
            _divider(),
            _infoRow("Date of Birth", patient.dateOfBirth),
            _divider(),
            _infoRow("Phone", patient.phoneNumber),
            _divider(),
            _infoRow("Address", patient.address),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(color: Colors.grey.shade300);
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
      label: const Text(
        "Delete Patient",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
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
          "This will permanently delete the patient and all related data. This action cannot be undone.",
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
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePatient(BuildContext context) async {
    final token = context.read<LoginCubit>().state.token!;
    final url = Uri.parse("$baseUrl/api/patients/${patient.id}");

    try {
      final response = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 204) {
        if (!context.mounted) return;
        Navigator.pop(context);
      } else {
        throw Exception();
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Delete failed (offline?)")),
      );
    }
  }
}
