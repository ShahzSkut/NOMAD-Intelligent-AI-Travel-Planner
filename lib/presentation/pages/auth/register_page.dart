import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nomad_mobile/core/constants/app_color.dart';
import 'package:nomad_mobile/core/constants/app_text_style.dart';
import 'package:nomad_mobile/core/utils/network_utils.dart';
import 'package:nomad_mobile/core/utils/validators.dart';
import 'package:nomad_mobile/logic/blocs/auth_bloc/auth_state.dart';
import 'package:nomad_mobile/presentation/components/input_field.dart';
import 'package:nomad_mobile/logic/blocs/auth_bloc/auth_bloc.dart';
import 'package:nomad_mobile/logic/blocs/auth_bloc/auth_event.dart';
import 'package:nomad_mobile/presentation/pages/auth/login_page.dart';
import 'package:nomad_mobile/presentation/pages/home/trip_dashboard_page.dart';

// Handles new user registration.
class RegisterPage extends StatefulWidget {
  static const routeName = '/register';

  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!await NetworkUtils.hasInternet()) {
        _showSnackBar('No internet connection');
        return;
      }

      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message == 'Feature coming soon!' ? AppColors.secondaryText : Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration successful!'),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.of(context).pushNamedAndRemoveUntil(
              TripDashboardPage.routeName,
              (route) => false,
            );
          } else if (state is AuthFailure) {
            if (mounted) {
              String errorMessage = state.error;
              if (errorMessage.contains('User already registered')) {
                errorMessage = "This email is already in use.";
              } else if (errorMessage.contains('AuthApiException')) {
                errorMessage = "Registration failed. Please try again.";
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Image.asset('assets/images/Nomad_Logo.png'),
                ),
                const SizedBox(height: 10),

                Text(
                  'Create Your Account',
                  style: AppTextStyle.authTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 20,
                        offset: const Offset(5, 5),
                      ),
                      BoxShadow(
                        color: Colors.white.withAlpha(20),
                        blurRadius: 20,
                        offset: const Offset(-5, -5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InputField(
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          controller: _nameController,
                          isPassword: false,
                          keyboardType: TextInputType.name,
                          validator: Validators.validateName,
                        ),
                        const SizedBox(height: 20),
                        InputField(
                          labelText: 'Email',
                          hintText: 'example@gmail.com',
                          controller: _emailController,
                          isPassword: false,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                        ),
                        const SizedBox(height: 20),
                        InputField(
                          labelText: 'Password',
                          hintText: 'Use a strong password',
                          controller: _passwordController,
                          isPassword: true,
                          keyboardType: TextInputType.visiblePassword,
                          validator: Validators.validatePassword,
                        ),
                        const SizedBox(height: 20),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;
                            return GestureDetector(
                              onTap: isLoading ? null : _register,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isLoading
                                      ? null
                                      : AppColors.primaryGradient,
                                  color: isLoading
                                      ? AppColors.secondaryText
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.person_add_outlined,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Register',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('or continue with'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 10),

                        SizedBox(
                          width: 100,
                          child: OutlinedButton(
                            onPressed: () => _showSnackBar('Feature coming soon!'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Colors.grey),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'G',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          LoginPage.routeName,
                        );
                      },
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return AppColors.primaryGradient.createShader(bounds);
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
