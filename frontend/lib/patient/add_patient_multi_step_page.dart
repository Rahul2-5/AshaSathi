import 'dart:io';
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
import 'add_patient_form_data.dart';
// import 'medical_model.dart';

class AddPatientMultiStepPage extends StatefulWidget {
  const AddPatientMultiStepPage({super.key});

  @override
  State<AddPatientMultiStepPage> createState() =>
      _AddPatientMultiStepPageState();
}

class _AddPatientMultiStepPageState extends State<AddPatientMultiStepPage> {
  // ==================== STATE ====================
  int _currentStep = 0; // 0: Family, 1: Patient, 2: Medical

  // Family Info
  final _headOfFamilyController = TextEditingController();
  final _numberOfMembersController = TextEditingController(text: '2');
  final _familyAddressController = TextEditingController();
  bool _sameAddressForAll = true;

  // Patient data for all members
  List<AddPatientFormData> _patients = [];
  int _currentPatientIndex = 0;

  // Form validation
  final _familyFormKey = GlobalKey<FormState>();
  final _patientFormKey = GlobalKey<FormState>();

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // ==================== INITIALIZATION ====================
  @override
  void initState() {
    super.initState();
    _numberOfMembersController.addListener(_updatePatientCount);
  }

  void _updatePatientCount() {
    final count = int.tryParse(_numberOfMembersController.text.trim()) ?? 2;
    if (_patients.length < count) {
      while (_patients.length < count) {
        _patients.add(
              AddPatientFormData(
                name: '',
                phoneNumber: '',
            memberNumber: "Member ${_patients.length + 1}",
          ),
        );
      }
    } else if (_patients.length > count) {
      _patients = _patients.sublist(0, count);
      if (_currentPatientIndex >= _patients.length) {
        _currentPatientIndex = _patients.length - 1;
      }
    }
    setState(() {});
  }

