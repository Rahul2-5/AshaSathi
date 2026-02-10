import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/auth/cubit/patient_cubit.dart';
import 'package:frontend/services/patient_service.dart';

import 'auth/cubit/login_cubit.dart';
import 'auth/cubit/login_state.dart';
import 'auth/cubit/signup_cubit.dart';
import 'auth/login_page.dart';
import 'navigation/main_navigation.dart';

import 'services/auth_service.dart';
import 'services/task_service.dart';

import 'task/task_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiBlocProvider(
      providers: [
        // 🔐 Auth
        BlocProvider(
          create: (_) => LoginCubit(AuthService()),
        ),
        BlocProvider(
          create: (_) => SignupCubit(AuthService()),
        ),

        // ✅ Tasks
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthCheckPage(),
      routes: {
        '/main': (_) => const MainNavigation(),
        '/login': (_) => const LoginView(),
      },
    );
  }
}

// 🔄 Check if user is already logged in
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
      // ✅ User is logged in → Go to MainNavigation
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
