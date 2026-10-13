import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';
import '../utils/formatters.dart';

class BarItem {
  final String label;
  final num value;
  final VoidCallback? onTap;
  final bool mono;

  const BarItem(this.label, this.value, {this.onTap, this.mono = false});
}

/// Ranked horizontal bars drawn behind each label, value right-aligned
/// (Dub / Tremor "BarList"). Bars share one scale: the largest value.
class BarList extends StatelessWidget {
  final List<BarItem> items;
  final String valueLabel;

  const BarList({super.key, required this.items, this.valueLabel = 'clicks'});

  @override
  Widget build(BuildContext context) {
    final maxValue = items.fold<num>(0, (m, i) => i.value > m ? i.value : m);
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in items) ...[
            _BarRow(item: item, fraction: maxValue == 0 ? 0 : item.value / maxValue, valueLabel: valueLabel),
            const SizedBox(height: Space.s1),
          ],
        ],
      ),
    );
  }
}

class _BarRow extends StatefulWidget {
  final BarItem item;
  final double fraction;
  final String valueLabel;

  const _BarRow({required this.item, required this.fraction, required this.valueLabel});

  @override
  State<_BarRow> createState() => _BarRowState();
}

class _BarRowState extends State<_BarRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final item = widget.item;
    final labelStyle = item.mono ? t.mono.copyWith(fontSize: 13) : t.body;

    final row = SizedBox(
      height: 32,
      child: Stack(
        children: [
          // Minimum sliver so zero/small values still read as a bar.
          FractionallySizedBox(
            widthFactor: widget.fraction == 0 ? 0 : widget.fraction.clamp(0.02, 1.0),
            child: AnimatedContainer(
              duration: Motion.fast,
              decoration: BoxDecoration(
                color: _hover && item.onTap != null ? c.accent.withValues(alpha: 0.18) : c.accentSubtle,
                borderRadius: Radii.smAll,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s3),
            child: Row(
              children: [
                Expanded(
                  child: Text(item.label, style: labelStyle, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: Space.s3),
                Text(Fmt.count(item.value), style: t.caption.copyWith(color: c.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: '${item.label}, ${Fmt.count(item.value)} ${widget.valueLabel}',
      button: item.onTap != null,
      excludeSemantics: true,
      child: item.onTap == null
          ? row
          : MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hover = true),
              onExit: (_) => setState(() => _hover = false),
              child: GestureDetector(onTap: item.onTap, child: row),
            ),
    );
  }
}
