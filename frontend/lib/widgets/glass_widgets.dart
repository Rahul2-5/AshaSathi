import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GRADIENT SCAFFOLD  — full-screen mesh gradient background
// ─────────────────────────────────────────────────────────────────────────────

class GradientScaffold extends StatefulWidget {
  const GradientScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.drawer,
    this.onDrawerChanged,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final void Function(bool)? onDrawerChanged;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;
  final bool extendBody;

  @override
  State<GradientScaffold> createState() => _GradientScaffoldState();
}

class _GradientScaffoldState extends State<GradientScaffold>
    with SingleTickerProviderStateMixin {
  // Smooth background transition duration
  static const _kDuration = Duration(milliseconds: 500);
  static const _kCurve = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgStart = isDark ? AppColors.darkBg1 : AppColors.lightBg1;
    final bgMid = isDark ? AppColors.darkBg2 : AppColors.lightBg2;
    final bgEnd = isDark ? AppColors.darkBg3 : AppColors.lightBg3;

    final orb1Color = isDark
        ? AppColors.teal.withValues(alpha: 0.12)
        : AppColors.teal.withValues(alpha: 0.18);
    final orb2Color = isDark
        ? AppColors.accentCyan.withValues(alpha: 0.07)
        : AppColors.accentCyan.withValues(alpha: 0.12);
    final orb3Color = isDark
        ? AppColors.purple.withValues(alpha: 0.06)
        : AppColors.lightPurple.withValues(alpha: 0.10);

    return Scaffold(
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      extendBody: widget.extendBody,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      appBar: widget.appBar,
      drawer: widget.drawer,
      onDrawerChanged: widget.onDrawerChanged,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.bottomNavigationBar,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Animated base gradient ──────────────────────────────────────
          AnimatedContainer(
            duration: _kDuration,
            curve: _kCurve,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bgStart, bgMid, bgEnd],
              ),
            ),
          ),
          // ── Orb 1 — top-right accent ────────────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: _AnimatedGlowOrb(
              size: 260,
              color: orb1Color,
              duration: _kDuration,
              curve: _kCurve,
            ),
          ),
          // ── Orb 2 — bottom-left accent ──────────────────────────────────
          Positioned(
            bottom: -100,
            left: -80,
            child: _AnimatedGlowOrb(
              size: 300,
              color: orb2Color,
              duration: _kDuration,
              curve: _kCurve,
            ),
          ),
          // ── Orb 3 — mid-right subtle ────────────────────────────────────
          Positioned(
            top: 200,
            right: -120,
            child: _AnimatedGlowOrb(
              size: 220,
              color: orb3Color,
              duration: _kDuration,
              curve: _kCurve,
            ),
          ),
          // ── Main content ────────────────────────────────────────────────
          widget.child,
        ],
      ),
    );
  }
}

/// A glow orb that smoothly animates its radial gradient color.
class _AnimatedGlowOrb extends StatelessWidget {
  const _AnimatedGlowOrb({
    required this.size,
    required this.color,
    required this.duration,
    required this.curve,
  });
  final double size;
  final Color color;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    // TweenAnimationBuilder interpolates the color smoothly
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: duration,
      curve: curve,
      builder: (context, animatedColor, _) {
        final c = animatedColor ?? color;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [c, Colors.transparent]),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS CONTAINER  — the core building block
// ─────────────────────────────────────────────────────────────────────────────

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 14.0,
    this.enableBlur = false,
    this.border,
    this.gradient,
    this.boxShadow,
    this.width,
    this.height,
    this.alignment,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;

  /// When true, renders a live [BackdropFilter] (expensive — re-blurs the
  /// background every frame). Off by default: the translucent gradient surface
  /// already reads as frosted glass over the app's gradient background, so
  /// cards in lists stay at 60fps. Enable only for overlays/sticky surfaces.
  final bool enableBlur;
  final BoxBorder? border;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(20);

    final defaultGradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.04),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.45),
              Colors.white.withValues(alpha: 0.28),
            ],
          );

    final defaultBorder = isDark
        ? Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1)
        : Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1);

    final defaultShadow = isDark
        ? [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];

    final surface = Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: gradient ?? defaultGradient,
        border: border ?? defaultBorder,
      ),
      child: child,
    );

    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: boxShadow ?? defaultShadow,
      ),
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: enableBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: surface,
              )
            : surface,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS SECTION CARD  — card with optional title
// ─────────────────────────────────────────────────────────────────────────────

class GlassSectionCard extends StatelessWidget {
  const GlassSectionCard({
    super.key,
    required this.child,
    this.title,
    this.titleIcon,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 14.0,
  });

  final Widget child;
  final String? title;
  final IconData? titleIcon;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.accentCyan : AppColors.teal;

