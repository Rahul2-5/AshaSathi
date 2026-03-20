import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:frontend/localization/language_controller.dart';

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
  static const Color _accentTextColor = Color(0xFF56C7AA);

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
    final l10n = context.l10n;
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
                      children: [
                        TextSpan(text: l10n.tr('home.welcome')),
                        TextSpan(
                          text: l10n.tr('home.ashaWorker'),
                          style: const TextStyle(color: _accentTextColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.monitor_heart_outlined,
                        size: 16,
                        color: Color(0xFF55C58D),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.tr('home.dailyOverview'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
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
                  Expanded(
                    child: Text(
                      l10n.tr('home.recentPatients'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PatientsListPage(),
                        ),
                      );
                    },
                    child: Text(
                      l10n.tr('common.viewAll'),
                      style: TextStyle(
                        color: _accentTextColor,
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: _languageSettingsCard(),
            ),
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
        Expanded(
          child: Text(
            context.l10n.tr('home.dailyTasks'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFE8EEF3) : const Color(0xFF171A1F),
            ),
          ),
        ),
        const SizedBox(width: 12),
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
          return SliverToBoxAdapter(
            child: Center(child: Text(context.l10n.tr('home.noTasksToday'))),
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
          return Center(child: Text(context.l10n.tr('home.noPatientsFound')));
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
      final normalizedPhoto = photo.replaceAll('\\', '/');
      final isWindowsAbsolutePath = RegExp(r'^[A-Za-z]:[/\\]').hasMatch(photo);

      // Server stores relative paths like "/uploads/patients/1/profile.jpg"
      if (normalizedPhoto.startsWith('/uploads/') ||
          normalizedPhoto.contains('/uploads/')) {
        networkUrl = "http://10.0.2.2:8080$normalizedPhoto";
      } else if ((photo.startsWith('/') && !photo.startsWith('/uploads/')) ||
          isWindowsAbsolutePath) {
        // Assume absolute local file path on device
        localPath = photo;
      } else if (photo.startsWith('http')) {
        networkUrl = photo;
      } else {
        // Treat as relative server path
        networkUrl = "http://10.0.2.2:8080/$normalizedPhoto";
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
              "${_localizedGender(patient.gender).toUpperCase()}  •  ${context.l10n.tr('patients.yearsShort', args: {'age': patient.age.toString()}).toUpperCase()}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.tr('common.view'),
                    style: const TextStyle(
                      color: _accentTextColor,
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

  String _localizedGender(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'male' || normalized == 'm') {
      return context.l10n.tr('patient.male');
    }
    if (normalized == 'female' || normalized == 'f') {
      return context.l10n.tr('patient.female');
    }
    return context.l10n.tr('patient.other');
  }

  Widget _languageSettingsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final currentCode = LanguageController.notifierOf(context).value.languageCode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A232C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3642) : const Color(0xFFE5E8EC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.tr('home.settings'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1F252B),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(l10n.tr('home.language')),
            trailing: Text(
              AppLocalizations.nativeLanguageNames[currentCode] ?? 'Hindi',
              style: TextStyle(
                color: isDark ? const Color(0xFFA5B3BF) : const Color(0xFF6C7580),
              ),
            ),
            onTap: _showLanguageSelector,
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguageSelector() async {
    final currentLocale = LanguageController.notifierOf(context).value;
    String selectedCode = currentLocale.languageCode;
    final l10n = context.l10n;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final media = MediaQuery.of(modalContext);
            final maxHeight = media.size.height * 0.86;

            return SafeArea(
              top: false,
              child: SizedBox(
                height: maxHeight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Text(
                              l10n.tr('common.selectLanguage'),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.tr('common.languageHint'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF9AA7B3)
                                    : const Color(0xFF7E8792),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: LanguageStorage.supportedLanguageCodes.length,
                          itemBuilder: (listContext, index) {
                            final code = LanguageStorage.supportedLanguageCodes[index];
                            return RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                AppLocalizations.nativeLanguageNames[code] ?? code,
                              ),
                              subtitle: Text(
                                AppLocalizations.nativeLanguageScripts[code] ?? '',
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF99A6B2)
                                      : const Color(0xFF7A8592),
                                ),
                              ),
                              value: code,
                              groupValue: selectedCode,
                              onChanged: (value) {
                                if (value == null) return;
                                setSheetState(() {
                                  selectedCode = value;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(modalContext, false),
                              child: Text(l10n.tr('common.cancel')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF14A7A0),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(modalContext, true),
                              child: Text(l10n.tr('common.confirmSelection')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed == true) {
      if (!mounted) return;
      final notifier = LanguageController.notifierOf(context);
      final locale = Locale(selectedCode);
      notifier.value = locale;
      await LanguageStorage.saveLocale(locale);
    }
  }
}
