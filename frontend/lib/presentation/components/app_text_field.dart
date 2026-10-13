import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';

/// Text field with its label above the input (SaaS-form style) rather than
/// a floating Material label.
class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? trailingLabel;
  final bool autofocus;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.trailingLabel,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: context.text.h3.copyWith(fontWeight: FontWeight.w500)),
            ),
            ?trailingLabel,
          ],
        ),
        const SizedBox(height: Space.s2),
        Semantics(
          label: label,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            validator: validator,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            obscureText: obscureText,
            autofocus: autofocus,
            enabled: enabled,
            style: context.text.body,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(hintText: hint, prefixIcon: prefixIcon, suffixIcon: suffixIcon),
          ),
        ),
      ],
    );
  }
}
