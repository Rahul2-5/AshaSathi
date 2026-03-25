import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/cubit/login_cubit.dart';
import '../auth/cubit/patient_cubit.dart';
import '../localization/app_localizations.dart';
import 'patient_offline_dao.dart';
import 'patient_offline_entity.dart';
import 'patient_sync_service.dart';

class PatientSyncConflictsPage extends StatefulWidget {
  const PatientSyncConflictsPage({super.key});

  @override
  State<PatientSyncConflictsPage> createState() => _PatientSyncConflictsPageState();
}

class _PatientSyncConflictsPageState extends State<PatientSyncConflictsPage> {
  final PatientOfflineDao _dao = PatientOfflineDao();
  final PatientSyncService _syncService = PatientSyncService();

  bool _loading = true;
  List<PatientOfflineEntity> _conflicts = const [];

  @override
  void initState() {
    super.initState();
    _loadConflicts();
  }

  Future<void> _loadConflicts() async {
    setState(() => _loading = true);
    final conflicts = await _dao.getConflicts();
    if (!mounted) return;
    setState(() {
      _conflicts = conflicts;
      _loading = false;
    });
  }

  Future<void> _keepLocal(PatientOfflineEntity entity) async {
    final token = context.read<LoginCubit>().state.token;
    final patientCubit = context.read<PatientCubit>();
    final successMessage = context.l10n.tr('sync.conflictResolvedLocal');
    final localId = entity.localId;
    if (token == null || localId == null) return;

    try {
      await _syncService.resolveConflictKeepLocal(localId: localId, token: token);
      if (!mounted) return;
      await patientCubit.loadPatients(token);
      await _loadConflicts();
      _showSnackBar(successMessage);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('$e', isError: true);
    }
  }

  Future<void> _keepServer(PatientOfflineEntity entity) async {
    final token = context.read<LoginCubit>().state.token;
    final patientCubit = context.read<PatientCubit>();
    final successMessage = context.l10n.tr('sync.conflictResolvedServer');
    final localId = entity.localId;
    if (localId == null) return;

    try {
      await _syncService.resolveConflictKeepServer(localId: localId);
      if (!mounted) return;
      if (token != null) {
        await patientCubit.loadPatients(token);
      }
      await _loadConflicts();
      _showSnackBar(successMessage);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('$e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tr('sync.conflictsTitle')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conflicts.isEmpty
              ? Center(
                  child: Text(
                    context.l10n.tr('sync.noConflicts'),
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF9EABB7)
                          : const Color(0xFF6C7580),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConflicts,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conflicts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final conflict = _conflicts[index];
                      final server = _serverPayload(conflict);
                      return _ConflictCard(
                        conflict: conflict,
                        server: server,
                        onKeepLocal: () => _keepLocal(conflict),
                        onKeepServer: () => _keepServer(conflict),
                      );
                    },
                  ),
                ),
    );
  }

  Map<String, dynamic> _serverPayload(PatientOfflineEntity entity) {
    final raw = (entity.conflictServerPayload ?? '').trim();
    if (raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return const {};
    }
    return const {};
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({
    required this.conflict,
    required this.server,
    required this.onKeepLocal,
    required this.onKeepServer,
  });

  final PatientOfflineEntity conflict;
  final Map<String, dynamic> server;
  final VoidCallback onKeepLocal;
  final VoidCallback onKeepServer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A232C) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE67E22).withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFE67E22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  conflict.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1F252B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _fieldRow(
            context.l10n.tr('sync.localValue'),
            '${conflict.phoneNumber} | ${conflict.address}',
          ),
          _fieldRow(
            context.l10n.tr('sync.serverValue'),
            '${server['phoneNumber'] ?? '-'} | ${server['address'] ?? '-'}',
          ),
          _fieldRow(
            context.l10n.tr('sync.localNotes'),
            conflict.description.trim().isEmpty ? '-' : conflict.description,
          ),
          _fieldRow(
            context.l10n.tr('sync.serverNotes'),
            '${server['description'] ?? '-'}',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onKeepServer,
                  child: Text(context.l10n.tr('sync.keepServer')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14A7A0),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onKeepLocal,
                  child: Text(context.l10n.tr('sync.keepLocal')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '$label: $value',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
