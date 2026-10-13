import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';
import '../utils/formatters.dart';

class ColumnDatum {
  final String label;
  final String tooltip;
  final num value;
  const ColumnDatum({required this.label, required this.tooltip, required this.value});
}

/// Minimal vertical bar chart: light gridlines, bottom labels, hover tooltips.
/// Every [labelEvery]-th label is shown to keep the axis readable.
class ColumnChart extends StatelessWidget {
  final List<ColumnDatum> data;
  final double height;
  final int labelEvery;
  final String valueLabel;

  const ColumnChart({super.key, required this.data, this.height = 180, this.labelEvery = 1, this.valueLabel = 'links'});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final maxValue = data.fold<num>(0, (m, d) => d.value > m ? d.value : m);
    // Round the scale up so the tallest bar doesn't touch the top gridline.
    final scale = maxValue <= 4 ? 4 : (maxValue * 1.15).ceil();

    return RepaintBoundary(
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Gridlines at 0, ½, max with the scale value on the right.
                  for (final f in const [0.0, 0.5, 1.0])
                    Align(
                      alignment: Alignment(0, 1 - f * 2),
                      child: Row(
                        children: [
                          Expanded(child: Container(height: 1, color: c.border)),
                          SizedBox(
                            width: 32,
                            child: Text(Fmt.count((scale * f).round()), style: t.caption, textAlign: TextAlign.right),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 40),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final d in data)
                          Expanded(
                            child: Tooltip(
                              message: '${d.tooltip}: ${Fmt.count(d.value)} $valueLabel',
                              child: Semantics(
                                label: '${d.tooltip}, ${Fmt.count(d.value)} $valueLabel',
                                excludeSemantics: true,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: FractionallySizedBox(
                                    heightFactor: d.value == 0 ? 0.01 : d.value / scale,
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: d.value == 0 ? c.border : c.accent,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.s2),
            Padding(
              padding: const EdgeInsets.only(right: 40),
              child: Row(
                children: [
                  for (var i = 0; i < data.length; i++)
                    Expanded(
                      child: Text(
                        i % labelEvery == 0 ? data[i].label : '',
                        style: t.caption,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
