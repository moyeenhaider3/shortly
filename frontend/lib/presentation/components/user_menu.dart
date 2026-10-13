import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../models/user_model.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';
import '../theme/theme_mode_cubit.dart';
import 'brand.dart';
import 'status_badge.dart';

/// Avatar button that opens account info, theme toggle and logout.
/// [expanded] shows name + email next to the avatar (sidebar layout).
class UserMenu extends StatelessWidget {
  final UserModel user;
  final bool expanded;

  const UserMenu({super.key, required this.user, this.expanded = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final isDark = context.isDark;

    return MenuAnchor(
      alignmentOffset: const Offset(0, Space.s1),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s3),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 260),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: t.h3, overflow: TextOverflow.ellipsis),
                Text(user.email, style: t.small, overflow: TextOverflow.ellipsis),
                if (user.role == 'ADMIN') ...[
                  const SizedBox(height: Space.s2),
                  const StatusBadge('Admin', tone: BadgeTone.accent),
                ],
              ],
            ),
          ),
        ),
        const Divider(),
        MenuItemButton(
          leadingIcon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 18),
          onPressed: () => context.read<ThemeModeCubit>().toggle(Theme.of(context).brightness),
          child: Text(isDark ? 'Light mode' : 'Dark mode'),
        ),
        MenuItemButton(
          leadingIcon: Icon(Icons.logout_rounded, size: 18, color: c.danger),
          onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
          child: Text('Log out', style: TextStyle(color: c.danger)),
        ),
      ],
      builder: (context, controller, _) {
        void toggle() => controller.isOpen ? controller.close() : controller.open();
        if (!expanded) {
          return IconButton(
            tooltip: 'Account',
            onPressed: toggle,
            icon: UserAvatar(name: user.name, size: 28),
          );
        }
        return Semantics(
          button: true,
          label: 'Account menu for ${user.name}',
          excludeSemantics: true,
          child: InkWell(
            onTap: toggle,
            borderRadius: Radii.mdAll,
            child: Padding(
              padding: const EdgeInsets.all(Space.s2),
              child: Row(
                children: [
                  UserAvatar(name: user.name),
                  const SizedBox(width: Space.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: t.h3, overflow: TextOverflow.ellipsis),
                        Text(user.email, style: t.caption, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Icon(Icons.unfold_more_rounded, size: 16, color: c.textMuted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
