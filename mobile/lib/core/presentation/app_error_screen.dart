import 'package:flutter/material.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:go_router/go_router.dart';

class AppErrorScreen extends StatelessWidget {
  const AppErrorScreen({
    super.key,
    required this.message,
    this.showHomeAction = true,
  });

  final String message;
  final bool showHomeAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppErrorWidget(
        message: message,
        onRetry: showHomeAction ? () => context.go(AppRoutes.home) : null,
      ),
    );
  }
}
