import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_dimensions.dart';
import 'package:flutter_base/core/widgets/app_button.dart';

class AppDialog {
  AppDialog._();

  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'OK',
    String cancelLabel = 'Cancel',
    bool barrierDismissible = true,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.dialogMaxWidth,
            ),
            child: Text(message),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel),
            ),
            destructive
                ? AppButton(
                    label: confirmLabel,
                    variant: AppButtonVariant.danger,
                    expand: false,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                  )
                : FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(confirmLabel),
                  ),
          ],
        );
      },
    );
  }

  static Future<void> alert({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'OK',
    bool barrierDismissible = true,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.dialogMaxWidth,
            ),
            child: Text(message),
          ),
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
