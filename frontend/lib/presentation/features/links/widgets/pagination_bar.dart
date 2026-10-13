import 'package:flutter/material.dart';

import '../../../theme/app_tokens.dart';
import '../../../theme/theme_extensions.dart';
import '../link_query.dart';

class PaginationBar extends StatelessWidget {
  final LinkPage page;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const PaginationBar({super.key, required this.page, required this.onPrevious, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.only(top: Space.s3),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                page.matched == 0 ? 'No links' : '${page.rangeStart}–${page.rangeEnd} of ${page.matched}',
                style: t.small,
              ),
            ),
          ),
          if (page.pageCount > 1) ...[
            OutlinedButton(onPressed: page.hasPrevious ? onPrevious : null, child: const Text('Previous')),
            const SizedBox(width: Space.s2),
            OutlinedButton(onPressed: page.hasNext ? onNext : null, child: const Text('Next')),
          ],
        ],
      ),
    );
  }
}
