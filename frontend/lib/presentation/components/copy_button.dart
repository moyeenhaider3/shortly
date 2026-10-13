import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';

/// Icon button that copies [value] and morphs into a check for 1.5s.
class CopyButton extends StatefulWidget {
  final String value;
  final String tooltip;
  final double size;

  const CopyButton({super.key, required this.value, this.tooltip = 'Copy link', this.size = 16});

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _copied = false;
  Timer? _reset;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    setState(() => _copied = true);
    SemanticsService.sendAnnouncement(View.of(context), 'Copied to clipboard', Directionality.of(context));
    _reset?.cancel();
    _reset = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IconButton(
      tooltip: _copied ? 'Copied!' : widget.tooltip,
      onPressed: _copy,
      visualDensity: VisualDensity.compact,
      icon: AnimatedSwitcher(
        duration: Motion.fast,
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: _copied
            ? Icon(Icons.check_rounded, key: const ValueKey('done'), size: widget.size, color: c.success)
            : Icon(Icons.content_copy_rounded, key: const ValueKey('copy'), size: widget.size),
      ),
    );
  }
}
