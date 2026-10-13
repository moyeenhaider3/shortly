import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../components/app_button.dart';
import '../components/empty_state.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Title(
      title: 'Page not found · Shortly',
      color: Theme.of(context).colorScheme.primary,
      child: Scaffold(
        body: Center(
          child: EmptyState(
            icon: Icons.explore_off_outlined,
            title: 'Page not found',
            message: "The page you're looking for doesn't exist or has moved.",
            action: AppButton(label: 'Go to dashboard', onPressed: () => context.go('/')),
          ),
        ),
      ),
    );
  }
}
