import 'package:flutter/material.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: AppLoader(message: 'Loading...'),
      ),
    );
  }
}
