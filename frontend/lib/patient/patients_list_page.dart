import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/config/app_config.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

import '../auth/cubit/login_cubit.dart';
import '../auth/cubit/patient_cubit.dart';
import 'patient_detail_page.dart';
import 'patient_model.dart';

enum _GenderFilter { all, male, female, others }

enum _SortBy { newest, oldest, nameAZ }

class PatientsListPage extends StatefulWidget {
  const PatientsListPage({super.key});

  @override
  State<PatientsListPage> createState() => _PatientsListPageState();
}

class _PatientsListPageState extends State<PatientsListPage> {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _GenderFilter _genderFilter = _GenderFilter.all;
  bool _age18to35 = false;
  _SortBy _sortBy = _SortBy.newest;

  bool get _isCompact => MediaQuery.sizeOf(context).width <= 380;
  double get _horizontalPad => _isCompact ? 10 : 14;
  double get _sectionGap => _isCompact ? 8 : 10;

  @override
  void initState() {
    super.initState();
    final token = context.read<LoginCubit>().state.token;
    if (token != null) {
      context.read<PatientCubit>().loadPatients(token);
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
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final border = isDark ? const Color(0xFF31414F) : const Color(0xFFDDE3E8);
    final titleColor = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1E24);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: titleColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.tr('patients.title'),
          style: TextStyle(
            color: titleColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Container(height: 1, color: border),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(_horizontalPad, _sectionGap, _horizontalPad, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBox(),
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
    );
  }

  Widget _buildSearchBox() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: _isCompact ? 38 : 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A232C) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF31414F) : const Color(0xFFDDE3E8),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _query = value.trim().toLowerCase();
          });
        },
        style: TextStyle(
          fontSize: 12,
          color: isDark ? const Color(0xFFD5E1EB) : const Color(0xFF1D232B),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            size: 16,
            color: isDark ? const Color(0xFFA5B3BF) : const Color(0xFF88939D),
          ),
          hintText: context.l10n.tr('patients.searchHint'),
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF8B99A6) : const Color(0xFF98A2AC),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: _isCompact ? 10 : 11),
        ),
      ),
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
        InkWell(
          onTap: _clearFilters,
          child: Text(
            context.l10n.tr('common.clear'),
            style: TextStyle(
              color: Color(0xFF23A7CB),
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
        _chip(
          label: context.l10n.tr('patients.allGender'),
          selected: _genderFilter == _GenderFilter.all,
          onTap: () => setState(() => _genderFilter = _GenderFilter.all),
        ),
        _chip(
          label: context.l10n.tr('patient.male'),
          selected: _genderFilter == _GenderFilter.male,
          onTap: () => setState(() => _genderFilter = _GenderFilter.male),
        ),
        _chip(
          label: context.l10n.tr('patient.female'),
          selected: _genderFilter == _GenderFilter.female,
          onTap: () => setState(() => _genderFilter = _GenderFilter.female),
        ),
        _chip(
          label: context.l10n.tr('patients.others'),
          selected: _genderFilter == _GenderFilter.others,
          onTap: () => setState(() => _genderFilter = _GenderFilter.others),
        ),
        _chip(
          label: context.l10n.tr('patients.age18to35'),
          selected: _age18to35,
          onTap: () => setState(() => _age18to35 = !_age18to35),
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _isCompact ? 11 : 12,
          vertical: _isCompact ? 6 : 7,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF27A8BE)
              : (isDark ? const Color(0xFF222D38) : const Color(0xFFF2F5F7)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF27A8BE)
                : (isDark ? const Color(0xFF32414E) : const Color(0xFFE2E7EB)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (isDark ? const Color(0xFFC0CDD8) : const Color(0xFF626E7A)),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _recordsHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        BlocBuilder<PatientCubit, PatientState>(
          builder: (context, state) {
            final filtered = _applyFilters(state.patients);
            return Text(
              context.l10n.tr('patients.recentRecords', args: {'count': filtered.length.toString()}),
              style: TextStyle(
                color: isDark ? const Color(0xFFAAB8C4) : const Color(0xFF5D6975),
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
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? const Color(0xFF31414F) : const Color(0xFFE3E8EE),
            ),
          ),
          constraints: const BoxConstraints(minWidth: 168),
          offset: const Offset(0, 8),
          onSelected: (value) {
            setState(() {
              _sortBy = value;
            });
          },
          itemBuilder: (_) => [
            _sortMenuItem(_SortBy.newest, context.l10n.tr('patients.newest')),
            _sortMenuItem(_SortBy.oldest, context.l10n.tr('patients.oldest')),
            _sortMenuItem(_SortBy.nameAZ, context.l10n.tr('patients.nameAZ')),
          ],
          child: Row(
            children: [
              Text(
                context.l10n.tr('patients.sortBy', args: {'sort': _sortLabel()}),
                style: const TextStyle(
                  color: Color(0xFF23A7CB),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: Color(0xFF23A7CB),
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF169FBD)
                    : (isDark ? const Color(0xFFC6D2DC) : const Color(0xFF2E3742)),
              ),
            ),
          ),
          if (selected)
            const Icon(
              Icons.check_rounded,
              size: 16,
              color: Color(0xFF169FBD),
            ),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    return BlocBuilder<PatientCubit, PatientState>(
      builder: (context, state) {
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
    final baseColor = isDark ? const Color(0xFF1A232C) : const Color(0xFFE9EDF1);
    final highlightColor = isDark ? const Color(0xFF2A3642) : const Color(0xFFF6F8FA);

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
              horizontal: _isCompact ? 12 : 13,
              vertical: _isCompact ? 12 : 13,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A232C) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF31414F) : const Color(0xFFE4E9ED),
              ),
            ),
            child: Row(
              children: [
                _skeletonBox(44, 44, baseColor, circular: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _skeletonBox(128, 14, baseColor),
                      const SizedBox(height: 8),
                      _skeletonBox(98, 12, baseColor),
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
        borderRadius:
            circular ? BorderRadius.circular(height / 2) : BorderRadius.circular(8),
      ),
    );
  }

  Widget _patientRow(Patient patient) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final deleted = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PatientDetailPage(patient: patient)),
        );

        if (!mounted) return;

        if (deleted == true) {
          final token = context.read<LoginCubit>().state.token;
          if (token != null) {
            context.read<PatientCubit>().loadPatients(token);
          }
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _isCompact ? 12 : 13,
          vertical: _isCompact ? 12 : 13,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A232C) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF31414F) : const Color(0xFFE4E9ED),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFE6ECF1),
              backgroundImage: _patientImage(patient),
              child: _patientImage(patient) == null
                  ? const Icon(Icons.person, size: 20, color: Color(0xFF7F8A95))
                  : null,
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Color(0xFFE6EDF3) : Color(0xFF21262C),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 12,
                    runSpacing: 2,
                    children: [
                      _metaItem(
                        Icons.calendar_today_outlined,
                        context.l10n.tr('patients.yearsShort', args: {'age': patient.age.toString()}),
                      ),
                      _metaItem(Icons.person_outline, _localizedGender(patient.gender)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: isDark ? const Color(0xFF9AA5AF) : const Color(0xFF9AA5AF),
              size: 18,
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
          color: isDark ? const Color(0xFF9CA9B5) : const Color(0xFF88939D),
        ),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFFA6B3BF) : const Color(0xFF7D8893),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A232C) : const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF31414F) : const Color(0xFFDCE3E9),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            color: isDark ? const Color(0xFFA3B0BB) : const Color(0xFF88939D),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.tr('patients.showingAll'),
            style: TextStyle(
              fontSize: 17,
              color: isDark ? const Color(0xFFD5E1EB) : const Color(0xFF4A5561),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.tr('patients.filtersHint'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFFA6B3BF) : const Color(0xFF8B96A0),
            ),
          ),
        ],
      ),
    );
  }

  List<Patient> _applyFilters(List<Patient> patients) {
    final result = patients.where((patient) {
      final name = patient.name.toLowerCase();
      final idText = ((patient.id ?? patient.uuid).toString()).toLowerCase();
      final gender = _normalizeGender(patient.gender);

      if (_query.isNotEmpty && !name.contains(_query) && !idText.contains(_query)) {
        return false;
      }

      if (_genderFilter == _GenderFilter.male && gender != 'male') {
        return false;
      }

      if (_genderFilter == _GenderFilter.female && gender != 'female') {
        return false;
      }

      if (_genderFilter == _GenderFilter.others && gender != 'others') {
        return false;
      }

      if (_age18to35 && (patient.age < 18 || patient.age > 35)) {
        return false;
      }

      return true;
    }).toList();

    switch (_sortBy) {
      case _SortBy.newest:
        result.sort((a, b) {
          final bId = b.id ?? -1;
          final aId = a.id ?? -1;
          return bId.compareTo(aId);
        });
        break;
      case _SortBy.oldest:
        result.sort((a, b) {
          final aId = a.id ?? -1;
          final bId = b.id ?? -1;
          return aId.compareTo(bId);
        });
        break;
      case _SortBy.nameAZ:
        result.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }

    return result;
  }

  ImageProvider? _patientImage(Patient patient) {
    final photo = patient.photoPath;
    if (photo == null || photo.isEmpty) return null;

    final normalizedPhoto = photo.replaceAll('\\', '/');
    final isWindowsAbsolutePath = RegExp(r'^[A-Za-z]:[/\\]').hasMatch(photo);

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

  String _normalizeGender(String rawGender) {
    final g = rawGender.trim().toLowerCase();

    if (g == 'male' || g == 'm') return 'male';
    if (g == 'female' || g == 'f') return 'female';

    return 'others';
  }
}
