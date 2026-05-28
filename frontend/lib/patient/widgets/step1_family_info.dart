import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:frontend/providers/add_patient_provider.dart';
import '../../widgets/common/common_widgets.dart';

class Step1FamilyInfo extends ConsumerWidget {
  const Step1FamilyInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addPatientFormProvider);
    final familyInfo = state.familyInfo;
    final errors = state.validationErrors;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            context.l10n.tr('patient.familyInformation'),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // Card container
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Head of Family
                _buildFormField(
                  label: context.l10n.tr('patient.headOfFamilyRequired'),
                  hintText: context.l10n.tr('patient.enterHeadOfFamily'),
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
                  label: context.l10n.tr('patient.familyAddressRequired'),
                  hintText: context.l10n.tr('patient.enterFamilyAddress'),
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
                  label: context.l10n.tr('patient.useAddressForAllFamilyMembers'),
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
            context,
            context.l10n.tr('patient.familyInfoHelpText'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hintText,
    required String value,
    required Function(String) onChanged,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _SyncedTextField(
          value: value,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
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
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
          color: value
              ? const Color(0xFF14b8a6).withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(
                  color: value
                      ? const Color(0xFF14b8a6)
                      : theme.colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(4),
                color: value ? const Color(0xFF14b8a6) : Colors.transparent,
              ),
              child: value
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
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
    final theme = Theme.of(context);

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
        Text(
          context.l10n.tr('patient.numberOfMembers'),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: errorText != null
                  ? theme.colorScheme.error
                  : theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? theme.colorScheme.outlineVariant,
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
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
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
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildHelpText(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        border: Border.all(color: theme.colorScheme.primary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontSize: 13,
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
    required this.keyboardType,
    required this.maxLines,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final InputDecoration decoration;
  final TextInputType keyboardType;
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
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      minLines: widget.maxLines == 1 ? 1 : null,
      onChanged: widget.onChanged,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: widget.decoration,
    );
  }
}
