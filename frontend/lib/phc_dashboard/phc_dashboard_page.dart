import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKeyMetricsSection(),
            const SizedBox(height: 28),
            _buildSummaryCards(),
          ],
        ),
      ),
    );
  }

  // ================= KEY METRICS =================

  Widget _buildKeyMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Key Metrics",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        BlocBuilder<PatientCubit, PatientState>(
          builder: (context, state) {
            final totalPatients = state.patients.length;

            return _metricCard(
              icon: Icons.person,
              label: "Total Patients",
              value: totalPatients.toString(),
              backgroundColor: const Color(0xFFE0F7F6),
              iconColor: const Color(0xFF00A6A6),
            );
          },
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
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
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= SUMMARY CARDS =================

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Gender Distribution",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        BlocBuilder<PatientCubit, PatientState>(
          builder: (context, state) {
            final maleCount = state.patients
                .where((p) => p.gender.toLowerCase() == 'male')
                .length;
            final femaleCount = state.patients
                .where((p) => p.gender.toLowerCase() == 'female')
                .length;
            final otherCount = state.patients
                .where((p) => p.gender.toLowerCase() == 'other')
                .length;

            return Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    title: "Male",
                    count: maleCount,
                    icon: Icons.male,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    title: "Female",
                    count: femaleCount,
                    icon: Icons.female,
                    color: const Color(0xFFF472B6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    title: "Other",
                    count: otherCount,
                    icon: Icons.person_outline,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
