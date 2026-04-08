import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/config/app_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:frontend/localization/language_controller.dart';
import 'package:shimmer/shimmer.dart';

import '../offline/patient_sync_service.dart';
import '../offline/task_sync_service.dart';
import '../offline/family_sync_service.dart';
import '../offline/connectivity_service.dart';
import '../offline/patient_sync_conflicts_page.dart';

import '../providers/login_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/task_provider.dart';
import '../providers/family_provider.dart';
import '../task/add_task_page.dart';
import 'widgets/task_card.dart';
import '../patient/patient_detail_page.dart';
import '../patient/patient_model.dart';
import '../patient/patients_list_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const Color _accentTextColor = Color(0xFF56C7AA);

  late final PatientSyncService _patientSyncService;
  late final TaskSyncService _taskSyncService;
  late final FamilySyncService _familySyncService;
  late final ConnectivityService _connectivityService;
  late final StreamSubscription _connectivitySub;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();

    // Sync service - lightweight setup
    _patientSyncService = PatientSyncService();
    _taskSyncService = TaskSyncService();
    _familySyncService = FamilySyncService();
    _connectivityService = ConnectivityService();
    _refreshConnectivityStatus();
    _patientSyncService.refreshSyncStatus();

    // Auto-sync when network comes back (setup listener only)
    _connectivitySub = Connectivity().onConnectivityChanged.listen((_) async {
      await _refreshConnectivityStatus();
      final token = await ref.read(loginProvider.notifier).getValidToken();
      if (token == null || !mounted) return;

      // Try patient, task, and family sync when network state changes
      final patientSynced = await _patientSyncService.sync(token);
      final taskSynced = await _taskSyncService.sync(token);
      final familySynced = await _familySyncService.syncPendingFamilies(token);

      if (patientSynced && mounted) {
        ref.read(patientListProvider.notifier).loadPatients(token);
      }

      if (taskSynced && mounted) {
        ref.read(taskListProvider.notifier).loadTasks(token);
      }

      if (familySynced > 0 && mounted) {
        // Trigger family list reload if families were synced
        ref.read(familyListProvider.notifier).loadFamilies(token);
      }
    });

    // Load data with valid token after frame build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPatientAndTaskData();
    });
  }

  Future<void> _loadPatientAndTaskData() async {
    final token = await ref.read(loginProvider.notifier).getValidToken();
    if (token == null || !mounted) return;

    // Initial load (always load to show cached data even if offline)
    ref.read(taskListProvider.notifier).loadTasks(token);
    ref.read(patientListProvider.notifier).loadPatients(token);
    ref.read(familyListProvider.notifier).loadFamilies(token);

    // Try an initial sync once on startup (useful after regaining connectivity)
    try {
      final initialPatientSynced = await _patientSyncService.sync(token);
      final initialTaskSynced = await _taskSyncService.sync(token);
      final initialFamilySynced = await _familySyncService.syncPendingFamilies(token);

      if (initialPatientSynced && mounted) {
        ref.read(patientListProvider.notifier).loadPatients(token);
      }
      if (initialTaskSynced && mounted) {
        ref.read(taskListProvider.notifier).loadTasks(token);
      }
      if (initialFamilySynced > 0 && mounted) {
        ref.read(familyListProvider.notifier).loadFamilies(token);
      }
    } catch (e) {
      // Sync attempt failed, but data may have loaded from cache
      debugPrint('Initial sync error: $e');
    }
  }

  Future<void> _refreshConnectivityStatus() async {
    final online = await _connectivityService.isOnline();
    if (!mounted) return;
    setState(() => _isOnline = online);
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
                      const SizedBox(width: 10),
                      _connectivityBadge(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _syncStatusCard(),
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

  Widget _connectivityBadge() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _isOnline ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOnline ? Icons.wifi : Icons.wifi_off,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            _isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
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
              final token = await ref.read(loginProvider.notifier).getValidToken();
              if (token != null && mounted) {
                ref.read(taskListProvider.notifier).loadTasks(token);
              }
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

  Widget _syncStatusCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<PatientSyncStatusSnapshot>(
      valueListenable: PatientSyncService.syncStatus,
      builder: (context, snapshot, _) {
        final queueCount = snapshot.totalQueueCount;
        final hasConflicts = snapshot.conflictCount > 0;
        final hasRetryableItems = queueCount > 0 || snapshot.retryQueueCount > 0;
        final isSynced = queueCount == 0 && 
                         snapshot.retryQueueCount == 0 && 
                         snapshot.conflictCount == 0 &&
                         !snapshot.isSyncing;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? isSynced
                      ? [const Color(0xFF1A2F28), const Color(0xFF0F2218)]
                      : hasConflicts
                          ? [const Color(0xFF3D2817), const Color(0xFF2A1810)]
                          : [const Color(0xFF1A232C), const Color(0xFF0F1419)]
                  : isSynced
                      ? [const Color(0xFFF0FFFE), const Color(0xFFE8FDFB)]
                      : hasConflicts
                          ? [const Color(0xFFFFF5F0), const Color(0xFFFFEADD)]
                          : [Colors.white, const Color(0xFFFAFBFC)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSynced
                  ? const Color(0xFF14B8A6).withValues(alpha: 0.3)
                  : hasConflicts
                      ? const Color(0xFFE67E22).withValues(alpha: 0.3)
                      : (isDark ? const Color(0xFF2A3642) : const Color(0xFFE5E8EC)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSynced
                    ? const Color(0xFF14B8A6).withValues(alpha: 0.08)
                    : hasConflicts
                        ? const Color(0xFFE67E22).withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and status indicator
              Row(
                children: [
                  if (snapshot.isSyncing)
                    RotationTransition(
                      turns: AlwaysStoppedAnimation(
                          DateTime.now().millisecondsSinceEpoch / 1500 % 1),
                      child: Icon(
                        Icons.sync,
                        color: const Color(0xFF0EA5E9),
                        size: 20,
                      ),
                    )
                  else
                    Icon(
                      isSynced ? Icons.check_circle : Icons.sync_alt,
                      color: isSynced
                          ? const Color(0xFF14B8A6)
                          : hasConflicts
                              ? const Color(0xFFE67E22)
                              : (isDark
                                  ? const Color(0xFF9EABB7)
                                  : const Color(0xFF6C7580)),
                      size: 20,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snapshot.isSyncing
                              ? 'Syncing in progress...'
                              : isSynced
                                  ? 'All synced!'
                                  : hasConflicts
                                      ? 'Conflicts detected'
                                      : 'Ready to sync',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.3,
                            color: isDark
                                ? const Color(0xFFE6EDF3)
                                : const Color(0xFF1F252B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          snapshot.isSyncing
                              ? 'Uploading changes...'
                              : isSynced
                                  ? 'No pending changes'
                                  : '$queueCount pending • ${snapshot.retryQueueCount} failed',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF9EABB7)
                                : const Color(0xFF6C7580),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasRetryableItems || hasConflicts)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: hasConflicts
                            ? const Color(0xFFE67E22).withValues(alpha: 0.15)
                            : const Color(0xFFEAB308).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        hasConflicts ? '⚠️  Needs action' : '⚡ Retry needed',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: hasConflicts
                              ? const Color(0xFFE67E22)
                              : const Color(0xFFEAB308),
                        ),
                      ),
                    ),
                ],
              ),

              // Status legend if not synced
              if (!isSynced) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statBadge(
                        icon: Icons.hourglass_empty_rounded,
                        label: 'Pending',
                        value: queueCount,
                        color: const Color(0xFF0EA5E9),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statBadge(
                        icon: Icons.error_outline_rounded,
                        label: 'Failed',
                        value: snapshot.retryQueueCount,
                        color: const Color(0xFFEF4444),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statBadge(
                        icon: Icons.merge_type_rounded,
                        label: 'Conflicts',
                        value: snapshot.conflictCount,
                        color: const Color(0xFFE67E22),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],

              // Error message if present
              if ((snapshot.lastError ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3E1F1F)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFDC2626),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          snapshot.lastError!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action buttons
              if (hasRetryableItems || hasConflicts) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (hasRetryableItems)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            backgroundColor: const Color(0xFF0EA5E9),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: snapshot.isSyncing
                              ? null
                              : () async {
                                  final token = await ref
                                      .read(loginProvider.notifier)
                                      .getValidToken();
                                  if (token == null) return;
                                  await _patientSyncService.refreshSyncStatus();
                                  final synced =
                                      await _patientSyncService.sync(token);
                                  if (!mounted) return;
                                  if (synced) {
                                    ref
                                        .read(
                                            patientListProvider.notifier)
                                        .loadPatients(token);
                                  }
                                },
                          icon: snapshot.isSyncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.refresh, size: 16),
                          label: Text(
                            snapshot.isSyncing ? 'Syncing...' : 'Retry Now',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    if (hasRetryableItems && hasConflicts)
                      const SizedBox(width: 8),
                    if (hasConflicts)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            backgroundColor: const Color(0xFFE67E22),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            // ignore: use_build_context_synchronously
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PatientSyncConflictsPage(),
                              ),
                            );
                            if (!mounted) return;
                            final token = await ref
                                .read(loginProvider.notifier)
                                .getValidToken();
                            if (token != null) {
                              ref
                                  .read(
                                      patientListProvider.notifier)
                                  .loadPatients(token);
                            }
                            await _patientSyncService.refreshSyncStatus();
                          },
                          icon: const Icon(Icons.merge_type, size: 16),
                          label: const Text(
                            'Resolve',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: isDark
                            ? const Color(0xFF9EABB7)
                            : const Color(0xFF6C7580),
                      ),
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'reset',
                          child: const Row(
                            children: [
                              Icon(Icons.delete_sweep, size: 18),
                              SizedBox(width: 8),
                              Text('Clear all data'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'reset') {
                          final didConfirm =
                              await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) =>
                                AlertDialog(
                              backgroundColor: isDark
                                  ? const Color(0xFF1A232C)
                                  : Colors.white,
                              title: Text(
                                'Clear all sync data?',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(
                                          0xFFE6EDF3)
                                      : const Color(0xFF1F252B),
                                ),
                              ),
                              content: Text(
                                'This will delete all offline queue items, conflicts, and sync history. This action cannot be undone.',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(
                                          0xFF9EABB7)
                                      : const Color(0xFF6C7580),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(
                                        dialogContext,
                                        false,
                                      ),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(
                                        dialogContext,
                                        true,
                                      ),
                                  style:
                                      TextButton.styleFrom(
                                    foregroundColor:
                                        Colors.red,
                                  ),
                                  child: const Text(
                                    'Clear',
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (didConfirm == true) {
                            if (!mounted) return;
                            await _patientSyncService
                                .resetAllData();
                            await _taskSyncService
                                .resetAllData();
                            await _patientSyncService
                                .refreshSyncStatus();
                            if (!mounted) return;
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(
                              // ignore: use_build_context_synchronously
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Sync data cleared successfully.',
                                ),
                                behavior:
                                    SnackBarBehavior.floating,
                                duration:
                                    Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statBadge({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFF9EABB7)
                  : const Color(0xFF6C7580),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskSliverList() {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(taskListProvider);
        if (state.loading && state.tasks.isEmpty) {
          return _buildTaskSkeletonSliver();
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
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(patientListProvider);
        if (state.loading && state.patients.isEmpty) {
          return _buildRecentPatientsSkeleton();
        }

        if (state.patients.isEmpty) {
          return Center(child: Text(context.l10n.tr('home.noPatientsFound')));
        }

        // ✅ SORT BY RECENCY: Most recently updated/created first
        final recentPatients = [...state.patients]
          ..sort((a, b) {
            // Use updatedAt for sorting (most recent first)
            final aTime = a.updatedAt ?? (a.id ?? -1);
            final bTime = b.updatedAt ?? (b.id ?? -1);
            return bTime.compareTo(aTime); // Descending: newest first
          });
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

  SliverToBoxAdapter _buildTaskSkeletonSliver() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1A232C) : const Color(0xFFE9EDF1);
    final highlightColor = isDark ? const Color(0xFF2A3642) : const Color(0xFFF6F8FA);

    return SliverToBoxAdapter(
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        period: const Duration(milliseconds: 1100),
        child: Column(
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A232C) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A3642) : const Color(0xFFE9EDF0),
                ),
              ),
              child: Row(
                children: [
                  _skeletonBox(48, 48, baseColor, circular: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _skeletonBox(140, 14, baseColor),
                        const SizedBox(height: 10),
                        _skeletonBox(220, 12, baseColor),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _skeletonBox(40, 20, baseColor),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRecentPatientsSkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1A232C) : const Color(0xFFE9EDF1);
    final highlightColor = isDark ? const Color(0xFF2A3642) : const Color(0xFFF6F8FA);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1100),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          return Container(
            width: 150,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A232C) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2A3642) : const Color(0xFFE5E8EC),
              ),
            ),
            child: Column(
              children: [
                _skeletonBox(56, 56, baseColor, circular: true),
                const SizedBox(height: 10),
                _skeletonBox(92, 14, baseColor),
                const SizedBox(height: 6),
                _skeletonBox(110, 10, baseColor),
                const Spacer(),
                _skeletonBox(120, 32, baseColor),
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
          if (normalizedPhoto.startsWith('/uploads/') || normalizedPhoto.contains('/uploads/')) {
            networkUrl = "${AppConfig.apiBaseUrl}$normalizedPhoto";
          } else if ((photo.startsWith('/') && !photo.startsWith('/uploads/')) || isWindowsAbsolutePath) {
        // Assume absolute local file path on device
        localPath = photo;
      } else if (photo.startsWith('http')) {
        networkUrl = photo;
      } else {
        // Treat as relative server path
            networkUrl = "${AppConfig.apiBaseUrl}/$normalizedPhoto";
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
          final token = await ref.read(loginProvider.notifier).getValidToken();
          if (token != null && mounted) {
            ref.read(patientListProvider.notifier).loadPatients(token);
          }
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
            const SizedBox(height: 8),
            Text(
              [
                if (patient.caste.trim().isNotEmpty) patient.caste.trim(),
                if (patient.phoneNumber.trim().isNotEmpty) patient.phoneNumber.trim(),
              ].join('  •  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF98A7B2) : const Color(0xFF70808C),
              ),
            ),
            if (patient.isPregnant || patient.activeDiseaseLabels.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                [
                  if (patient.isPregnant)
                    'Pregnant${patient.monthsOfPregnancy != null ? ' (${patient.monthsOfPregnancy} mo)' : ''}',
                  if (patient.activeDiseaseLabels.isNotEmpty)
                    patient.activeDiseaseLabels.take(2).join(', '),
                ].join('  •  '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.25,
                  color: isDark ? const Color(0xFFB2C0CC) : const Color(0xFF63707D),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              patient.description.trim().isEmpty
                  ? 'No notes'
                  : patient.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.25,
                color: isDark ? const Color(0xFFB2C0CC) : const Color(0xFF63707D),
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
                            final isSelected = selectedCode == code;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                setSheetState(() {
                                  selectedCode = code;
                                });
                              },
                              leading: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? const Color(0xFF14A7A0)
                                    : Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFF99A6B2)
                                        : const Color(0xFF7A8592),
                              ),
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
