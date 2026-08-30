import 'package:flutter/material.dart';
import 'package:flutter_base/core/router/app_routes.dart';

class AppDialog {
  AppDialog._();

  static Future<bool?> confirm({
    required String title,
    required String message,
    String confirmLabel = 'OK',
    String cancelLabel = 'Cancel',
    BuildContext? context,
  }) {
    final BuildContext? ctx = context ?? rootNavigatorKey.currentContext;
    if (ctx == null) {
      return Future<bool?>.value(null);
    }

    return showDialog<bool>(
      context: ctx,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  static Future<void> alert({
    required String title,
    required String message,
    String confirmLabel = 'OK',
    BuildContext? context,
  }) {
    final BuildContext? ctx = context ?? rootNavigatorKey.currentContext;
    if (ctx == null) {
      return Future<void>.value();
    }

    return showDialog<void>(
      context: ctx,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }
}
