import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/auth/cubit/login_cubit.dart';

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
      "username": _userNameController.text.trim(),
      "email": _emailController.text.trim(),
      "phone": _phoneController.text.trim(),
      "password": _passwordController.text,
    };

    context.read<SignupCubit>().signup(data);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignupCubit, SignupState>(
      listener: (context, state) {
        // ❌ Error
        if (state.error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error!),
              backgroundColor:Colors.red));
        }

        //  Normal signup success 
        if (state.isSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginView()),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  Text(
                    'Create New \nAsha Account',
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
                        _buildTextField(
                          _userNameController,
                          'Username',
                          Icons.person,
                          _appValidator.validateUsername,
                        ),
                        const SizedBox(height: 25),

                        _buildTextField(
                          _emailController,
                          'Email',
                          Icons.email,
                          _appValidator.validateEmail,
                        ),
                        const SizedBox(height: 25),

                        _buildTextField(
                          _phoneController,
                          'Phone Number',
                          Icons.call,
                          _appValidator.validatePhoneNumber,
                        ),
                        const SizedBox(height: 25),

                        _buildPasswordField(),
                        const SizedBox(height: 37),

                        _buildSignupButton(state),
                        const SizedBox(height: 30),

                        Row(
                          children: const [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('Or Sign up with'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 🔵 GOOGLE SIGNUP / LOGIN
                            InkWell(
                              onTap: () async {
                                try {
                                  final token = await AuthService().loginWithGoogle();

                                context.read<LoginCubit>().setToken(token);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          HomePage(),
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

                            // ⚫ GITHUB SIGNUP / LOGIN
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
                          "Already have an account?",
                          style: TextStyle(fontSize: 15),
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginView(),
                              ),
                            );
                          },
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: const Color.fromRGBO(46, 125, 50, 1.0),
                              fontSize: 22,
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

  //  UI HELPERS

  Widget _buildSignupButton(SignupState state) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state.isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(46, 125, 50, 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: state.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Create',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    String? Function(String?) validator,
  ) {
    return TextFormField(
      controller: controller,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _buildInputDecoration(label, icon),
    );
  }

  Widget _buildPasswordField() {
    return ValueListenableBuilder<bool>(
      valueListenable: _showPassword,
      builder: (context, showPassword, _) {
        return TextFormField(
          controller: _passwordController,
          obscureText: !showPassword,
          validator: _appValidator.validatePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            filled: true,
            fillColor: Colors.white,
            suffixIcon: IconButton(
              icon: Icon(
                showPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: () =>
                  _showPassword.value = !showPassword,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color.fromRGBO(46, 125, 50, 1.0)),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: const Color.fromRGBO(32, 85, 38, 1.0)),
            ),
             border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
            )
          ),
        );
      },
    );
  }

  InputDecoration _buildInputDecoration(
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
        borderSide: BorderSide(color: const Color.fromRGBO(32, 85, 38, 1.0)),
      ),
      border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
            )
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
