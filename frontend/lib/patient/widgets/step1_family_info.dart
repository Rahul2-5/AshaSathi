import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/add_patient_provider.dart';

class Step1FamilyInfo extends ConsumerWidget {
  const Step1FamilyInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addPatientFormProvider);
    final familyInfo = state.familyInfo;
    final errors = state.validationErrors;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Family Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // Card container
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1f2937),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade800),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Head of Family
                _buildFormField(
                  label: 'Head of Family *',
                  value: familyInfo.headOfFamily,
                  errorText: errors['headOfFamily'],
                  onChanged: (value) {
                    ref.read(addPatientFormProvider.notifier).updateFamilyInfo(
                      headOfFamily: value,
                    );
                  },
                  context: context,
                ),
                const SizedBox(height: 16),

                // Number of Members
                _buildMemberCounter(
                  context: context,
                  ref: ref,
                  value: int.tryParse(familyInfo.numberOfMembers) ?? 1,
                  errorText: errors['numberOfMembers'],
                ),
                const SizedBox(height: 16),

                // Family Address
                _buildFormField(
                  label: 'Family Address *',
                  value: familyInfo.familyAddress,
                  errorText: errors['familyAddress'],
                  maxLines: 3,
                  onChanged: (value) {
                    ref.read(addPatientFormProvider.notifier).updateFamilyInfo(
                      familyAddress: value,
                    );
                  },
                  context: context,
                ),
                const SizedBox(height: 16),

                // Same Address for All checkbox
                _buildCheckboxField(
                  label: 'Use this address for all family members',
                  value: familyInfo.sameAddressForAll,
                  onChanged: (value) {
                    ref.read(addPatientFormProvider.notifier).updateFamilyInfo(
                      sameAddressForAll: value ?? false,
                    );
                  },
                  context: context,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildHelpText(
            'Enter the family head\'s name and the total number of family members to register. The family address will be used by default for all members unless specified otherwise.',
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String value,
    required Function(String) onChanged,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value),
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: maxLines == 1 ? 1 : null,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0f1419),
            hintText: 'Enter $label',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Colors.grey.shade700,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Colors.grey.shade700,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF14b8a6),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(12),
            errorText: errorText,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxField({
    required String label,
    required bool value,
    required Function(bool?) onChanged,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade700),
          borderRadius: BorderRadius.circular(12),
          color: value
              ? const Color(0xFF14b8a6).withValues(alpha: 0.1)
              : transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(
                  color: value ? const Color(0xFF14b8a6) : Colors.grey.shade600,
                ),
                borderRadius: BorderRadius.circular(4),
                color: value ? const Color(0xFF14b8a6) : Colors.transparent,
              ),
              child: value
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCounter({
    required BuildContext context,
    required WidgetRef ref,
    required int value,
    String? errorText,
  }) {
    final safeValue = value < 1 ? 1 : value;

    void updateCount(int next) {
      final sanitized = next < 1 ? 1 : next;
      ref.read(addPatientFormProvider.notifier).updateFamilyInfo(
        numberOfMembers: sanitized.toString(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Number of Members',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0f1419),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null ? Colors.red : Colors.grey.shade700,
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: safeValue > 1 ? () => updateCount(safeValue - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: const Color(0xFF14b8a6),
              ),
              Expanded(
                child: Text(
                  safeValue.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => updateCount(safeValue + 1),
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFF14b8a6),
              ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildHelpText(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade900.withValues(alpha: 0.2),
        border: Border.all(color: Colors.blue.shade700),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.blue.shade300,
          fontSize: 13,
        ),
      ),
    );
  }
}

const transparent = Colors.transparent;
