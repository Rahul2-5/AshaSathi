import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:frontend/widgets/common/common_widgets.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class PatientSuccessPage extends StatefulWidget {
  const PatientSuccessPage({super.key});

  @override
  State<PatientSuccessPage> createState() => _PatientSuccessPageState();
}

class _PatientSuccessPageState extends State<PatientSuccessPage>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _checkAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _pulseController.repeat(reverse: true);
    });

    // Auto close after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    ? const [Color(0xFF0B1120), Color(0xFF0E1A26)]
                    : const [Color(0xFFE4F7F4), Color(0xFFEEF4FF), Color(0xFFF7FBFF)],
              ),
            ),
          ),
          // Background orbs
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.teal.withValues(alpha: isDark ? 0.14 : 0.20),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.accentCyan.withValues(alpha: isDark ? 0.08 : 0.14),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated pulsing glass success icon
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              AppColors.teal.withValues(alpha: 0.20),
                              Colors.transparent,
                            ]),
                          ),
                        ),
                        // Glass circle
                        ClipOval(
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? [
                                          Colors.white.withValues(alpha: 0.10),
                                          Colors.white.withValues(alpha: 0.05),
                                        ]
                                      : [
                                          Colors.white.withValues(alpha: 0.80),
                                          Colors.white.withValues(alpha: 0.55),
                                        ],
                                ),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.teal.withValues(alpha: 0.40)
                                      : AppColors.teal.withValues(alpha: 0.35),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.teal.withValues(alpha: 0.30),
                                    blurRadius: 28,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: AnimatedBuilder(
                                animation: _checkAnimation,
                                builder: (context, child) {
                                  return Icon(
                                    Icons.check_rounded,
                                    color: Color.lerp(
                                      AppColors.teal.withValues(alpha: 0),
                                      AppColors.teal,
                                      _checkAnimation.value,
                                    ),
                                    size: 58,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Glass pill label
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    borderRadius: BorderRadius.circular(24),
                    blur: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.tr('patient.saved'),
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFFE6EDF3)
                                : const Color(0xFF1F252B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.tr('patient.savedDetails'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFFA6B3BF)
                                : const Color(0xFF667384),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Progress indicator
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 2500),
                      tween: Tween(begin: 0, end: 1),
                      builder: (context, value, _) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 3,
                          color: AppColors.teal.withValues(alpha: 0.6),
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
