import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../components/app_button.dart';
import '../../components/app_text_field.dart';
import '../../components/inline_alert.dart';
import '../../theme/app_tokens.dart';
import '../../theme/theme_extensions.dart';
import '../../utils/link_rules.dart';
import 'widgets/auth_layout.dart';
import 'widgets/password_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    context.read<AuthBloc>().add(
      LoginRequested(email: _emailController.text.trim(), password: _passwordController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final loading = auth.status == AuthStatus.loading;
    final c = context.colors;

    return AuthLayout(
      tabTitle: 'Log in',
      title: 'Welcome back',
      subtitle: 'Log in to manage your links.',
      form: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (auth.status == AuthStatus.error && auth.errorMessage != null) ...[
                InlineAlert(auth.errorMessage!),
                const SizedBox(height: Space.s5),
              ],
              AppTextField(
                label: 'Email',
                controller: _emailController,
                hint: 'you@company.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: LinkRules.emailError,
                autofocus: true,
              ),
              const SizedBox(height: Space.s4),
              PasswordField(
                controller: _passwordController,
                autofillHints: const [AutofillHints.password],
                validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Space.s6),
              SizedBox(
                height: 44,
                child: AppButton(label: 'Log in', loading: loading, onPressed: _submit, expand: true),
              ),
            ],
          ),
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Don't have an account?", style: context.text.small),
          TextButton(
            onPressed: () => context.go('/signup'),
            style: TextButton.styleFrom(foregroundColor: c.accent),
            child: const Text('Sign up'),
          ),
        ],
      ),
    );
  }
}
