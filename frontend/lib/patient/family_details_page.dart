import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../widgets/common/common_widgets.dart';
import 'add_patient_models.dart';

class FamilyDetailsPage extends StatelessWidget {
  final FamilyInfo familyInfo;
  final List<PatientDataModel> members;
  final bool showAppBar;
  final bool showBackToDashboardButton;
  final bool isLoading;

  const FamilyDetailsPage({
    super.key,
    required this.familyInfo,
    required this.members,
    this.showAppBar = true,
    this.showBackToDashboardButton = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = SafeArea(
      child: Column(
        children: [
          Expanded(
            child: isLoading
                ? _loadingSkeleton(context)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _familyHeaderCard(context, isDark),
                      const SizedBox(height: 18),
                      _sectionHeader(
                        context,
                        title: 'Family Members',
                        subtitle: '${members.length} people listed below',
                      ),
                      const SizedBox(height: 12),
                      ...members.map(
                        (member) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _memberCard(context, member, isDark),
                        ),
                      ),
                    ],
                  ),
          ),
          if (showBackToDashboardButton)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GlassButton(
                icon: Icons.home_rounded,
                label: 'Back to Dashboard',
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                    '/main',
                    (route) => false,
                  );
                },
              ),
            ),
        ],
      ),
    );

    if (!showAppBar) {
      return GradientScaffold(
        child: content,
      );
    }

    return GradientScaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text('Family Details', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      child: content,
    );
  }

  Widget _familyHeaderCard(BuildContext context, bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF33424F), const Color(0xFF24313C)]
                          : [const Color(0xFFEAF4F1), const Color(0xFFD8EEEA)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(familyInfo.headOfFamily),
                    style: TextStyle(
                      color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF17302A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          familyInfo.headOfFamily.isEmpty ? 'Head of Family' : familyInfo.headOfFamily,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF152029),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          familyInfo.familyAddress.isEmpty ? 'No address provided' : familyInfo.familyAddress,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF9FB0C0) : const Color(0xFF66727C),
                          ),
                        ),
                      ],
                    ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _infoChip(
                  icon: Icons.groups_rounded,
                  label: 'Members: ${members.length}',
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _infoChip(
                  icon: Icons.badge_outlined,
                  label: 'Family record',
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
    );
  }

  Widget _memberCard(BuildContext context, PatientDataModel member, bool isDark) {
    final hasActiveDisease = member.diseases.values.any((active) => active);

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF33424F), const Color(0xFF24313C)]
                          : [const Color(0xFFEAF4F1), const Color(0xFFD8EEEA)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(member.patientName),
                    style: TextStyle(
                      color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF17302A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.patientName.isEmpty ? 'Unnamed Member' : member.patientName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                          color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1E252D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${member.gender.isEmpty ? 'Unknown' : member.gender} • Age ${member.age.isEmpty ? '-' : member.age}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF9FB0C0) : const Color(0xFF6D7882),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasActiveDisease)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF493029) : const Color(0xFFFFE8DE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Health Flag',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFFFB38F) : const Color(0xFFB74417),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _detailItem('Age', member.age),
                _detailItem('DOB', member.dateOfBirth),
                _detailItem('Gender', member.gender),
                _detailItem('Phone', member.phoneNumber),
              ],
            ),
            const SizedBox(height: 10),
            _metaRow(
              icon: Icons.home_outlined,
              label: member.sameAsFamilyAddress
                  ? familyInfo.familyAddress
                  : member.address,
                isDark: isDark,
              ),
            if (hasActiveDisease) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: member.diseases.entries
                    .where((entry) => entry.value)
                    .map(
                      (entry) => _infoChip(
                        icon: Icons.favorite_rounded,
                        label: entry.key,
                        isDark: isDark,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (member.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1419) : const Color(0xFFF4F7F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2B3946) : const Color(0xFFE4E9ED),
                  ),
                ),
                child: Text(
                  member.notes,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFD6E3EA) : const Color(0xFF46525D),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ],
        ),
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    String? subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
            color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1C232B),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF98A7B3) : const Color(0xFF6D7882),
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1419) : const Color(0xFFF5F8F7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? const Color(0xFF2B3946) : const Color(0xFFDDE4E9),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: isDark ? const Color(0xFF9FB0C0) : const Color(0xFF6C7783)),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFD6E3EA) : const Color(0xFF54606B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1A232C) : const Color(0xFFE9EDF1);
    final highlightColor = isDark ? const Color(0xFF253240) : const Color(0xFFF7F9FB);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1200),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 180,
            height: 20,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(3, (_) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 140,
                              height: 14,
                              decoration: BoxDecoration(
                                color: baseColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 110,
                              height: 12,
                              decoration: BoxDecoration(
                                color: baseColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      4,
                      (_) => Container(
                        width: 84,
                        height: 26,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF14B8A6).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: ${value.trim().isEmpty ? '-' : value}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F8D7F),
        ),
      ),
    );
  }

  Widget _metaRow({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            icon,
            size: 16,
            color: isDark ? const Color(0xFFAAB6C2) : const Color(0xFF6C7783),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label.isEmpty ? '-' : label,
            style: TextStyle(
              color: isDark ? const Color(0xFFC8D3DD) : const Color(0xFF525D69),
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  String _initials(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return '?';
    }

    final parts = text.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    final first = parts.first.isNotEmpty ? parts.first.substring(0, 1) : '';
    final second = parts.last.isNotEmpty ? parts.last.substring(0, 1) : '';
    return (first + second).toUpperCase();
  }
}