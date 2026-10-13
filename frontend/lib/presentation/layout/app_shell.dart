import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/url/url_bloc.dart';
import '../../bloc/url/url_state.dart';
import '../../models/user_model.dart';
import '../components/app_toast.dart';
import '../components/brand.dart';
import '../components/theme_switcher.dart';
import '../components/user_menu.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';
import '../theme/theme_mode_cubit.dart';
import 'breakpoints.dart';
import 'shell_commands.dart';

class _Destination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
  const _Destination(this.label, this.icon, this.selectedIcon, this.path);
}

const _baseDestinations = [
  _Destination('Dashboard', Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, '/'),
  _Destination('Links', Icons.link_rounded, Icons.link_rounded, '/links'),
  _Destination('Analytics', Icons.bar_chart_rounded, Icons.bar_chart_rounded, '/analytics'),
];

const _usersDestination = _Destination('Users', Icons.group_outlined, Icons.group_rounded, '/users');

/// Admins also get user management. The route and API are guarded separately;
/// hiding the entry is only for a clean UI.
List<_Destination> _destinationsFor(UserModel? user) =>
    user?.isAdmin == true ? const [..._baseDestinations, _usersDestination] : _baseDestinations;

/// Persistent frame around authenticated pages. Navigation adapts to width:
/// sidebar (≥1024) → icon rail (600–1023) → top bar + bottom nav (<600).
class AppShell extends StatelessWidget {
  final String location;
  final Widget child;

  const AppShell({super.key, required this.location, required this.child});

  /// Last matching path prefix wins ('/' matches everything), so
  /// `/links/abc` selects Links.
  int _selectedIndex(List<_Destination> destinations) {
    var best = 0;
    for (var i = 1; i < destinations.length; i++) {
      if (location.startsWith(destinations[i].path)) best = i;
    }
    return best;
  }

  void _focusSearch(BuildContext context) {
    if (location != '/links') context.go('/links');
    // Let the links page mount before asking it to focus its search field.
    WidgetsBinding.instance.addPostFrameCallback((_) => ShellCommands.focusSearch.value++);
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.breakpoint;
    final user = context.select<AuthBloc, UserModel?>((b) => b.state.user);
    final c = context.colors;
    final destinations = _destinationsFor(user);
    final selected = _selectedIndex(destinations);

    final Widget body = switch (bp) {
      Breakpoint.compact => Scaffold(
        appBar: AppBar(
          title: const BrandLogo(size: 24),
          actions: [
            if (user != null) UserMenu(user: user),
            const SizedBox(width: Space.s2),
          ],
        ),
        body: child,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: NavigationBar(
            selectedIndex: selected,
            onDestinationSelected: (i) => context.go(destinations[i].path),
            destinations: [
              for (final d in destinations)
                NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
            ],
          ),
        ),
      ),
      Breakpoint.medium => Scaffold(
        body: Row(
          children: [
            _Rail(destinations: destinations, selectedIndex: selected, user: user),
            Expanded(child: child),
          ],
        ),
      ),
      _ => Scaffold(
        body: Row(
          children: [
            _Sidebar(destinations: destinations, selectedIndex: selected, user: user),
            Expanded(child: child),
          ],
        ),
      ),
    };

    return BlocListener<UrlBloc, UrlState>(
      // Delete can be triggered from any page, so its feedback lives here.
      listenWhen: (_, s) =>
          (s is UrlActionSuccess && s.action == UrlAction.delete) || (s is UrlError && s.action == UrlAction.delete),
      listener: (context, s) => switch (s) {
        UrlActionSuccess(:final message) => AppToast.success(context, message),
        UrlError(:final message) => AppToast.error(context, message),
        _ => null,
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () => _focusSearch(context),
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): () => _focusSearch(context),
        },
        child: Focus(autofocus: true, child: body),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final List<_Destination> destinations;
  final int selectedIndex;
  final UserModel? user;

