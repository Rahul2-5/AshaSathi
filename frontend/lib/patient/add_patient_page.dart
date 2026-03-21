import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../auth/cubit/login_cubit.dart';
import '../auth/cubit/patient_cubit.dart';
import 'package:frontend/patient/patient_success_page.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../offline/patient_offline_service.dart';
import '../offline/connectivity_service.dart';
import '../offline/patient_sync_service.dart';


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
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSyncingAgeDob = false;

  String _gender = 'Female';
  bool _isLoading = false;

  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String? _validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return context.l10n.tr('common.required');
    if (v.length < 2) return context.l10n.tr('patient.invalidName');
    return null;
  }

  String? _validateAge(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return context.l10n.tr('common.required');
    final age = int.tryParse(v);
    if (age == null || age < 1 || age > 130) {
      return context.l10n.tr('patient.invalidAge');
    }
    return null;
  }

  String? _validateAddress(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return context.l10n.tr('common.required');
    if (v.length < 5) return context.l10n.tr('patient.invalidAddress');
    return null;
  }

  String? _validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return context.l10n.tr('common.required');
    if (!RegExp(r'^\d{10}$').hasMatch(v)) {
      return context.l10n.tr('patient.invalidPhone');
    }
    return null;
  }

  String? _validateDob(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return context.l10n.tr('common.required');
    final parsed = DateTime.tryParse(v);
    if (parsed == null || parsed.isAfter(DateTime.now())) {
      return context.l10n.tr('patient.invalidDob');
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _ageController.addListener(_syncDobFromAge);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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

  Widget _profilePhoto() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
                CircleAvatar(
                radius: 52,
                backgroundColor:
                    isDark ? const Color(0xFF293542) : Colors.grey.shade200,
                backgroundImage: _selectedImageBytes != null
                  ? MemoryImage(_selectedImageBytes!)
                  : (_selectedImage != null ? FileImage(_selectedImage!) : null),
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
        Text(
          context.l10n.tr('patient.addPhoto'),
          style: TextStyle(
            color: isDark ? const Color(0xFF66CFC7) : const Color(0xFF00A6A6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _patientForm() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
            _inputField(
              context.l10n.tr('patient.patientName'),
              _nameController,
              validator: _validateName,
            ),
            _inputField(context.l10n.tr('patient.age'), _ageController,
              keyboard: TextInputType.number,
              validator: _validateAge),
          _dobField(), 
          _genderDropdown(),
            _inputField(
              context.l10n.tr('patient.address'),
              _addressController,
              validator: _validateAddress,
            ),
            _inputField('Description / Notes', _descriptionController),
            _inputField(context.l10n.tr('auth.phoneNumber'), _phoneController,
              keyboard: TextInputType.phone,
              validator: _validatePhone),
        ],
      ),
    );
  }

  Widget _inputField(
    String title,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFAEBAC6) : const Color(0xFF6B7280))),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboard,
            validator: validator ??
              (v) =>
                v == null || v.trim().isEmpty
                  ? context.l10n.tr('common.required')
                  : null,
            decoration: _inputDecoration(title),
          ),
        ],
      ),
    );
  }

  // 📅 DATE OF BIRTH FIELD
  Widget _dobField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(context.l10n.tr('patient.dateOfBirth'),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFAEBAC6) : const Color(0xFF6B7280))),
          const SizedBox(height: 6),
          TextFormField(
            controller: _dobController,
            readOnly: true,
            onTap: _pickDateOfBirth,
            validator: _validateDob,
            decoration: _inputDecoration(context.l10n.tr('patient.selectDate'))
                .copyWith(suffixIcon: const Icon(Icons.calendar_today)),
          ),
        ],
      ),
    );
  }

  Widget _genderDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(context.l10n.tr('patient.gender'),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFAEBAC6) : const Color(0xFF6B7280))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            items: [
              DropdownMenuItem(value: 'Female', child: Text(context.l10n.tr('patient.female'))),
              DropdownMenuItem(value: 'Male', child: Text(context.l10n.tr('patient.male'))),
              DropdownMenuItem(value: 'Other', child: Text(context.l10n.tr('patient.other'))),
            ],
            onChanged: (v) => setState(() => _gender = v!),
            decoration: _inputDecoration(context.l10n.tr('patient.gender')),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: isDark ? const Color(0xFF1A232C) : Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF31414F) : Colors.grey.shade300,
        ),
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
            : Text(context.l10n.tr('patient.saveData'),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
      ),
    );
  }

  // ================= LOGIC =================

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final parsedDob = DateTime.tryParse(_dobController.text.trim());
    final initialDate =
        (parsedDob != null && !parsedDob.isAfter(now)) ? parsedDob : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      _dobController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      _syncAgeFromDob(picked);
    }
  }

  void _syncDobFromAge() {
    if (_isSyncingAgeDob) return;

    final rawAge = _ageController.text.trim();
    if (rawAge.isEmpty) {
      if (_dobController.text.isEmpty) return;
      _isSyncingAgeDob = true;
      _dobController.clear();
      _isSyncingAgeDob = false;
      return;
    }

    final age = int.tryParse(rawAge);
    if (age == null || age < 1 || age > 130) return;

    final now = DateTime.now();
    final targetYear = now.year - age;
    final maxDayInMonth = DateTime(targetYear, now.month + 1, 0).day;
    final targetDay = now.day <= maxDayInMonth ? now.day : maxDayInMonth;
    final estimatedDob = DateTime(targetYear, now.month, targetDay);
    final formattedDob =
        "${estimatedDob.year}-${estimatedDob.month.toString().padLeft(2, '0')}-${estimatedDob.day.toString().padLeft(2, '0')}";

    if (_dobController.text == formattedDob) return;

    _isSyncingAgeDob = true;
    _dobController.text = formattedDob;
    _isSyncingAgeDob = false;
  }

  void _syncAgeFromDob(DateTime dob) {
    if (_isSyncingAgeDob) return;

    final now = DateTime.now();
    var age = now.year - dob.year;
    final hadBirthdayThisYear =
        (now.month > dob.month) || (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthdayThisYear) {
      age -= 1;
    }

    if (age < 0 || age > 130) return;

    final ageText = age.toString();
    if (_ageController.text == ageText) return;

    _isSyncingAgeDob = true;
    _ageController.text = ageText;
    _isSyncingAgeDob = false;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final loginCubit = context.read<LoginCubit>();
    final patientCubit = context.read<PatientCubit>();
    final navigator = Navigator.of(context);

    if (_selectedImage == null) {
      _showSnackBar(l10n.tr('patient.pleaseAddPhoto'), isError: true);
      return;
    }

    final age = int.tryParse(_ageController.text.trim());
    if (age == null) {
      _showSnackBar(l10n.tr('patient.invalidAge'), isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await PatientOfflineService().saveOffline(
        name: _nameController.text.trim(),
        gender: _gender,
        age: age,
        dateOfBirth: _dobController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        photoPath: _selectedImage!.path,
      );

      final isOnline = await ConnectivityService().isOnline();
      final token = loginCubit.state.token;

      if (isOnline && token != null) {
        await PatientSyncService().sync(token);
      }

      if (!mounted) return;

      if (token != null) {
        await patientCubit.loadPatients(token);
      }

      if (!mounted) return;

      _showSnackBar(
        isOnline
            ? l10n.tr('patient.saveSuccessOnline')
            : l10n.tr('patient.saveSuccessOffline'),
      );

      navigator.push(
        MaterialPageRoute(builder: (_) => const PatientSuccessPage()),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(l10n.tr('patient.saveFailed'), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

 Future<void> _pickImage(ImageSource source) async {
  final image = await _picker.pickImage(
    source: source,
    imageQuality: 70,
  );

  if (image != null) {
    try {
      final persistedImage = await _persistPickedImage(image);
      final bytes = await persistedImage.readAsBytes();
      setState(() {
        _selectedImage = persistedImage;
        _selectedImageBytes = bytes;
      });
    } catch (_) {
      // Fallback to source file if persistence fails for any reason.
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = File(image.path);
        _selectedImageBytes = bytes;
      });
    }
  }
}

Future<File> _persistPickedImage(XFile image) async {
  final docsDir = await getApplicationDocumentsDirectory();
  final photosDir = Directory(p.join(docsDir.path, 'patient_photos'));
  if (!photosDir.existsSync()) {
    photosDir.createSync(recursive: true);
  }

  final ext = p.extension(image.path).isNotEmpty ? p.extension(image.path) : '.jpg';
  final fileName = 'patient_${DateTime.now().microsecondsSinceEpoch}$ext';
  final savedPath = p.join(photosDir.path, fileName);

  return File(image.path).copy(savedPath);
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
              title: Text(context.l10n.tr('patient.takePhoto')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(context.l10n.tr('patient.chooseFromGallery')),
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
    _ageController.removeListener(_syncDobFromAge);
    _nameController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
