// lib/presentation/pages/auth/update_password_page.dart

import 'package:flutter/material.dart';
import 'package:nomad_mobile/core/constants/app_color.dart';
import 'package:nomad_mobile/core/constants/app_text_style.dart';
import 'package:nomad_mobile/core/utils/network_utils.dart';
import 'package:nomad_mobile/core/utils/validators.dart';
import 'package:nomad_mobile/presentation/components/input_field.dart';
import 'package:nomad_mobile/presentation/pages/auth/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdatePasswordPage extends StatefulWidget {
  static const routeName = '/update-password';

  const UpdatePasswordPage({super.key});

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (!await NetworkUtils.hasInternet()) {
      _showSnackBar('No internet connection', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      if (mounted) {
        _showSnackBar('Password updated successfully!', Colors.green);
        
        // Navigate back to Login or Dashboard
        Navigator.of(context).pushNamedAndRemoveUntil(
          LoginPage.routeName,
          (route) => false,
        );
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
        title: const Text('Set New Password', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'New Password',
                style: AppTextStyle.authTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Please enter your new password below.",
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
                        labelText: 'New Password',
                        hintText: '••••••••',
                        controller: _passwordController,
                        isPassword: true,
                        keyboardType: TextInputType.visiblePassword,
                        validator: Validators.validatePassword,
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _isLoading ? null : _updatePassword,
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
                                    Icon(Icons.lock_outline, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Update Password',
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
