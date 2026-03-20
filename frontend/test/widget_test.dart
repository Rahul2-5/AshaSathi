import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/auth/cubit/login_cubit.dart';
import 'package:frontend/auth/cubit/patient_cubit.dart';
import 'package:frontend/auth/cubit/signup_cubit.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/patient_service.dart';
import 'package:frontend/services/task_service.dart';
import 'package:frontend/task/task_cubit.dart';

void main() {
  testWidgets('MyApp renders splash shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => LoginCubit(AuthService())),
          BlocProvider(create: (_) => SignupCubit(AuthService())),
          BlocProvider(create: (_) => TaskCubit(TaskService())),
          BlocProvider(create: (_) => PatientCubit(PatientService())),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.byType(MyApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.byType(MyApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
