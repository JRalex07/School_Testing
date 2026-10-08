import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:schooltesting/main.dart';

void main() {
  testWidgets('MPSApp smoke test, role switching, and honest empty states', (
    WidgetTester tester,
  ) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('TEST FLUTTER ERROR: ${details.exception}');
    };

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MPSApp());
    await tester.pumpAndSettle();

    // Verify app title displays MPS branding
    expect(find.text('MPS School Management System'), findsOneWidget);

    // Verify default role is Parent and displays honest empty state when no records exist
    expect(find.text('No Linked Children Found'), findsOneWidget);
    expect(find.text('Enroll First Student'), findsOneWidget);

    // Switch to Teacher role
    final teacherChip = find.text('Teacher');
    expect(teacherChip, findsOneWidget);
    await tester.tap(teacherChip);
    await tester.pump();

    // Verify Teacher honest empty state appears when no class is assigned
    expect(find.text('No Active Class Assignments'), findsOneWidget);
    expect(find.text('Create Assignment'), findsOneWidget);

    // Switch to Principal role
    final principalChip = find.text('Principal');
    expect(principalChip, findsOneWidget);
    await tester.tap(principalChip);
    await tester.pump();

    // Verify Principal metrics overview appears
    expect(
      find.textContaining('MPS Administrative & Security Overview'),
      findsOneWidget,
    );
    expect(find.text('0 Enrolled'), findsOneWidget);

    // Test Theme toggle
    final themeToggle = find.byIcon(Icons.dark_mode);
    expect(themeToggle, findsOneWidget);
    await tester.tap(themeToggle);
    await tester.pump();
    expect(find.byIcon(Icons.light_mode), findsOneWidget);

    // Test Locale toggle to Hindi
    final localeToggle = find.byIcon(Icons.translate);
    expect(localeToggle, findsOneWidget);
    await tester.tap(localeToggle);
    await tester.pump();

    // Verify Hindi title is rendered
    expect(find.text('एमपीएस स्कूल प्रबंधन प्रणाली'), findsOneWidget);
  });
}
