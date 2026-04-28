import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/add_patient_provider.dart';

class AddPatientStep1Widget extends ConsumerWidget {
  const AddPatientStep1Widget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addPatientFormProvider);
    final notifier = ref.read(addPatientFormProvider.notifier);
    final familyInfo = state.familyInfo;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // Show validation errors summary if any
          if (state.validationErrors.isNotEmpty && state.step == 1)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFef4444).withValues(alpha: 0.1),
                border: Border.all(
                  color: const Color(0xFFef4444).withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFef4444),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Please fix the errors below',
                      style: TextStyle(
                        color: Color(0xFFef4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Head of Family
                _buildInputField(
                  label: 'Head of Family *',
                  value: familyInfo.headOfFamily,
                  onChanged: (value) {
                    notifier.updateFamilyInfo(headOfFamily: value);
                  },
                  errorText: state.validationErrors['headOfFamily'],
                ),
                const SizedBox(height: 20),

                // Number of Members
                _buildInputField(
                  label: 'Number of Members *',
                  value: familyInfo.numberOfMembers,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    notifier.updateFamilyInfo(numberOfMembers: value);
                  },
                  errorText: state.validationErrors['numberOfMembers'],
                  helperText: '(Minimum 1, Maximum 20 members)',
                ),
                const SizedBox(height: 20),

                // Family Address
                _buildInputField(
                  label: 'Family Address *',
                  value: familyInfo.familyAddress,
                  maxLines: 3,
                  onChanged: (value) {
                    notifier.updateFamilyInfo(familyAddress: value);
                  },
                  errorText: state.validationErrors['familyAddress'],
                ),
                const SizedBox(height: 20),

                // Same Address for All
                GestureDetector(
                  onTap: () {
                    notifier.updateFamilyInfo(
                      sameAddressForAll: !familyInfo.sameAddressForAll,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF4B5563)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: familyInfo.sameAddressForAll
                                ? const Color(0xFF14b8a6)
                                : Colors.transparent,
                            border: Border.all(
                              color: const Color(0xFF4B5563),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: familyInfo.sameAddressForAll
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Use same address for all family members',
                            style: TextStyle(
                              color: Color(0xFFD1D5DB),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
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
    String? errorText,
    String? helperText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    
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
            hintText: 'Enter $label',
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFef4444),
              ),
            ),
            suffixIcon: value.isNotEmpty && !hasError
                ? const Icon(
                    Icons.check_circle,
                    color: Color(0xFF14b8a6),
                    size: 20,
                  )
                : null,
          ),
        ),
        if (hasError)
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
        else if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              helperText,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
