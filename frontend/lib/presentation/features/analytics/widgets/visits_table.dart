import 'package:flutter/material.dart';

import '../../../../models/url_analytics_model.dart';
import '../../../components/empty_state.dart';
import '../../../theme/app_tokens.dart';
import '../../../theme/theme_extensions.dart';
import '../../../utils/formatters.dart';
import '../../../utils/ip_mask.dart';
import '../../../utils/user_agent_parser.dart';

/// Last visits with parsed browser / OS / device. IPs are personal data, so
/// they're masked until the owner explicitly reveals them.
class VisitsTable extends StatefulWidget {
  final List<VisitModel> visits;
  final List<ParsedUserAgent> agents;

  const VisitsTable({super.key, required this.visits, required this.agents});

  @override
  State<VisitsTable> createState() => _VisitsTableState();
}

class _VisitsTableState extends State<VisitsTable> {
  bool _revealIps = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;

    if (widget.visits.isEmpty) {
      return const EmptyState(
        icon: Icons.visibility_off_outlined,
        title: 'No visits yet',
        message: 'Open the short link in another tab to record a visit.',
      );
    }

    final ipToggle = TextButton.icon(
      onPressed: () => setState(() => _revealIps = !_revealIps),
      style: TextButton.styleFrom(
        foregroundColor: c.textMuted,
        padding: const EdgeInsets.symmetric(horizontal: Space.s2),
      ),
      icon: Icon(_revealIps ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 16),
      label: Text(_revealIps ? 'Hide IPs' : 'Show IPs'),
    );

    String ip(VisitModel v) => _revealIps ? displayIp(v.ip) : maskIp(v.ip);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Narrow: stacked rows.
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.centerRight, child: ipToggle),
              for (var i = 0; i < widget.visits.length; i++) ...[
                if (i > 0) Divider(height: 1, color: c.border),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.s3),
                  child: Row(
                    children: [
                      _DeviceIcon(device: widget.agents[i].device),
                      const SizedBox(width: Space.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${widget.agents[i].browser} · ${widget.agents[i].os}', style: t.body),
                            Text(ip(widget.visits[i]), style: t.mono.copyWith(fontSize: 12, color: c.textMuted)),
                          ],
                        ),
                      ),
                      Tooltip(
                        message: Fmt.dateTime(widget.visits[i].visitedAt),
                        child: Text(Fmt.relative(widget.visits[i].visitedAt), style: t.small),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        }

        Widget head(String label, int flex) => Expanded(
          flex: flex,
          child: Text(label.toUpperCase(), style: t.overline),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s2),
              child: Row(
                children: [
                  head('Time', 3),
                  head('Browser', 3),
                  head('OS', 3),
                  head('Device', 3),
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        Text('IP', style: t.overline),
                        const Spacer(),
                        ipToggle,
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < widget.visits.length; i++) ...[
              Divider(height: 1, color: c.border),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.s3),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Tooltip(
                        message: Fmt.dateTime(widget.visits[i].visitedAt),
                        child: Text(Fmt.relative(widget.visits[i].visitedAt), style: t.body),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(widget.agents[i].browser, style: t.body, overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(widget.agents[i].os, style: t.body, overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          _DeviceIcon(device: widget.agents[i].device, size: 14),
                          const SizedBox(width: Space.s2),
                          Flexible(
                            child: Text(widget.agents[i].device, style: t.body, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Tooltip(
                        message: widget.visits[i].userAgent ?? 'Unknown user agent',
                        child: Text(ip(widget.visits[i]), style: t.mono.copyWith(fontSize: 13, color: c.textMuted)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DeviceIcon extends StatelessWidget {
  final String device;
  final double size;
  const _DeviceIcon({required this.device, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final icon = switch (device) {
      'Mobile' => Icons.smartphone_rounded,
      'Tablet' => Icons.tablet_mac_rounded,
      'Desktop' => Icons.desktop_windows_outlined,
      'Bot' => Icons.smart_toy_outlined,
      _ => Icons.devices_other_rounded,
    };
    return Icon(icon, size: size, color: context.colors.textMuted, semanticLabel: device);
  }
}
