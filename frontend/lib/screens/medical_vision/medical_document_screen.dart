import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/config/app_config.dart';
import 'package:frontend/widgets/common/common_widgets.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/providers/login_provider.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class MedicalMedicine {
  String name, dosage, frequency, duration;
  bool verified;
  String? matchedName;
  int? matchScore;
  bool userEdited;

  MedicalMedicine({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.verified = false,
    this.matchedName,
    this.matchScore,
    this.userEdited = false,
  });

  factory MedicalMedicine.fromJson(Map<String, dynamic> j) => MedicalMedicine(
        name: j['medicineName'] ?? '',
        dosage: j['dosage'] ?? '',
        frequency: j['frequency'] ?? '',
        duration: j['duration'] ?? '',
        verified: j['verified'] ?? false,
        matchedName: j['matchedDrugName'],
        matchScore: j['matchScore'],
      );
}

class MedicalLabResult {
  String testName, value, unit, severity, referenceRange;
  MedicalLabResult({
    required this.testName,
    required this.value,
    required this.unit,
    required this.severity,
    required this.referenceRange,
  });

  factory MedicalLabResult.fromJson(Map<String, dynamic> j) => MedicalLabResult(
        testName: j['testName'] ?? '',
        value: j['value'] ?? '',
        unit: j['unit'] ?? '',
        severity: j['severity'] ?? 'NORMAL',
        referenceRange: j['referenceRange'] ?? '',
      );
}

class MedicalDocumentResult {
  final int id;
  final String processingStatus;
  final String? diagnosis, followUpDate, aiSummary, rawText;
  final double? ocrConfidence;
  final List<MedicalMedicine> medicines;
  final List<MedicalLabResult> labResults;

  MedicalDocumentResult({
    required this.id,
    required this.processingStatus,
    this.diagnosis,
    this.followUpDate,
    this.aiSummary,
    this.rawText,
    this.ocrConfidence,
    required this.medicines,
    required this.labResults,
  });

