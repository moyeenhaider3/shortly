import 'package:flutter/material.dart';

import '../../../../models/user_model.dart';
import '../../../components/app_button.dart';
import '../../../components/app_text_field.dart';
import '../../../components/inline_alert.dart';
import '../../../theme/app_tokens.dart';
import '../../../theme/theme_extensions.dart';
import '../../../utils/link_rules.dart';
import '../../auth/widgets/password_field.dart';
import '../cubit/users_cubit.dart';

/// Opens the dialog; resolves to the created user, or null if cancelled.
Future<UserModel?> showAddUserDialog(BuildContext context, UsersCubit cubit) {
  return showDialog<UserModel>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AddUserDialog(cubit: cubit),
  );
}

class _AddUserDialog extends StatefulWidget {
  final UsersCubit cubit;
  const _AddUserDialog({required this.cubit});

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = UserModel.roleNormal;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final user = await widget.cubit.create(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        role: _role,
      );
      if (mounted) Navigator.of(context).pop(user);
    } catch (message) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$message';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.s6),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Add user', style: t.h2)),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(
                  'They can log in right away with this email and password. Share the password with them securely.',
                  style: t.small,
                ),
                const SizedBox(height: Space.s6),
                if (_error != null) ...[InlineAlert(_error!), const SizedBox(height: Space.s4)],
                AppTextField(
                  label: 'Full name',
                  controller: _name,
                  hint: 'Ada Lovelace',
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final n = (v ?? '').trim().length;
                    if (n < 2) return 'Enter at least 2 characters';
                    if (n > 50) return 'Use 50 characters or fewer';
                    return null;
                  },
                ),
                const SizedBox(height: Space.s4),
                AppTextField(
                  label: 'Email',
                  controller: _email,
                  hint: 'ada@company.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: LinkRules.emailError,
                ),
                const SizedBox(height: Space.s4),
                PasswordField(
                  controller: _password,
                  label: 'Temporary password',
                  hint: 'At least 6 characters',
                  autofillHints: const [AutofillHints.newPassword],
                  validator: LinkRules.passwordError,
                ),
                const SizedBox(height: Space.s5),
                Text('Role', style: t.h3.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: Space.s2),
                _RoleOption(
                  title: 'Normal',
                  description: 'Creates and manages their own links and analytics.',
                  icon: Icons.person_outline_rounded,
                  selected: _role == UserModel.roleNormal,
                  onTap: () => setState(() => _role = UserModel.roleNormal),
                ),
                const SizedBox(height: Space.s2),
                _RoleOption(
                  title: 'Admin',
                  description: 'Everything a normal user can do, plus adding users and creating other admins.',
                  icon: Icons.admin_panel_settings_outlined,
                  selected: _role == UserModel.roleAdmin,
                  onTap: () => setState(() => _role = UserModel.roleAdmin),
                ),
                const SizedBox(height: Space.s6),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: Space.s2,
                  runSpacing: Space.s2,
                  children: [
                    AppButton.secondary(label: 'Cancel', onPressed: _saving ? null : () => Navigator.of(context).pop()),
                    AppButton(
                      label: _role == UserModel.roleAdmin ? 'Create admin' : 'Create user',
                      icon: Icons.person_add_alt_1_rounded,
                      loading: _saving,
                      onPressed: _submit,
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

/// Radio-style card: whole card is the hit target, selection shown by border,
/// tint and a check, never by colour alone.
class _RoleOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '$title role. $description',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.mdAll,
        child: AnimatedContainer(
          duration: Motion.fast,
          padding: const EdgeInsets.all(Space.s3),
          decoration: BoxDecoration(
            color: selected ? c.accentSubtle : c.surface,
            borderRadius: Radii.mdAll,
            border: Border.all(color: selected ? c.accent : c.borderStrong, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: selected ? c.accent : c.textMuted),
              const SizedBox(width: Space.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.h3),
                    Text(description, style: t.small),
                  ],
                ),
              ),
              const SizedBox(width: Space.s2),
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: selected ? c.accent : c.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
