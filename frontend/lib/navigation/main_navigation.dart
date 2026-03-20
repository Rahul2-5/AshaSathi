import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/auth/cubit/patient_cubit.dart';
import 'package:frontend/task/task_cubit.dart';
import 'package:frontend/localization/app_localizations.dart';

import '../home/home_page.dart';
import '../patient/add_patient_page.dart';
import '../phc_dashboard/phc_dashboard_page.dart';
import '../auth/cubit/login_cubit.dart';
import '../main.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final AnimationController _drawerContentController;
  late final Animation<double> _drawerFadeAnimation;
  late final Animation<Offset> _drawerSlideAnimation;

  final List<Widget> _pages = const [
    HomePage(),
    AddPatientPage(),
    PhcDashboardPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _drawerContentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _drawerFadeAnimation = CurvedAnimation(
      parent: _drawerContentController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic,
    );
    _drawerSlideAnimation = Tween<Offset>(
      begin: const Offset(-0.08, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _drawerContentController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _drawerContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeModeNotifier = ThemeModeController.notifierOf(context);
    final l10n = context.l10n;

    return Scaffold(
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          _drawerContentController.forward(from: 0);
        } else {
          _drawerContentController.reverse();
        }
      },
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0.6,
        scrolledUnderElevation: 0.8,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          reverseDuration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey('appbar-title-$_currentIndex-$isDark'),
            child: _buildAppBarTitle(isDark),
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? const Color(0xFFD3DEE8) : const Color(0xFF494D53),
        ),
        actions: _currentIndex == 0
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedContainer(
                    width: 36,
                    height: 36,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2A35)
                          : const Color(0xFFE9F3F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: () {
                        themeModeNotifier.value = isDark
                            ? ThemeMode.light
                            : ThemeMode.dark;
                      },
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, animation) => RotationTransition(
                          turns: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                          child: FadeTransition(opacity: animation, child: child),
                        ),
                        child: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          key: ValueKey<bool>(isDark),
                          size: 20,
                          color: isDark
                              ? const Color(0xFFFFD166)
                              : const Color(0xFF1D2127),
                        ),
                      ),
                      tooltip: isDark
                          ? l10n.tr('theme.switchToLight')
                          : l10n.tr('theme.switchToDark'),
                      padding: EdgeInsets.zero,
                      splashRadius: 20,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      drawer: _buildDrawer(context),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          if (!mounted) return;
          setState(() => _currentIndex = index);
        },
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: isDark
          ? const Color(0xFF10171E)
          : const Color(0xFFF7F7F8),
        selectedItemColor: const Color(0xFF4DC982),
        unselectedItemColor:
          isDark ? const Color(0xFF8FA0B0) : const Color(0xFF8E949C),
        selectedFontSize: 12,
        unselectedFontSize: 11,
        type: BottomNavigationBarType.fixed,
        onTap: (index) async {
          if (_currentIndex == index) return;
          final token = context.read<LoginCubit>().state.token;
          final patientCubit = context.read<PatientCubit>();
          final taskCubit = context.read<TaskCubit>();

          await _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );

          // When navigating back to Home, refresh patients/tasks
          if (index == 0) {
            if (token != null) {
              // reload patients to reflect any recent changes
              patientCubit.loadPatients(token);
              taskCubit.loadTasks(token);
            }
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: l10n.tr('nav.dashboard'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_alt_1_outlined),
            activeIcon: Icon(Icons.person_add_alt_1),
            label: l10n.tr('nav.addPatient'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart_outlined_rounded),
            activeIcon: Icon(Icons.insert_chart_rounded),
            label: l10n.tr('nav.phcPortal'),
          ),
        ],
      ),
    );
  }

  String _getPageTitle(BuildContext context) {
    final l10n = context.l10n;
    switch (_currentIndex) {
      case 0:
        return l10n.tr('nav.dashboardTitle');
      case 1:
        return l10n.tr('nav.addPatient');
      case 2:
        return l10n.tr('nav.phcPortal');
      default:
        return l10n.tr('app.name');
    }
  }

  Widget _buildAppBarTitle(bool isDark) {
    if (_currentIndex != 0) {
      return AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        style: TextStyle(
          color: isDark ? const Color(0xFFDCE6EF) : const Color(0xFF23262B),
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        child: Text(_getPageTitle(context)),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          width: 28,
          height: 28,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFFDCE6EF) : const Color(0xFF1E2228),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.monitor_heart_outlined,
            size: 18,
            color: isDark ? const Color(0xFF1E2228) : Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            color: isDark ? const Color(0xFFDCE6EF) : const Color(0xFF1F2329),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            fontSize: 14,
          ),
          child: Text(context.l10n.tr('nav.dashboard').toUpperCase()),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1A232C) : Colors.white,
      child: SlideTransition(
        position: _drawerSlideAnimation,
        child: FadeTransition(
          opacity: _drawerFadeAnimation,
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF22303C)
                      : const Color(0xFF00A6A6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person, size: 48, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      "AshaSathi",
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFE6EDF3)
                            : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  context.l10n.tr('drawer.logout'),
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFE6EDF3)
                        : const Color(0xFF1F252B),
                  ),
                ),
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
        ),
      ),
    );
  }
}