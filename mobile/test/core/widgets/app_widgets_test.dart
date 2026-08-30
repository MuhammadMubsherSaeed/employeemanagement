import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_theme.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
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
}
