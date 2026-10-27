// lib/presentation/pages/auth/forgot_password_page.dart

import 'package:flutter/material.dart';
import 'package:nomad_mobile/core/constants/app_color.dart';
import 'package:nomad_mobile/core/constants/app_text_style.dart';
import 'package:nomad_mobile/core/utils/network_utils.dart';
import 'package:nomad_mobile/core/utils/validators.dart';
import 'package:nomad_mobile/presentation/components/input_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordPage extends StatefulWidget {
  static const routeName = '/forgot-password';

  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    if (!await NetworkUtils.hasInternet()) {
      _showSnackBar('No internet connection', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      final email = _emailController.text.trim();

      // First, check if a user with this email exists in your public profiles table.
      // This provides a specific error message if the email is not found.
      // NOTE: This approach can be used by attackers to check if an email is registered (email enumeration).
      // Supabase's `resetPasswordForEmail` intentionally doesn't throw an error for non-existent emails for security.
      // This implementation assumes you have a 'profiles' table with an 'email' column.
      final List userCheck = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('email', email)
          .limit(1);

      if (userCheck.isEmpty && mounted) {
        _showSnackBar('No user found with this email.', Colors.red);
        return;
      }

      // Note: Ensure you have configured Deep Links in your Supabase Dashboard
      // and your AndroidManifest.xml / Info.plist.
      // The redirectTo should match your app's deep link scheme.
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.nomad://login-callback',
      );

      if (mounted) {
        _showSnackBar(
          'Check your email for the password reset link.',
          Colors.green,
        );
        // Optional: Navigate back to login after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } on AuthException catch (e) {
      _showSnackBar(e.message, Colors.red);
    } catch (e) {
      _showSnackBar('An unexpected error occurred.', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
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
      body: SafeArea(
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
                'Forgot Password?',
                style: AppTextStyle.authTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Enter your email address and we'll send you a link to reset your password.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 30),
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
                        labelText: 'Email',
                        hintText: 'example@gmail.com',
                        controller: _emailController,
                        isPassword: false,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _isLoading ? null : _sendResetLink,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: _isLoading
                                ? null
                                : AppColors.primaryGradient,
                            color: _isLoading ? AppColors.secondaryText : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.mail_outline,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Send Reset Link',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
