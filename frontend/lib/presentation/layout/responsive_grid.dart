import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'breakpoints.dart';

/// A row of columns whose spans (out of 12) depend on the *container* width.
/// Columns that don't fit on one line wrap; at compact every column is full width.
class ResponsiveRow extends StatelessWidget {
  final List<ResponsiveCol> children;
  final double gap;

  const ResponsiveRow({super.key, required this.children, this.gap = Space.s6});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bp = Breakpoint.fromWidth(constraints.maxWidth);
        final width = constraints.maxWidth;
        final cols = children.map((c) => c.spanFor(bp)).toList();

        // Single column: stack with gaps; lets children size naturally.
        if (cols.every((s) => s >= 12)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i].child],
            ],
          );
        }

        // Multi-column: each run of spans ≤ 12 becomes a top-aligned Row.
        final rows = <List<int>>[[]];
        var used = 0;
        for (var i = 0; i < cols.length; i++) {
          if (used + cols[i] > 12) {
            rows.add([]);
            used = 0;
          }
          rows.last.add(i);
          used += cols[i];
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) SizedBox(height: gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var j = 0; j < rows[r].length; j++) ...[
                    if (j > 0) SizedBox(width: gap),
                    SizedBox(
                      width:
                          (width - gap * (rows[r].length - 1)) *
                          cols[rows[r][j]] /
                          rows[r].fold<int>(0, (sum, i) => sum + cols[i]).clamp(12, 1 << 30),
                      child: children[rows[r][j]].child,
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class ResponsiveCol {
  final Widget child;
  final int compact;
  final int? medium;
  final int? expanded;
  final int? large;

  const ResponsiveCol({required this.child, this.compact = 12, this.medium, this.expanded, this.large});

  int spanFor(Breakpoint bp) => responsiveValue(bp, compact: compact, medium: medium, expanded: expanded, large: large);
}
