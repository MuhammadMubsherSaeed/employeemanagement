import 'package:flutter/material.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_breakpoints.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_icon_well.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_base/features/settings/domain/settings_access.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsAccess access = SettingsAccess(
      ref.watch(authorizationProvider),
    );
    final TextTheme text = Theme.of(context).textTheme;
    final String subtitle = access.canEdit
        ? 'View and update company configuration.'
        : 'View company configuration.';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: AppBreakpoints.pagePadding(context),
        children: <Widget>[
          Text(subtitle, style: text.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.apartment_outlined,
            title: 'Company',
            subtitle: 'Name, logo, and timezone.',
            onTap: () => context.push(AppRoutes.settingsCompany),
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.schedule_outlined,
            title: 'Attendance',
            subtitle: 'Work hours, grace period, and working days.',
            onTap: () => context.push(AppRoutes.settingsAttendance),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          AppIconWell(icon: icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: text.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle, style: text.bodySmall),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }
}
