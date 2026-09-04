import 'package:flutter/material.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:go_router/go_router.dart';

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  static const String message =
      "You don't have permission to access this section.";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access denied')),
      body: AppEmptyState(
        icon: Icons.lock_outline,
        title: 'Access denied',
        subtitle: message,
        action: AppButton(
          label: 'Go to home',
          expand: false,
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
    );
  }
}