    return GlassContainer(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      blur: blur,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, size: 16, color: titleColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  title!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS APP BAR  — frosted glass top bar
// ─────────────────────────────────────────────────────────────────────────────

class GlassAppBar extends StatefulWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.elevation = 0,
    this.blur = 16.0,
    this.height = kToolbarHeight,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final double elevation;
  final double blur;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  State<GlassAppBar> createState() => _GlassAppBarState();
}

class _GlassAppBarState extends State<GlassAppBar> {
  static const _kDuration = Duration(milliseconds: 500);
  static const _kCurve = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Target colors for this theme
    final topColor = isDark
        ? AppColors.darkBg1.withValues(alpha: 0.85)
        : AppColors.lightBg1.withValues(alpha: 0.55);
    final bottomColor = isDark
        ? AppColors.darkBg1.withValues(alpha: 0.70)
        : AppColors.white.withValues(alpha: 0.38);
    final borderColor = isDark
        ? AppColors.white.withValues(alpha: 0.08)
        : AppColors.teal.withValues(alpha: 0.15);
    final topPadding = MediaQuery.of(context).padding.top;

    // A single AnimatedContainer smoothly interpolates the gradient/border on
    // theme change — replacing three nested TweenAnimationBuilders that rebuilt
    // every frame. One BackdropFilter is kept: the bar sits over scrolling
    // content, so the blur is meaningful here.
    return RepaintBoundary(
      child: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
        child: AnimatedContainer(
          duration: _kDuration,
          curve: _kCurve,
          height: widget.height + topPadding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [topColor, bottomColor],
            ),
            border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
          ),
          child: SafeArea(
            bottom: false,
            child: NavigationToolbar(
              leading: widget.leading,
              middle: widget.title,
              trailing: widget.actions != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.actions!,
                    )
                  : null,
              centerMiddle: widget.centerTitle,
            ),
          ),
        ),
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS CHIP  — filter chip with glass style
// ─────────────────────────────────────────────────────────────────────────────

class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = selectedColor ?? AppColors.teal;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [activeColor, activeColor.withValues(alpha: 0.75)],
                )
              : LinearGradient(
                  colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.04),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.38),
                          Colors.white.withValues(alpha: 0.22),
                        ],
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? activeColor.withValues(alpha: 0.60)
                : (isDark
                      ? AppColors.white.withValues(alpha: 0.12)
                      : AppColors.teal.withValues(alpha: 0.25)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.white
                : (isDark
                      ? AppColors.lightTextSecondary
                      : AppColors.darkTextSecondary),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS SEARCH BAR
// ─────────────────────────────────────────────────────────────────────────────

class GlassSearchBar extends StatelessWidget {
  const GlassSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.height = 44,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.05),
                ],
              )
            : LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.42),
                  Colors.white.withValues(alpha: 0.26),
                ],
              ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.white.withValues(alpha: 0.12)
              : AppColors.teal.withValues(alpha: 0.25),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.lightText : AppColors.darkText,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: isDark
                ? AppColors.lightTextTertiary
                : AppColors.teal.withValues(alpha: 0.7),
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.lightTextQuaternary
                : AppColors.darkTextTertiary,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: (height - 24) / 2),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS BUTTON  — gradient primary button
// ─────────────────────────────────────────────────────────────────────────────

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 56,
    this.gradientColors,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double width;
  final double height;
  final List<Color>? gradientColors;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? [AppColors.teal, AppColors.accentCyan];
    final radius = borderRadius ?? BorderRadius.circular(18);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: onPressed == null
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : colors,
          ),
          boxShadow: onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.40),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              // Shine overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: height / 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Center(
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 17,
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (icon != null) ...[
                            const SizedBox(width: 8),
                            Icon(icon, color: AppColors.white, size: 20),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS STAT BADGE
// ─────────────────────────────────────────────────────────────────────────────

class GlassStatBadge extends StatelessWidget {
  const GlassStatBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: isDark ? 0.12 : 0.10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? const Color(0xFF9EABB7)
                      : const Color(0xFF6C7580),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS SNACKBAR
// ─────────────────────────────────────────────────────────────────────────────

void showGlassSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final iconColor = isError ? AppColors.redAccent : AppColors.teal;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.08),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.90),
                        Colors.white.withValues(alpha: 0.75),
                      ],
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isError
                    ? AppColors.redAccent.withValues(alpha: 0.4)
                    : (isDark
                          ? AppColors.white.withValues(alpha: 0.15)
                          : AppColors.white.withValues(alpha: 0.90)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.info_outline_rounded,
                  color: iconColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isDark ? AppColors.lightText : AppColors.darkText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
