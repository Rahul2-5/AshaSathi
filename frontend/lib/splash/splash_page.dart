import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/auth/cubit/login_cubit.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final AnimationController _loopController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _tiltAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _floatAnimation = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(
        parent: _loopController,
        curve: Curves.easeInOut,
      ),
    );
    _tiltAnimation = Tween<double>(begin: -0.015, end: 0.015).animate(
      CurvedAnimation(
        parent: _loopController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    _loopController.repeat(reverse: true);
    _initialize();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await context.read<LoginCubit>().initializeAuth();
    } catch (_) {}

    // Keep the splash visible for a short moment so users can feel the motion.
    await Future.delayed(const Duration(milliseconds: 1200));

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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: AnimatedBuilder(
                animation: _loopController,
                builder: (context, child) {
                  final wave = (math.sin(_loopController.value * math.pi * 2) + 1) / 2;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: Transform.rotate(
                          angle: _tiltAnimation.value,
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Image.asset(
                              'assets/images/splash1.png',
                              width: size.width * 0.6,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _LoadingDots(
                        progress: wave,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final phase = ((progress + (index * 0.22)) % 1.0);
        final opacity = 0.25 + (phase * 0.75);
        final scale = 0.8 + (phase * 0.35);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
