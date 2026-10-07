import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:schooltesting/main.dart';

void main() {
  testWidgets('MPSApp smoke test, role switching, and access control', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MPSApp());
    await tester.pumpAndSettle();

    // Verify app title displays MPS branding
    expect(find.text('MPS School Management System'), findsOneWidget);

    // Verify default role is Parent
    expect(
      find.text('Student: Student (Class 6-A) (MPS-2026-001)'),
      findsOneWidget,
    );
    expect(find.textContaining('14500'), findsOneWidget);

    // Switch to Teacher role
    final teacherChip = find.text('Teacher');
    expect(teacherChip, findsOneWidget);
    await tester.tap(teacherChip);
    await tester.pumpAndSettle();

    // Verify Teacher attendance marking appears for assigned Class 6-A
    expect(find.textContaining('Assigned: Class 6-A'), findsOneWidget);

    // Switch to Principal role
    final principalChip = find.text('Principal');
    expect(principalChip, findsOneWidget);
    await tester.tap(principalChip);
    await tester.pumpAndSettle();

    // Verify Principal metrics appear
    expect(
      find.textContaining('Administrative & Security Overview'),
      findsOneWidget,
    );

    // Test Theme toggle
    final themeToggle = find.byIcon(Icons.dark_mode);
    expect(themeToggle, findsOneWidget);
    await tester.tap(themeToggle);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.light_mode), findsOneWidget);

    // Test Locale toggle to Hindi
    final localeToggle = find.byIcon(Icons.translate);
    expect(localeToggle, findsOneWidget);
    await tester.tap(localeToggle);
    await tester.pumpAndSettle();

    // Verify Hindi title is rendered
    expect(find.text('एमपीएस स्कूल प्रबंधन प्रणाली'), findsOneWidget);
  });
}
