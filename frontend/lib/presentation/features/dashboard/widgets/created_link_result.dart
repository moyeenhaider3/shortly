import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../models/url_model.dart';
import '../../../components/app_button.dart';
import '../../../components/app_card.dart';
import '../../../components/app_toast.dart';
import '../../../components/qr_dialog.dart';
import '../../../theme/app_tokens.dart';
import '../../../theme/theme_extensions.dart';
import '../../../utils/link_launcher.dart';

/// Confirmation card for a freshly created link with the primary next steps.
class CreatedLinkResult extends StatelessWidget {
  final UrlModel url;
  final VoidCallback onDismiss;

  const CreatedLinkResult({super.key, required this.url, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return AppCard(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 18, color: c.success),
              const SizedBox(width: Space.s2),
              Expanded(child: Text('Your short link is ready', style: t.h3)),
              IconButton(
                tooltip: 'Dismiss',
                visualDensity: VisualDensity.compact,
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, size: 16),
              ),
            ],
          ),
          const SizedBox(height: Space.s3),
          SelectableText(url.shortUrl, style: t.mono.copyWith(fontSize: 18, color: c.accent)),
          const SizedBox(height: Space.s1),
          Text('→ ${url.originalUrl}', style: t.small, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: Space.s4),
          Wrap(
            spacing: Space.s2,
            runSpacing: Space.s2,
            children: [
              AppButton(
                label: 'Copy link',
                icon: Icons.content_copy_rounded,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url.shortUrl));
                  if (context.mounted) AppToast.success(context, 'Copied to clipboard');
                },
              ),
              AppButton.secondary(
                label: 'QR code',
                icon: Icons.qr_code_2_rounded,
                onPressed: () => showQrDialog(context, url: url.shortUrl, code: url.shortCode),
              ),
              AppButton.secondary(
                label: 'Open',
                icon: Icons.open_in_new_rounded,
                onPressed: () => openExternal(url.shortUrl),
              ),
              AppButton.secondary(
                label: 'Analytics',
                icon: Icons.bar_chart_rounded,
                onPressed: () => context.go('/links/${url.id}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
