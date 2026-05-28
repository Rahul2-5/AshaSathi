import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/providers/login_provider.dart';
import 'package:frontend/localization/app_localizations.dart';

import '../home/home_page.dart';
import '../services/auth_service.dart';
import '../providers/signup_provider.dart';
import '../utils/app_validator.dart';
import '../widgets/common/common_widgets.dart';
import 'login_page.dart';

class SignUpView extends ConsumerStatefulWidget {
  const SignUpView({super.key});

  @override
  ConsumerState<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends ConsumerState<SignUpView>
    with SingleTickerProviderStateMixin {
  static const Color _brandTeal = Color(0xFF14A7A0);
  static const Color _accentCyan = Color(0xFF2ED1B0);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
    _userNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _showPassword.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'username': _userNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
      };
      ref.read(signupProvider.notifier).signup(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signupState = ref.watch(signupProvider);
    
    ref.listen(signupProvider, (prev, next) {
      if (next.error != null) {
        showGlassSnackBar(context, next.error!, isError: true);
      }
      if (next.isSuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
        );
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
            left: -60,
            child: _buildOrb(
              280,
              _isDark
                  ? _brandTeal.withValues(alpha: 0.14)
                  : _brandTeal.withValues(alpha: 0.20),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
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
                          _topBar(),
                          const SizedBox(height: 24),
                          _sectionTag(),
                          const SizedBox(height: 10),
                          Text(
                            'Create Your',
                            textAlign: TextAlign.left,
                            style: GoogleFonts.outfit(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              color: _isDark
                                  ? const Color(0xFFE6EDF3)
                                  : const Color(0xFF1F2933),
                            ),
                          ),
                          Text(
                            'Asha Account',
                            textAlign: TextAlign.left,
                            style: GoogleFonts.outfit(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              color: _accentCyan,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Join thousands of users optimizing their daily health and wellness journey.',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: _isDark
                                  ? const Color(0xFFACB7C2)
                                  : const Color(0xFF5B6670),
                              fontSize: 14,
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
                                  _buildLabel('USERNAME'),
                                  const SizedBox(height: 8),
                                  _buildGlassField(
                                    controller: _userNameController,
                                    hint: context.l10n.tr('auth.username'),
                                    icon: Icons.person_outline_rounded,
                                    validator: _appvalidator.validateUsername,
                                  ),
                                  const SizedBox(height: 18),
                                  _buildLabel('EMAIL ADDRESS'),
                                  const SizedBox(height: 8),
                                  _buildGlassField(
                                    controller: _emailController,
                                    hint: context.l10n.tr('auth.email'),
                                    icon: Icons.mail_outline_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: _appvalidator.validateEmail,
                                  ),
                                  const SizedBox(height: 18),
                                  _buildLabel('PHONE NUMBER'),
                                  const SizedBox(height: 8),
                                  _buildGlassField(
                                    controller: _phoneController,
                                    hint: context.l10n.tr('auth.phoneNumber'),
                                    icon: Icons.call_outlined,
                                    keyboardType: TextInputType.phone,
                                    validator: _appvalidator.validatePhoneNumber,
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
                                  _buildSignupButton(signupState),
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
                                      .tr('auth.orSignupWith')
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
                                l10n.tr('auth.alreadyHaveAccount'),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _isDark
                                      ? const Color(0xFFACB7C2)
                                      : const Color(0xFF5B6670),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginView(),
                                  ),
                                ),
                                child: Text(
                                  'Sign In',
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

  Widget _topBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: _isDark ? const Color(0xFFD3DDE8) : const Color(0xFF303741),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _accentCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Icon(Icons.bolt_rounded, size: 14, color: _accentCyan),
            ),
            const SizedBox(width: 6),
            Text(
              'Asha',
              style: GoogleFonts.outfit(
                color: _accentCyan,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginView()),
            );
          },
          child: Text(
            'Log In',
            style: GoogleFonts.outfit(
              color: _accentCyan,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTag() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 2,
          decoration: BoxDecoration(
            color: _accentCyan,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'GET STARTED',
          style: TextStyle(
            color: _accentCyan,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
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

  Widget _buildSignupButton(SignupState state) {
    return GlassButton(
      label: 'Create Account',
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
                  final navigator = Navigator.of(context);
                  try {
                    final token = await AuthService().loginWithGoogle();
                    if (!mounted) return;
                    await ref.read(loginProvider.notifier).setToken(token);
                    if (!mounted) return;
                    navigator.pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
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
