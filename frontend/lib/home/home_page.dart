import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/config/app_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:frontend/widgets/common/common_widgets.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../app/app_settings_controller.dart';
import '../app/dashboard_bootstrap_controller.dart';
import '../offline/patient_sync_service.dart';
import '../offline/task_sync_service.dart';
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
  late final PatientSyncService _patientSyncService;
  late final TaskSyncService _taskSyncService;
  late final ConnectivityService _connectivityService;
  late final StreamSubscription _connectivitySub;
  Timer? _syncDebounceTimer;
  bool _isOnline = false;
  String _welcomeName = 'Asha Worker';

  @override
  void initState() {
    super.initState();

    _patientSyncService = PatientSyncService();
    _taskSyncService = TaskSyncService();
    _connectivityService = ConnectivityService();
    _refreshConnectivityStatus();
    _patientSyncService.refreshSyncStatus();
    _loadWelcomeName();

    // Auto-sync when network comes back (setup listener only)
    _connectivitySub = Connectivity().onConnectivityChanged.listen((_) {
      _syncDebounceTimer?.cancel();
      _syncDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
        await _refreshConnectivityStatus();
        if (!mounted) return;
        await ref.read(dashboardBootstrapProvider.notifier).syncAllIfPossible();
      });
    });

    // Load data with valid token after frame build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardBootstrapProvider.notifier).bootstrapDashboard();
    });
  }

  Future<void> _refreshConnectivityStatus() async {
    final online = await _connectivityService.isOnline();
    if (!mounted) return;
    setState(() => _isOnline = online);
  }

  Future<void> _loadWelcomeName() async {
    final token = await ref.read(loginProvider.notifier).getValidToken();
    if (!mounted || token == null || token.isEmpty) return;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return;

      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      final raw =
          (map['username'] ?? map['name'] ?? map['email'] ?? '') as String;
      if (raw.isEmpty) return;

      final username = raw.contains('@') ? raw.split('@')[0] : raw;
      final displayName = username[0].toUpperCase() + username.substring(1);
      if (!mounted) return;
      setState(() => _welcomeName = displayName);
    } catch (_) {}
  }

  @override
  void dispose() {
    _syncDebounceTimer?.cancel();
    _connectivitySub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final titleColor = AppColors.textPrimary(context);

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
                    ? const [
                        Color(0xFF0B1120),
                        Color(0xFF0E1A26),
                        Color(0xFF0A1218),
                      ]
                    : const [
                        Color(0xFFE8F8F5),
                        Color(0xFFF0F4FF),
                        Color(0xFFF7FBFF),
                      ],
              ),
            ),
          ),
          // Orb decorations
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.teal.withValues(alpha: isDark ? 0.10 : 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentCyan.withValues(
                      alpha: isDark ? 0.06 : 0.10,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _welcomeHeader(),
                    const SizedBox(height: 12),
                    _overviewHero(),
                    const SizedBox(height: 12),
                    _syncStatusCard(),
                    _medicalVisionCard(isDark),
                    const SizedBox(height: 28),
                    _tasksHeader(),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: _taskSliverList(),
              ),
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
                          style: GoogleFonts.outfit(
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
                            color: AppColors.brand(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: 252, child: _recentPatientsList()),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  child: _languageSettingsCard(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _welcomeHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Welcome, ',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                  height: 1.15,
                ),
              ),
              TextSpan(
                text: _welcomeName,
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.brand(context),
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Here\'s your daily health overview 🩺',
          style: TextStyle(
            color: isDark ? const Color(0xFFAFC4D2) : const Color(0xFF3A5060),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _overviewHero() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final l10n = context.l10n;

    return Consumer(
      builder: (context, ref, _) {
        // Narrow subscriptions: the hero only shows counts, so rebuild only
        // when a count changes rather than on every list/loading mutation.
        final patientCount = ref.watch(
          patientListProvider.select((s) => s.patients.length),
        );
        final taskCount = ref.watch(
          taskListProvider.select((s) => s.tasks.length),
        );
        final familyCount = ref.watch(
          familyListProvider.select((s) => s.families.length),
        );

        return GlassContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(28),
          blur: 18,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.teal.withValues(alpha: 0.15),
                    AppColors.accentCyan.withValues(alpha: 0.05),
                  ]
                : [
                    AppColors.teal.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.60),
                  ],
          ),
          border: Border.all(
            color: isDark
                ? AppColors.teal.withValues(alpha: 0.3)
                : AppColors.teal.withValues(alpha: 0.4),
            width: 1.5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.tr('home.dailyOverview'),
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFAFBBC6)
                            : const Color(0xFF66707A),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  _connectivityBadge(),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _overviewMetric(
                      label: l10n.tr('home.recentPatients'),
                      value: patientCount.toString(),
                      icon: Icons.people_alt_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _overviewMetric(
                      label: l10n.tr('home.dailyTasks'),
                      value: taskCount.toString(),
                      icon: Icons.assignment_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _overviewMetric(
                      label: 'Families',
                      value: familyCount.toString(),
                      icon: Icons.groups_2_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _overviewMetric({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.04),
                ]
              : [
                  Colors.white.withValues(alpha: 0.50),
                  Colors.white.withValues(alpha: 0.30),
                ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.40),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.teal.withValues(alpha: 0.20),
                    AppColors.accentCyan.withValues(alpha: 0.10),
                  ],
                ),
              ),
              child: Icon(icon, size: 16, color: AppColors.brand(context)),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF9FB0BC)
                    : const Color(0xFF6A7480),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _connectivityBadge() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _isOnline ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      borderRadius: BorderRadius.circular(20),
      blur: 10,
      gradient: LinearGradient(
        colors: [
          color.withValues(alpha: isDark ? 0.15 : 0.10),
          color.withValues(alpha: isDark ? 0.08 : 0.06),
        ],
      ),
      border: Border.all(color: color.withValues(alpha: 0.40)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            context.l10n.tr('home.dailyTasks'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
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
              final token = await ref
                  .read(loginProvider.notifier)
                  .getValidToken();
              if (token != null && mounted) {
                ref.read(taskListProvider.notifier).loadTasks(token);
              }
            }
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.accentCyan],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, size: 20, color: Colors.white),
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
        final hasRetryableItems =
            queueCount > 0 || snapshot.retryQueueCount > 0;
        final isSynced =
            queueCount == 0 &&
            snapshot.retryQueueCount == 0 &&
            snapshot.conflictCount == 0 &&
            !snapshot.isSyncing;

        return GlassContainer(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(16),
          blur: 18,
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Colors.white.withValues(alpha: 0.06),
                    Colors.white.withValues(alpha: 0.03),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.35),
                  ],
          ),
          border: Border.all(
            color: isSynced
                ? const Color(0xFF14B8A6).withValues(alpha: 0.3)
                : hasConflicts
                ? const Color(0xFFE67E22).withValues(alpha: 0.3)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.5)),
            width: 1.5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and status indicator
              Row(
                children: [
                  if (snapshot.isSyncing)
                    const _SpinningSyncIcon(color: Color(0xFF0EA5E9), size: 20)
                  else
                    Icon(
                      isSynced ? Icons.check_circle : Icons.sync_alt,
                      color: isSynced
                          ? const Color(0xFF14B8A6)
                          : hasConflicts
                          ? const Color(0xFFE67E22)
                          : AppColors.textSecondary(context),
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
                            color: AppColors.textPrimary(context),
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
                            color: AppColors.textSecondary(context),
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
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                                  final synced = await _patientSyncService.sync(
                                    token,
                                  );
                                  if (!mounted) return;
                                  if (synced) {
                                    ref
                                        .read(patientListProvider.notifier)
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
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                                  .read(patientListProvider.notifier)
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
                        color: AppColors.textSecondary(context),
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
                          final didConfirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              backgroundColor: AppColors.surface(context),
                              title: Text(
                                'Clear all sync data?',
                                style: TextStyle(
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              content: Text(
                                'This will delete all offline queue items, conflicts, and sync history. This action cannot be undone.',
                                style: TextStyle(
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          );

                          if (didConfirm == true) {
                            if (!mounted) return;
                            await _patientSyncService.resetAllData();
                            await _taskSyncService.resetAllData();
                            await _patientSyncService.refreshSyncStatus();
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
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
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

  Widget _medicalVisionCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/medical-vision'),
        child: GlassContainer(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(18),
          blur: 18,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF14B8A6).withValues(alpha: 0.12),
                    const Color(0xFF0EA5E9).withValues(alpha: 0.06),
                  ]
                : [
                    const Color(0xFF14B8A6).withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.55),
                  ],
          ),
          border: Border.all(
            color: const Color(0xFF14B8A6).withValues(alpha: 0.35),
            width: 1.5,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14B8A6), Color(0xFF0EA5E9)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'AI Medical Vision',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0EA5E9,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'NEW',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? const Color(0xFF38BDF8)
                                  : const Color(0xFF0284C7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scan prescriptions & lab reports to extract medicines, values & summaries',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                        context, '/medical-vision-history'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF14B8A6)
                            .withValues(alpha: isDark ? 0.18 : 0.12),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: Color(0xFF14B8A6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textSecondary(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
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
              color: AppColors.textSecondary(context),
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
        final loading = ref.watch(patientListProvider.select((s) => s.loading));
        final allEmpty = ref.watch(
          patientListProvider.select((s) => s.patients.isEmpty),
        );
        final visiblePatients = ref.watch(recentPatientsProvider);

        if (loading && allEmpty) {
          return _buildRecentPatientsSkeleton();
        }

        if (allEmpty) {
          return Center(child: Text(context.l10n.tr('home.noPatientsFound')));
        }

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
    final baseColor = AppColors.shimmerBase(context);
    final highlightColor = AppColors.shimmerHighlight(context);

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
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border(context)),
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
    final baseColor = AppColors.shimmerBase(context);
    final highlightColor = AppColors.shimmerHighlight(context);

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
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
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

  Widget _skeletonBox(
    double width,
    double height,
    Color color, {
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

  Widget _patientCard(Patient patient) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final imageProvider = _resolvePatientImage(patient.photoPath);

    return RepaintBoundary(
      child: GestureDetector(
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

      child: GlassContainer(
        width: 150,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        borderRadius: BorderRadius.circular(18),
        blur: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.teal.withValues(
                alpha: isDark ? 0.15 : 0.12,
              ),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Icon(Icons.person_rounded, color: AppColors.brand(context))
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
                color: AppColors.textPrimary(context),
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
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              [
                if (patient.caste.trim().isNotEmpty) patient.caste.trim(),
                if (patient.phoneNumber.trim().isNotEmpty)
                  patient.phoneNumber.trim(),
              ].join('  •  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary(context),
              ),
            ),
            if (patient.isPregnant ||
                patient.activeDiseaseLabels.isNotEmpty) ...[
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
                  color: AppColors.textSecondary(context),
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
                color: AppColors.textSecondary(context),
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.teal, AppColors.accentCyan],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.tr('common.view'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  ImageProvider? _resolvePatientImage(String? photo) {
    if (photo == null || photo.isEmpty) return null;

    final cached = _imageProviderCache[photo];
    if (cached != null) return cached;

    final normalizedPhoto = photo.replaceAll('\\', '/');
    final isWindowsAbsolutePath = RegExp(r'^[A-Za-z]:[/\\]').hasMatch(photo);

    ImageProvider? provider;
    if (normalizedPhoto.contains('/uploads/')) {
      provider = NetworkImage("${AppConfig.apiBaseUrl}$normalizedPhoto");
    } else if ((photo.startsWith('/') && !photo.startsWith('/uploads/')) ||
        isWindowsAbsolutePath) {
      // Local device path. existsSync() is synchronous disk I/O, so it must
      // never run during build — resolve it once off-frame and cache below.
      final pending = _pendingLocalChecks;
      if (!pending.contains(photo)) {
        pending.add(photo);
        scheduleMicrotask(() async {
          final exists = await File(photo).exists();
          if (!mounted) return;
          setState(() {
            _imageProviderCache[photo] = exists ? FileImage(File(photo)) : null;
          });
        });
      }
      return null;
    } else if (photo.startsWith('http')) {
      provider = NetworkImage(photo);
    } else {
      provider = NetworkImage("${AppConfig.apiBaseUrl}/$normalizedPhoto");
    }

    _imageProviderCache[photo] = provider;
    return provider;
  }

  final Map<String, ImageProvider?> _imageProviderCache = {};
  final Set<String> _pendingLocalChecks = {};

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
    final l10n = context.l10n;
    final currentCode =
        ref.watch(appLocaleProvider).valueOrNull?.languageCode ?? 'en';

    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(20),
      blur: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.tr('home.settings'),
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.translate, color: AppColors.brand(context)),
            title: Text(l10n.tr('home.language')),
            trailing: Text(
              AppLocalizations.nativeLanguageNames[currentCode] ?? 'Hindi',
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
            onTap: _showLanguageSelector,
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguageSelector() async {
    final currentLocale =
        ref.read(appLocaleProvider).valueOrNull ?? const Locale('en');
    String selectedCode = currentLocale.languageCode;
    final l10n = context.l10n;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      clipBehavior: Clip.none,
      builder: (modalContext) {
        final isDarkSheet = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final media = MediaQuery.of(modalContext);
            final maxHeight = media.size.height * 0.86;

            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: SafeArea(
                  top: false,
                  child: Container(
                    height: maxHeight,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDarkSheet
                            ? [
                                const Color(0xFF0E1A20).withValues(alpha: 0.92),
                                const Color(0xFF0B1318).withValues(alpha: 0.96),
                              ]
                            : [
                                const Color(0xFFEAF7F5).withValues(alpha: 0.88),
                                Colors.white.withValues(alpha: 0.80),
                              ],
                      ),
                      border: Border(
                        top: BorderSide(
                          color: isDarkSheet
                              ? AppColors.teal.withValues(alpha: 0.30)
                              : AppColors.teal.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDarkSheet ? 0.5 : 0.12,
                          ),
                          blurRadius: 40,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle pill
                          Center(
                            child: Container(
                              width: 44,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isDarkSheet
                                    ? Colors.white.withValues(alpha: 0.20)
                                    : AppColors.teal.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Title
                          Center(
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      AppColors.teal,
                                      AppColors.accentCyan,
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    l10n.tr('common.selectLanguage'),
                                    style: GoogleFonts.outfit(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  l10n.tr('common.languageHint'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDarkSheet
                                        ? const Color(0xFF8A9BAA)
                                        : const Color(0xFF5A6878),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Divider
                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  isDarkSheet
                                      ? AppColors.teal.withValues(alpha: 0.35)
                                      : AppColors.teal.withValues(alpha: 0.30),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Language list
                          Expanded(
                            child: ListView.separated(
                              itemCount: supportedLanguageCodes.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (listContext, index) {
                                final code = supportedLanguageCodes[index];
                                final isSelected = selectedCode == code;
                                return GestureDetector(
                                  onTap: () =>
                                      setSheetState(() => selectedCode = code),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutCubic,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        colors: isSelected
                                            ? [
                                                AppColors.teal.withValues(
                                                  alpha: isDarkSheet
                                                      ? 0.30
                                                      : 0.18,
                                                ),
                                                AppColors.accentCyan.withValues(
                                                  alpha: isDarkSheet
                                                      ? 0.15
                                                      : 0.10,
                                                ),
                                              ]
                                            : [
                                                Colors.white.withValues(
                                                  alpha: isDarkSheet
                                                      ? 0.06
                                                      : 0.45,
                                                ),
                                                Colors.white.withValues(
                                                  alpha: isDarkSheet
                                                      ? 0.03
                                                      : 0.25,
                                                ),
                                              ],
                                      ),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.teal.withValues(
                                                alpha: isDarkSheet
                                                    ? 0.55
                                                    : 0.65,
                                              )
                                            : (isDarkSheet
                                                  ? Colors.white.withValues(
                                                      alpha: 0.07,
                                                    )
                                                  : AppColors.teal.withValues(
                                                      alpha: 0.15,
                                                    )),
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? AppColors.teal
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.teal
                                                  : (isDarkSheet
                                                        ? const Color(
                                                            0xFF6A7D8A,
                                                          )
                                                        : const Color(
                                                            0xFF9AABB8,
                                                          )),
                                              width: 2,
                                            ),
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 13,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                AppLocalizations
                                                        .nativeLanguageNames[code] ??
                                                    code,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  color: isSelected
                                                      ? (isDarkSheet
                                                            ? AppColors
                                                                  .accentCyan
                                                            : AppColors.teal)
                                                      : (isDarkSheet
                                                            ? const Color(
                                                                0xFFD2DDE8,
                                                              )
                                                            : const Color(
                                                                0xFF1E2830,
                                                              )),
                                                ),
                                              ),
                                              Text(
                                                AppLocalizations
                                                        .nativeLanguageScripts[code] ??
                                                    '',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDarkSheet
                                                      ? const Color(0xFF7A8D9A)
                                                      : const Color(0xFF7A8D9A),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      Navigator.pop(modalContext, false),
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDarkSheet
                                            ? Colors.white.withValues(
                                                alpha: 0.15,
                                              )
                                            : AppColors.teal.withValues(
                                                alpha: 0.35,
                                              ),
                                      ),
                                      color: isDarkSheet
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.white.withValues(
                                              alpha: 0.50,
                                            ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        l10n.tr('common.cancel'),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDarkSheet
                                              ? const Color(0xFFB0C0CC)
                                              : const Color(0xFF3A5060),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GlassButton(
                                  label: l10n.tr('common.confirmSelection'),
                                  height: 52,
                                  onPressed: () =>
                                      Navigator.pop(modalContext, true),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
      final locale = Locale(selectedCode);
      await ref.read(appLocaleProvider.notifier).setLocale(locale);
    }
  }
}

/// A sync icon that actually rotates while a sync is in progress.
/// (Replaces a fake `AlwaysStoppedAnimation(DateTime.now()…)` that never spun.)
class _SpinningSyncIcon extends StatefulWidget {
  const _SpinningSyncIcon({
    this.color = const Color(0xFF0EA5E9),
    this.size = 20,
  });

  final Color color;
  final double size;

  @override
  State<_SpinningSyncIcon> createState() => _SpinningSyncIconState();
}

class _SpinningSyncIconState extends State<_SpinningSyncIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(Icons.sync, color: widget.color, size: widget.size),
    );
  }
}
