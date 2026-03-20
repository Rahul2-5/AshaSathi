import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/localization/app_localizations.dart';

import '../services/auth_service.dart';
import '../utils/appValidator.dart';
import 'cubit/login_cubit.dart';
import 'cubit/login_state.dart';
import 'signup_page.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  static const Color _brandTeal = Color(0xFF1E8F7D);
  static const Color _accentTeal = Color(0xFF2ED1B0);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _pageBackground =>
    _isDark ? const Color(0xFF101720) : const Color(0xFFF3F5F6);
  Color get _primaryText =>
    _isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1F2933);
  Color get _secondaryText =>
    _isDark ? const Color(0xFFACB7C2) : const Color(0xFF5B6670);
  Color get _mutedText =>
    _isDark ? const Color(0xFF8F9CAA) : const Color(0xFF6D7780);
  Color get _fieldFill =>
    _isDark ? const Color(0xFF1C2833) : const Color(0xFFEBEEF0);
  Color get _fieldIcon =>
    _isDark ? const Color(0xFF9AA8B6) : const Color(0xFF65727C);
  Color get _dividerColor =>
    _isDark ? const Color(0xFF33424F) : const Color(0xFFD8DEE3);
  Color get _googleBorderColor =>
    _isDark ? const Color(0xFF40505E) : const Color(0xFFBDC5CC);
  Color get _logoOuterBg =>
    _isDark ? const Color(0xFF203039) : const Color(0xFFE2F4EF);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final ValueNotifier<bool> _showPassword = ValueNotifier(false);
  final Appvalidator appvalidator = Appvalidator();
  bool _isGoogleLoading = false;

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      context.read<LoginCubit>().login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
          );
        }

        if (state.token != null) {
          Navigator.pushReplacementNamed(context, '/main');
        }
      },
      builder: (context, state) {
        final l10n = context.l10n;
        return Scaffold(
          backgroundColor: _pageBackground,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 36),
                      _buildLogo(),
                      const SizedBox(height: 22),
                      Text.rich(
                        const TextSpan(
                          children: [
                            TextSpan(text: 'Welcome Back\n'),
                            TextSpan(
                              text: 'Asha Sathi',
                              style: TextStyle(color: _accentTeal),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _primaryText,
                          fontSize: 24,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.tr('auth.loginSubtitle'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _secondaryText,
                          fontSize: 16,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildInputLabel(l10n.tr('auth.emailAddress')),
                            const SizedBox(height: 8),
                            _buildEmailField(),
                            const SizedBox(height: 18),
                            _buildInputLabel(l10n.tr('auth.password')),
                            const SizedBox(height: 8),
                            _buildPasswordField(),
                            const SizedBox(height: 26),
                            _buildLoginButton(state),
                            const SizedBox(height: 30),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: _dividerColor,
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    l10n.tr('auth.orContinueWith').toUpperCase(),
                                    style: TextStyle(
                                      color: _mutedText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: _dividerColor,
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _buildGoogleButton(l10n),
                            const SizedBox(height: 42),
                            Column(
                              children: [
                                Text(
                                  l10n.tr('auth.dontHaveAccount'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _secondaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SignUpView(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: const EdgeInsets.only(top: 2),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    l10n.tr('auth.createAccount'),
                                    style: TextStyle(
                                      color: _accentTeal,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: _logoOuterBg,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _accentTeal,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/AshaIcon.png',
            width: 30,
            height: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: _mutedText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(
        color: _primaryText,
        fontSize: 15,
        height: 1,
        fontWeight: FontWeight.w600,
      ),
      validator: appvalidator.validateEmail,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _fieldDecoration(
        hintText: 'name@example.com',
        prefixIcon: Icons.mail_outline,
      ),
    );
  }

  Widget _buildPasswordField() {
    return ValueListenableBuilder<bool>(
      valueListenable: _showPassword,
      builder: (context, showPassword, _) {
        return TextFormField(
          controller: _passwordController,
          obscureText: !showPassword,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: TextStyle(
            color: _primaryText,
            fontSize: 15,
            height: 1,
            fontWeight: FontWeight.w600,
          ),
          validator: appvalidator.validatePassword,
          decoration: _fieldDecoration(
            hintText: '••••••••',
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility : Icons.visibility_off,
                color: _fieldIcon,
              ),
              onPressed: () => _showPassword.value = !showPassword,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginButton(LoginState state) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: state.isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _brandTeal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: state.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.tr('auth.login'),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGoogleButton(AppLocalizations l10n) {
    return OutlinedButton(
      onPressed: _isGoogleLoading
          ? null
          : () async {
        setState(() => _isGoogleLoading = true);
        final loginCubit = context.read<LoginCubit>();
        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);

        try {
          final token = await AuthService().loginWithGoogle();
          if (!mounted) return;

          await loginCubit.setToken(token);
          if (!mounted) return;

          navigator.pushReplacementNamed('/main');
        } catch (e) {
          if (!mounted) return;

          messenger.showSnackBar(SnackBar(content: Text(e.toString())));
        } finally {
          if (mounted) {
            setState(() => _isGoogleLoading = false);
          }
        }
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(170, 52),
        side: BorderSide(color: _googleBorderColor),
        backgroundColor: _isDark ? const Color(0xFF14202A) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                Image.asset('assets/images/google.png', width: 20, height: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.tr('auth.google'),
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: _mutedText,
        fontSize: 15,
        height: 1,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: _fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      prefixIcon: Icon(prefixIcon, color: _fieldIcon, size: 22),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _brandTeal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _showPassword.dispose();
    super.dispose();
  }
}
