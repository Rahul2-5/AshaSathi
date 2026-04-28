import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/config/app_config.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:frontend/utils/glass_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../providers/login_provider.dart';
import '../providers/patient_provider.dart';
import '../offline/patient_offline_dao.dart';
import '../offline/patient_sync_service.dart';
import '../offline/connectivity_service.dart';

import 'patient_model.dart';

class PatientDetailPage extends ConsumerStatefulWidget {
  final Patient patient;

  const PatientDetailPage({
    super.key,
    required this.patient,
  });

  @override
  ConsumerState<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends ConsumerState<PatientDetailPage> {
  late Patient _patient;

  static String get baseUrl => AppConfig.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF0B1120), Color(0xFF0E1A26)]
                    : const [Color(0xFFE4F7F4), Color(0xFFEEF4FF), Color(0xFFF7FBFF)],
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildGlassAppBar(isDark),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _profileSection(context),
                  const SizedBox(height: 32),
                  _infoCard(context),
                  const SizedBox(height: 32),
                  _deleteButton(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar(bool isDark) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: AppBar(
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.65),
            elevation: 0,
            centerTitle: true,
            title: Text(
              context.l10n.tr('patient.details'),
              style: GoogleFonts.outfit(
                color: isDark ? const Color(0xFFE6EDF3) : Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.3,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    Colors.white.withValues(alpha: 0.10),
                                    Colors.white.withValues(alpha: 0.06),
                                  ]
                                : [
                                    Colors.white.withValues(alpha: 0.80),
                                    Colors.white.withValues(alpha: 0.60),
                                  ],
                          ),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.90),
                          ),
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 20,
                          color: isDark ? kAccentCyan : kTeal,
                        ),
                      ),
                    ),
                  ),
                  tooltip: 'Edit Patient',
                  onPressed: _showEditPatientDialog,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= PROFILE =================

  Widget _profileSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow ring
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kTeal.withValues(alpha: isDark ? 0.22 : 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Glass ring
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.10),
                              Colors.white.withValues(alpha: 0.05),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.75),
                              Colors.white.withValues(alpha: 0.50),
                            ],
                    ),
                    border: Border.all(
                      color: isDark
                          ? kTeal.withValues(alpha: 0.35)
                          : kTeal.withValues(alpha: 0.30),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kTeal.withValues(alpha: 0.22),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Avatar
            CircleAvatar(
              radius: 55,
              backgroundColor: isDark ? const Color(0xFF2A3642) : Colors.grey.shade200,
              child: ClipOval(
                child: SizedBox(
                  width: 110,
                  height: 110,
                  child: _buildPatientImage(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _patient.name,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF111418),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? const Color(0xFF1A4D3E) : const Color(0xFFD1F2EF),
          ),
          child: Text(
            _localizedGender(context, _patient.gender),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF4EEFD4) : const Color(0xFF047857),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientImage() {
    final path = _patient.photoPath?.trim();
    final token = ref.read(loginProvider).token;
    final headers = (token != null && token.isNotEmpty)
        ? <String, String>{'Authorization': 'Bearer $token'}
        : null;

    if (path == null || path.isEmpty) {
      return const Icon(Icons.person, size: 50, color: Colors.grey);
    }

    final normalizedPath = path.replaceAll('\\', '/');
    final isWindowsAbsolutePath = RegExp(r'^[A-Za-z]:[/\\]').hasMatch(path);

    if ((path.startsWith('/') || isWindowsAbsolutePath) && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover);
    }

    if (normalizedPath.startsWith('uploads/') ||
        normalizedPath.contains('/uploads/') ||
        normalizedPath.contains('uploads/')) {
      final uploadIndex = normalizedPath.indexOf('uploads/');
      final uploadPath =
          uploadIndex >= 0 ? '/${normalizedPath.substring(uploadIndex)}' : normalizedPath;

      return Image.network(
        "$baseUrl$uploadPath",
        fit: BoxFit.cover,
        headers: headers,
        errorBuilder: (_, error, stackTrace) => const Icon(Icons.broken_image),
      );
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        headers: headers,
        errorBuilder: (_, error, stackTrace) => const Icon(Icons.broken_image),
      );
    }

    return const Icon(Icons.broken_image);
  }

  // ================= INFO =================

  Widget _infoCard(BuildContext context) {
    final activeDiseases = _activeDiseaseLabels(_patient.diseases);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // DEMOGRAPHICS SECTION
        _sectionCard(
          context,
          title: '👤 Demographics',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _infoField(
                      context,
                      label: context.l10n.tr('patient.age'),
                      value: context.l10n.tr('patient.ageYears', args: {'age': _patient.age.toString()}),
                      icon: Icons.cake_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoField(
                      context,
                      label: context.l10n.tr('patient.dateOfBirth'),
                      value: _patient.dateOfBirth,
                      icon: Icons.calendar_today_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _infoField(
                      context,
                      label: 'Caste',
                      value: _patient.caste.trim().isEmpty ? '-' : _patient.caste,
                      icon: Icons.people_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoField(
                      context,
                      label: context.l10n.tr('patient.gender'),
                      value: _localizedGender(context, _patient.gender),
                      icon: Icons.wc_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // CONTACT SECTION
        _sectionCard(
          context,
          title: '📞 Contact Information',
          child: Column(
            children: [
              _infoField(
                context,
                label: context.l10n.tr('patient.phone'),
                value: _patient.phoneNumber,
                icon: Icons.phone_outlined,
              ),
              const SizedBox(height: 12),
              _infoField(
                context,
                label: context.l10n.tr('patient.address'),
                value: _patient.address,
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // HEALTH SECTION
        _sectionCard(
          context,
          title: '⚕️ Health Information',
          child: Column(
            children: [
              if (_patient.gender == 'Female')
                Row(
                  children: [
                    Expanded(
                      child: _statusBadgeField(
                        context,
                        label: 'Pregnancy',
                        value: _patient.isPregnant
                            ? 'Yes${_patient.monthsOfPregnancy != null ? ' (${_patient.monthsOfPregnancy} months)' : ''}'
                            : 'No',
                        isActive: _patient.isPregnant,
                        icon: Icons.favorite_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statusBadgeField(
                        context,
                        label: 'Health Info',
                        value: _patient.declinedHealthInfo ? 'Declined' : 'Shared',
                        isActive: !_patient.declinedHealthInfo,
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
              if (!(_patient.gender == 'Female'))
                Row(
                  children: [
                    Expanded(
                      child: _statusBadgeField(
                        context,
                        label: 'Health Info',
                        value: _patient.declinedHealthInfo ? 'Declined' : 'Shared',
                        isActive: !_patient.declinedHealthInfo,
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
              if (_patient.expectedDeliveryDate.trim().isNotEmpty && _patient.gender == 'Female') ...[
                const SizedBox(height: 12),
                _infoField(
                  context,
                  label: 'Expected Delivery',
                  value: _patient.expectedDeliveryDate,
                  icon: Icons.event_outlined,
                ),
              ],
              const SizedBox(height: 12),
              _medicalConditionsDisplay(
                context,
                conditions: activeDiseases,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // NOTES SECTION
        if (_patient.description.trim().isNotEmpty)
          _sectionCard(
            context,
            title: '📝 Notes',
            child: _infoField(
              context,
              label: 'Description / Notes',
              value: _patient.description,
              icon: Icons.description_outlined,
              maxLines: 4,
              showLabel: false,
            ),
          ),
      ],
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(16),
      blur: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.label_outline_rounded,
                size: 14,
                color: isDark ? kAccentCyan : kTeal,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? kAccentCyan : kTeal,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoField(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    int maxLines = 1,
    bool showLabel = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(icon, size: 16, color: isDark ? const Color(0xFF7FB3D5) : const Color(0xFF0BAEB4)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFA6B3BF) : const Color(0xFF6B7280),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isDark ? const Color(0xFF0D1419) : const Color(0xFFF9FAFB),
            border: Border.all(
              color: isDark ? const Color(0xFF2A3642) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Text(
            value,
            maxLines: maxLines,
            overflow: maxLines == 1 ? TextOverflow.ellipsis : TextOverflow.fade,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFD5E1EB) : const Color(0xFF111418),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadgeField(
    BuildContext context, {
    required String label,
    required String value,
    required bool isActive,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(icon, size: 16, color: isDark ? const Color(0xFF7FB3D5) : const Color(0xFF0BAEB4)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFA6B3BF) : const Color(0xFF6B7280),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isActive
                ? (isDark ? const Color(0xFF1A4D3E) : const Color(0xFFD1F2EF))
                : (isDark ? const Color(0xFF4D1A1A) : const Color(0xFFFEE2E2)),
            border: Border.all(
              color: isActive
                  ? (isDark ? const Color(0xFF0BAEB4) : const Color(0xFF0BAEB4))
                  : (isDark ? const Color(0xFFDC2626) : const Color(0xFFFCA5A5)),
              width: 1,
            ),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? (isDark ? const Color(0xFF4EEFD4) : const Color(0xFF047857))
                  : (isDark ? const Color(0xFFFEA6A6) : const Color(0xFFDC2626)),
            ),
          ),
        ),
      ],
    );
  }

  List<String> _activeDiseaseLabels(Map<String, bool> diseases) {
    return diseases.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  Widget _medicalConditionsDisplay(
    BuildContext context, {
    required List<String> conditions,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Color palette for different conditions
    final conditionColors = {
      'Diabetes': {'bg': 0xFFDCF2FF, 'border': 0xFF4B9EFF, 'text': 0xFF0D47A1},
      'Hypertension': {'bg': 0xFFFFDCDC, 'border': 0xFFFF6B6B, 'text': 0xFFAD0000},
      'HeartDisease': {'bg': 0xFFFFDCDC, 'border': 0xFFF44336, 'text': 0xFFAD0000},
      'Asthma': {'bg': 0xFFE0F2D8, 'border': 0xFF52C41A, 'text': 0xFF254000},
      'Arthritis': {'bg': 0xFFFFEED2, 'border': 0xFFFFB84D, 'text': 0xFF663C00},
      'Kidney': {'bg': 0xFFFFDDC7, 'border': 0xFFFF7A45, 'text': 0xFFA23800},
      'Liver': {'bg': 0xFFE8D8FF, 'border': 0xFFB37FEB, 'text': 0xFF540099},
      'Anemia': {'bg': 0xFFFDDCFF, 'border': 0xFFEB2F96, 'text': 0xFF88003F},
      'Thyroid': {'bg': 0xFFDDEDFF, 'border': 0xFF1890FF, 'text': 0xFF001A5C},
      'Cancer': {'bg': 0xFFFFD4D0, 'border': 0xFFF5222D, 'text': 0xFF5C0A0A},
      'TB': {'bg': 0xFFDEE8D8, 'border': 0xFF95DE64, 'text': 0xFF274000},
      'Elephantiasis': {'bg': 0xFFD8E4E8, 'border': 0xFF13C2C2, 'text': 0xFF003C3C},
    };

    // Dark mode adjustments
    final darkConditionColors = {
      'Diabetes': {'bg': 0xFF1A3A4D, 'border': 0xFF177DFF, 'text': 0xFF91D5FF},
      'Hypertension': {'bg': 0xFF4D1A1A, 'border': 0xFFFF7875, 'text': 0xFFFFB1B1},
      'HeartDisease': {'bg': 0xFF4D1A1A, 'border': 0xFFFF7875, 'text': 0xFFFFB1B1},
      'Asthma': {'bg': 0xFF1A3A2A, 'border': 0xFF95DE64, 'text': 0xFFC6E48B},
      'Arthritis': {'bg': 0xFF4D3A1A, 'border': 0xFFFFD591, 'text': 0xFFFFDD91},
      'Kidney': {'bg': 0xFF4D2A1A, 'border': 0xFFFFB373, 'text': 0xFFFFD591},
      'Liver': {'bg': 0xFF3A1A4D, 'border': 0xFFD3ADF7, 'text': 0xFFF9F0FF},
      'Anemia': {'bg': 0xFF4D1A3A, 'border': 0xFFF759AB, 'text': 0xFFFFAED6},
      'Thyroid': {'bg': 0xFF1A2A4D, 'border': 0xFF85A5FF, 'text': 0xFFB3D9FF},
      'Cancer': {'bg': 0xFF4D1A1A, 'border': 0xFFFF4D4F, 'text': 0xFFFFA8A8},
      'TB': {'bg': 0xFF1A3A1A, 'border': 0xFFB7EB8F, 'text': 0xFFDFEFD8},
      'Elephantiasis': {'bg': 0xFF1A3A3A, 'border': 0xFF36CFC7, 'text': 0xFFB5EAE0},
    };

    final colors = isDark ? darkConditionColors : conditionColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(
                Icons.local_hospital_outlined,
                size: 16,
                color: isDark ? const Color(0xFF7FB3D5) : const Color(0xFF0BAEB4),
              ),
              const SizedBox(width: 8),
              Text(
                'Medical Conditions',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFA6B3BF) : const Color(0xFF6B7280),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        if (conditions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isDark ? const Color(0xFF0D1419) : const Color(0xFFF9FAFB),
              border: Border.all(
                color: isDark ? const Color(0xFF2A3642) : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: isDark ? const Color(0xFF4EEFD4) : const Color(0xFF22C55E),
                ),
                const SizedBox(width: 10),
                Text(
                  'No medical conditions recorded',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF9FB0BE) : const Color(0xFF6B7280),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: conditions.map((condition) {
              final colorSet = colors[condition] ?? colors.values.first;
              final bgColor = Color(colorSet['bg'] ?? 0xFFDCF2FF);
              final borderColor = Color(colorSet['border'] ?? 0xFF4B9EFF);
              final textColor = Color(colorSet['text'] ?? 0xFF0D47A1);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: bgColor,
                  border: Border.all(
                    color: borderColor,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  condition,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: 0.3,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  String _localizedGender(BuildContext context, String raw) {
    final g = raw.trim().toLowerCase();
    if (g == 'male' || g == 'm') return context.l10n.tr('patient.male');
    if (g == 'female' || g == 'f') return context.l10n.tr('patient.female');
    return context.l10n.tr('patient.other');
  }

  String _formatMedicalConditions(List<String> conditionIds) {
    if (conditionIds.isEmpty) return 'None';
    
    final conditionLabels = {
      'bp': 'BP',
      'elephantiasis': 'Elephantiasis',
      'diabetes': 'Diabetes',
      'heart_disease': 'Heart Disease',
      'asthma': 'Asthma',
      'thyroid': 'Thyroid',
      'arthritis': 'Arthritis',
      'kidney_disease': 'Kidney Disease',
      'liver_disease': 'Liver Disease',
      'cancer': 'Cancer',
    };
    
    return conditionIds
        .map((id) => conditionLabels[id] ?? id)
        .join(', ');
  }

  Future<void> _showEditPatientDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: _patient.name);
    final ageController = TextEditingController(text: _patient.age.toString());
    final dobController = TextEditingController(text: _patient.dateOfBirth);
    final addressController = TextEditingController(text: _patient.address);
    final phoneController = TextEditingController(text: _patient.phoneNumber);
    final notesController = TextEditingController(text: _patient.description);
    var selectedGender = _patient.gender;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1B232C) : Colors.white;
    final fieldBg = isDark ? const Color(0xFF24303B) : const Color(0xFFF5F7FA);
    final labelColor = isDark ? const Color(0xFF9FB0BE) : const Color(0xFF637282);
    final textColor = isDark ? const Color(0xFFE4EDF5) : const Color(0xFF1B2026);
    const fieldGap = 12.0;

    InputDecoration sheetFieldDecoration(String label, {Widget? suffixIcon}) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor),
        floatingLabelStyle: TextStyle(color: labelColor),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );
    }

    Widget sectionLabel(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            color: isDark ? const Color(0xFF8FA3B3) : const Color(0xFF5F7283),
            fontSize: 12,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final updated = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> pickDob() async {
              final now = DateTime.now();
              final currentDob = DateTime.tryParse(dobController.text.trim()) ??
                  DateTime(now.year - 20, now.month, now.day);
              final picked = await showDatePicker(
                context: ctx,
                initialDate: currentDob.isAfter(now) ? now : currentDob,
                firstDate: DateTime(1900),
                lastDate: now,
              );
              if (picked == null) return;
              dobController.text =
                  "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 14,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF3A4754)
                                  : const Color(0xFFD2D9E0),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Edit Patient Details',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Update patient profile and notes',
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        sectionLabel('BASIC INFO'),
                        TextFormField(
                          controller: nameController,
                          style: TextStyle(color: textColor),
                          decoration: sheetFieldDecoration('Patient Name'),
                          validator: (v) =>
                              (v == null || v.trim().length < 2) ? 'Enter valid name' : null,
                        ),
                        const SizedBox(height: fieldGap),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: ageController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: textColor),
                                decoration: sheetFieldDecoration('Age'),
                                validator: (v) {
                                  final age = int.tryParse((v ?? '').trim());
                                  if (age == null || age < 1 || age > 130) {
                                    return 'Invalid age';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedGender,
                                dropdownColor: sheetBg,
                                style: TextStyle(color: textColor),
                                decoration: sheetFieldDecoration('Gender'),
                                items: const [
                                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setDialogState(() {
                                    selectedGender = v;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: fieldGap),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: dobController,
                                readOnly: true,
                                onTap: pickDob,
                                style: TextStyle(color: textColor),
                                decoration: sheetFieldDecoration(
                                  'Date of Birth',
                                  suffixIcon: Icon(
                                    Icons.calendar_today_outlined,
                                    color: labelColor,
                                  ),
                                ),
                                validator: (v) {
                                  final dt = DateTime.tryParse((v ?? '').trim());
                                  if (dt == null || dt.isAfter(DateTime.now())) {
                                    return 'Invalid DOB';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                style: TextStyle(color: textColor),
                                decoration: sheetFieldDecoration('Phone Number'),
                                validator: (v) =>
                                    RegExp(r'^\d{10}$').hasMatch((v ?? '').trim())
                                        ? null
                                        : 'Invalid phone',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        sectionLabel('ADDRESS'),
                        TextFormField(
                          controller: addressController,
                          maxLines: 2,
                          style: TextStyle(color: textColor),
                          decoration: sheetFieldDecoration('Address'),
                          validator: (v) =>
                              (v == null || v.trim().length < 5) ? 'Enter valid address' : null,
                        ),
                        const SizedBox(height: 16),
                        sectionLabel('NOTES'),
                        TextFormField(
                          controller: notesController,
                          minLines: 3,
                          maxLines: 3,
                          style: TextStyle(color: textColor),
                          decoration: sheetFieldDecoration('Description / Notes'),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  side: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF3C4B59)
                                        : const Color(0xFFD1D9E1),
                                  ),
                                ),
                                child: Text(context.l10n.tr('common.cancel')),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (!formKey.currentState!.validate()) return;
                                  Navigator.pop(ctx, {
                                    'name': nameController.text.trim(),
                                    'age': int.parse(ageController.text.trim()),
                                    'dateOfBirth': dobController.text.trim(),
                                    'gender': selectedGender,
                                    'address': addressController.text.trim(),
                                    'phoneNumber': phoneController.text.trim(),
                                    'description': notesController.text.trim(),
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  backgroundColor: const Color(0xFF0BAEB4),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (updated == null) return;
    await _saveUpdatedPatient(updated);
  }

  Future<void> _saveUpdatedPatient(Map<String, dynamic> updated) async {
    final token = ref.read(loginProvider).token;
    final connectivity = ConnectivityService();
    final dao = PatientOfflineDao();
    final patientNotifier = ref.read(patientListProvider.notifier);
    var updatedOnline = false;

    try {
      if (token != null && _patient.id != null && await connectivity.isOnline()) {
        final res = await http.put(
          Uri.parse('$baseUrl/api/patients/${_patient.id}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'patientName': updated['name'],
            'gender': updated['gender'],
            'age': updated['age'],
            'dateOfBirth': updated['dateOfBirth'],
            'address': updated['address'],
            'description': updated['description'],
            'phoneNumber': updated['phoneNumber'],
            'clientTempId': _patient.uuid,
            'photoPath': _patient.photoPath,
          }),
        );

        if (res.statusCode != 200) {
          throw Exception('Failed to update notes: ${res.statusCode}');
        }

        updatedOnline = true;
      }

      await dao.updatePatientByUuid(
        uuid: _patient.uuid,
        name: updated['name'],
        gender: updated['gender'],
        age: updated['age'],
        dateOfBirth: updated['dateOfBirth'],
        address: updated['address'],
        phoneNumber: updated['phoneNumber'],
        description: updated['description'],
        markPending: !updatedOnline,
        serverId: _patient.id,
      );
      await PatientSyncService().refreshSyncStatus();

      if (!mounted) return;
      setState(() {
        _patient = Patient(
          id: _patient.id,
          uuid: _patient.uuid,
          name: updated['name'],
          gender: updated['gender'],
          age: updated['age'],
          dateOfBirth: updated['dateOfBirth'],
          address: updated['address'],
          description: updated['description'],
          phoneNumber: updated['phoneNumber'],
          photoPath: _patient.photoPath,
        );
      });
      patientNotifier.upsertPatient(_patient);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient details updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update patient details: $e')),
      );
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _hideLoadingDialog(BuildContext context) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  // ================= DELETE =================

  Widget _deleteButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade600,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 2,
      ),
      icon: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
      label: Text(
        context.l10n.tr('patient.delete'),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      onPressed: () => _confirmDelete(context),
    );
  }

  void _confirmDelete(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1B232C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.tr('patient.delete'),
                style: TextStyle(
                  color: isDark ? const Color(0xFFE6EDF3) : Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          context.l10n.tr('patient.deleteConfirm'),
          style: TextStyle(
            color: isDark ? const Color(0xFFD5E1EB) : Colors.black87,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              context.l10n.tr('common.cancel'),
              style: TextStyle(
                color: isDark ? const Color(0xFF7FB3D5) : const Color(0xFF0BAEB4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _showLoadingDialog(context);
              final shouldClosePage = await _deletePatient(context);
              if (!context.mounted) return;
              _hideLoadingDialog(context);
              if (shouldClosePage) {
                Navigator.pop(context, true);
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade600.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              context.l10n.tr('common.delete'),
              style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _deletePatient(BuildContext context) async {
    final token = ref.read(loginProvider).token!;
    final dao = PatientOfflineDao();
    final connectivity = ConnectivityService();
    final patientNotifier = ref.read(patientListProvider.notifier);

    debugPrint("Delete patient: id=${_patient.id}, uuid=${_patient.uuid}, online=${await connectivity.isOnline()}");

    // OFFLINE OR NOT YET SYNCED
    if (!await connectivity.isOnline() || _patient.id == null) {
      await dao.markDeletedByUuid(_patient.uuid);
      await PatientSyncService().refreshSyncStatus();

      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('patient.markedDeletion'))),
      );
      return true;
    }

    // ONLINE DELETE
    try {
      final url = "$baseUrl/api/patients/${_patient.id}";
      debugPrint("Attempting DELETE: $url");
      debugPrint("Patient ID: ${_patient.id}");
      debugPrint("Token: ${token.substring(0, 10)}...");

      final res = await http.delete(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("Delete response status: ${res.statusCode}");
      debugPrint("Delete response headers: ${res.headers}");
      debugPrint("Delete response body: ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 204 || res.statusCode == 201 || res.statusCode == 404) {
        if (res.statusCode == 404) {
          debugPrint("Delete returned 404 - treating as already deleted on server.");
        } else {
          debugPrint("Delete successful! Removing from local storage...");
        }
        // Hard delete from offline storage
        await dao.hardDeleteByUuid(_patient.uuid);
        await PatientSyncService().refreshSyncStatus();
        patientNotifier.removePatientByUuid(_patient.uuid);

        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.tr('patient.deletedSuccessfully'))),
        );
        debugPrint("Returning to previous page...");
        return true;
      } else {
        debugPrint("Delete failed with status: ${res.statusCode}");
        // Delete failed, try offline
        await dao.markDeletedByUuid(_patient.uuid);
        await PatientSyncService().refreshSyncStatus();
        patientNotifier.removePatientByUuid(_patient.uuid);

        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.tr(
                'patient.deleteFailedStatus',
                args: {'status': res.statusCode.toString()},
              ),
            ),
          ),
        );
        return true;
      }
    } catch (e, stackTrace) {
      debugPrint("Delete error: $e");
      debugPrint("Stack trace: $stackTrace");
      // fallback to offline delete
      await dao.markDeletedByUuid(_patient.uuid);
      await PatientSyncService().refreshSyncStatus();
      patientNotifier.removePatientByUuid(_patient.uuid);

      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.tr('patient.errorDeleting', args: {'error': e.toString()}),
          ),
        ),
      );
      return true;
    }
  }

}
