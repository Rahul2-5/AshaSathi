import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/add_patient_provider.dart';
import 'package:frontend/providers/login_provider.dart';
import 'package:frontend/patient/add_patient_models.dart';
import 'package:frontend/screens/add_patient/widgets/add_patient_step1.dart';
import 'package:frontend/screens/add_patient/widgets/add_patient_step2.dart';
import 'package:frontend/screens/add_patient/widgets/add_patient_step3.dart';

class AddPatientWizardScreen extends ConsumerWidget {
  const AddPatientWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addPatientFormProvider);
    final notifier = ref.read(addPatientFormProvider.notifier);

    return PopScope(
      canPop: state.step == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && state.step > 1) {
          notifier.previousStep();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0f1419),
        body: Column(
          children: [
            // ==================== HEADER ====================
            _buildHeader(context, state, notifier),
            
            // ==================== CONTENT ====================
            Expanded(
              child: Stack(
                children: [
                  // Step 1: Family Information
                  if (state.step == 1)
                    const AddPatientStep1Widget()
                  // Step 2: Patient Details
                  else if (state.step == 2)
                    const AddPatientStep2Widget()
                  // Step 3: Medical Information
                  else if (state.step == 3)
                    const AddPatientStep3Widget(),
                  
                  // Loading overlay
                  if (state.isLoading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF14b8a6)),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ==================== NAVIGATION BUTTONS ====================
            _buildNavigationButtons(context, ref, state, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AddPatientFormState state,
    AddPatientNotifier notifier,
  ) {
    return Container(
      color: const Color(0xFF1f2937),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button + Title
            Row(
              children: [
                if (state.step > 1)
                  GestureDetector(
                    onTap: notifier.previousStep,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Add Patient',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Progress Indicator
            _buildProgressIndicator(state.step),
            const SizedBox(height: 12),
            
            // Step labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStepLabel('Family', state.step >= 1, state.step == 1),
                _buildStepLabel('Patient', state.step >= 2, state.step == 2),
                _buildStepLabel('Medical', state.step >= 3, state.step == 3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int currentStep) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: currentStep >= 1
                  ? const Color(0xFF14b8a6)
                  : const Color(0xFF374151),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: currentStep >= 2
                  ? const Color(0xFF14b8a6)
                  : const Color(0xFF374151),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: currentStep >= 3
                  ? const Color(0xFF14b8a6)
                  : const Color(0xFF374151),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLabel(String label, bool isCompleted, bool isActive) {
    return Text(
      label,
      style: TextStyle(
        color: isActive || isCompleted
            ? const Color(0xFF14b8a6)
            : const Color(0xFF9CA3AF),
        fontSize: 12,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    WidgetRef ref,
    AddPatientFormState state,
    AddPatientNotifier notifier,
  ) {
    return Container(
      color: const Color(0xFF1f2937),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          children: [
            // Error message with more details
            if (state.errorMessage.isNotEmpty)
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFef4444),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.errorMessage,
                            style: const TextStyle(
                              color: Color(0xFFef4444),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Show validation errors if any
                    if (state.validationErrors.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: state.validationErrors.entries
                              .take(3)
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '• ${e.value}',
                                    style: const TextStyle(
                                      color: Color(0xFFef4444),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    if (state.validationErrors.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• +${state.validationErrors.length - 3} more error(s)',
                          style: const TextStyle(
                            color: Color(0xFFef4444),
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Buttons
            Row(
              children: [
                // Back button
                if (state.step > 1)
                  Expanded(
                    child: GestureDetector(
                      onTap: notifier.previousStep,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF374151),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Back',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (state.step > 1) const SizedBox(width: 12),

                // Next/Save button
                Expanded(
                  child: GestureDetector(
                    onTap: state.isLoading
                        ? null
                        : () async {
                            if (state.step < 3) {
                              notifier.nextStep();
                            } else {
                              final token = await ref.read(loginProvider.notifier).getValidToken();
                              if (token == null || token.isEmpty) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Session expired. Please login again.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }

                              // Submit
                              final success = await notifier.submitRegistration(
                                token,
                              );
                              
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Family registered successfully!',
                                    ),
                                    backgroundColor: Color(0xFF14b8a6),
                                  ),
                                );
                                Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                                  '/main',
                                  (route) => false,
                                );
                              }
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF14b8a6), Color(0xFF0d9488)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF14b8a6).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          state.step < 3
                              ? 'Next: ${_getStepTitle(state.step + 1)}'
                              : 'Save Patient Data',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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

  String _getStepTitle(int step) {
    switch (step) {
      case 2:
        return 'Patient Details';
      case 3:
        return 'Medical Info';
      default:
        return '';
    }
  }
}
