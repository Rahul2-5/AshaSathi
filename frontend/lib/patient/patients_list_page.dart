import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/config/app_config.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:frontend/utils/glass_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/login_provider.dart';
import '../providers/patient_provider.dart';
import 'patient_detail_page.dart';
import 'patient_model.dart';

enum _GenderFilter { all, male, female, others }

enum _SortBy { newest, oldest, nameAZ }

class PatientsListPage extends ConsumerStatefulWidget {
  const PatientsListPage({super.key});

  @override
  ConsumerState<PatientsListPage> createState() => _PatientsListPageState();
}

class _PatientsListPageState extends ConsumerState<PatientsListPage> {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _GenderFilter _genderFilter = _GenderFilter.all;
  bool _age18to35 = false;
  _SortBy _sortBy = _SortBy.newest;

  bool get _isCompact => MediaQuery.sizeOf(context).width <= 380;
  double get _horizontalPad => _isCompact ? 12 : 16;
  double get _sectionGap => _isCompact ? 10 : 12;

  @override
  void initState() {
    super.initState();
    final token = ref.read(loginProvider).token;
    if (token != null) {
      ref.read(patientListProvider.notifier).loadPatients(token);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient background
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
          // Glass orbs
          Positioned(
            top: -80,
            right: -60,
            child: _buildOrb(
              240,
              isDark
                  ? kTeal.withValues(alpha: 0.10)
                  : kTeal.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _buildOrb(
              280,
              isDark
                  ? kAccentCyan.withValues(alpha: 0.06)
                  : kAccentCyan.withValues(alpha: 0.12),
            ),
          ),
          // Main scaffold
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildGlassAppBar(isDark),
            body: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      _horizontalPad,
                      _sectionGap,
                      _horizontalPad,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heroSummary(),
                        SizedBox(height: _sectionGap),
                        GlassSearchBar(
                          controller: _searchController,
                          hintText: context.l10n.tr('patients.searchHint'),
                          onChanged: (v) =>
                              setState(() => _query = v.trim().toLowerCase()),
                          height: 44,
                        ),
                        SizedBox(height: _sectionGap),
                        _buildFiltersHeader(),
                        SizedBox(height: _isCompact ? 6 : 8),
                        _buildFilters(),
                        SizedBox(height: _isCompact ? 10 : 12),
                        _recordsHeader(),
                        SizedBox(height: _isCompact ? 6 : 8),
                        Expanded(child: _buildPatientsList()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
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
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1E24),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              context.l10n.tr('patients.title'),
              style: GoogleFonts.outfit(
                color: isDark
                    ? const Color(0xFFE6EDF3)
                    : const Color(0xFF1A1E24),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: false,
          ),
        ),
      ),
    );
  }

  Widget _heroSummary() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(patientListProvider);
        final filtered = _applyFilters(state.patients);

        return GlassContainer(
          padding: EdgeInsets.fromLTRB(
            _isCompact ? 14 : 16,
            _isCompact ? 14 : 16,
            _isCompact ? 14 : 16,
            _isCompact ? 12 : 14,
          ),
          borderRadius: BorderRadius.circular(22),
          blur: 14,
          child: Row(
            children: [
              Container(
                width: _isCompact ? 46 : 52,
                height: _isCompact ? 46 : 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kTeal, kAccentCyan],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kTeal.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.people_alt_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              SizedBox(width: _isCompact ? 12 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${filtered.length} visible patients',
                      style: GoogleFonts.outfit(
                        fontSize: _isCompact ? 16 : 18,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFFE6EDF3)
                            : const Color(0xFF1A1E24),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.loading
                          ? 'Refreshing patient records...'
                          : 'Search, filter, and open records quickly.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark
                            ? const Color(0xFFA5B3BF)
                            : const Color(0xFF667384),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFiltersHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(
          context.l10n.tr('patients.quickFilters'),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFAAB8C4) : const Color(0xFF6F7B87),
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _clearFilters,
          child: Text(
            context.l10n.tr('common.clear'),
            style: TextStyle(
              color: isDark ? kAccentCyan : kTeal,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: _isCompact ? 6 : 8,
      runSpacing: _isCompact ? 6 : 8,
      children: [
        GlassChip(
          label: context.l10n.tr('patients.allGender'),
          selected: _genderFilter == _GenderFilter.all,
          onTap: () => setState(() => _genderFilter = _GenderFilter.all),
        ),
        GlassChip(
          label: context.l10n.tr('patient.male'),
          selected: _genderFilter == _GenderFilter.male,
          onTap: () => setState(() => _genderFilter = _GenderFilter.male),
        ),
        GlassChip(
          label: context.l10n.tr('patient.female'),
          selected: _genderFilter == _GenderFilter.female,
          onTap: () => setState(() => _genderFilter = _GenderFilter.female),
        ),
        GlassChip(
          label: context.l10n.tr('patients.others'),
          selected: _genderFilter == _GenderFilter.others,
          onTap: () => setState(() => _genderFilter = _GenderFilter.others),
        ),
        GlassChip(
          label: context.l10n.tr('patients.age18to35'),
          selected: _age18to35,
          onTap: () => setState(() => _age18to35 = !_age18to35),
        ),
      ],
    );
  }

  Widget _recordsHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(patientListProvider);
            final filtered = _applyFilters(state.patients);
            return Text(
              context.l10n.tr('patients.recentRecords',
                  args: {'count': filtered.length.toString()}),
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFAAB8C4)
                    : const Color(0xFF5D6975),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
        const Spacer(),
        PopupMenuButton<_SortBy>(
          color: isDark ? const Color(0xFF1A232C) : Colors.white,
          surfaceTintColor: isDark ? const Color(0xFF1A232C) : Colors.white,
          shadowColor: const Color(0x1A1A1A1A),
          elevation: 10,
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          constraints: const BoxConstraints(minWidth: 168),
          offset: const Offset(0, 8),
          onSelected: (value) => setState(() => _sortBy = value),
          itemBuilder: (_) => [
            _sortMenuItem(_SortBy.newest, context.l10n.tr('patients.newest')),
            _sortMenuItem(_SortBy.oldest, context.l10n.tr('patients.oldest')),
            _sortMenuItem(_SortBy.nameAZ, context.l10n.tr('patients.nameAZ')),
          ],
          child: Row(
            children: [
              Text(
                context.l10n.tr('patients.sortBy',
                    args: {'sort': _sortLabel()}),
                style: TextStyle(
                  color: isDark ? kAccentCyan : kTeal,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: isDark ? kAccentCyan : kTeal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<_SortBy> _sortMenuItem(_SortBy value, String label) {
    final bool selected = _sortBy == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuItem<_SortBy>(
      value: value,
      height: _isCompact ? 42 : 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? kTeal
                    : (isDark
                        ? const Color(0xFFC6D2DC)
                        : const Color(0xFF2E3742)),
              ),
            ),
          ),
          if (selected) Icon(Icons.check_rounded, size: 16, color: kTeal),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(patientListProvider);
        if (state.loading && state.patients.isEmpty) {
          return _buildPatientsSkeletonList();
        }

        final filtered = _applyFilters(state.patients);

        if (filtered.isEmpty) {
          return _emptyState();
        }

        return ListView.separated(
          itemCount: filtered.length,
          padding: EdgeInsets.only(bottom: _isCompact ? 92 : 104),
          separatorBuilder: (_, _) => SizedBox(height: _isCompact ? 9 : 10),
          itemBuilder: (context, index) => _patientRow(filtered[index]),
        );
      },
    );
  }

  Widget _buildPatientsSkeletonList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? const Color(0xFF1A232C) : const Color(0xFFE9EDF1);
    final highlightColor =
        isDark ? const Color(0xFF2A3642) : const Color(0xFFF6F8FA);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1100),
      child: ListView.separated(
        itemCount: 6,
        padding: EdgeInsets.only(bottom: _isCompact ? 92 : 104),
        separatorBuilder: (_, _) => SizedBox(height: _isCompact ? 9 : 10),
        itemBuilder: (_, index) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isCompact ? 12 : 14,
              vertical: _isCompact ? 14 : 16,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.80),
              ),
            ),
            child: Row(
              children: [
                _skeletonBox(46, 46, baseColor, circular: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _skeletonBox(130, 14, baseColor),
                      const SizedBox(height: 8),
                      _skeletonBox(100, 12, baseColor),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _skeletonBox(16, 16, baseColor, circular: true),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _skeletonBox(double width, double height, Color color,
      {bool circular = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: circular
            ? BorderRadius.circular(height / 2)
            : BorderRadius.circular(8),
      ),
    );
  }

  Widget _patientRow(Patient patient) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () async {
        final deleted = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PatientDetailPage(patient: patient)),
        );

        if (!mounted) return;

        if (deleted == true) {
          final token = ref.read(loginProvider).token;
          if (token != null) {
            ref.read(patientListProvider.notifier).loadPatients(token);
          }
        }
      },
      child: GlassContainer(
        padding: EdgeInsets.symmetric(
          horizontal: _isCompact ? 12 : 14,
          vertical: _isCompact ? 12 : 14,
        ),
        borderRadius: BorderRadius.circular(16),
        blur: 12,
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    kTeal.withValues(alpha: 0.20),
                    kAccentCyan.withValues(alpha: 0.10),
                  ],
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : kTeal.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: _patientImage(patient) != null
                    ? Image(
                        image: _patientImage(patient)!,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.person_rounded,
                        size: 22,
                        color: isDark ? kAccentCyan : kTeal,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFE6EDF3)
                          : const Color(0xFF21262C),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 12,
                    runSpacing: 2,
                    children: [
                      _metaItem(
                        Icons.cake_outlined,
                        context.l10n.tr('patients.yearsShort',
                            args: {'age': patient.age.toString()}),
                      ),
                      _metaItem(
                          Icons.person_outline, _localizedGender(patient.gender)),
                    ],
                  ),
                  if (patient.phoneNumber.trim().isNotEmpty ||
                      patient.activeDiseaseLabels.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (patient.phoneNumber.trim().isNotEmpty)
                          patient.phoneNumber.trim(),
                        if (patient.activeDiseaseLabels.isNotEmpty)
                          patient.activeDiseaseLabels.take(2).join(', '),
                      ].join(' | '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF90A1AE)
                            : const Color(0xFF73808A),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : kTeal.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: isDark ? kAccentCyan : kTeal,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaItem(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 11,
          color: isDark ? const Color(0xFF9CA9B5) : kTeal.withValues(alpha: 0.65),
        ),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? const Color(0xFFA6B3BF)
                : const Color(0xFF7D8893),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassContainer(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      borderRadius: BorderRadius.circular(20),
      blur: 14,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  kTeal.withValues(alpha: isDark ? 0.20 : 0.14),
                  kAccentCyan.withValues(alpha: isDark ? 0.10 : 0.07),
                ],
              ),
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 44,
              color: isDark ? kAccentCyan : kTeal,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.tr('patients.showingAll'),
            style: GoogleFonts.outfit(
              fontSize: 18,
              color: isDark
                  ? const Color(0xFFD5E1EB)
                  : const Color(0xFF4A5561),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.tr('patients.filtersHint'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? const Color(0xFFA6B3BF)
                  : const Color(0xFF8B96A0),
            ),
          ),
        ],
      ),
    );
  }

  List<Patient> _applyFilters(List<Patient> patients) {
    final result = patients.where((patient) {
      final name = patient.name.toLowerCase();
      final idText =
          ((patient.id ?? patient.uuid).toString()).toLowerCase();
      final gender = _normalizeGender(patient.gender);

      if (_query.isNotEmpty &&
          !name.contains(_query) &&
          !idText.contains(_query)) {
        return false;
      }

      if (_genderFilter == _GenderFilter.male && gender != 'male') return false;
      if (_genderFilter == _GenderFilter.female && gender != 'female') {
        return false;
      }
      if (_genderFilter == _GenderFilter.others && gender != 'others') {
        return false;
      }
      if (_age18to35 && (patient.age < 18 || patient.age > 35)) return false;

      return true;
    }).toList();

    switch (_sortBy) {
      case _SortBy.newest:
        result.sort((a, b) => (b.id ?? -1).compareTo(a.id ?? -1));
        break;
      case _SortBy.oldest:
        result.sort((a, b) => (a.id ?? -1).compareTo(b.id ?? -1));
        break;
      case _SortBy.nameAZ:
        result.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }

    return result;
  }

  ImageProvider? _patientImage(Patient patient) {
    final photo = patient.photoPath;
    if (photo == null || photo.isEmpty) return null;

    final normalizedPhoto = photo.replaceAll('\\', '/');
    final isWindowsAbsolutePath =
        RegExp(r'^[A-Za-z]:[/\\]').hasMatch(photo);

    if (normalizedPhoto.startsWith('/uploads/') ||
        normalizedPhoto.contains('/uploads/')) {
      return NetworkImage('$_baseUrl$normalizedPhoto');
    }

    if (photo.startsWith('/') || isWindowsAbsolutePath) {
      final file = File(photo);
      if (file.existsSync()) {
        return FileImage(file);
      }
      return null;
    }

    if (photo.startsWith('http')) {
      return NetworkImage(photo);
    }

    return NetworkImage('$_baseUrl/$normalizedPhoto');
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _searchController.clear();
      _genderFilter = _GenderFilter.all;
      _age18to35 = false;
      _sortBy = _SortBy.newest;
    });
  }

  String _sortLabel() {
    switch (_sortBy) {
      case _SortBy.newest:
        return context.l10n.tr('patients.newest');
      case _SortBy.oldest:
        return context.l10n.tr('patients.oldest');
      case _SortBy.nameAZ:
        return 'A-Z';
    }
  }

  String _localizedGender(String rawGender) {
    final normalized = _normalizeGender(rawGender);
    if (normalized == 'male') return context.l10n.tr('patient.male');
    if (normalized == 'female') return context.l10n.tr('patient.female');
    return context.l10n.tr('patient.other');
  }

  String _normalizeGender(String raw) {
    final g = raw.trim().toLowerCase();
    if (g == 'male' || g == 'm') return 'male';
    if (g == 'female' || g == 'f') return 'female';
    return 'others';
  }
}
