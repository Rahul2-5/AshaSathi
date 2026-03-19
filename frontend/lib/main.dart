import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/auth/cubit/patient_cubit.dart';
import 'package:frontend/services/patient_service.dart';

import 'auth/cubit/login_cubit.dart';
import 'auth/cubit/login_state.dart';
import 'auth/cubit/signup_cubit.dart';
import 'auth/login_page.dart';
import 'navigation/main_navigation.dart';
import 'splash/splash_page.dart';

import 'services/auth_service.dart';
import 'services/task_service.dart';

import 'task/task_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiBlocProvider(
      providers: [
        //  Auth
        BlocProvider(
          create: (_) => LoginCubit(AuthService()),
        ),
        BlocProvider(
          create: (_) => SignupCubit(AuthService()),
        ),

        //  Tasks
        BlocProvider(
          create: (_) => TaskCubit(TaskService()),
        ),
        BlocProvider(
        create: (_) => PatientCubit(PatientService()),
),


      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AppRoot();
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  final ValueNotifier<ThemeMode> _themeMode = ValueNotifier(ThemeMode.light);

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeModeController(
      notifier: _themeMode,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeMode,
        builder: (context, mode, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: mode,
            theme: _lightTheme(),
            darkTheme: _darkTheme(),
            home: const SplashPage(),
            routes: {
              '/main': (_) => const MainNavigation(),
              '/login': (_) => const LoginView(),
            },
          );
        },
      ),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF14A7A0),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F6F8),
        foregroundColor: Color(0xFF1F252B),
        elevation: 0,
        centerTitle: true,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F1419),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF14A7A0),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF10171E),
        foregroundColor: Color(0xFFEAF2F8),
        elevation: 0,
        centerTitle: true,
      ),
      cardColor: const Color(0xFF1A232C),
      dividerColor: const Color(0xFF28323D),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class ThemeModeController extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const ThemeModeController({
    super.key,
    required ValueNotifier<ThemeMode> notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static ValueNotifier<ThemeMode> notifierOf(BuildContext context) {
    final controller =
        context.dependOnInheritedWidgetOfExactType<ThemeModeController>();
    assert(controller != null, 'ThemeModeController not found in widget tree');
    return controller!.notifier!;
  }
}

// Check if user is already logged in
class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({super.key});

  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Initialize auth (loads saved token if exists)
    await context.read<LoginCubit>().initializeAuth();

    // Wait a moment then check if token was loaded
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final token = context.read<LoginCubit>().state.token;

    if (token != null) {
      //  User is logged in → Go to MainNavigation
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        if (state.token != null) {
          // Navigate to home if token exists
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/main');
            }
          });
        }

        // Show login page while checking
        return const LoginView();
      },
    );
  }
}
