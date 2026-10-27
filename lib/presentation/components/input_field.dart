import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nomad_mobile/core/constants/app_color.dart';

// A reusable text input field with validation and styling.
class InputField extends StatefulWidget{
  final String labelText;
  final String? hintText;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const InputField({super.key, required this.labelText, this.hintText, required this.controller, required this.isPassword, required this.keyboardType, this.inputFormatters, this.validator});

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  late bool _obcureText;

  @override
  void initState() {
    super.initState();
    _obcureText = widget.isPassword;
  }

  void _toggleObcureText() {
    setState(() {
      _obcureText = !_obcureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: _obcureText,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          cursorColor: AppColors.primaryBlue,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(color: AppColors.secondaryText),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryBlue),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.accentGreen, width: 2),
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      widget.isPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey
                    ),
                    onPressed: _toggleObcureText,
                  )
                  
                : null,
          ),
        ),
      ],
    );
  }
}
