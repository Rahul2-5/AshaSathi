import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/auth/cubit/login_cubit.dart';
import 'package:frontend/localization/app_localizations.dart';

import '../home/home_page.dart';
import '../services/auth_service.dart';
import 'cubit/signup_cubit.dart';
import 'cubit/signup_state.dart';
import '../utils/appValidator.dart';
import 'login_page.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  static const Color _accentTextColor = Color(0xFF29A68C);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ValueNotifier<bool> _showPassword = ValueNotifier(false);
  final Appvalidator _appValidator = Appvalidator();

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'username': _userNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'password': _passwordController.text,
    };

    context.read<SignupCubit>().signup(data);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignupCubit, SignupState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
          );
        }

        if (state.isSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginView()),
          );
        }
      },
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final pageBg = isDark ? const Color(0xFF10141D) : const Color(0xFFF6F7F8);
        final cardBg = isDark ? const Color(0xFF1A2E40) : const Color(0xFFEEF2F5);
        final titleColor = isDark ? const Color(0xFFEAF0F7) : const Color(0xFF1E242C);
        final subtitleColor = isDark ? const Color(0xFFA9B6C5) : const Color(0xFF6B7480);
        final labelColor = isDark ? const Color(0xFF96A3B3) : const Color(0xFF7C8794);
        final inputTextColor = isDark ? const Color(0xFFE9EFF6) : const Color(0xFF29313A);
        final dividerColor = isDark ? const Color(0xFF3A4556) : const Color(0xFFD0D5DC);

        return Scaffold(
          backgroundColor: pageBg,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _topBar(isDark),
                    const SizedBox(height: 8),
                    _sectionTag(isDark),
                    const SizedBox(height: 10),
                    Text(
                      'Create Your',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'Asha Account',
                      style: const TextStyle(
                        color: _accentTextColor,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Join thousands of users optimizing their daily health and wellness journey.',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _fieldLabel('USERNAME', labelColor),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _userNameController,
                      context.l10n.tr('auth.username'),
                      Icons.person_outline,
                      _appValidator.validateUsername,
                      cardBg: cardBg,
                      textColor: inputTextColor,
                      iconColor: labelColor,
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('EMAIL ADDRESS', labelColor),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _emailController,
                      context.l10n.tr('auth.email'),
                      Icons.email_outlined,
                      _appValidator.validateEmail,
                      cardBg: cardBg,
                      textColor: inputTextColor,
                      iconColor: labelColor,
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('PHONE NUMBER', labelColor),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _phoneController,
                      context.l10n.tr('auth.phoneNumber'),
                      Icons.call_outlined,
                      _appValidator.validatePhoneNumber,
                      cardBg: cardBg,
                      textColor: inputTextColor,
                      iconColor: labelColor,
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('PASSWORD', labelColor),
                    const SizedBox(height: 6),
                    _buildPasswordField(
                      cardBg: cardBg,
                      textColor: inputTextColor,
                      iconColor: labelColor,
                    ),
                    const SizedBox(height: 26),
                    _buildSignupButton(state),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Divider(color: dividerColor)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            context.l10n.tr('auth.orSignupWith').toUpperCase(),
                            style: TextStyle(
                              color: subtitleColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: dividerColor)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final loginCubit = context.read<LoginCubit>();
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          try {
                            final token = await AuthService().loginWithGoogle();
                            if (!mounted) return;

                            await loginCubit.setToken(token);
                            if (!mounted) return;

                            navigator.pushReplacement(
                              MaterialPageRoute(builder: (_) => const HomePage()),
                            );
                          } catch (e) {
                            if (!mounted) return;

                            messenger.showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                        icon: Image.asset('assets/images/google.png', width: 18),
                        label: Text(
                          'Google',
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: dividerColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    Center(
                      child: Text(
                        context.l10n.tr('auth.alreadyHaveAccount'),
                        style: TextStyle(
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginView()),
                          );
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: _accentTextColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _topBar(bool isDark) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? const Color(0xFFD3DDE8) : const Color(0xFF303741),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0x1A29A68C),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Icon(Icons.bolt_rounded, size: 14, color: _accentTextColor),
            ),
            const SizedBox(width: 6),
            const Text(
              'Asha',
              style: TextStyle(
                color: _accentTextColor,
                fontSize: 17,
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
          child: const Text(
            'Log In',
            style: TextStyle(
              color: _accentTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTag(bool isDark) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 2,
          decoration: BoxDecoration(
            color: _accentTextColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'GET STARTED',
          style: TextStyle(
            color: isDark ? const Color(0xFF84D8C4) : const Color(0xFF3EA891),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 10,
        letterSpacing: 0.9,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSignupButton(SignupState state) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state.isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentTextColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: state.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create Account',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    String? Function(String?) validator, {
    required Color cardBg,
    required Color textColor,
    required Color iconColor,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _buildInputDecoration(
        label,
        icon,
        cardBg: cardBg,
        textColor: textColor,
        iconColor: iconColor,
      ),
    );
  }

  Widget _buildPasswordField({
    required Color cardBg,
    required Color textColor,
    required Color iconColor,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: _showPassword,
      builder: (context, showPassword, _) {
        return TextFormField(
          controller: _passwordController,
          obscureText: !showPassword,
          validator: _appValidator.validatePassword,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: context.l10n.tr('auth.password'),
            hintStyle: TextStyle(
              color: textColor.withValues(alpha: 0.68),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: cardBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            prefixIcon: Icon(Icons.lock_outline, color: iconColor),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility : Icons.visibility_off,
                color: iconColor,
              ),
              onPressed: () => _showPassword.value = !showPassword,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(16),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _accentTextColor, width: 1.1),
              borderRadius: BorderRadius.circular(16),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _buildInputDecoration(
    String label,
    IconData icon, {
    required Color cardBg,
    required Color textColor,
    required Color iconColor,
  }) {
    return InputDecoration(
      hintText: label,
      hintStyle: TextStyle(
        color: textColor.withValues(alpha: 0.68),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: cardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      prefixIcon: Icon(icon, color: iconColor),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _accentTextColor, width: 1.1),
        borderRadius: BorderRadius.circular(16),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _showPassword.dispose();
    super.dispose();
  }
}
