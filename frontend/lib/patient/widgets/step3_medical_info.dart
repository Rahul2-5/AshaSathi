import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:frontend/patient/add_patient_models.dart';
import 'package:frontend/providers/add_patient_provider.dart';

class Step3MedicalInfo extends ConsumerWidget {
  const Step3MedicalInfo({super.key});

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final warningContainer =
        isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.35) : const Color(0xFFFFEDD5);
    final warningBorder = isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C);
    final warningText = isDark ? const Color(0xFFFED7AA) : const Color(0xFF9A3412);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          context.l10n.tr('patient.medicalInformation'),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
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
            color: isDark
                ? const Color(0xFF1f2937)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
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
                    color: warningContainer,
                    border: Border.all(color: warningBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: warningText,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.tr('patient.privacyDeclinedBanner'),
                          style: TextStyle(
                            color: warningText,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Disease selection title
              Text(
                context.l10n.tr('patient.selectHealthConditions'),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
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
                    itemCount: diseaseKeys.length,
                    itemBuilder: (context, index) {
                      final diseaseKey = diseaseKeys[index];
                      final diseaseName = context.l10n.tr('patient.condition.$diseaseKey');
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
                                : (isDark
                                    ? const Color(0xFF0f1419)
                                    : theme.colorScheme.surface),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF14b8a6)
                                  : theme.colorScheme.outlineVariant,
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
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.75),
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
              Text(
                context.l10n.tr('patient.additionalNotes'),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _SyncedTextField(
                value: currentPatient.notes,
                maxLines: 4,
                onChanged: (value) {
                  ref
                      .read(addPatientFormProvider.notifier)
                      .updateNotes(value);
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0f1419)
                      : theme.colorScheme.surface,
                  hintText: context.l10n.tr('patient.additionalNotesHint'),
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
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
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                  border: Border.all(color: theme.colorScheme.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.tr('patient.summary'),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.tr(
                        'patient.totalPatients',
                        args: {'count': state.patients.length.toString()},
                      ),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      context.l10n.tr(
                        'patient.conditionsSelected',
                        args: {
                          'count': currentPatient.diseases.values
                              .where((v) => v)
                              .length
                              .toString(),
                        },
                      ),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: 13,
                      ),
                    ),
                    if (currentPatient.declinedHealthInfo)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          context.l10n.tr('patient.privacyDeclinedSummary'),
                          style: TextStyle(
                            color: warningText,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                      : (isDark
                          ? const Color(0xFF1f2937)
                          : theme.colorScheme.surfaceContainerHighest),
                  foregroundColor: isActive
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  side: BorderSide(
                    color: isActive
                        ? const Color(0xFF14b8a6)
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Text(patient.patientName.isEmpty
                    ? context.l10n.tr(
                        'patient.memberWithIndex',
                        args: {'index': (index + 1).toString()},
                      )
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final warningContainer =
        isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.2) : const Color(0xFFFFEDD5);
    final warningBorder = isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C);
    final warningText = isDark ? const Color(0xFFFED7AA) : const Color(0xFF9A3412);

    return GestureDetector(
      onTap: () {
        ref.read(addPatientFormProvider.notifier).togglePrivacy();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: patient.declinedHealthInfo
                ? warningBorder
                : theme.colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(10),
          color: patient.declinedHealthInfo
              ? warningContainer
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
                      ? warningBorder
                      : theme.colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(4),
                color: patient.declinedHealthInfo
                    ? warningBorder
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
            Expanded(
              child: Text(
                context.l10n.tr('patient.privacyDeclined'),
                style: TextStyle(
                  color: patient.declinedHealthInfo
                      ? warningText
                      : theme.colorScheme.onSurface,
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

class _SyncedTextField extends StatefulWidget {
  const _SyncedTextField({
    required this.value,
    required this.onChanged,
    required this.decoration,
    required this.maxLines,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final InputDecoration decoration;
  final int maxLines;

  @override
  State<_SyncedTextField> createState() => _SyncedTextFieldState();
}

class _SyncedTextFieldState extends State<_SyncedTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _SyncedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: widget.decoration,
    );
  }
}
