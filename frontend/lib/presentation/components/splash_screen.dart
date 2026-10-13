import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'brand.dart';

/// Shown while the stored session is being verified, so protected pages
/// never flash before the auth check finishes.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(showWordmark: false, size: 40),
            SizedBox(height: Space.s6),
            SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
    );
  }
}
