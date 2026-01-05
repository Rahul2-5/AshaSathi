import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth/cubit/login_cubit.dart';
import 'auth/cubit/signup_cubit.dart';
import 'auth/login_page.dart';

import 'services/auth_service.dart';
import 'services/task_service.dart';

import 'task/task_cubit.dart';
import 'language/language_cubit.dart';

void main() {
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

        // 🌍 Language
        BlocProvider(
          create: (_) => LanguageCubit(),
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
    return BlocBuilder<LanguageCubit, Locale>(
      builder: (context, locale) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('mr'),
            Locale('ta'),
            Locale('te'),
            Locale('kn'),
            Locale('bn'),
          ],
          home: const LoginView(),
        );
      },
    );
  }
}
