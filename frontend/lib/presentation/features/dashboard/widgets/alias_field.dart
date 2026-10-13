import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/app_tokens.dart';
import '../../../theme/theme_extensions.dart';
import '../cubit/alias_check_cubit.dart';

/// Alias input with a fixed domain prefix and a live availability line.
class AliasField extends StatelessWidget {
  final TextEditingController controller;
  final String domainPrefix;
  final ValueChanged<String>? onSubmitted;

  const AliasField({super.key, required this.controller, required this.domainPrefix, this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('Custom alias', style: t.h3.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(width: Space.s2),
            Text('Optional', style: t.caption),
          ],
        ),
        const SizedBox(height: Space.s2),
        Semantics(
          label: 'Custom alias',
          child: TextField(
            controller: controller,
            onChanged: context.read<AliasCheckCubit>().onChanged,
            onSubmitted: onSubmitted,
            style: t.mono,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.go,
            decoration: InputDecoration(
              hintText: 'my-campaign',
              hintStyle: t.mono.copyWith(color: c.textMuted.withValues(alpha: 0.6)),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              prefixIcon: Container(
                margin: const EdgeInsets.only(right: Space.s2),
                padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: 10),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  border: Border(right: BorderSide(color: c.borderStrong)),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(Radii.md)),
                ),
                child: Text(domainPrefix, style: t.mono.copyWith(color: c.textMuted)),
              ),
              suffixIcon: const _StatusIcon(),
            ),
          ),
        ),
        const SizedBox(height: Space.s2),
        const _StatusLine(),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final status = context.select<AliasCheckCubit, AliasStatus>((cubit) => cubit.state.status);
    final Widget? icon = switch (status) {
      AliasStatus.checking => const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 1.5)),
      AliasStatus.available => Icon(Icons.check_circle_rounded, size: 18, color: c.success),
      AliasStatus.taken || AliasStatus.invalid => Icon(Icons.cancel_rounded, size: 18, color: c.danger),
      AliasStatus.unknown => Icon(Icons.help_outline_rounded, size: 18, color: c.warning),
      AliasStatus.idle => null,
    };
    if (icon == null) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.all(Space.s3), child: icon);
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final state = context.watch<AliasCheckCubit>().state;
    final (text, color) = switch (state.status) {
      AliasStatus.idle => (
        'Leave empty for a random code. Letters, numbers and hyphens, 3–30 characters.',
        c.textMuted,
      ),
      AliasStatus.checking => ('Checking availability…', c.textMuted),
      AliasStatus.available => ('This alias is available', c.success),
      AliasStatus.taken || AliasStatus.invalid => (state.message ?? 'Not available', c.danger),
      AliasStatus.unknown => (state.message ?? "Couldn't check availability", c.warning),
    };
    return Semantics(
      liveRegion: state.status != AliasStatus.idle && state.status != AliasStatus.checking,
      child: AnimatedSwitcher(
        duration: Motion.fast,
        child: Text(
          text,
          key: ValueKey(text),
          style: t.small.copyWith(color: color),
        ),
      ),
    );
  }
}
