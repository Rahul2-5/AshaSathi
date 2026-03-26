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
import 'package:uuid/uuid.dart';

import '../offline/patient_offline_service.dart';
import '../offline/connectivity_service.dart';
import '../offline/patient_sync_service.dart';
import 'add_patient_form_data.dart';


class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  // ==================== STATE ====================
  int _currentStep = 0; // 0: Family, 1: Patient, 2: Medical
  
  // Family Info
  final _headOfFamilyController = TextEditingController();
  final _numberOfMembersController = TextEditingController(text: '1');
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
      // Add more patients
      while (_patients.length < count) {
        _patients.add(
          AddPatientFormData(
            memberNumber: "Member ${_patients.length + 1}",
            name: '',
          ),
        );
      }
    } else if (_patients.length > count) {
      // Remove extra patients
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
    if (v.isEmpty) return context.l10n.tr('common.required');
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

  String? _validatePhone(String? value) {
    final v = value?.trim() ?? '';
    // Phone is only mandatory for the first member
    if (_currentPatientIndex == 0) {
      if (v.isEmpty) return context.l10n.tr('common.required');
      if (!RegExp(r'^\d{10}$').hasMatch(v)) {
        return 'Phone must be 10 digits';
      }
    } else {
      // For other members, phone is optional but must be valid if provided
      if (v.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(v)) {
        return 'Phone must be 10 digits';
      }
    }
    return null;
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildStepProgressHeader(),
          Expanded(
            child: switch (_currentStep) {
              0 => _buildFamilyStep(),
              1 => _buildPatientStep(),
              2 => _buildMedicalStep(),
              _ => const SizedBox(),
            },
          ),
        ],
      ),
    );
  }


  // ==================== FAMILY STEP ====================
  Widget _buildFamilyStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1419) : const Color(0xFFF3F4F6);
    
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
        child: Form(
          key: _familyFormKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                    // Section breadcrumb
                    Text(
                      'Family Information',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF25D8C3) : const Color(0xFF14A7A0),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Card container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2B42) : const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2A3F5A) : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card title with icon
                          Row(
                            children: [
                              Container(
                                height: 44,
                                width: 44,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F3A48) : const Color(0xFFD1F5F0),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF25D8C3).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.group_outlined,
                                  color: Color(0xFF25D8C3),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Family Information',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171A1F),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Head of Family Name
                          _buildInputField(
                            initialValue: _headOfFamilyController.text,
                            label: 'Head of Family Name *',
                            controller: _headOfFamilyController,
                            validator: _validateHeadOfFamily,
                            hint: 'Enter name',
                          ),
                          // Number of Members with stepper
                          _buildNumberField(
                            label: 'Number of Family Members *',
                            controller: _numberOfMembersController,
                            validator: _validateNumberOfMembers,
                          ),
                          // Family Address
                          _buildInputField(
                            initialValue: _familyAddressController.text,
                            label: 'Family Address *',
                            controller: _familyAddressController,
                            validator: _validateAddress,
                            hint: 'Enter address',
                          ),
                          // Same address checkbox
                          const SizedBox(height: 4),
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF151D2E) : const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2A3F5A) : const Color(0xFFE5E7EB),
                                width: 1,
                              ),
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                checkboxTheme: CheckboxThemeData(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  side: const BorderSide(color: Color(0xFF25D8C3), width: 2),
                                  fillColor: MaterialStateProperty.resolveWith(
                                    (states) {
                                      if (states.contains(MaterialState.selected)) {
                                        return const Color(0xFF25D8C3);
                                      }
                                      return Colors.transparent;
                                    },
                                  ),
                                ),
                              ),
                              child: CheckboxListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                controlAffinity: ListTileControlAffinity.leading,
                                title: Text(
                                  'Same address for all members',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF171A1F),
                                  ),
                                ),
                                value: _sameAddressForAll,
                                onChanged: (v) {
                                  setState(() => _sameAddressForAll = v ?? true);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Next Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_familyFormKey.currentState!.validate()) {
                            _updatePatientCount();
                            setState(() => _currentStep = 1);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D8C3),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          shadowColor: const Color(0xFF25D8C3).withOpacity(0.4),
                        ),
                        child: const Text(
                          'Next: Add Patient Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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

  Widget _buildStepProgressHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = Color(0xFF25D8C3);
    final inactiveLineColor = isDark ? const Color(0xFF3D4F67) : const Color(0xFFD1D5DB);
    final inactiveTextColor = isDark ? const Color(0xFF8EA1C4) : const Color(0xFF9CA3AF);
    final bgColor = isDark ? const Color(0xFF0C1324) : const Color(0xFFF5F6F8);

    Widget stepItem(String title, bool active) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: active ? activeColor : inactiveLineColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: active ? activeColor : inactiveTextColor,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
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

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Form(
          key: _patientFormKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Member tabs with Add button
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Member',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF25D8C3) : const Color(0xFF14A7A0),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _patients.length,
                              itemBuilder: (context, index) {
                                final isSelected = index == _currentPatientIndex;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _currentPatientIndex = index);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF25D8C3)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF25D8C3)
                                              : const Color(0xFF2A3F5A),
                                          width: 1.5,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF25D8C3).withOpacity(0.25),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          _patients[index].memberNumber,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: isSelected ? Colors.black87 : const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Patient Information Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2B42) : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2A3F5A) : const Color(0xFFE5E7EB),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo section
                    _buildPhotoSection(currentPatient),
                    const SizedBox(height: 24),

                    // Patient Name
                    _buildInputField(
                      label: 'Patient Name *',
                      initialValue: currentPatient.name,
                      validator: _validatePatientName,
                      hint: 'Enter name',
                      onChanged: (v) {
                        _patients[_currentPatientIndex] = currentPatient.copyWith(name: v);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Age and DOB
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'Age',
                            initialValue: currentPatient.age?.toString() ?? '',
                            validator: _validateAge,
                            hint: 'Age',
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final age = int.tryParse(v);
                              _patients[_currentPatientIndex] = currentPatient.copyWith(age: age);
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
                              _patients[_currentPatientIndex] = currentPatient.copyWith(dateOfBirth: v);
                              _syncAgeFromDob(v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Gender
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Gender *'),
                        const SizedBox(height: 8),
                        Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF151D2E) : const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2A3F5A) : const Color(0xFFE5E7EB),
                              width: 1.5,
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: currentPatient.gender,
                            items: [
                              DropdownMenuItem(
                                value: 'Male',
                                child: Text(
                                  context.l10n.tr('patient.male'),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF171A1F),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Female',
                                child: Text(
                                  context.l10n.tr('patient.female'),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF171A1F),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Other',
                                child: Text(
                                  context.l10n.tr('patient.other'),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF171A1F),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() {
                                _patients[_currentPatientIndex] = currentPatient.copyWith(gender: v!);
                                if (v != 'Female') {
                                  _patients[_currentPatientIndex] =
                                      _patients[_currentPatientIndex].copyWith(isPregnant: false);
                                }
                              });
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                            dropdownColor: isDark ? const Color(0xFF1F2B42) : const Color(0xFFFFFFFF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Pregnancy section (only for females)
                    if (currentPatient.gender == 'Female')
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A2A2A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFF6B6B), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B).withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Theme(
                              data: Theme.of(context).copyWith(
                                checkboxTheme: CheckboxThemeData(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  side: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
                                  fillColor: MaterialStateProperty.resolveWith(
                                    (states) {
                                      if (states.contains(MaterialState.selected)) {
                                        return const Color(0xFFFF6B6B);
                                      }
                                      return Colors.transparent;
                                    },
                                  ),
                                ),
                              ),
                              child: CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: const Text(
                                  'Is Pregnant?',
                                  style: TextStyle(
                                    color: Color(0xFFFF6B6B),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                value: currentPatient.isPregnant,
                                onChanged: (v) {
                                  setState(() {
                                    _patients[_currentPatientIndex] =
                                        currentPatient.copyWith(isPregnant: v ?? false);
                                  });
                                },
                              ),
                            ),
                            if (currentPatient.isPregnant) ...[
                              const SizedBox(height: 16),
                              _buildLabel('Months of Pregnancy'),
                              const SizedBox(height: 8),
                              _buildNumberFieldForPregnancy(
                                controller: TextEditingController(
                                  text: currentPatient.monthsOfPregnancy?.toString() ?? '1',
                                ),
                                onChanged: (v) {
                                  final months = int.tryParse(v);
                                  _patients[_currentPatientIndex] = currentPatient.copyWith(
                                    monthsOfPregnancy: months,
                                  );
                                  if (months != null && months >= 1) {
                                    _calculateExpectedDeliveryDate(months);
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildDeliveryDateField(
                                label: 'Expected Delivery Date',
                                initialValue: currentPatient.expectedDeliveryDate ?? '',
                                onChanged: (v) {
                                  _patients[_currentPatientIndex] =
                                      currentPatient.copyWith(expectedDeliveryDate: v);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Caste
                    _buildInputField(
                      label: 'Caste',
                      initialValue: currentPatient.caste,
                      hint: 'Enter caste (optional)',
                      onChanged: (v) {
                        _patients[_currentPatientIndex] = currentPatient.copyWith(caste: v);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Same as family address
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF151D2E) : const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2A3F5A) : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          checkboxTheme: CheckboxThemeData(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: const BorderSide(color: Color(0xFF25D8C3), width: 2),
                            fillColor: MaterialStateProperty.resolveWith(
                              (states) {
                                if (states.contains(MaterialState.selected)) {
                                  return const Color(0xFF25D8C3);
                                }
                                return Colors.transparent;
                              },
                            ),
                          ),
                        ),
                        child: CheckboxListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text(
                            'Same as family address',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          value: currentPatient.usesFamilyAddress,
                          onChanged: (v) {
                            setState(() {
                              _patients[_currentPatientIndex] =
                                  currentPatient.copyWith(usesFamilyAddress: v ?? true);
                            });
                          },
                        ),
                      ),
                    ),
                    
                    // Conditional address field if not using family address
                    if (!currentPatient.usesFamilyAddress) ...[
                      const SizedBox(height: 16),
                      _buildInputField(
                        label: 'Patient Address *',
                        initialValue: currentPatient.address ?? '',
                        hint: 'Enter address',
                        onChanged: (v) {
                          _patients[_currentPatientIndex] = currentPatient.copyWith(address: v);
                        },
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Phone Number
                    _buildInputField(
                      label: _currentPatientIndex == 0 ? 'Phone Number *' : 'Phone Number',
                      initialValue: currentPatient.phoneNumber,
                      validator: _validatePhone,
                      hint: 'Enter 10-digit phone',
                      keyboardType: TextInputType.phone,
                      onChanged: (v) {
                        _patients[_currentPatientIndex] = currentPatient.copyWith(phoneNumber: v);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Back and Next buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => setState(() => _currentStep -= 1),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3A4F67),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                shadowColor: const Color(0xFF3A4F67).withOpacity(0.3),
                              ),
                              child: const Text(
                                'Back',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 56,
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
                                backgroundColor: const Color(0xFF25D8C3),
                                foregroundColor: Colors.black87,
                                elevation: 4,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                shadowColor: const Color(0xFF25D8C3).withOpacity(0.4),
                              ),
                              child: Text(
                                _currentPatientIndex == _patients.length - 1
                                    ? 'Next: Medical Info'
                                    : 'Next Patient',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
    if (_patients.isEmpty) {
      return const SizedBox();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1419) : const Color(0xFFF3F4F6);
    final currentPatient = _patients[_currentPatientIndex];

    return Container(
      decoration: BoxDecoration(color: bgColor),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select Member Section
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medical Information - ${currentPatient.memberNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF25D8C3) : const Color(0xFF14A7A0),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Member tabs
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _patients.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _currentPatientIndex;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => setState(() => _currentPatientIndex = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF25D8C3)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF25D8C3)
                                      : const Color(0xFF2A3F5A),
                                  width: 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF25D8C3).withOpacity(0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  _patients[index].memberNumber,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: isSelected ? Colors.black87 : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Medical Information Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2B42) : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A3F5A) : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient name & info
                  Row(
                    children: [
                      Icon(
                        Icons.medical_information_outlined,
                        color: const Color(0xFF25D8C3),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentPatient.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF171A1F),
                              ),
                            ),
                            Text(
                              currentPatient.memberNumber,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF8EA1C4) : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFF2A3F5A), height: 1),
                  const SizedBox(height: 20),

                  // Refuse to share checkbox
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFF6B6B), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF4A2A2A).withOpacity(0.3),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        checkboxTheme: CheckboxThemeData(
                          side: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
                          fillColor: MaterialStateProperty.resolveWith(
                            (states) {
                              if (states.contains(MaterialState.selected)) {
                                return const Color(0xFFFF6B6B);
                              }
                              return Colors.transparent;
                            },
                          ),
                        ),
                      ),
                      child: CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'Patient prefers not to share medical information',
                          style: TextStyle(
                            color: Color(0xFFFF6B6B),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: currentPatient.medicalInfo.refusedToShare,
                        onChanged: (v) {
                          setState(() {
                            final medicalInfo = currentPatient.medicalInfo;
                            if (v == true) {
                              // Clear all selections
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
                  ),
                  const SizedBox(height: 24),

                  // Medical Conditions
                  Text(
                    'Medical Conditions',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (currentPatient.medicalInfo.refusedToShare)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF151D2E)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2A3F5A) : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        'Data not collected per patient preference',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
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
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
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
                                    ? const Color(0xFF25D8C3)
                                    : (isDark
                                        ? const Color(0xFF2A3F5A)
                                        : Colors.grey.shade300),
                                width: condition.selected ? 2: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: condition.selected
                                  ? const Color(0xFF25D8C3).withOpacity(0.12)
                                  : (isDark ? const Color(0xFF151D2E) : Colors.white),
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
                                    color: Color(0xFF25D8C3),
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
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Notes Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2B42) : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A3F5A) : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes / Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF171A1F),
                    ),
                  ),
                  const SizedBox(height: 12),
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
            ),
            const SizedBox(height: 32),

            // Save buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () =>
                          setState(() => _currentStep -= 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A4F67),
                        elevation: 4,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        shadowColor: const Color(0xFF3A4F67).withOpacity(0.3),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSaveAllData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D8C3),
                        elevation: 4,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        shadowColor: const Color(0xFF25D8C3).withOpacity(0.4),
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
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
          _buildLabel(label),
          const SizedBox(height: 6),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
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
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                Container(
                  width: 44,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: borderColor, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final current = int.tryParse(controller.text) ?? 0;
                              if (current < 20) {
                                controller.text = (current + 1).toString();
                                setState(() {});
                              }
                            },
                            child: const Icon(
                              Icons.arrow_drop_up,
                              color: Color(0xFF24D6C3),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 1,
                        color: borderColor,
                      ),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final current = int.tryParse(controller.text) ?? 0;
                              if (current > 1) {
                                controller.text = (current - 1).toString();
                                setState(() {});
                              }
                            },
                            child: const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF24D6C3),
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
          ),
          if (validator != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                validator(controller.text) ?? '',
                style: const TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String? initialValue,
    String? label,
    TextEditingController? controller,
    String? Function(String?)? validator,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF171A1F);
    final ctrl = controller;

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
            initialValue: ctrl == null ? initialValue : null,
            controller: ctrl,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            onChanged: onChanged,
            style: TextStyle(color: textColor),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: initialValue);
    final isDeliveryDate = label.contains('Delivery');
    final fillColor = isDark ? const Color(0xFF151D2E) : const Color(0xFFFFFFFF);
    final hintColor = isDark ? const Color(0xFF6F85A8) : const Color(0xFF6B7280);
    final textColor = isDark ? Colors.white : const Color(0xFF171A1F);

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
            style: TextStyle(color: textColor),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: isDeliveryDate ? now.add(const Duration(days: 270)) : DateTime.now(),
                firstDate: isDeliveryDate ? now : DateTime(1900),
                lastDate: isDeliveryDate ? now.add(const Duration(days: 365)) : now,
              );
              if (picked != null) {
                final formatted =
                    "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                controller.text = formatted;
                onChanged(formatted);
                setState(() {});
              }
            },
            decoration: isDeliveryDate
                ? InputDecoration(
                    hintText: 'dd-mm-yyyy',
                    hintStyle: TextStyle(
                      color: hintColor,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: fillColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFFFF6B6B)),
                  )
                : _inputDecoration('dd-mm-yyyy').copyWith(
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
          ),
        ],
      ),
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
          _buildLabel(label),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            readOnly: true,
            style: TextStyle(color: textColor),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 270)),
                firstDate: now,
                lastDate: now.add(const Duration(days: 365)),
              );
              if (picked != null) {
                final formatted =
                    "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                controller.text = formatted;
                onChanged(formatted);
                setState(() {});
              }
            },
            decoration: InputDecoration(
              hintText: 'dd-mm-yyyy',
              hintStyle: TextStyle(
                color: hintColor,
                fontSize: 13,
              ),
              filled: true,
              fillColor: fillColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
              ),
              suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF25D8C3), size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
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
        color: hintColor,
        fontSize: 13,
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
        borderSide: const BorderSide(color: Color(0xFF25D8C3), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
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

