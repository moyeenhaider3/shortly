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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    context.read<AuthBloc>().add(
      SignupRequested(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final loading = auth.status == AuthStatus.loading;
    final c = context.colors;

    return AuthLayout(
      tabTitle: 'Sign up',
      title: 'Create your account',
      subtitle: 'Start shortening links in under a minute.',
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
                label: 'Full name',
                controller: _nameController,
                hint: 'Ada Lovelace',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (v) => (v ?? '').trim().length < 2 ? 'Enter at least 2 characters' : null,
                autofocus: true,
              ),
              const SizedBox(height: Space.s4),
              AppTextField(
                label: 'Email',
                controller: _emailController,
                hint: 'you@company.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: LinkRules.emailError,
              ),
              const SizedBox(height: Space.s4),
              PasswordField(
                controller: _passwordController,
                hint: 'At least 6 characters',
                autofillHints: const [AutofillHints.newPassword],
                validator: LinkRules.passwordError,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Space.s6),
              SizedBox(
                height: 44,
                child: AppButton(label: 'Create account', loading: loading, onPressed: _submit, expand: true),
              ),
            ],
          ),
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Already have an account?', style: context.text.small),
          TextButton(
            onPressed: () => context.go('/login'),
            style: TextButton.styleFrom(foregroundColor: c.accent),
            child: const Text('Log in'),
          ),
        ],
      ),
    );
  }
}
