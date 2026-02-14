import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/auth/cubit/patient_cubit.dart';
import 'package:frontend/task/task_cubit.dart';

import '../home/home_page.dart';
import '../patient/add_patient_page.dart';
import '../phc_dashboard/phc_dashboard_page.dart';
import '../auth/cubit/login_cubit.dart';

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
    PhcDashboardPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _getPageTitle(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: _buildDrawer(context),
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF00A6A6),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          // When navigating back to Home, refresh patients/tasks
          if (index == 0) {
            final token = context.read<LoginCubit>().state.token;
            if (token != null) {
              // reload patients to reflect any recent changes
              context.read<PatientCubit>().loadPatients(token);
              context.read<TaskCubit>().loadTasks(token);
            }
          }
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

  String _getPageTitle() {
    switch (_currentIndex) {
      case 0:
        return "ASHA Dashboard";
      case 1:
        return "Patient Visit";
      case 2:
        return "PHC Dashboard";
      default:
        return "AshaSathi";
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF00A6A6),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  "AshaSathi",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () async {
              Navigator.pop(context); // Close drawer
              await context.read<LoginCubit>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}