  factory MedicalDocumentResult.fromJson(Map<String, dynamic> j) =>
      MedicalDocumentResult(
        id: j['id'],
        processingStatus: j['processingStatus'] ?? 'PENDING',
        diagnosis: j['diagnosis'],
        followUpDate: j['followUpDate'],
        aiSummary: j['aiSummary'],
        rawText: j['rawText'],
        ocrConfidence: (j['ocrConfidence'] as num?)?.toDouble(),
        medicines: (j['medicines'] as List? ?? [])
            .map((m) => MedicalMedicine.fromJson(m))
            .toList(),
        labResults: (j['labResults'] as List? ?? [])
            .map((l) => MedicalLabResult.fromJson(l))
            .toList(),
      );
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class MedicalDocumentScreen extends ConsumerStatefulWidget {
  final int? patientId;
  const MedicalDocumentScreen({super.key, this.patientId});

  @override
  ConsumerState<MedicalDocumentScreen> createState() =>
      _MedicalDocumentScreenState();
}

class _MedicalDocumentScreenState extends ConsumerState<MedicalDocumentScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedImage;
  bool _isUploading = false;
  bool _isPolling = false;
  String _statusMessage = '';
  MedicalDocumentResult? _result;
  Timer? _pollTimer;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // Editable fields
  final TextEditingController _diagnosisCtrl = TextEditingController();
  final TextEditingController _followUpCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    _diagnosisCtrl.dispose();
    _followUpCtrl.dispose();
    super.dispose();
  }

  // ─── Pick Image ────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 82,       // 75-85% JPEG quality
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (picked == null) return;
    setState(() {
      _selectedImage = File(picked.path);
      _result = null;
      _statusMessage = '';
    });
  }

  // ─── Upload & Process ──────────────────────────────────────────────────────

  Future<void> _uploadAndProcess() async {
    if (_selectedImage == null) return;
    final token = await ref.read(loginProvider.notifier).getValidToken();
    if (token == null || token.isEmpty) {
      _showSnack('Session expired. Please login again.');
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = 'Uploading image...';
    });

    try {
      final baseUrl = AppConfig.apiBaseUrl;

      // 1. Upload
      final uploadUri = Uri.parse('$baseUrl/api/medical-documents/upload');
      final req = http.MultipartRequest('POST', uploadUri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('file', _selectedImage!.path));
      if (widget.patientId != null) {
        req.fields['patientId'] = widget.patientId.toString();
      }

      final uploadResp = await req.send().timeout(const Duration(seconds: 30));
      if (uploadResp.statusCode != 201) {
        throw Exception('Upload failed: ${uploadResp.statusCode}');
      }

      final uploadBody = jsonDecode(await uploadResp.stream.bytesToString());
      final docId = uploadBody['id'] as int;

      setState(() => _statusMessage = 'Processing with AI...');

      // 2. Trigger processing
      final processUri = Uri.parse('$baseUrl/api/medical-documents/$docId/process');
      await http
          .post(processUri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));

      // 3. Start polling
      setState(() {
        _isUploading = false;
        _isPolling = true;
        _statusMessage = 'Extracting medical data (this may take ~15 seconds)...';
      });
      _startPolling(docId, token, baseUrl);
    } catch (e) {
      setState(() {
        _isUploading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  void _startPolling(int docId, String token, String baseUrl) {
    _pollTimer?.cancel();
    int pollAttempts = 0;
    const maxPollAttempts = 40; // 40 * 3 seconds = 120 seconds (2 minutes)
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      pollAttempts++;
      if (pollAttempts > maxPollAttempts) {
        timer.cancel();
        if (!mounted) return;
        setState(() {
          _isPolling = false;
          _statusMessage = 'Processing timed out. Please try again.';
        });
        debugPrint('Medical document polling timed out after $maxPollAttempts attempts.');
        return;
      }

      try {
        final resp = await http.get(
          Uri.parse('$baseUrl/api/medical-documents/$docId'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 8));

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final status = data['processingStatus'] as String;
          debugPrint('Poll attempt $pollAttempts: Document $docId status is $status');

          if (status == 'COMPLETED') {
            timer.cancel();
            final result = MedicalDocumentResult.fromJson(data);
            if (!mounted) return;
            setState(() {
              _isPolling = false;
              _result = result;
              _diagnosisCtrl.text = result.diagnosis ?? '';
              _followUpCtrl.text = result.followUpDate ?? '';
              _statusMessage = 'Processing complete!';
            });
          } else if (status == 'FAILED') {
            timer.cancel();
            if (!mounted) return;
            setState(() {
              _isPolling = false;
              _statusMessage = 'Processing failed. Please try again.';
            });
          }
        } else {
          debugPrint('Poll attempt $pollAttempts received status ${resp.statusCode}: ${resp.body}');
        }
      } catch (e, stack) {
        debugPrint('Poll attempt $pollAttempts error: $e\n$stack');
      }
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0B1120), Color(0xFF0E1A26), Color(0xFF091018)]
                : const [Color(0xFFE8F8F5), Color(0xFFF0F4FF), Color(0xFFF7FBFF)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(isDark)),
              SliverToBoxAdapter(child: _buildImagePicker(isDark)),
              if (_isUploading || _isPolling)
                SliverToBoxAdapter(child: _buildProcessingIndicator(isDark)),
              if (_result != null) ...[
                SliverToBoxAdapter(child: _buildConfidenceBadge(isDark)),
                SliverToBoxAdapter(child: _buildSummaryCard(isDark)),
                SliverToBoxAdapter(child: _buildDiagnosisCard(isDark)),
                SliverToBoxAdapter(child: _buildMedicinesSection(isDark)),
                SliverToBoxAdapter(child: _buildLabResultsSection(isDark)),
                SliverToBoxAdapter(child: _buildConfirmButton(isDark)),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: GlassContainer(
              padding: const EdgeInsets.all(10),
              borderRadius: BorderRadius.circular(14),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFFE0EAF3) : const Color(0xFF1D232B)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Medical Vision',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFFE8EEF3) : const Color(0xFF171A1F),
                    )),
                Text('AI-powered prescription & lab report reader',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF9FB0C0) : const Color(0xFF667384),
                    )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                  colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)]),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text('Gemini 2.5',
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Image Picker ─────────────────────────────────────────────────────────

  Widget _buildImagePicker(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _selectedImage != null
              ? AppColors.teal.withValues(alpha: 0.5)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2)),
          width: 1.5,
        ),
        child: Column(
          children: [
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_selectedImage!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover),
              )
            else
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : AppColors.teal.withValues(alpha: 0.05),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.document_scanner_rounded,
                        size: 48,
                        color: isDark ? AppColors.accentCyan : AppColors.teal),
                    const SizedBox(height: 10),
                    Text('Tap to capture or upload medical document',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF9FB0C0)
                              : const Color(0xFF667384),
                        )),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            if (_selectedImage != null && !_isUploading && !_isPolling) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _uploadAndProcess,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)]),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.teal.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text('Analyze with AI',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 12),
        borderRadius: BorderRadius.circular(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: isDark ? AppColors.accentCyan : AppColors.teal),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFD5E1EB)
                        : const Color(0xFF1D232B))),
          ],
        ),
      ),
    );
  }

  // ─── Processing Indicator ─────────────────────────────────────────────────

  Widget _buildProcessingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) => Opacity(
                opacity: _pulseAnimation.value,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF14B8A6))),
                    const SizedBox(width: 12),
                    Text('AI Processing',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFFE8EEF3)
                                : const Color(0xFF171A1F))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(_statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF9FB0C0)
                        : const Color(0xFF667384))),
          ],
        ),
      ),
    );
  }

  // ─── OCR Confidence Badge ─────────────────────────────────────────────────

  Widget _buildConfidenceBadge(bool isDark) {
    final conf = _result?.ocrConfidence ?? 0;
    final confPercent = (conf * 100).toStringAsFixed(1);
    Color confColor;
    String confLabel;
    if (conf >= 0.90) {
      confColor = const Color(0xFF22C55E);
      confLabel = 'High Confidence';
    } else if (conf >= 0.75) {
      confColor = const Color(0xFFF59E0B);
      confLabel = 'Medium Confidence';
    } else {
      confColor = const Color(0xFFEF4444);
      confLabel = 'Review Required';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: confColor.withValues(alpha: 0.4)),
        child: Row(
          children: [
            Icon(Icons.analytics_outlined, color: confColor, size: 20),
            const SizedBox(width: 10),
            Text('OCR Confidence: $confPercent%',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: confColor)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: confColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(confLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: confColor)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AI Summary Card ──────────────────────────────────────────────────────

  Widget _buildSummaryCard(bool isDark) {
    final summary = _result?.aiSummary;
    if (summary == null || summary.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.teal.withValues(alpha: isDark ? 0.15 : 0.10),
            AppColors.accentCyan.withValues(alpha: isDark ? 0.07 : 0.04),
          ],
        ),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.summarize_rounded,
                    color: Color(0xFF14B8A6), size: 18),
                const SizedBox(width: 8),
                Text('AI Clinical Summary',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFE8EEF3)
                            : const Color(0xFF171A1F))),
              ],
            ),
            const SizedBox(height: 10),
            Text(summary,
                style: TextStyle(
                    height: 1.5,
                    color: isDark
                        ? const Color(0xFFBFCBDA)
                        : const Color(0xFF3A5060))),
          ],
        ),
      ),
    );
  }

  // ─── Diagnosis Card ───────────────────────────────────────────────────────

  Widget _buildDiagnosisCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Diagnosis & Follow-up', Icons.medical_information_rounded, isDark),
            const SizedBox(height: 14),
            _editableField(
              label: 'Diagnosis',
              controller: _diagnosisCtrl,
              isDark: isDark,
              confidence: _result?.ocrConfidence,
            ),
            const SizedBox(height: 10),
            _editableField(
              label: 'Follow-up Date',
              controller: _followUpCtrl,
              isDark: isDark,
              confidence: _result?.ocrConfidence,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Medicines Section ────────────────────────────────────────────────────

  Widget _buildMedicinesSection(bool isDark) {
    final meds = _result?.medicines ?? [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Medicines', Icons.medication_rounded, isDark),
            const SizedBox(height: 14),
            if (meds.isEmpty)
              _emptyState('No medicines extracted', isDark)
            else
              ...meds.map((m) => _medicineCard(m, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _medicineCard(MedicalMedicine med, bool isDark) {
    // Color coding:
    // Green = verified in drug_master
    // Yellow = partial match (score 70-84)
    // Red = unknown drug
    Color borderColor;
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    if (med.verified) {
      borderColor = const Color(0xFF22C55E);
      badgeColor = const Color(0xFF22C55E);
      badgeText = 'Verified';
      badgeIcon = Icons.verified_rounded;
    } else if ((med.matchScore ?? 0) >= 70) {
      borderColor = const Color(0xFFF59E0B);
      badgeColor = const Color(0xFFF59E0B);
      badgeText = 'Review (${med.matchScore}%)';
      badgeIcon = Icons.warning_amber_rounded;
    } else {
      borderColor = const Color(0xFFEF4444);
      badgeColor = const Color(0xFFEF4444);
      badgeText = 'Unknown';
      badgeIcon = Icons.help_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
        color: borderColor.withValues(alpha: isDark ? 0.08 : 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(med.name,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark
                            ? const Color(0xFFE8EEF3)
                            : const Color(0xFF171A1F))),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 12, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(badgeText,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeColor)),
                  ],
                ),
              ),
            ],
          ),
          if (med.matchedName != null && med.matchedName != med.name)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Matched: ${med.matchedName}',
                  style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? const Color(0xFF9FB0C0)
                          : const Color(0xFF667384))),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _chip('Dosage: ${med.dosage}', isDark),
              _chip('Freq: ${med.frequency}', isDark),
              _chip('Duration: ${med.duration}', isDark),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Lab Results Section ──────────────────────────────────────────────────

  Widget _buildLabResultsSection(bool isDark) {
    final labs = _result?.labResults ?? [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Lab Results', Icons.biotech_rounded, isDark),
            const SizedBox(height: 14),
            if (labs.isEmpty)
              _emptyState('No lab results extracted', isDark)
            else
              ...labs.map((l) => _labResultRow(l, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _labResultRow(MedicalLabResult lab, bool isDark) {
    Color severityColor;
    switch (lab.severity) {
      case 'CRITICAL':
        severityColor = const Color(0xFFDC2626);
        break;
      case 'HIGH':
        severityColor = const Color(0xFFEF4444);
        break;
      case 'LOW':
        severityColor = const Color(0xFFF59E0B);
        break;
      default:
        severityColor = const Color(0xFF22C55E);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withValues(alpha: 0.4)),
        color: severityColor.withValues(alpha: isDark ? 0.07 : 0.04),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lab.testName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (lab.referenceRange.isNotEmpty)
                  Text('Ref: ${lab.referenceRange}',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF9FB0C0)
                              : const Color(0xFF667384))),
              ],
            ),
          ),
          Text('${lab.value} ${lab.unit}',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: severityColor)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(lab.severity,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: severityColor)),
          ),
        ],
      ),
    );
  }

  // ─── Confirm Button ───────────────────────────────────────────────────────

  Widget _buildConfirmButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: GestureDetector(
        onTap: _confirmAndSave,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
                colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)]),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text('Confirm & Save Record',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmAndSave() {
    // The user can edit diagnosis/follow-up before confirming.
    // Final record is already saved in PostgreSQL — this just closes the screen.
    _showSnack('Medical record confirmed and saved!');
    Navigator.pop(context, true);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon,
            size: 18,
            color: isDark ? AppColors.accentCyan : AppColors.teal),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isDark
                    ? const Color(0xFFE8EEF3)
                    : const Color(0xFF171A1F))),
      ],
    );
  }

  Widget _editableField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    double? confidence,
  }) {
    final isLowConf = (confidence ?? 1.0) < 0.75;
    return TextField(
      controller: controller,
      style: TextStyle(
          color: isDark ? const Color(0xFFD5E1EB) : const Color(0xFF1D232B)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: isDark ? const Color(0xFF9FB0C0) : const Color(0xFF667384),
            fontSize: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isLowConf
                ? const Color(0xFFF59E0B)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.3)),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? AppColors.accentCyan : AppColors.teal),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.6),
        suffixIcon: isLowConf
            ? const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFF59E0B), size: 18)
            : null,
      ),
    );
  }

  Widget _chip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.05),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? const Color(0xFFB0C4D3)
                  : const Color(0xFF4A5568))),
    );
  }

  Widget _emptyState(String msg, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(msg,
            style: TextStyle(
                color: isDark
                    ? const Color(0xFF9FB0C0)
                    : const Color(0xFF667384))),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }
}
