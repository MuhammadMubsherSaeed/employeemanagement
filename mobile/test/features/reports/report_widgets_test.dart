import 'package:flutter/material.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/reports/domain/entities/report_items.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/domain/entities/report_query.dart';
import 'package:flutter_base/features/reports/presentation/widgets/report_empty_state.dart';
import 'package:flutter_base/features/reports/presentation/widgets/report_filter_sheet.dart';
import 'package:flutter_base/features/reports/presentation/widgets/report_item_cards.dart';
import 'package:flutter_base/features/reports/presentation/widgets/report_summary_card.dart';
import 'package:flutter_base/features/reports/presentation/widgets/report_table.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/employee_fakes.dart';
import '../../helpers/report_fakes.dart';

Widget _app(Widget child, {Size size = const Size(400, 800)}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('phone cards and tablet tables render long names without overflow',
      (WidgetTester tester) async {
    final AttendanceReportItem longName = AttendanceReportItem.fromJson(
      <String, dynamic>{
        ...sampleAttendanceReportJson(),
        'employee': const <String, dynamic>{
          'id': 'emp-1',
          'employee_code': 'EMP-001',
          'first_name': 'Alexandrina Victoria of the United Kingdom',
          'last_name': 'Lovelace-Hopper-Babbage',
          'department': <String, dynamic>{
            'id': 'dept-1',
            'name': 'Research and Advanced Engineering Operations',
            'status': 'ACTIVE',
          },
        },
      },
    );

    await tester.pumpWidget(
      _app(
        ListView(
          children: <Widget>[
            const ReportSummaryCard(count: 1),
            AttendanceReportCard(item: longName),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Alexandrina'), findsOneWidget);

    await tester.pumpWidget(
      _app(
        ReportTable(
          columns: <ReportColumn>[
            ReportColumn(
              label: 'Employee',
              value: (Object row) =>
                  (row as AttendanceReportItem).employee.fullName,
            ),
            ReportColumn(
              label: 'Department',
              value: (Object row) =>
                  (row as AttendanceReportItem).employee.department?.name ?? '',
            ),
          ],
          rows: <Object>[longName],
          emptyMessage: 'No attendance records found.',
        ),
        size: const Size(1024, 768),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DataTable), findsOneWidget);
  });

  testWidgets('empty reports are not treated as errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        const ReportTable(
          columns: <ReportColumn>[
            ReportColumn(label: 'Name', value: _label),
          ],
          rows: <Object>[],
          emptyMessage: 'No leave records found.',
        ),
      ),
    );
    expect(find.byType(ReportEmptyState), findsOneWidget);
    expect(find.text('No leave records found.'), findsOneWidget);
  });

  testWidgets('filter sheet apply, clear, and cancel', (WidgetTester tester) async {
    ReportQuery? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showReportFilterSheet(
                    context: context,
                    current: const ReportQuery(
                      kind: ReportKind.attendance,
                      status: 'LATE',
                    ),
                    canFilterByEmployee: true,
                    canFilterByDepartment: true,
                    departments: <Department>[sampleEmployee().department!],
                    employees: <Employee>[sampleEmployee()],
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Apply'));
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(result?.status, 'LATE');

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Clear'));
    await tester.tap(find.text('Clear'));
    await tester.ensureVisible(find.text('Apply'));
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(result?.status, isNull);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}

String _label(Object row) => 'x';
