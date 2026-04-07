import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth/login_page.dart';
import 'localization/app_localizations.dart';
import 'localization/language_controller.dart';
import 'navigation/main_navigation.dart';
import 'splash/splash_page.dart';
import 'providers/login_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: MyApp(),
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

class _AppRoot extends ConsumerStatefulWidget {
  const _AppRoot();

  @override
  ConsumerState<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<_AppRoot> {
  late final ValueNotifier<ThemeMode> _themeMode;
  late final ValueNotifier<Locale> _locale;

  @override
  void initState() {
    super.initState();
    _themeMode = ValueNotifier(ThemeMode.system);
    _locale = ValueNotifier(const Locale('en'));
    _loadSavedLocale();
    _initializeAuth();
  }

  Future<void> _loadSavedLocale() async {
    final savedLocale = await LanguageStorage.loadLocale();
    if (!mounted) return;
    _locale.value = savedLocale;
  }

  Future<void> _initializeAuth() async {
    final loginNotifier = ref.read(loginProvider.notifier);
    await loginNotifier.initializeAuth();
  }

  @override
  void dispose() {
    _themeMode.dispose();
    _locale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LanguageController(
      notifier: _locale,
      child: ThemeModeController(
        notifier: _themeMode,
        child: ValueListenableBuilder<Locale>(
          valueListenable: _locale,
          builder: (context, locale, _) {
            return ValueListenableBuilder<ThemeMode>(
              valueListenable: _themeMode,
              builder: (context, mode, _) {
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
                  themeMode: mode,
                  themeAnimationDuration: const Duration(milliseconds: 820),
                  themeAnimationCurve: Curves.easeInOutCubicEmphasized,
                  theme: _lightTheme(),
                  darkTheme: _darkTheme(),
                  home: const SplashPage(),
                  routes: {
                    '/main': (_) => const MainNavigation(),
                    '/login': (_) => const LoginView(),
                  },
                );
              },
            );
          },
        ),
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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SmoothPageTransitionsBuilder(),
          TargetPlatform.iOS: _SmoothPageTransitionsBuilder(),
          TargetPlatform.linux: _SmoothPageTransitionsBuilder(),
          TargetPlatform.macOS: _SmoothPageTransitionsBuilder(),
          TargetPlatform.windows: _SmoothPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _SmoothPageTransitionsBuilder(),
        },
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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SmoothPageTransitionsBuilder(),
          TargetPlatform.iOS: _SmoothPageTransitionsBuilder(),
          TargetPlatform.linux: _SmoothPageTransitionsBuilder(),
          TargetPlatform.macOS: _SmoothPageTransitionsBuilder(),
          TargetPlatform.windows: _SmoothPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _SmoothPageTransitionsBuilder(),
        },
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
    required super.child,
  }) : super(notifier: notifier);

  static ValueNotifier<ThemeMode> notifierOf(BuildContext context) {
    final controller =
        context.dependOnInheritedWidgetOfExactType<ThemeModeController>();
    assert(controller != null, 'ThemeModeController not found in widget tree');
    return controller!.notifier!;
  }
}

class _SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const beginOffset = Offset(0.06, 0);
    const endOffset = Offset.zero;
    const curve = Curves.easeOutCubic;

    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
      reverseCurve: curve,
    );

    final offsetTween = Tween<Offset>(begin: beginOffset, end: endOffset)
        .chain(CurveTween(curve: curve));

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
      child: SlideTransition(
        position: curvedAnimation.drive(offsetTween),
        child: child,
      ),
    );
  }
}

// Check if user is already logged in
class AuthCheckPage extends ConsumerStatefulWidget {
  const AuthCheckPage({super.key});

  @override
  ConsumerState<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends ConsumerState<AuthCheckPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Initialize auth (loads saved token if exists)
    await ref.read(loginProvider.notifier).initializeAuth();

    // Wait a moment then check if token was loaded
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final token = ref.read(loginProvider).token;

    if (token != null) {
      //  User is logged in → Go to MainNavigation
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);
    
    if (loginState.token != null) {
      // Navigate to home if token exists
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      });
    }

    // Show login page while checking
    return const LoginView();
  }
}
