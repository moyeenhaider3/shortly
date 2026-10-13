import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';
import '../theme/theme_mode_cubit.dart';

/// Three-way System / Light / Dark pill.
class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  static const _options = [
    (ThemeMode.system, Icons.desktop_windows_outlined, 'System theme'),
    (ThemeMode.light, Icons.light_mode_outlined, 'Light theme'),
    (ThemeMode.dark, Icons.dark_mode_outlined, 'Dark theme'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mode = context.watch<ThemeModeCubit>().state;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: Radii.mdAll,
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (value, icon, label) in _options)
            Tooltip(
              message: label,
              child: Semantics(
                selected: mode == value,
                button: true,
                label: label,
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => context.read<ThemeModeCubit>().setMode(value),
                  borderRadius: Radii.smAll,
                  child: AnimatedContainer(
                    duration: Motion.fast,
                    width: 28,
                    height: 24,
                    decoration: BoxDecoration(
                      color: mode == value ? c.surface : null,
                      borderRadius: Radii.smAll,
                      border: mode == value ? Border.all(color: c.border) : null,
                    ),
                    child: Icon(icon, size: 14, color: mode == value ? c.textPrimary : c.textMuted),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
