import 'package:flutter/material.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/theme/theme_mode_controller.dart';
import 'package:flutter_base/core/widgets/app_avatar.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_dialog.dart';
import 'package:flutter_base/core/widgets/app_status_badge.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    final bool? confirmed = await AppDialog.confirm(
      context: context,
      title: 'Sign out',
      message: 'Sign out of this device?',
      confirmLabel: 'Sign out',
    );
    if (confirmed != true || _loggingOut) {
      return;
    }
    setState(() => _loggingOut = true);
    try {
      await ref.read(authControllerProvider.notifier).logout();
    } finally {
      if (mounted) {
        setState(() => _loggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthState auth = ref.watch(authControllerProvider);
    final User? user = auth is AuthAuthenticated ? auth.user : null;
    final ThemeMode themeMode = ref.watch(themeModeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: <Widget>[
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () =>
                ref.read(themeModeControllerProvider.notifier).cycle(),
            icon: Icon(switch (themeMode) {
              ThemeMode.light => Icons.light_mode_outlined,
              ThemeMode.dark => Icons.dark_mode_outlined,
              ThemeMode.system => Icons.brightness_auto_outlined,
            }),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screen,
          children: <Widget>[
            AppCard(
              child: Row(
                children: <Widget>[
                  AppAvatar(name: user?.fullName ?? 'User'),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          user?.fullName.isNotEmpty == true
                              ? user!.fullName
                              : 'Signed in',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(user?.email ?? ''),
                        const SizedBox(height: AppSpacing.xs),
                        AppStatusBadge(
                          label: user?.roleValue ?? 'UNKNOWN',
                          tone: AppBadgeTone.info,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Text(
                'This is a temporary home screen. HRMS modules will be added later.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Sign out',
              variant: AppButtonVariant.outlined,
              isLoading: _loggingOut,
              onPressed: _loggingOut ? null : _logout,
            ),
          ],
        ),
      ),
    );
  }
}
