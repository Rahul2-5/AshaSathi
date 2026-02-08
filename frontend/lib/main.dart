import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/auth/cubit/patient_cubit.dart';
import 'package:frontend/services/patient_service.dart';

import 'auth/cubit/login_cubit.dart';
import 'auth/cubit/signup_cubit.dart';
import 'auth/login_page.dart';

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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginView(),
    );
  }
}
