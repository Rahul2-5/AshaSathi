import 'package:flutter/material.dart';

import '../home/home_page.dart';
import '../patient/add_patient_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    AddPatientPage(),
    Placeholder(), // PHC Dashboard (later)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF00A6A6),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "ASHA Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: "Add Patient",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "PHC Dashboard",
          ),
        ],
      ),
    );
  }
}
