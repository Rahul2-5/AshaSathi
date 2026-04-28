import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/add_patient_provider.dart';

class AddPatientStep3Widget extends ConsumerWidget {
  const AddPatientStep3Widget({super.key});

  static const List<Map<String, String>> diseases = [
    {'key': 'bp', 'label': 'BP'},
    {'key': 'elephantiasis', 'label': 'Elephantiasis'},
    {'key': 'diabetes', 'label': 'Diabetes'},
    {'key': 'heartDisease', 'label': 'Heart Disease'},
    {'key': 'asthma', 'label': 'Asthma'},
    {'key': 'thyroid', 'label': 'Thyroid'},
    {'key': 'arthritis', 'label': 'Arthritis'},
    {'key': 'kidney', 'label': 'Kidney'},
    {'key': 'liver', 'label': 'Liver'},
    {'key': 'cancer', 'label': 'Cancer'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addPatientFormProvider);
    final notifier = ref.read(addPatientFormProvider.notifier);
    final currentPatient = ref.watch(currentPatientProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // ==================== PATIENT SELECTOR ====================
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: state.patients.asMap().entries.map(
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
                        state.patients[index].patientName.isEmpty
                            ? 'Member ${index + 1}'
                            : state.patients[index].patientName,
                        style: TextStyle(
                          color: isActive ? Colors.white : Color(0xFF9CA3AF),
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // ==================== MEDICAL INFO CARD ====================
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Privacy Checkbox
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: currentPatient.declinedHealthInfo
                        ? const Color(0xFFf97316).withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: currentPatient.declinedHealthInfo
                          ? const Color(0xFFf97316)
                          : const Color(0xFF4B5563),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: GestureDetector(
                    onTap: notifier.togglePrivacy,
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: currentPatient.declinedHealthInfo
                                ? const Color(0xFFf97316)
                                : Colors.transparent,
                            border: Border.all(
                              color: currentPatient.declinedHealthInfo
                                  ? const Color(0xFFf97316)
                                  : const Color(0xFF4B5563),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: currentPatient.declinedHealthInfo
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
                            'Patient prefers not to share medical information',
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
                const SizedBox(height: 20),

                // Privacy Warning
                if (currentPatient.declinedHealthInfo)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf97316).withValues(alpha: 0.1),
                      border: Border.all(
                        color: const Color(0xFFf97316).withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFf97316),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Patient has declined to share medical information',
                            style: TextStyle(
                              color: Color(0xFFf97316),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Disease Selection Grid
                Text(
                  'Select Diseases',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  physics: const NeverScrollableScrollPhysics(),
                  children: diseases.map((disease) {
                    final isSelected = currentPatient.diseases[disease['key']] ?? false;

                    return GestureDetector(
                      onTap: currentPatient.declinedHealthInfo
                          ? null
                          : () => notifier.toggleDisease(disease['key']!),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF14b8a6)
                              : const Color(0xFF0f1419),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF14b8a6)
                                : const Color(0xFF4B5563),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF14b8a6)
                                        .withValues(alpha: 0.2),
                                    blurRadius: 8,
                                  )
                                ]
                              : [],
                        ),
                        child: Opacity(
                          opacity: currentPatient.declinedHealthInfo ? 0.4 : 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isSelected)
                                const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              const SizedBox(height: 4),
                              Text(
                                disease['label']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF9CA3AF),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Notes
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: currentPatient.notes),
                      onChanged: notifier.updateNotes,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        hintText: 'Additional notes...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF6B7280),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0f1419),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF14b8a6),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
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
}
