import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';

/// Pulsing placeholder block. One shared animation drives every block inside
/// a [SkeletonScope], so a skeleton list costs a single ticker.
class SkeletonScope extends StatefulWidget {
  final Widget child;
  const SkeletonScope({super.key, required this.child});

  @override
  State<SkeletonScope> createState() => _SkeletonScopeState();
}

class _SkeletonScopeState extends State<SkeletonScope> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Loading',
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: reduceMotion ? const AlwaysStoppedAnimation(1) : Tween(begin: 0.5, end: 1.0).animate(_controller),
          child: widget.child,
        ),
      ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius radius;

  const SkeletonBox({super.key, this.width, this.height = 12, this.radius = Radii.smAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: context.colors.surfaceMuted, borderRadius: radius),
    );
  }
}
