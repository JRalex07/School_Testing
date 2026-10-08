import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schooltesting/core/constants/app_constants.dart';
import 'package:schooltesting/core/widgets/app_badge.dart';
import 'package:schooltesting/core/widgets/app_card.dart';
import 'package:schooltesting/core/widgets/app_stat_card.dart';
import 'package:schooltesting/core/widgets/app_text_field.dart';
import 'package:schooltesting/core/widgets/responsive_layout.dart';

void main() {
  group('ResponsiveLayout & Component Constraints Tests', () {
    testWidgets(
      'ResponsiveLayout adapts to mobile, tablet, and desktop viewports',
      (WidgetTester tester) async {
        // 1. Mobile viewport (375 x 667)
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResponsiveLayout(
                mobile: (ctx) => const Text('Mobile Layout View'),
                tablet: (ctx) => const Text('Tablet Layout View'),
                desktop: (ctx) => const Text('Desktop Layout View'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Mobile Layout View'), findsOneWidget);
        expect(find.text('Tablet Layout View'), findsNothing);
        expect(find.text('Desktop Layout View'), findsNothing);

        // 2. Tablet viewport (768 x 1024)
        tester.view.physicalSize = const Size(768, 1024);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResponsiveLayout(
                mobile: (ctx) => const Text('Mobile Layout View'),
                tablet: (ctx) => const Text('Tablet Layout View'),
                desktop: (ctx) => const Text('Desktop Layout View'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Tablet Layout View'), findsOneWidget);
        expect(find.text('Mobile Layout View'), findsNothing);

        // 3. Desktop viewport (1280 x 800)
        tester.view.physicalSize = const Size(1280, 800);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResponsiveLayout(
                mobile: (ctx) => const Text('Mobile Layout View'),
                tablet: (ctx) => const Text('Tablet Layout View'),
                desktop: (ctx) => const Text('Desktop Layout View'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Desktop Layout View'), findsOneWidget);
      },
    );

    testWidgets('ResponsivePageContainer enforces maxContentWidth boundary', (
      WidgetTester tester,
    ) async {
      // Ultra-wide display (1920 x 1080)
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsivePageContainer(
              child: SizedBox(height: 100, child: Text('Bounded Content')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final constrainedBoxFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ConstrainedBox &&
            widget.constraints.maxWidth == AppConstants.maxContentWidth,
      );
      expect(constrainedBoxFinder, findsOneWidget);
    });

    testWidgets('ResponsiveGrid reflows columns smoothly without overflow', (
      WidgetTester tester,
    ) async {
      // Mobile (400px wide) -> 1 column
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveGrid(
              targetItemWidth: 240,
              maxColumns: 4,
              children: [Text('Item 1'), Text('Item 2'), Text('Item 3')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('AppStatCard renders compact metric, icon, and badge cleanly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppStatCard(
              title: 'Total Students',
              value: '420',
              icon: Icons.people_outline,
              badge: 'Active',
              badgeVariant: AppBadgeVariant.success,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Total Students'), findsOneWidget);
      expect(find.text('420'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('AppTextField constrains maxWidth preventing endless stretch', (
      WidgetTester tester,
    ) async {
      // 1440px wide desktop
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppTextField(label: 'Student Name')),
        ),
      );
      await tester.pumpAndSettle();

      final constrainedBoxFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ConstrainedBox &&
            widget.constraints.maxWidth == AppConstants.maxFormWidth,
      );
      expect(constrainedBoxFinder, findsOneWidget);
    });

    testWidgets('AppCard supports min and max width/height boundaries', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              minWidth: 200,
              maxWidth: 400,
              child: Text('Card Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final constrainedFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ConstrainedBox &&
            widget.constraints.minWidth == 200 &&
            widget.constraints.maxWidth == 400,
      );
      expect(constrainedFinder, findsOneWidget);
    });
  });
}
