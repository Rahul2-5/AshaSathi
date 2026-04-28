import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/login_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final AnimationController _loopController;
  late final AnimationController _orbController;
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
    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
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
    _floatAnimation = Tween<double>(begin: 0.0, end: -12.0).animate(
      CurvedAnimation(parent: _loopController, curve: Curves.easeInOut),
    );
    _tiltAnimation = Tween<double>(begin: -0.012, end: 0.012).animate(
      CurvedAnimation(parent: _loopController, curve: Curves.easeInOut),
    );
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _animationController.forward();
    _loopController.repeat(reverse: true);
    _orbController.repeat(reverse: true);
    _initialize();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loopController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await ref.read(loginProvider.notifier).initializeAuth();
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    final token = ref.read(loginProvider).token;
    if (token != null) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF0B1120), Color(0xFF0E1A26), Color(0xFF091520)]
                    : const [Color(0xFFE4F7F4), Color(0xFFEFF5FF), Color(0xFFF7FBFF)],
              ),
            ),
          ),
          // Animated orbs
          AnimatedBuilder(
            animation: _orbController,
            builder: (context, _) {
              final t = _orbController.value;
              return Stack(
                children: [
                  Positioned(
                    top: -60 + (t * 20),
                    right: -40 + (t * 15),
                    child: _buildOrb(
                      250,
                      isDark
                          ? const Color(0xFF14A7A0).withValues(alpha: 0.15)
                          : const Color(0xFF14A7A0).withValues(alpha: 0.22),
                    ),
                  ),
                  Positioned(
                    bottom: -80 - (t * 20),
                    left: -60 + (t * 10),
                    child: _buildOrb(
                      300,
                      isDark
                          ? const Color(0xFF2ED1B0).withValues(alpha: 0.08)
                          : const Color(0xFF2ED1B0).withValues(alpha: 0.14),
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.4,
                    right: -100 + (t * 30),
                    child: _buildOrb(
                      200,
                      isDark
                          ? const Color(0xFF4F46E5).withValues(alpha: 0.08)
                          : const Color(0xFF818CF8).withValues(alpha: 0.10),
                    ),
                  ),
                ],
              );
            },
          ),
          // Main content
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: AnimatedBuilder(
                    animation: _loopController,
                    builder: (context, child) {
                      final wave =
                          (math.sin(_loopController.value * math.pi * 2) + 1) / 2;
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
                                  width: size.width * 0.62,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // App name with glass pill
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [
                                            Colors.white.withValues(alpha: 0.08),
                                            Colors.white.withValues(alpha: 0.04),
                                          ]
                                        : [
                                            Colors.white.withValues(alpha: 0.72),
                                            Colors.white.withValues(alpha: 0.50),
                                          ],
                                  ),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.10)
                                        : Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                                child: Text(
                                  'AsHa SaTHi',
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                    color: isDark
                                        ? const Color(0xFF2ED1B0)
                                        : const Color(0xFF14A7A0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          _LoadingDots(
                            progress: wave,
                            color: isDark
                                ? const Color(0xFF2ED1B0)
                                : const Color(0xFF14A7A0),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
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
        final scale = 0.75 + (phase * 0.40);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
