import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../bloc/url/url_bloc.dart';
import '../../../../bloc/url/url_event.dart';
import '../../../../models/url_model.dart';
import '../../../components/confirm_dialog.dart';
import '../../../components/copy_button.dart';
import '../../../components/qr_dialog.dart';
import '../../../theme/theme_extensions.dart';
import '../../../utils/formatters.dart';
import '../../../utils/link_launcher.dart';

Future<void> confirmDeleteLink(BuildContext context, UrlModel url) async {
  final bloc = context.read<UrlBloc>();
  final ok = await showConfirmDialog(
    context,
    title: 'Deactivate link?',
    message:
        '${Fmt.stripScheme(url.shortUrl)} will stop redirecting and disappear from your list. '
        'Its click history is kept.',
    confirmLabel: 'Deactivate',
    destructive: true,
  );
  if (ok) bloc.add(DeleteUrlRequested(url.id));
}

enum _MenuAction { open, qr, analytics, delete }

/// Copy · QR · Analytics · ⋯ (Open, Delete) for a single link.
/// [menuOnly] collapses everything into the ⋯ menu for tight layouts.
class LinkActionButtons extends StatelessWidget {
  final UrlModel url;
  final bool menuOnly;

  const LinkActionButtons({super.key, required this.url, this.menuOnly = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!menuOnly) ...[
          CopyButton(value: url.shortUrl),
          IconButton(
            tooltip: 'QR code',
            visualDensity: VisualDensity.compact,
            onPressed: () => showQrDialog(context, url: url.shortUrl, code: url.shortCode),
            icon: const Icon(Icons.qr_code_2_rounded, size: 18),
          ),
          IconButton(
            tooltip: 'View analytics',
            visualDensity: VisualDensity.compact,
            onPressed: () => context.go('/links/${url.id}'),
            icon: const Icon(Icons.bar_chart_rounded, size: 18),
          ),
        ],
        PopupMenuButton<_MenuAction>(
          tooltip: 'More actions',
          icon: const Icon(Icons.more_horiz_rounded, size: 18),
          style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
          position: PopupMenuPosition.under,
          onSelected: (action) => switch (action) {
            _MenuAction.open => openExternal(url.shortUrl),
            _MenuAction.qr => showQrDialog(context, url: url.shortUrl, code: url.shortCode),
            _MenuAction.analytics => context.go('/links/${url.id}'),
            _MenuAction.delete => confirmDeleteLink(context, url),
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: _MenuAction.open,
              height: 36,
              child: _MenuRow(icon: Icons.open_in_new_rounded, label: 'Open link'),
            ),
            if (menuOnly) ...[
              const PopupMenuItem(
                value: _MenuAction.qr,
                height: 36,
                child: _MenuRow(icon: Icons.qr_code_2_rounded, label: 'QR code'),
              ),
              const PopupMenuItem(
                value: _MenuAction.analytics,
                height: 36,
                child: _MenuRow(icon: Icons.bar_chart_rounded, label: 'View analytics'),
              ),
            ],
            const PopupMenuDivider(),
            PopupMenuItem(
              value: _MenuAction.delete,
              height: 36,
              child: _MenuRow(icon: Icons.delete_outline_rounded, label: 'Deactivate', color: c.danger),
            ),
          ],
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MenuRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.colors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? context.colors.textMuted),
        const SizedBox(width: 10),
        Text(label, style: context.text.body.copyWith(color: fg)),
      ],
    );
  }
}
