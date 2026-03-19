import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../offline/patient_sync_service.dart';
import '../offline/task_sync_service.dart';

import '../auth/cubit/login_cubit.dart';
import '../auth/cubit/patient_cubit.dart';
import '../task/task_cubit.dart';
import '../task/add_task_page.dart';
import 'widgets/task_card.dart';
import '../patient/patient_detail_page.dart';
import '../patient/patient_model.dart';
import '../patient/patients_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PatientSyncService _patientSyncService;
  late final TaskSyncService _taskSyncService;
  late final StreamSubscription _connectivitySub;

  @override
  void initState() {
    super.initState();

    final token = context.read<LoginCubit>().state.token!;

    // Initial load
    context.read<TaskCubit>().loadTasks(token);
    context.read<PatientCubit>().loadPatients(token);

    // Sync service
    _patientSyncService = PatientSyncService();
    _taskSyncService = TaskSyncService();

    // Try an initial sync once on startup (useful after regaining connectivity)
    (() async {
      final initialPatientSynced = await _patientSyncService.sync(token);
      final initialTaskSynced = await _taskSyncService.sync(token);

      if (initialPatientSynced && mounted) {
        context.read<PatientCubit>().loadPatients(token);
      }
      if (initialTaskSynced && mounted) {
        context.read<TaskCubit>().loadTasks(token);
      }
    })();

    // Auto-sync when network comes back
    _connectivitySub = Connectivity().onConnectivityChanged.listen((_) async {
      // Try both patient and task sync when network state changes
      final patientSynced = await _patientSyncService.sync(token);
      final taskSynced = await _taskSyncService.sync(token);

      if (patientSynced && mounted) {
        context.read<PatientCubit>().loadPatients(token);
      }

      if (taskSynced && mounted) {
        context.read<TaskCubit>().loadTasks(token);
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFE8EEF3) : const Color(0xFF171A1F);
    final subtitleColor = isDark ? const Color(0xFF9AA7B3) : const Color(0xFF8D959E);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header + welcome
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        height: 1.14,
                      ),
                      children: const [
                        TextSpan(text: "Welcome,\n"),
                        TextSpan(
                          text: "Asha Worker!",
                          style: TextStyle(color: Color(0xFF50C5A3)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.monitor_heart_outlined,
                        size: 16,
                        color: Color(0xFF55C58D),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Your daily health overview is ready",
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _tasksHeader(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Task list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _taskSliverList(),
          ),

          // Recent patients title
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Patients",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PatientsListPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "View All",
                      style: TextStyle(
                        color: Color(0xFF50C785),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent patients list
          SliverToBoxAdapter(
            child: SizedBox(
              height: 252,
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

  Widget _tasksHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Daily Tasks",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFE8EEF3) : const Color(0xFF171A1F),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTaskPage()),
            );

            if (!mounted) return;

            if (result == true) {
              final token = context.read<LoginCubit>().state.token!;
              context.read<TaskCubit>().loadTasks(token);
            }
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF4EC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.add,
              size: 20,
              color: Color(0xFF54BD9E),
            ),
          ),
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
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TaskCard(task: state.tasks[index]),
            ),
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

        final recentPatients = [...state.patients]
          ..sort((a, b) => (b.id ?? -1).compareTo(a.id ?? -1));
        final visiblePatients = recentPatients.take(5).toList();

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: visiblePatients.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            return _patientCard(visiblePatients[index]);
          },
        );
      },
    );
  }

  Widget _patientCard(Patient patient) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A232C) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2A3642) : const Color(0xFFE5E8EC);

    final String? photo = patient.photoPath;
    String? localPath;
    String? networkUrl;

    if (photo != null && photo.isNotEmpty) {
      // Server stores relative paths like "/uploads/patients/1/profile.jpg"
      if (photo.startsWith('/uploads/') || photo.contains('/uploads/')) {
        networkUrl = "http://10.0.2.2:8080$photo";
      } else if (photo.startsWith('/') && !photo.startsWith('/uploads/')) {
        // Assume absolute local file path on device
        localPath = photo;
      } else if (photo.startsWith('http')) {
        networkUrl = photo;
      } else {
        // Treat as relative server path
        networkUrl = "http://10.0.2.2:8080/$photo";
      }
    }

    ImageProvider? imageProvider;

    if (localPath != null && File(localPath).existsSync()) {
      imageProvider = FileImage(File(localPath));
    } else if (networkUrl != null) {
      imageProvider = NetworkImage(networkUrl);
    }

    return InkWell(
      onTap: () async {
        final deleted = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientDetailPage(patient: patient),
          ),
        );

        if (!mounted) return;

        if (deleted == true) {
          final token = context.read<LoginCubit>().state.token!;
          context.read<PatientCubit>().loadPatients(token);
        }
      },

      child: Container(
        width: 150,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFE5EDF3),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.person, color: Color(0xFF80909A))
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              patient.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF202329),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${patient.gender.toUpperCase()}  •  ${patient.age} YRS",
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.3,
                color: isDark ? const Color(0xFF9EABB7) : const Color(0xFF7B838C),
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEFFFF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA9E1C2)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "View",
                    style: TextStyle(
                      color: Color(0xFF49BD83),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Color(0xFF49BD83),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
