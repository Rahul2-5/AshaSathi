import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/patient/add_patient_models.dart';
import 'package:frontend/providers/add_patient_provider.dart';

class Step3MedicalInfo extends ConsumerWidget {
  const Step3MedicalInfo({super.key});

  // Disease list to display
  static const List<String> diseases = [
    'BP',
    'Elephantiasis',
    'Diabetes',
    'Heart Disease',
    'Asthma',
    'Thyroid',
    'Arthritis',
    'Kidney',
    'Liver',
    'Cancer',
  ];

  static const List<String> diseaseKeys = [
    'bp',
    'elephantiasis',
    'diabetes',
    'heartDisease',
    'asthma',
    'thyroid',
    'arthritis',
    'kidney',
    'liver',
    'cancer',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addPatientFormProvider);
    final currentPatient = ref.watch(currentPatientProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Text(
          'Medical Information',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),

        // Patient selector tabs
        _buildPatientTabs(context, ref, state),
        const SizedBox(height: 16),

        // Medical info card
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1f2937),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Privacy preference checkbox
              _buildPrivacyCheckbox(context, ref, currentPatient),
              const SizedBox(height: 20),

              // Warning banner (if privacy declined)
              if (currentPatient.declinedHealthInfo)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade900.withValues(alpha: 0.3),
                    border: Border.all(color: Colors.orange.shade700),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade300,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Patient has declined to share medical information',
                          style: TextStyle(
                            color: Colors.orange.shade300,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Disease selection title
              const Text(
                'Select Health Conditions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Disease grid
              Opacity(
                opacity: currentPatient.declinedHealthInfo ? 0.4 : 1.0,
                child: IgnorePointer(
                  ignoring: currentPatient.declinedHealthInfo,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 3.5,
                    ),
                    itemCount: diseases.length,
                    itemBuilder: (context, index) {
                      final diseaseKey = diseaseKeys[index];
                      final diseaseName = diseases[index];
                      final isSelected =
                          currentPatient.diseases[diseaseKey] ?? false;

                      return GestureDetector(
                        onTap: () {
                          ref
                              .read(addPatientFormProvider.notifier)
                              .toggleDisease(diseaseKey);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF14b8a6)
                                : const Color(0xFF0f1419),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF14b8a6)
                                  : Colors.grey.shade700,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF14b8a6)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isSelected)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  diseaseName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 12,
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
                ),
              ),
              const SizedBox(height: 20),

              // Notes
              const Text(
                'Additional Notes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: currentPatient.notes),
                maxLines: 4,
                onChanged: (value) {
                  ref
                      .read(addPatientFormProvider.notifier)
                      .updateNotes(value);
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0f1419),
                  hintText: 'Add any additional notes about the patient...',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF14b8a6),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 20),

              // Data summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.blue.shade700),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total patients: ${state.patients.length}',
                      style: TextStyle(color: Colors.blue.shade300, fontSize: 13),
                    ),
                    Text(
                      'Conditions selected: ${currentPatient.diseases.values.where((v) => v).length}',
                      style: TextStyle(color: Colors.blue.shade300, fontSize: 13),
                    ),
                    if (currentPatient.declinedHealthInfo)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Privacy: Patient declined to share health info',
                          style: TextStyle(
                            color: Colors.orange.shade300,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientTabs(BuildContext context, WidgetRef ref, AddPatientFormState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          state.patients.length,
          (index) {
            final patient = state.patients[index];
            final isActive = state.currentPatientIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: () {
                  ref.read(addPatientFormProvider.notifier).selectPatient(index);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive
                      ? const Color(0xFF14b8a6)
                      : const Color(0xFF1f2937),
                  foregroundColor: isActive ? Colors.white : Colors.grey,
                  side: BorderSide(
                    color: isActive
                        ? const Color(0xFF14b8a6)
                        : Colors.grey.shade700,
                  ),
                ),
                child: Text(patient.patientName.isEmpty
                    ? 'Member ${index + 1}'
                    : patient.patientName),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPrivacyCheckbox(
    BuildContext context,
    WidgetRef ref,
    PatientDataModel patient,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(addPatientFormProvider.notifier).togglePrivacy();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: patient.declinedHealthInfo
                ? Colors.orange.shade700
                : Colors.grey.shade700,
          ),
          borderRadius: BorderRadius.circular(10),
          color: patient.declinedHealthInfo
              ? Colors.orange.shade900.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(
                  color: patient.declinedHealthInfo
                      ? Colors.orange.shade700
                      : Colors.grey.shade600,
                ),
                borderRadius: BorderRadius.circular(4),
                color: patient.declinedHealthInfo
                    ? Colors.orange.shade700
                    : Colors.transparent,
              ),
              child: patient.declinedHealthInfo
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Patient prefers not to share medical information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
