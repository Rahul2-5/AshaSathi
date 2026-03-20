import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/auth/cubit/login_cubit.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await context.read<LoginCubit>().initializeAuth();
    } catch (_) {}

    // Keep the splash visible for a short moment so users see the logo
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    final token = context.read<LoginCubit>().state.token;

    if (token != null) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Image.asset(
            'assets/images/splash1.png',
            width: size.width * 0.6,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
