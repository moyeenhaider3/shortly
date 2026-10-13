import 'package:flutter/material.dart';

import '../../../components/app_text_field.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final Iterable<String> autofillHints;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  const PasswordField({
    super.key,
    required this.controller,
    required this.autofillHints,
    this.label = 'Password',
    this.hint,
    this.validator,
    this.onSubmitted,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      controller: widget.controller,
      hint: widget.hint,
      obscureText: _obscure,
      autofillHints: widget.autofillHints,
      validator: widget.validator,
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.visiblePassword,
      suffixIcon: IconButton(
        tooltip: _obscure ? 'Show password' : 'Hide password',
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
      ),
    );
  }
}
