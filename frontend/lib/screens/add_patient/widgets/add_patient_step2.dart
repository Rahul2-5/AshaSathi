import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:frontend/providers/add_patient_provider.dart';

class AddPatientStep2Widget extends ConsumerWidget {
  const AddPatientStep2Widget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addPatientFormProvider);
    final notifier = ref.read(addPatientFormProvider.notifier);
    final currentPatient = ref.watch(currentPatientProvider);
    final currentIndex = state.currentPatientIndex;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // ==================== PATIENT SELECTOR TABS ====================
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...state.patients.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final isActive = index == state.currentPatientIndex;

                    return GestureDetector(
                      onTap: () => notifier.selectPatient(index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF14b8a6)
                              : const Color(0xFF374151),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Member ${index + 1}',
                          style: TextStyle(
                            color:
                                isActive ? Colors.white : Color(0xFF9CA3AF),
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap: notifier.addPatient,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF14b8a6),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '+ Add',
                      style: TextStyle(
                        color: Color(0xFF14b8a6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ==================== PATIENT FORM ====================
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo Upload (optional)
                _buildPhotoSection(notifier, currentPatient),
                const SizedBox(height: 20),

                // Patient Name
                _buildInputField(
                  label: 'Patient Name *',
                  value: currentPatient.patientName,
                  onChanged: (value) {
                    notifier.updatePatient(patientName: value);
                  },
                  errorKey: 'patient_${currentIndex}_name',
                  errors: state.validationErrors,
                ),
                const SizedBox(height: 16),

                // Age and DOB Row
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: 'Age *',
                        value: currentPatient.age,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          notifier.updatePatient(age: value);
                        },
                        helperText: 'Enter in years (0-150)',
                        errorKey: 'patient_${currentIndex}_age',
                        errors: state.validationErrors,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        label: 'DOB *',
                        value: currentPatient.dateOfBirth,
                        placeholder: 'YYYY-MM-DD',
                        onChanged: (value) {
                          notifier.updatePatient(dateOfBirth: value);
                        },
                        helperText: 'Auto-fills from age',
                        errorKey: 'patient_${currentIndex}_dob',
                        errors: state.validationErrors,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Gender
                _buildDropdown(
                  label: 'Gender',
                  value: currentPatient.gender,
                  items: ['Female', 'Male', 'Other'],
                  onChanged: (value) {
                    notifier.updatePatient(gender: value);
                  },
                ),
                const SizedBox(height: 16),

                // PREGNANCY SECTION (Female only)
                if (currentPatient.gender == 'Female')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFec4899).withValues(alpha: 0.1),
                          border: Border.all(
                            color: const Color(0xFFec4899).withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            notifier.updatePatient(
                              isPregnant: !currentPatient.isPregnant,
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: currentPatient.isPregnant
                                      ? const Color(0xFFec4899)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: const Color(0xFFec4899),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: currentPatient.isPregnant
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Is Pregnant?',
                                style: TextStyle(
                                  color: Color(0xFFec4899),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (currentPatient.isPregnant) ...[
                        const SizedBox(height: 12),
                        _buildInputField(
                          label: 'Months of Pregnancy *',
                          value: currentPatient.monthsOfPregnancy,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            notifier.updatePatient(
                              monthsOfPregnancy: value.isEmpty ? '1' : value,
                            );
                          },
                          helperText: 'Enter between 1-9 months',
                          errorKey: 'patient_${currentIndex}_months',
                          errors: state.validationErrors,
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          label: 'Expected Delivery Date *',
                          value: currentPatient.expectedDeliveryDate,
                          placeholder: 'YYYY-MM-DD',
                          onChanged: (value) {
                            notifier.updatePatient(
                              expectedDeliveryDate: value,
                            );
                          },
                          helperText: 'Must be a future date',
                          errorKey: 'patient_${currentIndex}_delivery',
                          errors: state.validationErrors,
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),

                // Caste
                _buildInputField(
                  label: 'Caste',
                  value: currentPatient.caste,
                  onChanged: (value) {
                    notifier.updatePatient(caste: value);
                  },
                ),
                const SizedBox(height: 16),

                // Address
                if (!state.familyInfo.sameAddressForAll)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputField(
                        label: 'Address *',
                        value: currentPatient.address,
                        maxLines: 2,
                        onChanged: (value) {
                          notifier.updatePatient(address: value);
                        },
                        errorKey: 'patient_${currentIndex}_address',
                        errors: state.validationErrors,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Phone Number
                _buildInputField(
                  label: 'Phone Number',
                  value: currentPatient.phoneNumber,
                  keyboardType: TextInputType.phone,
                  onChanged: (value) {
                    notifier.updatePatient(phoneNumber: value);
                  },
                  errorKey: 'patient_${currentIndex}_phone',
                  errors: state.validationErrors,
                ),
                const SizedBox(height: 20),

                // Delete Button (only if > 1 patient)
                if (state.patients.length > 1)
                  GestureDetector(
                    onTap: () {
                      notifier.removePatient(state.currentPatientIndex);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFef4444).withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Remove This Member',
                          style: TextStyle(
                            color: Color(0xFFef4444),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(dynamic notifier, dynamic currentPatient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photo (Optional)',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            try {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.camera);
              if (pickedFile != null) {
                final docsDir = await getApplicationDocumentsDirectory();
                final photosDir = Directory(p.join(docsDir.path, 'patient_photos'));
                if (!photosDir.existsSync()) {
                  photosDir.createSync(recursive: true);
                }
                final ext = p.extension(pickedFile.path).isNotEmpty ? p.extension(pickedFile.path) : '.jpg';
                final fileName = 'patient_${DateTime.now().microsecondsSinceEpoch}$ext';
                final savedPath = p.join(photosDir.path, fileName);
                
                final savedFile = await File(pickedFile.path).copy(savedPath);
                notifier.updatePatient(photoPath: savedFile.path);
              }
            } catch (e) {
              debugPrint('Failed to pick image: $e');
            }
          },
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF0f1419),
              border: Border.all(
                color: const Color(0xFF4B5563),
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: currentPatient.photoPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(currentPatient.photoPath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          color: Color(0xFF6B7280),
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap to upload photo',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1f2937),
        border: Border.all(color: const Color(0xFF4B5563)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildInputField({
    required String label,
    required String value,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? placeholder,
    String? errorKey,
    Map<String, String>? errors,
    String? helperText,
  }) {
    final hasError = errorKey != null && errors != null && errors.containsKey(errorKey);
    final errorText = hasError ? errors[errorKey] : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (label.endsWith('*'))
              const Text(
                ' (Required)',
                style: TextStyle(
                  color: Color(0xFFef4444),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value),
          onChanged: onChanged,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            hintText: placeholder ?? 'Enter $label',
            hintStyle: const TextStyle(color: Color(0xFF6B7280)),
            filled: true,
            fillColor: hasError
                ? const Color(0xFFef4444).withValues(alpha: 0.08)
                : const Color(0xFF0f1419),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFef4444) : const Color(0xFF4B5563),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFef4444) : const Color(0xFF4B5563),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFef4444) : const Color(0xFF14b8a6),
                width: 2,
              ),
            ),
            suffixIcon: value.isNotEmpty && !hasError && label.endsWith('*')
                ? const Icon(
                    Icons.check_circle,
                    color: Color(0xFF14b8a6),
                    size: 20,
                  )
                : null,
          ),
        ),
        if (hasError && errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFef4444),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    errorText,
                    style: const TextStyle(
                      color: Color(0xFFef4444),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (helperText != null && helperText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outlined,
                  color: Color(0xFF6B7280),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    helperText,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0f1419),
            border: Border.all(color: const Color(0xFF4B5563)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF1f2937),
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ))
                .toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