  const _Sidebar({required this.destinations, required this.selectedIndex, required this.user});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return RepaintBoundary(
      child: Container(
        width: Layout.sidebarWidth,
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(right: BorderSide(color: c.border)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(Space.s5, Space.s5, Space.s5, Space.s6),
                child: Align(alignment: Alignment.centerLeft, child: BrandLogo()),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.s3),
                child: const _SearchHint(),
              ),
              const SizedBox(height: Space.s4),
              Expanded(
                child: FocusTraversalGroup(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: Space.s3),
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        _NavItem(destination: destinations[i], selected: i == selectedIndex),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.s5, vertical: Space.s3),
                child: Row(
                  children: [
                    Expanded(child: Text('Theme', style: context.text.caption)),
                    const ThemeSwitcher(),
                  ],
                ),
              ),
              Divider(color: c.border),
              if (user != null)
                Padding(
                  padding: const EdgeInsets.all(Space.s2),
                  child: UserMenu(user: user!, expanded: true),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Faux search box in the sidebar that advertises the ⌘K shortcut.
class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isMac = Theme.of(context).platform == TargetPlatform.macOS;
    return Semantics(
      button: true,
      label: 'Search links',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: Radii.mdAll,
        onTap: () {
          context.go('/links');
          WidgetsBinding.instance.addPostFrameCallback((_) => ShellCommands.focusSearch.value++);
        },
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: Space.s3),
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: Radii.mdAll,
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 16, color: c.textMuted),
              const SizedBox(width: Space.s2),
              Expanded(child: Text('Search links', style: context.text.small)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: Radii.smAll,
                  border: Border.all(color: c.border),
                ),
                child: Text(isMac ? '⌘K' : 'Ctrl K', style: context.text.caption),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _Destination destination;
  final bool selected;

  const _NavItem({required this.destination, required this.selected});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        selected: selected,
        button: true,
        label: destination.label,
        excludeSemantics: true,
        child: Material(
          color: selected ? c.surfaceMuted : const Color(0x00000000),
          borderRadius: Radii.mdAll,
          child: InkWell(
            borderRadius: Radii.mdAll,
            onTap: () => context.go(destination.path),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: Space.s2),
              child: Row(
                children: [
                  Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 18,
                    color: selected ? c.accent : c.textMuted,
                  ),
                  const SizedBox(width: Space.s3),
                  Text(
                    destination.label,
                    style: context.text.body.copyWith(
                      color: selected ? c.textPrimary : c.textMuted,
                      fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  final List<_Destination> destinations;
  final int selectedIndex;
  final UserModel? user;

  const _Rail({required this.destinations, required this.selectedIndex, required this.user});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return RepaintBoundary(
      child: Container(
        width: Layout.railWidth,
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(right: BorderSide(color: c.border)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: Space.s5),
              const BrandLogo(showWordmark: false),
              const SizedBox(height: Space.s6),
              for (var i = 0; i < destinations.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.s1),
                  child: Tooltip(
                    message: destinations[i].label,
                    child: IconButton(
                      onPressed: () => context.go(destinations[i].path),
                      isSelected: i == selectedIndex,
                      style: IconButton.styleFrom(
                        backgroundColor: i == selectedIndex ? c.surfaceMuted : null,
                        fixedSize: const Size(44, 40),
                      ),
                      icon: Icon(destinations[i].icon, size: 20),
                      selectedIcon: Icon(destinations[i].selectedIcon, size: 20, color: c.accent),
                    ),
                  ),
                ),
              const Spacer(),
              Tooltip(
                message: context.isDark ? 'Light mode' : 'Dark mode',
                child: IconButton(
                  onPressed: () => context.read<ThemeModeCubit>().toggle(Theme.of(context).brightness),
                  icon: Icon(context.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 18),
                ),
              ),
              if (user != null) UserMenu(user: user!),
              const SizedBox(height: Space.s4),
            ],
          ),
        ),
      ),
    );
  }
}
