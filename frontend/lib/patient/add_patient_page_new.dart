import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/patient/add_patient_models.dart';
import 'package:frontend/providers/add_patient_provider.dart';
import 'package:frontend/providers/login_provider.dart';
import 'widgets/step1_family_info.dart';
import 'widgets/step2_patient_details.dart';
import 'widgets/step3_medical_info.dart';

class AddPatientPageNew extends ConsumerWidget {
  const AddPatientPageNew({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addPatientFormProvider);

    return PopScope(
      canPop: state.step == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && state.step > 1) {
          ref.read(addPatientFormProvider.notifier).previousStep();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0f1419),
        body: SafeArea(
          child: Column(
            children: [
              // Header with progress indicator
              _buildHeader(context, state.step),
              
              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: () {
                    switch (state.step) {
                      case 1:
                        return Step1FamilyInfo();
                      case 2:
                        return Step2PatientDetails();
                      case 3:
                        return Step3MedicalInfo();
                      default:
                        return SizedBox.shrink();
                    }
                  }(),
                ),
              ),

              // Navigation buttons
              _buildNavigationButtons(context, ref, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int currentStep) {
    return Container(
      color: const Color(0xFF1f2937),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress bars
          Row(
            children: [
              _buildProgressSegment(
                currentStep >= 1,
                'Family',
                index: 1,
              ),
              Container(
                width: 8,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: currentStep >= 2 ? const Color(0xFF14b8a6) : const Color(0xFF374151),
              ),
              _buildProgressSegment(
                currentStep >= 2,
                'Patient',
                index: 2,
              ),
              Container(
                width: 8,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: currentStep >= 3 ? const Color(0xFF14b8a6) : const Color(0xFF374151),
              ),
              _buildProgressSegment(
                currentStep >= 3,
                'Medical',
                index: 3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSegment(bool isActive, String label, {required int index}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive ? const Color(0xFF14b8a6) : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF14b8a6) : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, WidgetRef ref, AddPatientFormState state) {
    final canProceed = ref.watch(canProceedToNextStepProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade800,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          if (state.errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withValues(alpha: 0.3),
                border: Border.all(color: Colors.red.shade700),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                state.errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          Row(
            children: [
              // Back button (visible after step 1)
              if (state.step > 1)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(addPatientFormProvider.notifier).previousStep();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1f2937),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (state.step > 1) const SizedBox(width: 12),

              // Next/Save button
              Expanded(
                child: ElevatedButton(
                  onPressed: canProceed
                      ? state.step == 3
                          ? () => _handleSubmit(context, ref, state)
                          : () {
                              ref.read(addPatientFormProvider.notifier).nextStep();
                            }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canProceed
                        ? const Color(0xFF14b8a6)
                        : const Color(0xFF14b8a6).withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    state.step == 3 ? 'Save Patient Data' : 'Next',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Future<void> _handleSubmit(
    BuildContext context,
    WidgetRef ref,
    AddPatientFormState state,
  ) async {
    try {
      final token = ref.read(loginProvider).token;
      if (token == null || token.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      );

      final success =
          await ref.read(addPatientFormProvider.notifier).submitRegistration(token);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Family registered successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Close add patient page
        } else {
          final latestState = ref.read(addPatientFormProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(latestState.errorMessage.isNotEmpty
                  ? latestState.errorMessage
                  : 'Failed to save. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
