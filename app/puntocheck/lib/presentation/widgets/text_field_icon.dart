import 'package:flutter/material.dart';

class TextFieldIcon extends StatelessWidget {
  const TextFieldIcon({
    super.key,
    required this.controller,
    required this.icon,
    required this.label,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.suffix,
    this.onTap,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final Widget? suffix;
  final VoidCallback? onTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onTap: onTap,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
      ),
    );
  }
}
