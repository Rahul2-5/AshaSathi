import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:frontend/patient/add_patient_models.dart';
import 'package:frontend/providers/add_patient_provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../utils/glass_widgets.dart';

class Step2PatientDetails extends ConsumerWidget {
  const Step2PatientDetails({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addPatientFormProvider);
    final currentPatient = ref.watch(currentPatientProvider);
    final familyInfo = state.familyInfo;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          context.l10n.tr('patient.details'),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // Patient tabs
        _buildPatientTabs(context, ref, state),
        const SizedBox(height: 16),

        // Patient form card
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Patient photo
              _buildPhotoPicker(context, ref, currentPatient),
              const SizedBox(height: 16),

              // Patient name
              _buildTextInput(
                context,
                label: context.l10n.tr('patient.patientNameRequired'),
                value: currentPatient.patientName,
                onChanged: (value) {
                  ref.read(addPatientFormProvider.notifier).updatePatient(
                    patientName: value,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Age and Gender row
              Row(
                children: [
                  Expanded(
                    child: _buildTextInput(
                      context,
                      label: context.l10n.tr('patient.age'),
                      value: currentPatient.age,
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      onChanged: (value) {
                        ref.read(addPatientFormProvider.notifier).updatePatient(
                          age: value,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGenderDropdown(context, ref, currentPatient),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date of birth
              _buildDateInput(
                context,
                label: context.l10n.tr('patient.dateOfBirth'),
                value: currentPatient.dateOfBirth,
                onChanged: (value) {
                  ref.read(addPatientFormProvider.notifier).updatePatient(
                    dateOfBirth: value,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Pregnancy section (Female only)
              if (currentPatient.gender == 'Female')
                Column(
                  children: [
                    _buildPregnancySection(context, ref, currentPatient),
                    const SizedBox(height: 16),
                  ],
                ),

              // Caste
              _buildTextInput(
                context,
                label: context.l10n.tr('patient.caste'),
                value: currentPatient.caste,
                onChanged: (value) {
                  ref.read(addPatientFormProvider.notifier).updatePatient(
                    caste: value,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Address section
              _buildAddressSection(context, ref, currentPatient, familyInfo),
              const SizedBox(height: 16),

              // Phone number
              _buildTextInput(
                context,
                label: context.l10n.tr('auth.phoneNumber'),
                value: currentPatient.phoneNumber,
                keyboardType: TextInputType.number,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (value) {
                  ref.read(addPatientFormProvider.notifier).updatePatient(
                    phoneNumber: value,
                  );
                },
              ),

              // Delete button (visible if more than 1 patient)
              if (state.patients.length > 1)
                Column(
                  children: [
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(context.l10n.tr('patient.removeMemberTitle')),
                              content: Text(
                                currentPatient.patientName.isEmpty
                                    ? context.l10n.tr('patient.removeMemberPromptDefault')
                                    : context.l10n.tr(
                                        'patient.removeMemberPromptNamed',
                                        args: {'name': currentPatient.patientName},
                                      ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(context.l10n.tr('common.cancel')),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    ref
                                        .read(
                                            addPatientFormProvider.notifier)
                                        .removePatient(state.currentPatientIndex);
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: Text(context.l10n.tr('patient.remove')),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: Text(context.l10n.tr('patient.removeThisMember')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.red.shade400,
                          side: BorderSide(color: Colors.red.shade700),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientTabs(BuildContext context, WidgetRef ref, AddPatientFormState state) {
    final maxMembers = int.tryParse(state.familyInfo.numberOfMembers) ?? 1;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...List.generate(
            state.patients.length,
            (index) {
              final isActive = state.currentPatientIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(addPatientFormProvider.notifier).selectPatient(index);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive
                        ? const Color(0xFF14A7A0).withValues(alpha: 0.15)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05)),
                    foregroundColor: isActive
                        ? const Color(0xFF14A7A0)
                        : theme.colorScheme.onSurface,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    side: BorderSide(
                      color: isActive
                          ? const Color(0xFF14A7A0).withValues(alpha: 0.8)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    context.l10n.tr(
                      'patient.memberWithIndex',
                      args: {'index': (index + 1).toString()},
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            '${state.patients.length}/$maxMembers',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker(
    BuildContext context,
    WidgetRef ref,
    PatientDataModel patient,
  ) {
    final theme = Theme.of(context);
    final photoPath = patient.photoPath;
    final hasPhoto =
        photoPath != null && photoPath.isNotEmpty && File(photoPath).existsSync();

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showImageSourceSheet(context, ref),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: theme.colorScheme.surfaceContainer,
                  backgroundImage: hasPhoto ? FileImage(File(photoPath)) : null,
                  child: !hasPhoto
                      ? Icon(
                          Icons.person,
                          size: 42,
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        )
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF14b8a6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showImageSourceSheet(context, ref),
            child: Text(
              hasPhoto
                  ? context.l10n.tr('patient.changePhoto')
                  : context.l10n.tr('patient.addPhoto'),
              style: const TextStyle(
                color: Color(0xFF14b8a6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (hasPhoto)
            TextButton(
              onPressed: () {
                ref.read(addPatientFormProvider.notifier).updatePatient(
                  photoPath: '',
                );
              },
              child: Text(
                context.l10n.tr('patient.removePhoto'),
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showImageSourceSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(context.l10n.tr('patient.takePhoto')),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _pickAndSaveImage(ref, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(context.l10n.tr('patient.chooseFromGallery')),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _pickAndSaveImage(ref, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndSaveImage(WidgetRef ref, ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 70);
    if (image == null) {
      return;
    }

    try {
      final savedPath = await _persistPickedImage(image);
      ref.read(addPatientFormProvider.notifier).updatePatient(photoPath: savedPath);
    } catch (_) {
      ref.read(addPatientFormProvider.notifier).updatePatient(photoPath: image.path);
    }
  }

  Future<String> _persistPickedImage(XFile image) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docsDir.path, 'patient_photos'));
    if (!photosDir.existsSync()) {
      photosDir.createSync(recursive: true);
    }

    final ext = p.extension(image.path).isNotEmpty ? p.extension(image.path) : '.jpg';
    final fileName = 'patient_${DateTime.now().microsecondsSinceEpoch}$ext';
    final savedPath = p.join(photosDir.path, fileName);
    final copied = await File(image.path).copy(savedPath);
    return copied.path;
  }

  Widget _buildTextInput(
    BuildContext context, {
    required String label,
    required String value,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        _SyncedTextField(
          value: value,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildDateInput(
    BuildContext context, {
    required String label,
    required String value,
    required Function(String) onChanged,
    bool allowFutureDates = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final parsed = value.isNotEmpty ? DateTime.tryParse(value) : null;
            final initialDate = parsed ?? now;
            final firstDate = allowFutureDates ? DateTime(1900) : DateTime(1900);
            final lastDate = allowFutureDates
                ? DateTime(now.year + 5, 12, 31)
                : now;

            final date = await showDatePicker(
              context: context,
              initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
              firstDate: firstDate,
              lastDate: lastDate,
            );
            if (date != null) {
              onChanged(
                DateFormat('yyyy-MM-dd').format(date),
              );
            }
          },
          child: TextField(
            controller: TextEditingController(text: value),
            enabled: false,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              suffixIcon: Icon(
                Icons.calendar_today,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown(
    BuildContext context,
    WidgetRef ref,
    PatientDataModel patient,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.tr('patient.gender'),
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            border: Border.all(color: theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<String>(
            value: patient.gender,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: isDark
                ? const Color(0xFF1f2937)
                : theme.colorScheme.surfaceContainerHighest,
            items: const ['Female', 'Male', 'Other']
                .map(
                  (gender) => DropdownMenuItem(
                    value: gender,
                    child: Text(
                      gender == 'Female'
                          ? context.l10n.tr('patient.female')
                          : gender == 'Male'
                              ? context.l10n.tr('patient.male')
                              : context.l10n.tr('patient.other'),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                ref.read(addPatientFormProvider.notifier).updatePatient(
                  gender: value,
                );
              }
            },
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ),
      ],
    );
  }

  Widget _buildPregnancySection(
    BuildContext context,
    WidgetRef ref,
    PatientDataModel patient,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
        border: Border.all(color: const Color(0xFFec4899).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              final nextIsPregnant = !patient.isPregnant;
              ref.read(addPatientFormProvider.notifier).updatePatient(
                isPregnant: nextIsPregnant,
                expectedDeliveryDate: nextIsPregnant
                    ? _calculateExpectedDeliveryDate(patient.monthsOfPregnancy)
                    : null,
              );
            },
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFec4899),
                    ),
                    borderRadius: BorderRadius.circular(3),
                    color: patient.isPregnant
                        ? const Color(0xFFec4899)
                        : Colors.transparent,
                  ),
                  child: patient.isPregnant
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.tr('patient.isPregnant'),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (patient.isPregnant)
            Column(
              children: [
                const SizedBox(height: 12),
                _buildPregnancyMonthCounter(context, ref, patient),
                const SizedBox(height: 12),
                _buildDateInput(
                  context,
                  label: context.l10n.tr('patient.expectedDeliveryDate'),
                  value: patient.expectedDeliveryDate,
                  allowFutureDates: true,
                  onChanged: (value) {
                    ref.read(addPatientFormProvider.notifier).updatePatient(
                      expectedDeliveryDate: value,
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPregnancyMonthCounter(
    BuildContext context,
    WidgetRef ref,
    PatientDataModel patient,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentMonths = int.tryParse(patient.monthsOfPregnancy) ?? 1;
    final safeMonths = currentMonths.clamp(1, 9);

    void updateMonths(int months) {
      final next = months.clamp(1, 9);
      final monthText = next.toString();
      ref.read(addPatientFormProvider.notifier).updatePatient(
        monthsOfPregnancy: monthText,
        expectedDeliveryDate: _calculateExpectedDeliveryDate(monthText),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.tr('patient.monthsOfPregnancy'),
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: safeMonths > 1 ? () => updateMonths(safeMonths - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: const Color(0xFF14b8a6),
              ),
              Expanded(
                child: Text(
                  context.l10n.tr(
                    'patient.monthsCount',
                    args: {'count': safeMonths.toString()},
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: safeMonths < 9 ? () => updateMonths(safeMonths + 1) : null,
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFF14b8a6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _calculateExpectedDeliveryDate(String monthsOfPregnancy) {
    final months = int.tryParse(monthsOfPregnancy) ?? 1;
    final clampedMonths = months.clamp(1, 9);
    final remainingDays = ((9 - clampedMonths) * 30.4).round();
    final expectedDate = DateTime.now().add(Duration(days: remainingDays));
    return DateFormat('yyyy-MM-dd').format(expectedDate);
  }

  Widget _buildAddressSection(
    BuildContext context,
    WidgetRef ref,
    PatientDataModel patient,
    FamilyInfo familyInfo,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            ref.read(addPatientFormProvider.notifier).updatePatient(
              sameAsFamilyAddress: !patient.sameAsFamilyAddress,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(10),
              color: patient.sameAsFamilyAddress
                  ? const Color(0xFF14b8a6).withValues(alpha: 0.1)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: patient.sameAsFamilyAddress
                          ? const Color(0xFF14b8a6)
                        : theme.colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(3),
                    color: patient.sameAsFamilyAddress
                        ? const Color(0xFF14b8a6)
                        : Colors.transparent,
                  ),
                  child: patient.sameAsFamilyAddress
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.tr('patient.sameAsFamilyAddress'),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!patient.sameAsFamilyAddress)
          Column(
            children: [
              const SizedBox(height: 12),
              _buildTextInput(
                context,
                label: context.l10n.tr('patient.patientAddress'),
                value: patient.address,
                maxLines: 3,
                onChanged: (value) {
                  ref.read(addPatientFormProvider.notifier).updatePatient(
                    address: value,
                  );
                },
              ),
            ],
          ),
      ],
    );
  }
}

class _SyncedTextField extends StatefulWidget {
  const _SyncedTextField({
    required this.value,
    required this.onChanged,
    required this.decoration,
    required this.keyboardType,
    required this.maxLines,
    this.inputFormatters,
    this.maxLength,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final InputDecoration decoration;
  final TextInputType keyboardType;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

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
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      minLines: widget.maxLines == 1 ? 1 : null,
      onChanged: widget.onChanged,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: widget.decoration,
    );
  }
}