  // ==================== VALIDATION ====================
  String? _validateHeadOfFamily(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Required';
    if (v.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateNumberOfMembers(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Required';
    final num = int.tryParse(v);
    if (num == null || num < 1 || num > 20) {
      return 'Family size must be 1-20';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Required';
    if (v.length < 5) return 'Address must be at least 5 characters';
    return null;
  }

  String? _validatePatientName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Required';
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

  String? _validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Required';
    if (!RegExp(r'^\d{10}$').hasMatch(v)) {
      return 'Phone must be 10 digits';
    }
    return null;
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_getStepTitle()),
        centerTitle: true,
      ),
      body: switch (_currentStep) {
        0 => _buildFamilyStep(),
        1 => _buildPatientStep(),
        2 => _buildMedicalStep(),
        _ => const SizedBox(),
      },
    );
  }

  String _getStepTitle() {
    return switch (_currentStep) {
      0 => 'Family Information',
      1 => 'Add Patient Details',
      2 => 'Medical Information',
      _ => '',
    };
  }

  // ==================== FAMILY STEP ====================
  Widget _buildFamilyStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _familyFormKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A232C) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.family_restroom, color: Color(0xFF00A6A6)),
                  const SizedBox(width: 12),
                  Text(
                    'Family Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildInputField(
              label: 'Head of Family Name',
              controller: _headOfFamilyController,
              validator: _validateHeadOfFamily,
              hint: 'Enter name',
            ),
            _buildInputField(
              label: 'Number of Family Members',
              controller: _numberOfMembersController,
              validator: _validateNumberOfMembers,
              hint: '2',
              keyboardType: TextInputType.number,
            ),
            _buildInputField(
              label: 'Family Address',
              controller: _familyAddressController,
              validator: _validateAddress,
              hint: 'Enter address',
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Same address for all members'),
              value: _sameAddressForAll,
              onChanged: (v) {
                setState(() => _sameAddressForAll = v ?? true);
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (_familyFormKey.currentState!.validate()) {
                    _updatePatientCount();
                    setState(() => _currentStep = 1);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A6A6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Next: Add Patient Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPatient = _patients[_currentPatientIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member tabs
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _patients.length,
              itemBuilder: (context, index) {
                final isSelected = index == _currentPatientIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      if (_patientFormKey.currentState?.validate() ?? true) {
                        setState(() => _currentPatientIndex = index);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00A6A6)
                            : (isDark
                                ? const Color(0xFF1A232C)
                                : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _patients[index].memberNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          Form(
            key: _patientFormKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhotoSection(currentPatient),
                const SizedBox(height: 24),
                _buildInputField(
                  label: 'Patient Name',
                  initialValue: currentPatient.name,
                  validator: _validatePatientName,
                  hint: 'Enter name',
                  onChanged: (v) {
                    _patients[_currentPatientIndex] =
                        currentPatient.copyWith(name: v);
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: 'Age',
                        initialValue:
                            currentPatient.age?.toString() ?? '',
                        validator: _validateAge,
                        hint: 'Age',
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final age = int.tryParse(v);
                          _patients[_currentPatientIndex] =
                              currentPatient.copyWith(age: age);
                          if (age != null) {
                            _syncDobFromAge(age);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateField(
                        label: 'Date of Birth',
                        initialValue: currentPatient.dateOfBirth,
                        onChanged: (v) {
                          _patients[_currentPatientIndex] =
                              currentPatient.copyWith(dateOfBirth: v);
                          _syncAgeFromDob(v);
                        },
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Gender'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: currentPatient.gender,
                      items: [
                        DropdownMenuItem(
                          value: 'Male',
                          child: Text(context.l10n.tr('patient.male')),
                        ),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text(context.l10n.tr('patient.female')),
                        ),
                        DropdownMenuItem(
                          value: 'Other',
                          child: Text(context.l10n.tr('patient.other')),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _patients[_currentPatientIndex] =
                              currentPatient.copyWith(gender: v!);
                          if (v != 'Female') {
                            _patients[_currentPatientIndex] = _patients[
                                    _currentPatientIndex]
                                .copyWith(isPregnant: false);
                          }
                        });
                      },
                      decoration: _inputDecoration('Select gender'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (currentPatient.gender == 'Female')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        title: const Text(
                          'Is Pregnant?',
                          style: TextStyle(color: Color(0xFFFF6B6B)),
                        ),
                        value: currentPatient.isPregnant,
                        onChanged: (v) {
                          setState(() {
                            _patients[_currentPatientIndex] = currentPatient
                                .copyWith(isPregnant: v ?? false);
                          });
                        },
                      ),
                      if (currentPatient.isPregnant) ...[
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: 'Months of Pregnancy',
                          initialValue: currentPatient.monthsOfPregnancy
                                  ?.toString() ??
                              '',
                          hint: '1-9',
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final months = int.tryParse(v);
                            _patients[_currentPatientIndex] =
                                currentPatient.copyWith(
                              monthsOfPregnancy: months,
                            );
                            if (months != null && months >= 1 && months <= 9) {
                              _calculateExpectedDeliveryDate(months);
                            }
                          },
                        ),
                        if (currentPatient.expectedDeliveryDate != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              _buildLabel('Expected Delivery Date'),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A232C),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF00A6A6),
                                  ),
                                ),
                                child: Text(
                                  currentPatient.expectedDeliveryDate!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ],
                  ),
                const SizedBox(height: 18),
                _buildInputField(
                  label: 'Caste',
                  initialValue: currentPatient.caste,
                  hint: 'Enter caste (optional)',
                  onChanged: (v) {
                    _patients[_currentPatientIndex] =
                        currentPatient.copyWith(caste: v);
                  },
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Address'),
                    const SizedBox(height: 6),
                    CheckboxListTile(
                      title: const Text('Same as family address'),
                      value: currentPatient.usesFamilyAddress,
                      onChanged: (v) {
                        setState(() {
                          _patients[_currentPatientIndex] = currentPatient
                              .copyWith(usesFamilyAddress: v ?? true);
                        });
                      },
                    ),
                    if (!currentPatient.usesFamilyAddress)
                      _buildInputField(
                        initialValue: currentPatient.address ?? '',
                        hint: 'Enter address',
                        maxLines: 2,
                        onChanged: (v) {
                          _patients[_currentPatientIndex] =
                              currentPatient.copyWith(address: v);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildInputField(
                  label: 'Phone Number',
                  initialValue: currentPatient.phoneNumber,
                  validator: _validatePhone,
                  hint: 'Enter 10-digit phone',
                  keyboardType: TextInputType.phone,
                  onChanged: (v) {
                    _patients[_currentPatientIndex] =
                        currentPatient.copyWith(phoneNumber: v);
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => setState(() => _currentStep -= 1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_patientFormKey.currentState!.validate()) {
                            if (_currentPatientIndex == _patients.length - 1) {
                              setState(() => _currentStep = 2);
                            } else {
                              setState(() => _currentPatientIndex += 1);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A6A6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _currentPatientIndex == _patients.length - 1
                              ? 'Next: Medical Info'
                              : 'Next Patient',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(AddPatientFormData patient) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _pickImage(patient),
      child: Center(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: isDark
                      ? const Color(0xFF293542)
                      : Colors.grey.shade200,
                  backgroundImage: patient.photoPath != null
                      ? FileImage(File(patient.photoPath!))
                      : null,
                  child: patient.photoPath == null
                      ? const Icon(Icons.person, size: 48, color: Colors.grey)
                      : null,
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A6A6),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Add Photo',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF66CFC7)
                    : const Color(0xFF00A6A6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MEDICAL STEP ====================
  Widget _buildMedicalStep() {
    if (_patients.isEmpty) return const SizedBox();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPatient = _patients[_currentPatientIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _patients.length,
              itemBuilder: (context, index) {
                final isSelected = index == _currentPatientIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _currentPatientIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00A6A6)
                            : (isDark
                                ? const Color(0xFF1A232C)
                                : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _patients[index].memberNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFF6B6B)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: CheckboxListTile(
              title: const Text(
                'Patient prefers not to share medical information',
                style: TextStyle(color: Color(0xFFFF6B6B)),
              ),
              value: currentPatient.medicalInfo.refusedToShare,
              onChanged: (v) {
                setState(() {
                  final medicalInfo = currentPatient.medicalInfo;
                  if (v == true) {
                    for (var condition in medicalInfo.conditions) {
                      condition.selected = false;
                    }
                  }
                  _patients[_currentPatientIndex] = currentPatient.copyWith(
                    medicalInfo:
                        medicalInfo.copyWith(refusedToShare: v ?? false),
                  );
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Medical Conditions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (currentPatient.medicalInfo.refusedToShare)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A232C)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Data not collected per patient preference',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: currentPatient.medicalInfo.conditions.length,
              itemBuilder: (context, index) {
                final condition = currentPatient.medicalInfo.conditions[index];
                return GestureDetector(
                  onTap: currentPatient.medicalInfo.refusedToShare
                      ? null
                      : () {
                          setState(() {
                            condition.selected = !condition.selected;
                          });
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: condition.selected
                            ? const Color(0xFF00A6A6)
                            : (isDark
                                ? const Color(0xFF31414F)
                                : Colors.grey.shade300),
                        width: condition.selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: condition.selected
                          ? const Color(0xFF00A6A6).withOpacity(0.1)
                          : (isDark
                              ? const Color(0xFF1A232C)
                              : Colors.white),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: condition.selected,
                          onChanged: currentPatient.medicalInfo.refusedToShare
                              ? null
                              : (v) {
                                  setState(() {
                                    condition.selected = v ?? false;
                                  });
                                },
                          side: const BorderSide(
                            color: Color(0xFF00A6A6),
                            width: 2,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            condition.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Notes / Description'),
              const SizedBox(height: 6),
              TextFormField(
                initialValue: currentPatient.medicalInfo.notes,
                onChanged: (v) {
                  final medicalInfo = currentPatient.medicalInfo;
                  _patients[_currentPatientIndex] = currentPatient.copyWith(
                    medicalInfo: medicalInfo.copyWith(notes: v),
                  );
                },
                maxLines: 3,
                decoration: _inputDecoration('Add description or notes'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _currentStep -= 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSaveAllData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A6A6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Patient Data',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildInputField({
    String? initialValue,
    String? label,
    TextEditingController? controller,
    String? Function(String?)? validator,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            _buildLabel(label),
            const SizedBox(height: 6),
          ],
          TextFormField(
            initialValue: controller != null ? null : initialValue,
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            onChanged: onChanged,
            decoration: _inputDecoration(hint ?? ''),
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
    final controller = TextEditingController(text: initialValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            readOnly: true,
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: now,
              );
              if (picked != null) {
                final formatted =
                    "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                controller.text = formatted;
                onChanged(formatted);
              }
            },
            decoration: _inputDecoration('dd-mm-yyyy').copyWith(
              suffixIcon: const Icon(Icons.calendar_today),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFAEBAC6)
            : const Color(0xFF6B7280),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: isDark ? const Color(0xFF1A232C) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF31414F) : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00A6A6)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  // ==================== LOGIC ====================
  void _syncDobFromAge(int age) {
    final now = DateTime.now();
    final targetYear = now.year - age;
    final maxDayInMonth = DateTime(targetYear, now.month + 1, 0).day;
    final targetDay = now.day <= maxDayInMonth ? now.day : maxDayInMonth;
    final estimatedDob = DateTime(targetYear, now.month, targetDay);
    final formatted =
        "${estimatedDob.year}-${estimatedDob.month.toString().padLeft(2, '0')}-${estimatedDob.day.toString().padLeft(2, '0')}";

    if (_patients[_currentPatientIndex].dateOfBirth != formatted) {
      _patients[_currentPatientIndex] =
          _patients[_currentPatientIndex].copyWith(dateOfBirth: formatted);
      setState(() {});
    }
  }

  void _syncAgeFromDob(String dob) {
    final now = DateTime.now();
    final parsed = DateTime.tryParse(dob);
    if (parsed == null) return;

    var age = now.year - parsed.year;
    final hadBirthdayThisYear = (now.month > parsed.month) ||
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

  Future<void> _pickImage(AddPatientFormData patient) async {
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
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromSource(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      try {
        final persistedImage = await _persistPickedImage(image);
        _patients[_currentPatientIndex] = _patients[_currentPatientIndex]
            .copyWith(photoPath: persistedImage.path);
        setState(() {});
      } catch (_) {
        _patients[_currentPatientIndex] = _patients[_currentPatientIndex]
            .copyWith(photoPath: image.path);
        setState(() {});
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

  Future<void> _handleSaveAllData() async {
    final loginCubit = context.read<LoginCubit>();
    final patientCubit = context.read<PatientCubit>();
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

      // Save each patient to offline database
      for (final patient in _patients) {
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
        );
      }

      await PatientSyncService().refreshSyncStatus();

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

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==================== CLEANUP ====================
  @override
  void dispose() {
    _headOfFamilyController.dispose();
    _numberOfMembersController.removeListener(_updatePatientCount);
    _numberOfMembersController.dispose();
    _familyAddressController.dispose();
    super.dispose();
  }
}
