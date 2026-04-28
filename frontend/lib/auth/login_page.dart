import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../utils/app_validator.dart';
import '../utils/glass_widgets.dart';
import '../providers/login_provider.dart';
import 'signup_page.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView>
    with SingleTickerProviderStateMixin {
  static const Color _brandTeal = Color(0xFF14A7A0);
  static const Color _accentCyan = Color(0xFF2ED1B0);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ValueNotifier<bool> _showPassword = ValueNotifier(false);
  final Appvalidator _appvalidator = Appvalidator();
  bool _isGoogleLoading = false;

  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _showPassword.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ref.read(loginProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);

    ref.listen(loginProvider, (prev, next) {
      if (next.error != null) {
        showGlassSnackBar(context, next.error!, isError: true);
      }
      if (next.token != null && prev?.token == null) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    });

    final l10n = context.l10n;

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
                colors: _isDark
                    ? const [Color(0xFF0B1120), Color(0xFF0D1825), Color(0xFF091318)]
                    : const [Color(0xFFE4F7F4), Color(0xFFEEF4FF), Color(0xFFF7FBFF)],
              ),
            ),
          ),
          // Orbs
          Positioned(
            top: -80,
            right: -60,
            child: _buildOrb(
              280,
              _isDark
                  ? _brandTeal.withValues(alpha: 0.14)
                  : _brandTeal.withValues(alpha: 0.20),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _buildOrb(
              320,
              _isDark
                  ? _accentCyan.withValues(alpha: 0.07)
                  : _accentCyan.withValues(alpha: 0.13),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 32),
                          _buildGlassLogo(),
                          const SizedBox(height: 24),
                          Text(
                            'Welcome Back',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              color: _isDark
                                  ? const Color(0xFFE6EDF3)
                                  : const Color(0xFF1F2933),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Asha Sathi',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _accentCyan,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.tr('auth.loginSubtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isDark
                                  ? const Color(0xFFACB7C2)
                                  : const Color(0xFF5B6670),
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Glass form card
                          GlassContainer(
                            padding: const EdgeInsets.all(24),
                            borderRadius: BorderRadius.circular(24),
                            blur: 16,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _buildLabel(l10n.tr('auth.emailAddress')),
                                  const SizedBox(height: 8),
                                  _buildGlassField(
                                    controller: _emailController,
                                    hint: 'name@example.com',
                                    icon: Icons.mail_outline_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: _appvalidator.validateEmail,
                                  ),
                                  const SizedBox(height: 18),
                                  _buildLabel(l10n.tr('auth.password')),
                                  const SizedBox(height: 8),
                                  ValueListenableBuilder<bool>(
                                    valueListenable: _showPassword,
                                    builder: (context, showPwd, _) {
                                      return _buildGlassField(
                                        controller: _passwordController,
                                        hint: '••••••••',
                                        icon: Icons.lock_outline_rounded,
                                        obscureText: !showPwd,
                                        validator: _appvalidator.validatePassword,
                                        suffix: IconButton(
                                          icon: Icon(
                                            showPwd
                                                ? Icons.visibility_rounded
                                                : Icons.visibility_off_rounded,
                                            size: 20,
                                            color: _isDark
                                                ? const Color(0xFF9AA8B6)
                                                : const Color(0xFF65727C),
                                          ),
                                          onPressed: () =>
                                              _showPassword.value = !showPwd,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  _buildLoginButton(loginState),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: _isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.10),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  l10n
                                      .tr('auth.orContinueWith')
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: _isDark
                                        ? const Color(0xFF8F9CAA)
                                        : const Color(0xFF6D7780),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: _isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.10),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildGoogleButton(l10n),
                          const SizedBox(height: 36),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.tr('auth.dontHaveAccount'),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _isDark
                                      ? const Color(0xFFACB7C2)
                                      : const Color(0xFF5B6670),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpView(),
                                  ),
                                ),
                                child: Text(
                                  l10n.tr('auth.createAccount'),
                                  style: GoogleFonts.outfit(
                                    color: _accentCyan,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassLogo() {
    return Center(
      child: GlassContainer(
        width: 90,
        height: 90,
        borderRadius: BorderRadius.circular(24),
        blur: 18,
        alignment: Alignment.center,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_accentCyan, _brandTeal],
            ),
            boxShadow: [
              BoxShadow(
                color: _brandTeal.withValues(alpha: 0.40),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/AshaIcon.png',
            width: 34,
            height: 34,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: _isDark ? const Color(0xFF8F9CAA) : const Color(0xFF6D7780),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
        ),
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validator,
          style: TextStyle(
            color: _isDark
                ? const Color(0xFFE6EDF3)
                : const Color(0xFF1F2933),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              size: 20,
              color: _isDark
                  ? const Color(0xFF9AA8B6)
                  : _brandTeal.withValues(alpha: 0.7),
            ),
            suffixIcon: suffix,
            filled: true,
            fillColor: _isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.65),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.85),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.85),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _brandTeal, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(LoginState state) {
    return GlassButton(
      label: context.l10n.tr('auth.login'),
      onPressed: state.isLoading ? null : _submitForm,
      icon: Icons.arrow_forward_rounded,
      isLoading: state.isLoading,
      height: 56,
    );
  }

  Widget _buildGoogleButton(AppLocalizations l10n) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: OutlinedButton(
          onPressed: _isGoogleLoading
              ? null
              : () async {
                  setState(() => _isGoogleLoading = true);
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  try {
                    final token = await AuthService().loginWithGoogle();
                    if (!mounted) return;
                    await ref.read(loginProvider.notifier).setToken(token);
                    if (!mounted) return;
                    navigator.pushReplacementNamed('/main');
                  } catch (e) {
                    if (!mounted) return;
                    String errorMsg = e.toString();
                    if (errorMsg.contains('network_error') || errorMsg.contains('ApiException: 7')) {
                      errorMsg = 'Network error. Please check your internet connection and try again.';
                    } else if (errorMsg.contains('Google Sign-In')) {
                      errorMsg = 'Google Sign-In failed. Please try again.';
                    }
                    showGlassSnackBar(context, errorMsg, isError: true);
                  } finally {
                    if (mounted) setState(() => _isGoogleLoading = false);
                  }
                },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            side: BorderSide(
              color: _isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.85),
            ),
            backgroundColor: _isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.65),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isGoogleLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/google.png',
                        width: 22, height: 22),
                    const SizedBox(width: 10),
                    Text(
                      l10n.tr('auth.google'),
                      style: TextStyle(
                        color: _isDark
                            ? const Color(0xFFE6EDF3)
                            : const Color(0xFF1F252B),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
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
