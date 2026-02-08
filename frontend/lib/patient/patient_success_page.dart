import 'package:flutter/material.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.check_circle,
              color: Color(0xFF00A6A6),
              size: 96,
            ),
            SizedBox(height: 24),
            Text(
              "Patient Saved",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Details recorded successfully",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
