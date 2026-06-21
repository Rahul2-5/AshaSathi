import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:frontend/patient/add_patient_models.dart';
import 'package:frontend/patient/patient_model.dart';
import 'package:frontend/navigation/main_navigation.dart';
import 'package:frontend/providers/add_patient_provider.dart';
import 'package:frontend/providers/login_provider.dart';
import 'package:frontend/providers/family_provider.dart';
import 'package:frontend/providers/patient_provider.dart';
import 'package:frontend/offline/family_sync_service.dart';
import 'package:frontend/offline/connectivity_service.dart';
import 'widgets/step1_family_info.dart';
import 'widgets/step2_patient_details.dart';
import 'widgets/step3_medical_info.dart';
import '../widgets/common/common_widgets.dart';

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
        backgroundColor: Colors.transparent,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: BorderRadius.zero,
      blur: 16,
      padding: const EdgeInsets.all(16),
      border: Border(bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5))),
      child: Column(
        children: [
          // Progress bars
          Row(
            children: [
              _buildProgressSegment(
                context,
                currentStep >= 1,
                context.l10n.tr('patient.stepFamily'),
                index: 1,
              ),
              Container(
                width: 8,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: currentStep >= 2
                    ? const Color(0xFF14A7A0)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05)),
              ),
              _buildProgressSegment(
                context,
                currentStep >= 2,
                context.l10n.tr('patient.stepPatient'),
                index: 2,
              ),
              Container(
                width: 8,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: currentStep >= 3
                    ? const Color(0xFF14A7A0)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05)),
              ),
              _buildProgressSegment(
                context,
                currentStep >= 3,
                context.l10n.tr('patient.stepMedical'),
                index: 3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSegment(
    BuildContext context,
    bool isActive,
    String label, {
    required int index,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Column(
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive
                  ? const Color(0xFF14A7A0)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? const Color(0xFF14A7A0)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.zero,
      blur: 24,
      border: Border(
        top: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (state.errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.8),
                border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                state.errorMessage,
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontSize: 13,
                ),
              ),
            ),
          Row(
            children: [
              // Back button (visible after step 1)
              if (state.step > 1)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(addPatientFormProvider.notifier).previousStep();
                    },
                    icon: const Icon(Icons.arrow_back, size: 20),
                    label: Text(
                      context.l10n.tr('common.back'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                      foregroundColor: theme.colorScheme.onSurface,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              if (state.step > 1) const SizedBox(width: 12),

              // Next/Save button
              Expanded(
                child: GlassButton(
                  onPressed: canProceed
                      ? state.step == 3
                          ? () => _handleSubmit(context, ref, state)
                          : () {
                              ref.read(addPatientFormProvider.notifier).nextStep();
                            }
                      : () {},
                  label: state.step == 3
                      ? context.l10n.tr('patient.saveData')
                      : context.l10n.tr('common.next'),
                  icon: state.step == 3 ? Icons.check : Icons.arrow_forward,
                  gradientColors: canProceed
                      ? [const Color(0xFF14A7A0), const Color(0xFF108C86)]
                      : [const Color(0xFF14A7A0).withValues(alpha: 0.3), const Color(0xFF108C86).withValues(alpha: 0.3)],
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
      final token = await ref.read(loginProvider.notifier).getValidToken();
      if (token == null || token.isEmpty) {
        if (context.mounted) {
          _showStatusSnackBar(
            context,
            message: context.l10n.tr('patient.sessionExpiredLogin'),
            type: _StatusType.error,
          );
        }
        return;
      }

      if (!context.mounted) {
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
          final now = DateTime.now().millisecondsSinceEpoch;
          final patientNotifier = ref.read(patientListProvider.notifier);

          for (var index = 0; index < state.patients.length; index++) {
            final patient = state.patients[index];
            final resolvedAddress = patient.sameAsFamilyAddress
                ? state.familyInfo.familyAddress
                : patient.address;

            patientNotifier.upsertPatient(
              Patient(
                id: null,
                uuid: '${state.familyInfo.headOfFamily}-$now-$index',
                name: patient.patientName,
                gender: patient.gender,
                age: int.tryParse(patient.age) ?? 0,
                dateOfBirth: patient.dateOfBirth,
                address: resolvedAddress,
                phoneNumber: patient.phoneNumber,
                description: patient.notes,
                caste: patient.caste,
                isPregnant: patient.isPregnant,
                monthsOfPregnancy: int.tryParse(patient.monthsOfPregnancy),
                expectedDeliveryDate: patient.expectedDeliveryDate,
                declinedHealthInfo: patient.declinedHealthInfo,
                diseases: patient.diseases,
                photoPath: patient.photoPath,
                updatedAt: now + index,
              ),
            );
          }

          // 🔄 If online, try to sync pending families (those registered offline)
          final isOnline = await ConnectivityService().isOnline();
          if (isOnline) {
            try {
              await FamilySyncService().syncPendingFamilies(token);
              debugPrint('[AddPatient] Family sync triggered after registration');
            } catch (e) {
              debugPrint('[AddPatient] Family sync error: $e');
              // Continue anyway - families are saved locally
            }
          }

          // 📋 Reload family list to show newly registered families
          await ref.read(familyListProvider.notifier).loadFamilies(token);

          final snapshot = ref
              .read(addPatientFormProvider.notifier)
              .consumeLastRegisteredFamily();
          if (snapshot != null) {
            ref.read(lastRegisteredFamilyProvider.notifier).state = snapshot;
          }

          if (!context.mounted) return;
          _showStatusSnackBar(
            context,
            message: context.l10n.tr('patient.familyRegisteredSuccess'),
            type: _StatusType.success,
          );
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const MainNavigation(initialIndex: 2),
            ),
            (route) => false,
          );
        } else {
          final latestState = ref.read(addPatientFormProvider);
          _showStatusSnackBar(
            context,
            message: latestState.errorMessage.isNotEmpty
                ? latestState.errorMessage
                : context.l10n.tr('patient.saveFailedTryAgain'),
            type: _StatusType.error,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        _showStatusSnackBar(
          context,
          message: context.l10n.tr('common.errorWithMessage', args: {'error': e.toString()}),
          type: _StatusType.error,
        );
      }
    }
  }

  void _showStatusSnackBar(
    BuildContext context, {
    required String message,
    required _StatusType type,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    late final Color background;
    late final Color foreground;

    switch (type) {
      case _StatusType.success:
        background = isDark ? const Color(0xFF166534) : const Color(0xFFD1FAE5);
        foreground = isDark ? Colors.white : const Color(0xFF065F46);
        break;
      case _StatusType.error:
        background = theme.colorScheme.errorContainer;
        foreground = theme.colorScheme.onErrorContainer;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: foreground),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        showCloseIcon: true,
        closeIconColor: foreground,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

enum _StatusType {
  success,
  error,
}
