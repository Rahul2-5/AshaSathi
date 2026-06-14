import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/app_settings_controller.dart';
import 'package:frontend/app/app_theme.dart';
import 'package:frontend/auth/login_page.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:frontend/navigation/main_navigation.dart';
import 'package:frontend/splash/splash_page.dart';

import 'package:frontend/screens/medical_vision/medical_document_screen.dart';

class AshaSathiApp extends ConsumerWidget {
  const AshaSathiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale =
        ref.watch(appLocaleProvider).valueOrNull ?? const Locale('en');
    final themeMode =
        ref.watch(appThemeModeProvider).valueOrNull ?? ThemeMode.system;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 820),
      themeAnimationCurve: Curves.easeInOutCubicEmphasized,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      scrollBehavior: const AppScrollBehavior(),
      home: const SplashPage(),
      onGenerateRoute: (settings) {
        if (settings.name == '/main') {
          final initialIndex = settings.arguments is int
              ? settings.arguments as int
              : 0;
          return MaterialPageRoute(
            builder: (_) => MainNavigation(initialIndex: initialIndex),
            settings: settings,
          );
        }

        if (settings.name == '/login') {
          return MaterialPageRoute(
            builder: (_) => const LoginView(),
            settings: settings,
          );
        }

        if (settings.name == '/medical-vision') {
          final patientId = settings.arguments is int
              ? settings.arguments as int
              : null;
          return MaterialPageRoute(
            builder: (_) => MedicalDocumentScreen(patientId: patientId),
            settings: settings,
          );
        }

        return null;
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AshaSathiApp();
  }
}