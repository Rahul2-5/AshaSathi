import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/cubit/login_cubit.dart';
import '../auth/cubit/patient_cubit.dart';
import '../task/task_cubit.dart';
import '../task/add_task_page.dart';
import '../utils/app_colors.dart';
import 'widgets/task_card.dart';
import '../patient/patient_detail_page.dart';
import '../patient/patient_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    final token = context.read<LoginCubit>().state.token!;
    context.read<TaskCubit>().loadTasks(token);
    context.read<PatientCubit>().loadPatients(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "ASHA Dashboard",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: CustomScrollView(
        slivers: [

          // 🔹 HEADER + WELCOME
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  const Text(
                    "Welcome, ASHA Worker!",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Your daily overview",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),

                  _tasksHeader(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // 🔹 TASK LIST (SLIVER – CORRECT)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _taskSliverList(),
          ),

          // 🔹 RECENT PATIENTS TITLE
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            sliver: const SliverToBoxAdapter(
              child: Text(
                "Recent Patients",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // 🔹 RECENT PATIENTS HORIZONTAL LIST
          SliverToBoxAdapter(
            child: SizedBox(
              height: 190,
              child: _recentPatientsList(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  // ================= TASKS =================

  Widget _tasksHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Daily Tasks",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTaskPage()),
            );

            if (result == true) {
              final token = context.read<LoginCubit>().state.token!;
              context.read<TaskCubit>().loadTasks(token);
            }
          },
        ),
      ],
    );
  }

  Widget _taskSliverList() {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        if (state.loading && state.tasks.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.tasks.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(child: Text("No tasks for today")),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TaskCard(task: state.tasks[index]),
              );
            },
            childCount: state.tasks.length,
          ),
        );
      },
    );
  }

  // ================= PATIENTS =================

  Widget _recentPatientsList() {
    return BlocBuilder<PatientCubit, PatientState>(
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.patients.isEmpty) {
          return const Center(child: Text("No patients found"));
        }

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: state.patients.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            return _patientCard(state.patients[index]);
          },
        );
      },
    );
  }

  Widget _patientCard(Patient patient) {
    final String? imageUrl =
        patient.photoPath != null && patient.photoPath!.isNotEmpty
            ? "http://10.0.2.2:8080${patient.photoPath}"
            : null;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientDetailPage(patient: patient),
          ),
        );
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      imageUrl != null ? NetworkImage(imageUrl) : null,
                  child: imageUrl == null
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              patient.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              patient.gender,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
