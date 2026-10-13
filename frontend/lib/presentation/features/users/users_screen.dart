import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/auth/auth_bloc.dart';
import '../../../core/di/injection_container.dart';
import '../../../models/user_model.dart';
import '../../../repositories/user_repository.dart';
import '../../components/app_button.dart';
import '../../components/app_toast.dart';
import '../../components/brand.dart';
import '../../components/empty_state.dart';
import '../../components/skeleton.dart';
import '../../components/status_badge.dart';
import '../../layout/page_scaffold.dart';
import '../../theme/app_tokens.dart';
import '../../theme/theme_extensions.dart';
import '../../utils/formatters.dart';
import 'cubit/users_cubit.dart';
import 'widgets/add_user_dialog.dart';

/// Admin-only: everyone with an account, plus "Add user".
class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => UsersCubit(sl<UserRepository>())..load(), child: const _UsersView());
  }
}

class _UsersView extends StatelessWidget {
  const _UsersView();

  Future<void> _add(BuildContext context) async {
    final user = await showAddUserDialog(context, context.read<UsersCubit>());
    if (user != null && context.mounted) {
      AppToast.success(context, '${user.name} added as ${user.isAdmin ? 'an admin' : 'a normal user'}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UsersCubit>().state;
    final cubit = context.read<UsersCubit>();

    final Widget body;
    if (state.users.isEmpty && state.status == UsersStatus.loading) {
      body = const _UsersSkeleton();
    } else if (state.users.isEmpty && state.status == UsersStatus.error) {
      body = EmptyState(
        icon: Icons.cloud_off_rounded,
        isError: true,
        title: "Couldn't load users",
        message: state.error ?? 'Something went wrong.',
        action: AppButton.secondary(label: 'Try again', icon: Icons.refresh_rounded, onPressed: cubit.load),
      );
    } else {
      body = _UsersTable(users: state.users);
    }

    return PageScaffold(
      title: 'Users',
      subtitle: state.users.isEmpty
          ? 'Everyone who can sign in to Shortly.'
          : '${state.users.length} ${state.users.length == 1 ? 'person' : 'people'} · '
                '${state.adminCount} ${state.adminCount == 1 ? 'admin' : 'admins'}',
      actions: [
        AppButton.secondary(label: 'Refresh', icon: Icons.refresh_rounded, onPressed: cubit.load),
        AppButton(label: 'Add user', icon: Icons.person_add_alt_1_rounded, onPressed: () => _add(context)),
      ],
      child: body,
    );
  }
}

class _UsersTable extends StatelessWidget {
  final List<UserModel> users;
  const _UsersTable({required this.users});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final myId = context.select<AuthBloc, String?>((b) => b.state.user?.id);

    Widget role(UserModel u) => u.isAdmin
        ? const StatusBadge('Admin', tone: BadgeTone.accent, icon: Icons.shield_outlined)
        : const StatusBadge('Normal');

    Widget nameCell(UserModel u) => Row(
      children: [
        UserAvatar(name: u.name),
        const SizedBox(width: Space.s3),
        Flexible(
          child: Text(
            u.name,
            style: t.body.copyWith(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (u.id == myId) ...[const SizedBox(width: Space.s2), const StatusBadge('You')],
      ],
    );

    Widget joined(UserModel u) => u.createdAt == null
        ? Text('—', style: t.small)
        : Tooltip(
            message: Fmt.dateTime(u.createdAt!),
            child: Text(Fmt.relative(u.createdAt!), style: t.small),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final frame = BoxDecoration(
          color: c.surface,
          borderRadius: Radii.lgAll,
          border: Border.all(color: c.border),
        );

        // Narrow: one card-row per user.
        if (constraints.maxWidth < 640) {
          return Container(
            decoration: frame,
            child: Column(
              children: [
                for (var i = 0; i < users.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: c.border),
                  Padding(
                    padding: const EdgeInsets.all(Space.s4),
                    child: Row(
                      children: [
                        UserAvatar(name: users[i].name),
                        const SizedBox(width: Space.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(users[i].name, style: t.body.copyWith(fontWeight: FontWeight.w500)),
                              Text(users[i].email, style: t.small, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: Space.s2),
                        role(users[i]),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        Widget head(String label, int flex) => Expanded(
          flex: flex,
          child: Text(label.toUpperCase(), style: t.overline),
        );

        return Container(
          decoration: frame,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: c.surfaceMuted,
                padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s2),
                child: Row(children: [head('Name', 4), head('Email', 5), head('Role', 2), head('Joined', 2)]),
              ),
              for (final u in users) ...[
                Divider(height: 1, color: c.border),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: nameCell(u)),
                      Expanded(flex: 5, child: SelectableText(u.email, style: t.small, maxLines: 1)),
                      Expanded(
                        flex: 2,
                        child: Align(alignment: Alignment.centerLeft, child: role(u)),
                      ),
                      Expanded(flex: 2, child: joined(u)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _UsersSkeleton extends StatelessWidget {
  const _UsersSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SkeletonScope(
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: Radii.lgAll,
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) Divider(height: 1, color: c.border),
              const Padding(
                padding: EdgeInsets.all(Space.s4),
                child: Row(
                  children: [
                    SkeletonBox(width: 32, height: 32, radius: BorderRadius.all(Radius.circular(16))),
                    SizedBox(width: Space.s3),
                    SkeletonBox(width: 140),
                    Spacer(),
                    SkeletonBox(width: 60),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
