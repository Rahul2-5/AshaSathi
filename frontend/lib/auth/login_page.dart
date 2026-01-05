import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home/home_page.dart';
import '../services/auth_service.dart';
import 'cubit/login_cubit.dart';
import 'cubit/login_state.dart';
import 'signup_page.dart';
import '../utils/appValidator.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final ValueNotifier<bool> _showPassword = ValueNotifier(false);
  final Appvalidator appvalidator = Appvalidator();

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
        // ❌ Error
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }

        // ✅ Success → Navigate to Home
        if (state.token != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(token: state.token!),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  Text(
                    'Welcome Back \nAsha Sathi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color.fromRGBO(46, 125, 50, 1.0),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 40),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildEmailField(),
                        const SizedBox(height: 25),
                        _buildPasswordField(),
                        const SizedBox(height: 37),
                        _buildLoginButton(state),
                        const SizedBox(height: 30),

                        Row(
                          children: const [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('Or Login with'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 🔵 GOOGLE LOGIN
                            InkWell(
                              onTap: () async {
                                try {
                                  final token =
                                      await AuthService().loginWithGoogle();

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          HomePage(token: token),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(e.toString())),
                                  );
                                }
                              },
                              child: Image.asset(
                                'assets/images/google.png',
                                width: 36,
                              ),
                            ),

                            // ⚫ GITHUB LOGIN
                            InkWell(
                              onTap: () {
                                AuthService().loginWithGithub();
                              },
                              child: Image.asset(
                                'assets/images/github.png',
                                width: 36,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 50),

                        const Text(
                          "Don't have an account?",
                          style: TextStyle(fontSize: 15),
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
                          child: Text(
                            'Create new account',
                            style: TextStyle(
                              color: const Color.fromRGBO(46, 125, 50, 1.0),
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= UI HELPERS =================

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(color: Colors.black),
      validator: appvalidator.validateEmail,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _inputDecoration('Email', Icons.email
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
          style: TextStyle(color: Colors.black),
          validator: appvalidator.validatePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color.fromRGBO(46, 125, 50, 1.0)),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color.fromRGBO(32, 85, 38, 1.0)),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: () =>
                  _showPassword.value = !showPassword,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0)
            )
          ),
        );
      },
    );
  }

  Widget _buildLoginButton(LoginState state) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: state.isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromRGBO(46, 125, 50, 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: state.isLoading
            ? const CircularProgressIndicator(
                color: Colors.white,
              )
            : const Text(
                'Login',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: Icon(icon),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color.fromRGBO(46, 125, 50, 1.0)),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color:Color.fromRGBO(32, 85, 38, 1.0)),
      ),
    border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
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
