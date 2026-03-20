import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:shimmer/shimmer.dart';
import '../auth/cubit/login_cubit.dart';
import '../auth/cubit/patient_cubit.dart';

class PhcDashboardPage extends StatefulWidget {
  const PhcDashboardPage({super.key});

  @override
  State<PhcDashboardPage> createState() => _PhcDashboardPageState();
}

class _PhcDashboardPageState extends State<PhcDashboardPage> {

  @override
  void initState() {
    super.initState();

    // Load patients data if not already loaded
    final token = context.read<LoginCubit>().state.token!;
    context.read<PatientCubit>().loadPatients(token);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatientCubit, PatientState>(
      builder: (context, state) {
        final isInitialLoading = state.loading && state.patients.isEmpty;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: isInitialLoading
                  ? _buildSkeletonContent()
                  : Column(
                      key: const ValueKey('phc-content'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildKeyMetricsSection(state),
                        const SizedBox(height: 28),
                        _buildSummaryCards(state),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  //  KEY METRICS 

  Widget _buildKeyMetricsSection(PatientState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.tr('phc.keyMetrics'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFE6EDF3) : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        _metricCard(
          icon: Icons.person,
          label: context.l10n.tr('phc.totalPatients'),
          value: state.patients.length.toString(),
          backgroundColor: const Color(0xFFE0F7F6),
          iconColor: const Color(0xFF00A6A6),
        ),
      ],
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A232C) : backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE6EDF3) : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFFA6B3BF) : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // SUMMARY CARDS 

  Widget _buildSummaryCards(PatientState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maleCount = state.patients
        .where((p) => p.gender.toLowerCase() == 'male')
        .length;
    final femaleCount = state.patients
        .where((p) => p.gender.toLowerCase() == 'female')
        .length;
    final otherCount = state.patients
        .where((p) => p.gender.toLowerCase() == 'other')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.tr('phc.genderDistribution'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFE6EDF3) : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: context.l10n.tr('patient.male'),
                count: maleCount,
                icon: Icons.male,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                title: context.l10n.tr('patient.female'),
                count: femaleCount,
                icon: Icons.female,
                color: const Color(0xFFF472B6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                title: context.l10n.tr('patient.other'),
                count: otherCount,
                icon: Icons.person_outline,
                color: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1A232C) : const Color(0xFFE9EDF1);
    final highlightColor = isDark ? const Color(0xFF2A3642) : const Color(0xFFF6F8FA);

    return Shimmer.fromColors(
      key: const ValueKey('phc-skeleton'),
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skeletonBox(width: 130, height: 20, color: baseColor),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A232C) : const Color(0xFFE0F7F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _skeletonBox(width: 56, height: 56, color: baseColor, circular: true),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonBox(width: 64, height: 30, color: baseColor),
                    const SizedBox(height: 8),
                    _skeletonBox(width: 110, height: 14, color: baseColor),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _skeletonBox(width: 170, height: 20, color: baseColor),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _skeletonSummaryCard(baseColor)),
              const SizedBox(width: 12),
              Expanded(child: _skeletonSummaryCard(baseColor)),
              const SizedBox(width: 12),
              Expanded(child: _skeletonSummaryCard(baseColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _skeletonSummaryCard(Color shimmerColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A232C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _skeletonBox(width: 32, height: 32, color: shimmerColor, circular: true),
          const SizedBox(height: 10),
          _skeletonBox(width: 28, height: 22, color: shimmerColor),
          const SizedBox(height: 8),
          _skeletonBox(width: 54, height: 12, color: shimmerColor),
        ],
      ),
    );
  }

  Widget _skeletonBox({
    required double width,
    required double height,
    required Color color,
    bool circular = false,
  }) {
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

  Widget _summaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A232C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE6EDF3) : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFFA6B3BF) : const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
