import 'package:flutter/material.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/features/attendance/domain/attendance_access.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:go_router/go_router.dart';

class AttendanceProfileLink extends StatelessWidget {
  const AttendanceProfileLink({
    super.key,
    required this.role,
    this.isSelf = false,
  });

  final UserRole role;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    final AttendanceAccess access = AttendanceAccess(role);
    final String subtitle = isSelf
        ? 'Open your attendance dashboard to check in, check out, and review your records.'
        : access.canViewTeam
            ? 'Open attendance to view records your role is authorized to see. The server decides which employees are included.'
            : 'Open attendance to view your own records.';

    return Padding(
      padding: AppSpacing.screen,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Attendance', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            if (access.canView)
              AppButton(
                label: isSelf ? 'Open my attendance' : 'Open attendance',
                onPressed: () => context.push(AppRoutes.attendance),
              ),
          ],
        ),
      ),
    );
  }
}
