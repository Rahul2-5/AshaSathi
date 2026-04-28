import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../providers/login_provider.dart';
import '../providers/patient_provider.dart';
import 'package:frontend/patient/patient_success_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../offline/patient_offline_service.dart';
import '../offline/connectivity_service.dart';
import '../offline/patient_sync_service.dart';
import 'add_patient_form_data.dart';


class AddPatientPage extends ConsumerStatefulWidget {
  const AddPatientPage({super.key});

  @override
  ConsumerState<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends ConsumerState<AddPatientPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSyncingAgeDob = false;

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  late final AnimationController _photoAnimController;

  // ================= SNACKBAR =================

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isError
            ? (isDark ? const Color(0xFFB91C1C) : const Color(0xFFDC2626))
            : (isDark ? const Color(0xFF166534) : const Color(0xFF16A34A)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
        showCloseIcon: true,
        closeIconColor: Colors.white70,
      ),
    );
  }

  // ================= VALIDATORS =================

  String? _validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return context.l10n.tr('common.required');
    if (v.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateNumberOfMembers(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return context.l10n.tr('common.required');

    final age = int.tryParse(v);
    if (age == null) {
      return 'Please enter a valid number for age';
    }

    // Validate realistic age limits
    if (age < 0) {
      return 'Age cannot be negative';
    }

    if (age > 150) {
      return 'Age seems too high. Please verify (max 150)';
    }

    if (age > 130) {
      return 'Age is over 130. Please verify this is correct';
    }

    // Age 0 is valid (newborns)
    return null;
  }

  String? _validateAddress(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return context.l10n.tr('common.required');
    if (v.length < 5) return 'Address must be at least 5 characters';
    return null;
  }

  String? _validatePatientName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return context.l10n.tr('common.required');
    if (v.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateAge(String? value) {
    final v = value?.trim() ?? '';
    if (v.isNotEmpty) {
      final age = int.tryParse(v);
      if (age == null || age < 0 || age > 130) {
        return 'Age must be 0-130 years';
      }
    }
    return null;
  }

  // ================= LIFECYCLE =================

  @override
  void initState() {
    super.initState();
    _photoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Add listener to age controller for auto DOB sync
    _ageController.addListener(_syncDobFromAge);
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: isDark ? const Color(0xFFD3DEE8) : const Color(0xFF494D53),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            context.l10n.tr('patient.patientName'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1E24),
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                _profilePhoto(),
                const SizedBox(height: 28),
                _patientForm(),
                const SizedBox(height: 32),
                _saveButton(),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1F2B42) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          stepItem('Family', _currentStep == 0),
          const SizedBox(width: 12),
          stepItem('Patient', _currentStep == 1),
          const SizedBox(width: 12),
          stepItem('Medical', _currentStep == 2),
        ],
      ),
    );
  }

  // ==================== PATIENT STEP ====================
  Widget _buildPatientStep() {
    if (_patients.isEmpty) {
      return Center(
        child: Text(context.l10n.tr('common.noData')),
      );
    }

    final currentPatient = _patients[_currentPatientIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1419) : const Color(0xFFF3F4F6);

    return Column(
      children: [
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: _selectedImageBytes != null
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00A6A6).withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor:
                      isDark ? const Color(0xFF293542) : Colors.grey.shade200,
                  backgroundImage: _selectedImageBytes != null
                      ? MemoryImage(_selectedImageBytes!)
                      : (_selectedImage != null
                          ? FileImage(_selectedImage!)
                          : null),
                  child: _selectedImage == null && _selectedImageBytes == null
                      ? Icon(Icons.person, size: 48, color: isDark
                          ? const Color(0xFF5A6B7B)
                          : Colors.grey.shade400)
                      : null,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A6A6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF0F1419) : Colors.white,
                      width: 2.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _selectedImageBytes != null
              ? context.l10n.tr('patient.addPhoto')
              : context.l10n.tr('patient.addPhoto'),
          style: TextStyle(
            color: isDark ? const Color(0xFF66CFC7) : const Color(0xFF00A6A6),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildNumberFieldForPregnancy({
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF151D2E) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFFFF6B6B) : const Color(0xFFFF6B6B);
    final dividerColor = isDark ? const Color(0xFFFF6B6B) : const Color(0xFFFF6B6B);
    final hintColor = isDark ? const Color(0xFF6F85A8) : const Color(0xFF6B7280);
    final textColor = isDark ? Colors.white : const Color(0xFF171A1F);
    
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                hintText: '1',
                hintStyle: TextStyle(
                  color: hintColor,
                  fontSize: 13,
                ),
              ),
              onChanged: onChanged,
            ),
          ),
          Container(
            width: 44,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: dividerColor, width: 2),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final current = int.tryParse(controller.text) ?? 1;
                        if (current < 9) {
                          controller.text = (current + 1).toString();
                          onChanged(controller.text);
                          setState(() {});
                        }
                      },
                      child: const Icon(
                        Icons.arrow_drop_up,
                        color: Color(0xFF25D8C3),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 1,
                  color: const Color(0xFFFF6B6B),
                ),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final current = int.tryParse(controller.text) ?? 1;
                        if (current > 1) {
                          controller.text = (current - 1).toString();
                          onChanged(controller.text);
                          setState(() {});
                        }
                      },
                      child: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF25D8C3),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF0A1424) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF2A4265) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : const Color(0xFF171A1F);
    final hintColor = isDark ? const Color(0xFF6F85A8) : const Color(0xFF9CA3AF);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputField(
            context.l10n.tr('patient.patientName'),
            _nameController,
            validator: _validateName,
            prefixIcon: Icons.person_outline,
          ),
          _ageField(),
          _dobField(),
          _genderDropdown(),
          _inputField(
            context.l10n.tr('patient.address'),
            _addressController,
            validator: _validateAddress,
            prefixIcon: Icons.location_on_outlined,
            maxLines: 2,
          ),
          _inputField(
            'Description / Notes',
            _descriptionController,
            prefixIcon: Icons.notes_outlined,
            maxLines: 3,
            isOptional: true,
          ),
          _inputField(
            context.l10n.tr('auth.phoneNumber'),
            _phoneController,
            keyboard: TextInputType.phone,
            validator: _validatePhone,
            prefixIcon: Icons.phone_outlined,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
        ],
      ),
    );
  }

  // 📊 AGE FIELD - Auto-syncs Date of Birth
  Widget _ageField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _ageController,
      builder: (context, ageValue, child) {
        final age = ageValue.text.trim();
        final parsedAge = int.tryParse(age);
        final isValidAge = parsedAge != null && parsedAge >= 0 && parsedAge <= 130;

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel(context.l10n.tr('patient.age')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: _validateAge,
                decoration: _inputDecoration(
                  age.isNotEmpty ? 'Age: $age' : context.l10n.tr('patient.age'),
                ).copyWith(
                  prefixIcon: Icon(
                    Icons.cake_outlined,
                    size: 20,
                    color: isDark ? const Color(0xFF78849E) : const Color(0xFF9CA3AF),
                  ),
                  suffixIcon: isValidAge && age.isNotEmpty
                      ? Icon(Icons.check_circle,
                          color: isDark
                              ? const Color(0xFF66CFC7)
                              : const Color(0xFF00A6A6),
                          size: 20)
                      : null,
                ),
              ),
              if (age.isNotEmpty && isValidAge)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 13,
                          color: isDark
                              ? const Color(0xFF66CFC7)
                              : const Color(0xFF00A6A6)),
                      const SizedBox(width: 6),
                      Text(
                        'Date of Birth will auto-calculate',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF66CFC7)
                              : const Color(0xFF00A6A6),
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _inputField(
    String title,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
    IconData? prefixIcon,
    int maxLines = 1,
    bool isOptional = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF171A1F);
    final ctrl = controller;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _fieldLabel(title),
              if (isOptional) ...[
                const SizedBox(width: 6),
                Text(
                  '(optional)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: isDark ? const Color(0xFF78849E) : const Color(0xFFADB5BD),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            validator: isOptional
                ? null
                : (validator ??
                    (v) => v == null || v.trim().isEmpty
                        ? context.l10n.tr('common.required')
                        : null),
            decoration: _inputDecoration(title).copyWith(
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      size: 20,
                      color: isDark
                          ? const Color(0xFF78849E)
                          : const Color(0xFF9CA3AF),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String initialValue,
    required Function(String) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: initialValue);
    final isDeliveryDate = label.contains('Delivery');
    final fillColor = isDark ? const Color(0xFF151D2E) : const Color(0xFFFFFFFF);
    final hintColor = isDark ? const Color(0xFF6F85A8) : const Color(0xFF6B7280);
    final textColor = isDark ? Colors.white : const Color(0xFF171A1F);

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _dobController,
      builder: (context, dobValue, child) {
        final dob = dobValue.text.trim();
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel(context.l10n.tr('patient.dateOfBirth')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                onTap: _pickDateOfBirth,
                validator: _validateDob,
                decoration: _inputDecoration(dob.isEmpty
                        ? context.l10n.tr('patient.selectDate')
                        : dob)
                    .copyWith(
                  prefixIcon: Icon(
                    Icons.calendar_month_outlined,
                    size: 20,
                    color: isDark
                        ? const Color(0xFF78849E)
                        : const Color(0xFF9CA3AF),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
                ),
              ),
              if (dob.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 13,
                          color: isDark
                              ? const Color(0xFF66CFC7)
                              : const Color(0xFF00A6A6)),
                      const SizedBox(width: 6),
                      Text(
                        'Auto-calculated from age',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF66CFC7)
                              : const Color(0xFF00A6A6),
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryDateField({
    required String label,
    required String initialValue,
    required Function(String) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: initialValue);
    final fillColor = isDark ? const Color(0xFF151D2E) : const Color(0xFFFFFFFF);
    final hintColor = isDark ? const Color(0xFF6F85A8) : const Color(0xFF9CA3AF);
    final textColor = isDark ? Colors.white : const Color(0xFF171A1F);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(context.l10n.tr('patient.gender')),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            items: [
              DropdownMenuItem(
                  value: 'Female',
                  child: Text(context.l10n.tr('patient.female'))),
              DropdownMenuItem(
                  value: 'Male',
                  child: Text(context.l10n.tr('patient.male'))),
              DropdownMenuItem(
                  value: 'Other',
                  child: Text(context.l10n.tr('patient.other'))),
            ],
            onChanged: (v) => setState(() => _gender = v!),
            decoration: _inputDecoration(context.l10n.tr('patient.gender')).copyWith(
              prefixIcon: Icon(
                _gender == 'Male'
                    ? Icons.male
                    : _gender == 'Female'
                        ? Icons.female
                        : Icons.transgender,
                size: 20,
                color: isDark
                    ? const Color(0xFF78849E)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFFAEBAC6) : const Color(0xFF6B7280),
        letterSpacing: 0.1,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFF8EA1C4) : const Color(0xFF374151);
    
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: labelColor,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF151D2E) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF2A3F5A) : const Color(0xFFE5E7EB);
    final hintColor = isDark ? const Color(0xFF6F85A8) : const Color(0xFF6B7280);
    
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark
            ? const Color(0xFF5A6B7B)
            : const Color(0xFFB0B7BF),
        fontSize: 14,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF1A232C) : Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00A6A6), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFFEF4444) : const Color(0xFFF87171),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }

  Widget _saveButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF00A6A6).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A6A6),
            disabledBackgroundColor: isDark
                ? const Color(0xFF1A3A3A)
                : const Color(0xFFB3E0E0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_outlined, size: 20, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      context.l10n.tr('patient.saveData'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
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
      _isSyncingAgeDob = true;
      final hadValue = _dobController.text.isNotEmpty;
      _dobController.clear();
      _isSyncingAgeDob = false;
      if (hadValue) {
        setState(() {});
      }
      return;
    }

    final age = int.tryParse(rawAge);
    if (age == null || age < 1 || age > 130) return;

    final now = DateTime.now();
    final targetYear = now.year - age;
    final maxDayInMonth = DateTime(targetYear, now.month + 1, 0).day;
    final targetDay = now.day <= maxDayInMonth ? now.day : maxDayInMonth;
    final estimatedDob = DateTime(targetYear, now.month, targetDay);
    final formatted =
        "${estimatedDob.year}-${estimatedDob.month.toString().padLeft(2, '0')}-${estimatedDob.day.toString().padLeft(2, '0')}";

    if (_dobController.text == formattedDob) return;

    _isSyncingAgeDob = true;
    _dobController.text = formattedDob;
    _isSyncingAgeDob = false;

    setState(() {});
  }

  void _syncAgeFromDob(String dob) {
    final parsed = DateTime.tryParse(dob);
    if (parsed == null) return;

    final now = DateTime.now();
    var age = now.year - parsed.year;
    final hadBirthdayThisYear =
        (now.month > parsed.month) ||
            (now.month == parsed.month && now.day >= parsed.day);
    if (!hadBirthdayThisYear) {
      age -= 1;
    }

    if (age < 0 || age > 130) return;

    if (_patients[_currentPatientIndex].age != age) {
      _patients[_currentPatientIndex] =
          _patients[_currentPatientIndex].copyWith(age: age);
      setState(() {});
    }
  }

  void _calculateExpectedDeliveryDate(int months) {
    final now = DateTime.now();
    final deliveryDate = now.add(Duration(days: months * 30));
    final formatted =
        "${deliveryDate.year}-${deliveryDate.month.toString().padLeft(2, '0')}-${deliveryDate.day.toString().padLeft(2, '0')}";
    
    if (_patients[_currentPatientIndex].expectedDeliveryDate != formatted) {
      _patients[_currentPatientIndex] = _patients[_currentPatientIndex]
          .copyWith(expectedDeliveryDate: formatted);
      setState(() {});
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fix the errors in the form', isError: true);
      return;
    }

    final l10n = context.l10n;
    final patientNotifier = ref.read(patientListProvider.notifier);
    final navigator = Navigator.of(context);

    // Validate all patients
    for (int i = 0; i < _patients.length; i++) {
      if (!_patients[i].isValidForPatientStep()) {
        _showSnackBar('Patient ${i + 1} is incomplete', isError: true);
        setState(() => _currentPatientIndex = i);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      const uuid = Uuid();

      // Save each patient to offline database
      for (final patient in _patients) {
        uuid.v4();
        final selectedConditions = patient.medicalInfo.conditions
            .where((c) => c.selected)
            .map((c) => c.id)
            .toList();
        
        await PatientOfflineService().saveOffline(
          name: patient.name,
          gender: patient.gender,
          age: patient.age ?? 0,
          dateOfBirth: patient.dateOfBirth,
          address: patient.usesFamilyAddress
              ? _familyAddressController.text.trim()
              : (patient.address ?? _familyAddressController.text.trim()),
          description: patient.medicalInfo.notes,
          phoneNumber: patient.phoneNumber,
          photoPath: patient.photoPath,
          caste: patient.caste,
          isPregnant: patient.isPregnant,
          monthsOfPregnancy: patient.monthsOfPregnancy,
          expectedDeliveryDate: patient.expectedDeliveryDate,
          medicalConditions: selectedConditions,
        );
      }

      await PatientSyncService().refreshSyncStatus();

      final isOnline = await ConnectivityService().isOnline();
      final token = ref.read(loginProvider).token;

      if (isOnline && token != null) {
        await PatientSyncService().sync(token);
      }

      if (!mounted) return;

      if (token != null) {
        await patientNotifier.loadPatients(token);
      }

      if (!mounted) return;

      _showSnackBar(
        isOnline
            ? 'Data saved and synced'
            : 'Data saved offline. Will sync when online',
      );

      navigator.push(
        MaterialPageRoute(builder: (_) => const PatientSuccessPage()),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to save patient data: $e', isError: true);
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
        _photoAnimController.forward(from: 0);
      } catch (_) {
        // Fallback to source file if persistence fails for any reason.
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = File(image.path);
          _selectedImageBytes = bytes;
        });
        _photoAnimController.forward(from: 0);
      }
    }
  }

  Future<File> _persistPickedImage(XFile image) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docsDir.path, 'patient_photos'));
    if (!photosDir.existsSync()) {
      photosDir.createSync(recursive: true);
    }

    final ext =
        p.extension(image.path).isNotEmpty ? p.extension(image.path) : '.jpg';
    final fileName = 'patient_${DateTime.now().microsecondsSinceEpoch}$ext';
    final savedPath = p.join(photosDir.path, fileName);

    return File(image.path).copy(savedPath);
  }

  void _showImageSourceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A232C) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3D4E5C)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A6A6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Color(0xFF00A6A6), size: 22),
                  ),
                  title: Text(context.l10n.tr('patient.takePhoto')),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A6A6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library,
                        color: Color(0xFF00A6A6), size: 22),
                  ),
                  title: Text(context.l10n.tr('patient.chooseFromGallery')),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
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
    _descriptionController.dispose();
    _phoneController.dispose();
    _photoAnimController.dispose();
    super.dispose();
  }

}

