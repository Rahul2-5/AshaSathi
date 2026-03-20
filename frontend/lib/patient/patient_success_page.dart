import 'package:flutter/material.dart';
import 'package:frontend/localization/app_localizations.dart';

class PatientSuccessPage extends StatefulWidget {
  const PatientSuccessPage({super.key});

  @override
  State<PatientSuccessPage> createState() => _PatientSuccessPageState();
}

class _PatientSuccessPageState extends State<PatientSuccessPage> {
  @override
  void initState() {
    super.initState();

    // ⏱ Auto close after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF00A6A6),
              size: 96,
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.tr('patient.saved'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1F252B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.tr('patient.savedDetails'),
              style: TextStyle(
                color: isDark ? const Color(0xFFA6B3BF) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
