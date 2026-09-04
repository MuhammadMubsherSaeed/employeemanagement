import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_theme.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_status_badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppButton shows a label and can load',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppButton(
            label: 'Continue',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Continue'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AppButton(
            label: 'Continue',
            isLoading: true,
            onPressed: null,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppStatusBadge renders semantic tones',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AppStatusBadge(label: 'Ready', tone: AppBadgeTone.success),
        ),
      ),
    );

    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('AppEmptyState and AppErrorWidget expose actions',
      (WidgetTester tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: <Widget>[
              const AppEmptyState(
                title: 'No employees found',
                subtitle: 'Add someone to get started.',
              ),
              AppErrorWidget(
                message: 'Could not load data.',
                onRetry: () => retries++,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('No employees found'), findsOneWidget);
    expect(find.text('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('AppButton danger variant still shows its label',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppButton(
            label: 'Delete',
            variant: AppButtonVariant.danger,
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(find.text('Delete'), findsOneWidget);
  });
}
