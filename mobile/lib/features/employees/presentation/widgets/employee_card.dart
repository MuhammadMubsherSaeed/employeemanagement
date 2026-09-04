import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_dimensions.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_avatar.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_status_badge.dart';

class EmployeeCard extends StatelessWidget {
  const EmployeeCard({
    super.key,
    required this.employee,
    this.onTap,
  });

  final Employee employee;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String meta = <String?>[
      employee.department?.name,
      employee.position?.title,
    ]
        .whereType<String>()
        .where((String v) => v.isNotEmpty)
        .join(' · ');
    return Semantics(
      button: onTap != null,
      label: '${employee.fullName}, ${employee.employeeCode}',
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: <Widget>[
            AppAvatar(
              name: employee.fullName,
              imageUrl: employee.profileImage.isEmpty
                  ? null
                  : employee.profileImage,
              size: AppDimensions.avatarLg,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    employee.fullName,
                    style: text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    employee.employeeCode,
                    style: text.bodySmall,
                  ),
                  if (meta.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      meta,
                      style: text.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (employee.manager != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      employee.manager!.fullName,
                      style: text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            EmployeeStatusBadge(status: employee.status),
          ],
        ),
      ),
    );
  }
}

class EmployeeListItem extends StatelessWidget {
  const EmployeeListItem({
    super.key,
    required this.employee,
    this.onTap,
  });

  final Employee employee;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '${employee.fullName}, ${employee.employeeCode}',
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        leading: AppAvatar(
          name: employee.fullName,
          imageUrl:
              employee.profileImage.isEmpty ? null : employee.profileImage,
        ),
        title: Text(employee.fullName),
        subtitle: Text(
          <String?>[
            employee.employeeCode,
            employee.department?.name,
            employee.position?.title,
          ].whereType<String>().where((String v) => v.isNotEmpty).join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: EmployeeStatusBadge(status: employee.status),
      ),
    );
  }
}
