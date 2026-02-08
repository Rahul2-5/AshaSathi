import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/cubit/login_cubit.dart';
import 'package:frontend/patient/patient_success_page.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  String _gender = "Female";
  bool _isLoading = false;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  static const String baseUrl = "http://10.0.2.2:8080/api/patients";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      appBar: AppBar(
        title: const Text("Patient Visit"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _syncBanner(),
            const SizedBox(height: 28),
            _profilePhoto(),
            const SizedBox(height: 28),
            _patientForm(),
            const SizedBox(height: 28),
            _saveButton(),
          ],
        ),
      ),
    );
  }

  // ================= UI =================

  Widget _syncBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE6FAFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 18, color: Color(0xFF00A6A6)),
          const SizedBox(width: 8),
          const Text("Pending Sync",
              style: TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00A6A6),
              side: const BorderSide(color: Color(0xFF00A6A6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("Sync Now"),
          ),
        ],
      ),
    );
  }

  Widget _profilePhoto() {
    return Column(
      children: [
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    _selectedImage != null ? FileImage(_selectedImage!) : null,
                child: _selectedImage == null
                    ? const Icon(Icons.person,
                        size: 48, color: Colors.grey)
                    : null,
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF00A6A6),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.camera_alt,
                    size: 16, color: Colors.white),
              )
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text("Add Photo",
            style: TextStyle(
                color: Color(0xFF00A6A6),
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _patientForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _inputField("Patient Name", _nameController),
          _inputField("Age", _ageController,
              keyboard: TextInputType.number),
          _dobField(), // 👈 calendar field
          _genderDropdown(),
          _inputField("Address", _addressController),
          _inputField("Phone Number", _phoneController,
              keyboard: TextInputType.phone),
        ],
      ),
    );
  }

  Widget _inputField(
    String title,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboard,
            validator: (v) =>
                v == null || v.trim().isEmpty ? "Required" : null,
            decoration: _inputDecoration(title),
          ),
        ],
      ),
    );
  }

  // 📅 DATE OF BIRTH FIELD
  Widget _dobField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Date of Birth",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          TextFormField(
            controller: _dobController,
            readOnly: true,
            onTap: _pickDateOfBirth,
            validator: (v) =>
                v == null || v.isEmpty ? "Required" : null,
            decoration: _inputDecoration("Select date")
                .copyWith(suffixIcon: const Icon(Icons.calendar_today)),
          ),
        ],
      ),
    );
  }

  Widget _genderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Gender",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _gender,
            items: const [
              DropdownMenuItem(value: "Female", child: Text("Female")),
              DropdownMenuItem(value: "Male", child: Text("Male")),
              DropdownMenuItem(value: "Other", child: Text("Other")),
            ],
            onChanged: (v) => setState(() => _gender = v!),
            decoration: _inputDecoration("Gender"),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFF00A6A6)),
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A6A6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Save Patient Data",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
      ),
    );
  }

  // ================= LOGIC =================

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      _dobController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

 Future<void> _handleSave() async {
  if (!_formKey.currentState!.validate()) return;

  // ❌ PHOTO IS MANDATORY
  if (_selectedImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please add a patient photo"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final id = await _savePatient();
    await _uploadPhoto(id);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PatientSuccessPage(),
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.toString())));
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}



Future<int> _savePatient() async {
  final token = context.read<LoginCubit>().state.token!;

  final res = await http.post(
    Uri.parse(baseUrl),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token", // ✅ THIS FIXES 403
    },
    body: jsonEncode({
      "patientName": _nameController.text.trim(),
      "age": int.parse(_ageController.text.trim()),
      "dateOfBirth": _dobController.text.trim(),
      "gender": _gender,
      "address": _addressController.text.trim(),
      "phoneNumber": _phoneController.text.trim(),
    }),
  );

  debugPrint("STATUS CODE: ${res.statusCode}");
  debugPrint("RESPONSE BODY: ${res.body}");

  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception("Failed to save patient");
  }

  return jsonDecode(res.body)["id"];
}



 Future<void> _pickImage(ImageSource source) async {
  final image = await _picker.pickImage(
    source: source,
    imageQuality: 70,
  );

  if (image != null) {
    setState(() {
      _selectedImage = File(image.path);
    });
  }
}


Future<void> _uploadPhoto(int patientId) async {
  if (_selectedImage == null) return;

  final token = context.read<LoginCubit>().state.token!;

  final uri = Uri.parse("$baseUrl/$patientId/photo");
  final request = http.MultipartRequest("POST", uri);

  request.headers["Authorization"] = "Bearer $token";

  request.files.add(
    await http.MultipartFile.fromPath(
      "photo",
      _selectedImage!.path,
    ),
  );

  final response = await request.send();

  // 🔥 READ BACKEND ERROR MESSAGE
  final responseBody = await response.stream.bytesToString();

  debugPrint("PHOTO UPLOAD STATUS: ${response.statusCode}");
  debugPrint("PHOTO UPLOAD BODY: $responseBody");

  if (response.statusCode != 200) {
    throw Exception(responseBody);
  }
}

void _showImageSourceSheet() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take Photo"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      );
    },
  );
}




  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
