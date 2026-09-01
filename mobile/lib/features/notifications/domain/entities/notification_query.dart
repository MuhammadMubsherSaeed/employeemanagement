import 'package:equatable/equatable.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_enums.dart';

class NotificationQuery extends Equatable {
  const NotificationQuery({
    this.isRead,
    this.type,
    this.createdAtAfter,
    this.createdAtBefore,
    this.page = 1,
    this.pageSize = AppConstants.defaultPageSize,
  });

  final bool? isRead;
  final AppNotificationType? type;
  final DateTime? createdAtAfter;
  final DateTime? createdAtBefore;
  final int page;
  final int pageSize;

  int get activeFilterCount {
    int count = 0;
    if (isRead != null) {
      count++;
    }
    if (type != null && type != AppNotificationType.unknown) {
      count++;
    }
    if (createdAtAfter != null) {
      count++;
    }
    if (createdAtBefore != null) {
      count++;
    }
    return count;
  }

  NotificationQuery copyWith({
    bool? isRead,
    AppNotificationType? type,
    DateTime? createdAtAfter,
    DateTime? createdAtBefore,
    int? page,
    int? pageSize,
    bool clearIsRead = false,
    bool clearType = false,
    bool clearCreatedAtAfter = false,
    bool clearCreatedAtBefore = false,
  }) {
    return NotificationQuery(
      isRead: clearIsRead ? null : (isRead ?? this.isRead),
      type: clearType ? null : (type ?? this.type),
      createdAtAfter:
          clearCreatedAtAfter ? null : (createdAtAfter ?? this.createdAtAfter),
      createdAtBefore: clearCreatedAtBefore
          ? null
          : (createdAtBefore ?? this.createdAtBefore),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  NotificationQuery clearedFilters() {
    return NotificationQuery(page: 1, pageSize: pageSize);
  }

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      if (isRead != null) 'is_read': isRead,
      if (type != null && type != AppNotificationType.unknown)
        'type': type!.apiValue,
      if (createdAtAfter != null)
        'created_at_after': createdAtAfter!.toUtc().toIso8601String(),
      if (createdAtBefore != null)
        'created_at_before': createdAtBefore!.toUtc().toIso8601String(),
      'page': page,
      'page_size': pageSize,
    };
  }

  @override
  List<Object?> get props => <Object?>[
        isRead,
        type,
        createdAtAfter,
        createdAtBefore,
        page,
        pageSize,
      ];
}

class NotificationPage<T> extends Equatable {
  const NotificationPage({
    required this.results,
    required this.count,
    this.next,
    this.previous,
  });

  final List<T> results;
  final int count;
  final String? next;
  final String? previous;

  bool get hasMore => next != null && next!.trim().isNotEmpty;

  @override
  List<Object?> get props => <Object?>[results, count, next, previous];
}
