import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_grid_layout/flutter_adaptive_grid_layout.dart'; // Ensure correct import for your package

void main() {
  // Define your breakpoints (re-using them here for clarity, assuming they match your app)
  final AdaptiveBreakpoints materialDesignBreakpoints =
      AdaptiveBreakpoints.materialDesign;

  group('AdaptiveGridTemplate', () {
    test('should parse a simple template correctly', () {
      final template = AdaptiveGridTemplate(
        size: AdaptiveLayoutSize.compact,
        template: ["header header", "main main", "footer footer"],
      );

      expect(template.numRows, 3);
      expect(template.numColumns, 2);
      expect(template.cells.length, 3); // header, main, footer

      // Verify header cell
      final header = template.cells.firstWhere((c) => c.name == 'header');
      expect(header.row, 0);
      expect(header.column, 0);
      expect(header.rowSpan, 1);
      expect(header.columnSpan, 2);

      // Verify main cell
      final main = template.cells.firstWhere((c) => c.name == 'main');
      expect(main.row, 1);
      expect(main.column, 0);
      expect(main.rowSpan, 1);
      expect(main.columnSpan, 2);

      // Verify footer cell
      final footer = template.cells.firstWhere((c) => c.name == 'footer');
      expect(footer.row, 2);
      expect(footer.column, 0);
      expect(footer.rowSpan, 1);
      expect(footer.columnSpan, 2);
    });

    test('should handle empty cells correctly', () {
      final template = AdaptiveGridTemplate(
        size: AdaptiveLayoutSize.compact,
        template: ["a .", ". b"],
      );

      expect(template.numRows, 2);
      expect(template.numColumns, 2);
      expect(template.cells.length, 2); // a, b

      final a = template.cells.firstWhere((c) => c.name == 'a');
      expect(a.row, 0);
      expect(a.column, 0);
      expect(a.rowSpan, 1);
      expect(a.columnSpan, 1);

      final b = template.cells.firstWhere((c) => c.name == 'b');
      expect(b.row, 1);
      expect(b.column, 1);
      expect(b.rowSpan, 1);
      expect(b.columnSpan, 1);
    });

    test('should throw ArgumentError for inconsistent column counts', () {
      expect(
        () => AdaptiveGridTemplate(
          size: AdaptiveLayoutSize.compact,
          template: ["a a", "b"], // Second row has fewer columns
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains(
              'All rows in the template must have the same number of columns.'),
        )),
      );
    });

    test(
        'should handle multi-line named regions (spanning multiple rows/columns)',
        () {
      final template = AdaptiveGridTemplate(
        size: AdaptiveLayoutSize.large,
        template: [
          "header header header",
          "sidebar main main",
          "sidebar footer footer",
        ],
      );

      expect(template.numRows, 3);
      expect(template.numColumns, 3);
      expect(template.cells.length, 4); // header, sidebar, main, footer

      final header = template.cells.firstWhere((c) => c.name == 'header');
      expect(header.row, 0);
      expect(header.column, 0);
      expect(header.rowSpan, 1);
      expect(header.columnSpan, 3);

      final sidebar = template.cells.firstWhere((c) => c.name == 'sidebar');
      expect(sidebar.row, 1);
      expect(sidebar.column, 0);
      expect(sidebar.rowSpan, 2); // Spans row 1 and 2
      expect(sidebar.columnSpan, 1);

      final main = template.cells.firstWhere((c) => c.name == 'main');
      expect(main.row, 1);
      expect(main.column, 1);
      expect(main.rowSpan, 1);
      expect(main.columnSpan, 2);

      final footer = template.cells.firstWhere((c) => c.name == 'footer');
      expect(footer.row, 2);
      expect(footer.column, 1);
      expect(footer.rowSpan, 1);
      expect(footer.columnSpan, 2);
    });

    test('should throw ArgumentError for non-rectangular region', () {
      expect(
        () => AdaptiveGridTemplate(
          size: AdaptiveLayoutSize.compact,
          template: [
            "a a b",
            "a . b", // 'a' is not rectangular
          ],
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('cells for "a" must form a contiguous rectangular block.'),
        )),
      );

      expect(
        () => AdaptiveGridTemplate(
          size: AdaptiveLayoutSize.compact,
          template: [
            "a b",
            "a a", // 'a' not rectangular
          ],
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('cells for "a" must form a contiguous rectangular block.'),
        )),
      );
    });

    test('should handle empty template without error', () {
      final template = AdaptiveGridTemplate(
        size: AdaptiveLayoutSize.compact,
        template: [],
      );
      expect(template.numRows, 0);
      expect(template.numColumns, 0);
      expect(template.cells, isEmpty);
    });

    test(
        'should throw ArgumentError for template with empty rows (only spaces)',
        () {
      expect(
        () => AdaptiveGridTemplate(
          size: AdaptiveLayoutSize.compact,
          template: [" "], // Only spaces
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains(
              'Template rows must contain at least one non-empty region name.'),
        )),
      );

      expect(
        () => AdaptiveGridTemplate(
          size: AdaptiveLayoutSize.compact,
          template: [". . ."], // Only dots
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains(
              'Template rows must contain at least one non-empty region name.'),
        )),
      );
    });
  });

  group('AdaptiveGridLayout Widget', () {
    testWidgets('renders correct template based on screen width',
        (WidgetTester tester) async {
      // --- Test for compact layout (e.g., width <= 600) ---
      // Set a compact screen size for the test environment
      tester.view.physicalSize =
          const Size(400 * 2.0, 800 * 2.0); // Logical 400px width
      tester.view.devicePixelRatio = 2.0;
      await tester.pumpAndSettle(); // Pump to apply new window size

      // Build the widget tree for the compact test
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveLayoutSizeProvider(
              size: materialDesignBreakpoints.fromWidth(400),
              breakpoints: materialDesignBreakpoints,
              child: AdaptiveGridLayout(
                breakpoints: materialDesignBreakpoints,
                layoutTemplates: {
                  AdaptiveLayoutSize.compact: AdaptiveGridTemplate(
                    size: AdaptiveLayoutSize.compact,
                    template: ["a", "b"], // Stacked
                    columnSizes: [FlexSize.flex(1)],
                    rowSizes: [FlexSize.content(), FlexSize.flex(1)],
                  ),
                  AdaptiveLayoutSize.medium: AdaptiveGridTemplate(
                    size: AdaptiveLayoutSize.medium,
                    template: ["a b"],
                    columnSizes: [FlexSize.flex(1), FlexSize.flex(1)],
                    rowSizes: [FlexSize.content()],
                  ),
                },
                children: {
                  'a': Container(key: const Key('widgetA'), color: Colors.red),
                  'b': Container(key: const Key('widgetB'), color: Colors.blue),
                },
              ),
            ),
          ),
        ),
      );

      // Verify compact layout (a above b)
      final Rect aRectCompact =
          tester.getRect(find.byKey(const Key('widgetA')));
      final Rect bRectCompact =
          tester.getRect(find.byKey(const Key('widgetB')));

      // Assert 'a' is above 'b' by checking their vertical positions meet
      expect(aRectCompact.bottom, closeTo(bRectCompact.top, 0.1));
      expect(aRectCompact.width, closeTo(400, 0.1));
      expect(bRectCompact.width, closeTo(400, 0.1));
      expect(aRectCompact.height, greaterThan(0)); // Should have some height
      expect(bRectCompact.height, greaterThan(0)); // Should have some height

      // --- Test for medium layout (e.g., width > 600 and <= 960) ---
      // Reset window size for medium breakpoint
      tester.view.physicalSize =
          const Size(800 * 2.0, 600 * 2.0); // Logical 800px width
      tester.view.devicePixelRatio = 2.0;
      await tester.pumpAndSettle(); // Pump to apply new window size

      // Need to re-pump the widget to ensure it rebuilds with the new MediaQuery context
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            // Removed Center widget for simpler constraint flow
            body: SizedBox(
              width: 800, // Explicitly set width to 800 for the LayoutBuilder
              height: 600,
              child: AdaptiveLayoutSizeProvider(
                size: materialDesignBreakpoints.fromWidth(800),
                breakpoints: materialDesignBreakpoints,
                child: AdaptiveGridLayout(
                  breakpoints: materialDesignBreakpoints,
                  layoutTemplates: {
                    AdaptiveLayoutSize.compact: AdaptiveGridTemplate(
                      size: AdaptiveLayoutSize.compact,
                      template: ["a", "b"],
                      columnSizes: [FlexSize.flex(1)],
                      rowSizes: [FlexSize.content(), FlexSize.flex(1)],
                    ),
                    AdaptiveLayoutSize.medium: AdaptiveGridTemplate(
                      size: AdaptiveLayoutSize.medium,
                      template: ["a b"],
                      columnSizes: [FlexSize.flex(1), FlexSize.flex(1)],
                      rowSizes: [FlexSize.content()],
                    ),
                  },
                  children: {
                    'a':
                        Container(key: const Key('widgetA'), color: Colors.red),
                    'b': Container(
                        key: const Key('widgetB'), color: Colors.blue),
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Verify medium layout (a next to b)
      final Rect aRectMedium = tester.getRect(find.byKey(const Key('widgetA')));
      final Rect bRectMedium = tester.getRect(find.byKey(const Key('widgetB')));

      // In a two-column layout, 'a' should be to the left of 'b'
      expect(aRectMedium.left, lessThan(bRectMedium.left));
      // They should occupy half the width each, based on 800px total
      expect(aRectMedium.width, closeTo(800 / 2, 0.1));
      expect(bRectMedium.width, closeTo(800 / 2, 0.1));
    });

    testWidgets('handles missing template for current size gracefully',
        (WidgetTester tester) async {
      // Set up a screen width that maps to AdaptiveLayoutSize.compact
      tester.view.physicalSize =
          const Size(400 * 2.0, 600 * 2.0); // e.g., 400px width
      tester.view.devicePixelRatio = 2.0;
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400, // Compact size
              height: 600,
              child: AdaptiveLayoutSizeProvider(
                size: AdaptiveBreakpoints.materialDesign
                    .fromWidth(400), // This maps to compact
                breakpoints: AdaptiveBreakpoints.materialDesign,
                child: AdaptiveGridLayout(
                  breakpoints: AdaptiveBreakpoints.materialDesign,
                  layoutTemplates: {
                    // Only medium template provided, compact is intentionally missing
                    AdaptiveLayoutSize.medium: AdaptiveGridTemplate(
                      size: AdaptiveLayoutSize.medium,
                      template: ["a"],
                      columnSizes: [FlexSize.flex(1)],
                      rowSizes: [FlexSize.flex(1)],
                    ),
                  },
                  children: {
                    'a': Container(),
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Add an extra pump to ensure the error text is rendered.
      await tester.pump();

      // Expect to find the fallback text for AdaptiveLayoutSize.compact
      expect(
          find.text(
              'No adaptive layout defined for size: AdaptiveLayoutSize.compact'),
          findsOneWidget);
    });

    testWidgets('handles missing children for regions gracefully',
        (WidgetTester tester) async {
      // Set window size for MediaQuery to pick up, matching SizedBox width
      tester.view.physicalSize = const Size(400 * 2.0, 600 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: AdaptiveLayoutSizeProvider(
                size: AdaptiveBreakpoints.materialDesign.fromWidth(400),
                breakpoints: AdaptiveBreakpoints.materialDesign,
                child: AdaptiveGridLayout(
                  breakpoints: AdaptiveBreakpoints.materialDesign,
                  layoutTemplates: {
                    AdaptiveLayoutSize.compact: AdaptiveGridTemplate(
                      size: AdaptiveLayoutSize.compact,
                      template: ["a", "b"],
                      columnSizes: [
                        FlexSize.flex(1)
                      ], // Added for clarity/robustness
                      rowSizes: [
                        FlexSize.flex(1),
                        FlexSize.flex(1)
                      ], // Added for clarity/robustness
                    ),
                  },
                  children: {
                    'a': Container(key: const Key('widgetA')),
                    // 'b' is intentionally missing
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Ensure everything pumps and settles, including LayoutBuilder
      await tester.pumpAndSettle();

      // Widget 'a' should still be found, as its template is present and widget is provided
      expect(find.byKey(const Key('widgetA')), findsOneWidget);
      // 'b' should NOT be found, as its widget was not provided
      expect(find.byKey(const Key('widgetB')), findsNothing);

      // Verify no unhandled exceptions were thrown by the missing 'b' child.
      expect(tester.takeException(), isNull);
    });

    testWidgets('calculates and applies fixed and flex sizes correctly',
        (WidgetTester tester) async {
      // Explicitly set window size for this test for Media Query to pick up
      tester.view.physicalSize = const Size(300 * 2.0, 400 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      await tester.pumpAndSettle(); // Apply new window size

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width:
                  300, // Total width for columns - LayoutBuilder will get this
              height:
                  400, // Total height for rows - LayoutBuilder will get this
              child: AdaptiveLayoutSizeProvider(
                // Use fromWidth to get correct size, assuming 300px is compact
                size: AdaptiveBreakpoints.materialDesign.fromWidth(300),
                breakpoints: AdaptiveBreakpoints.materialDesign,
                child: AdaptiveGridLayout(
                  breakpoints: AdaptiveBreakpoints
                      .materialDesign, // Ensure breakpoints are passed
                  layoutTemplates: {
                    AdaptiveLayoutSize.compact: AdaptiveGridTemplate(
                      size: AdaptiveLayoutSize.compact,
                      template: [
                        "r1c1 r1c2 r1c3",
                        "r2c1 r2c2 r2c3",
                      ],
                      // 300px width: Fixed 100, Flex 1 (remaining 200px), Flex 1 (remaining 200px) => 100, 100, 100
                      columnSizes: [
                        FlexSize.fixed(100),
                        FlexSize.flex(1),
                        FlexSize.flex(1)
                      ],
                      // 400px height: Flex 1 (remaining 400px), Flex 1 (remaining 400px) => 200, 200
                      rowSizes: [FlexSize.flex(1), FlexSize.flex(1)],
                    ),
                  },
                  children: {
                    'r1c1': Container(key: const Key('r1c1')),
                    'r1c2': Container(key: const Key('r1c2')),
                    'r1c3': Container(key: const Key('r1c3')),
                    'r2c1': Container(key: const Key('r2c1')),
                    'r2c2': Container(key: const Key('r2c2')),
                    'r2c3': Container(key: const Key('r2c3')),
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Always pumpAndSettle after changing window size or pumping new widgets
      await tester.pumpAndSettle();

      // Verify column widths
      final Rect r1c1Rect = tester.getRect(find.byKey(const Key('r1c1')));
      final Rect r1c2Rect = tester.getRect(find.byKey(const Key('r1c2')));
      final Rect r1c3Rect = tester.getRect(find.byKey(const Key('r1c3')));

      expect(r1c1Rect.width, closeTo(100, 0.1)); // Fixed size
      expect(r1c2Rect.width, closeTo(100, 0.1)); // Flex 1 (from 200 remaining)
      expect(r1c3Rect.width, closeTo(100, 0.1)); // Flex 1 (from 200 remaining)

      // Verify column positions
      expect(r1c1Rect.left, closeTo(0, 0.1));
      expect(r1c2Rect.left, closeTo(100, 0.1));
      expect(r1c3Rect.left, closeTo(200, 0.1));

      // Verify row heights
      final Rect r1c1RectH = tester.getRect(find.byKey(const Key('r1c1')));
      final Rect r2c1RectH = tester.getRect(find.byKey(const Key('r2c1')));

      expect(r1c1RectH.height, closeTo(200, 0.1)); // Flex 1 (from 400 total)
      expect(r2c1RectH.height, closeTo(200, 0.1)); // Flex 1 (from 400 total)

      // Verify row positions
      expect(r1c1RectH.top, closeTo(0, 0.1));
      expect(r2c1RectH.top, closeTo(200, 0.1));
    });

    testWidgets('correctly handles a cell spanning multiple rows and columns',
        (WidgetTester tester) async {
      // Set window size for MediaQuery to pick up, matching SizedBox width
      tester.view.physicalSize = const Size(300 * 2.0, 300 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: AdaptiveLayoutSizeProvider(
                // Ensure this resolves to compact for 300px
                size: AdaptiveBreakpoints.materialDesign.fromWidth(300),
                breakpoints: AdaptiveBreakpoints.materialDesign,
                child: AdaptiveGridLayout(
                  breakpoints: AdaptiveBreakpoints.materialDesign,
                  layoutTemplates: {
                    AdaptiveLayoutSize.compact: AdaptiveGridTemplate(
                      size: AdaptiveLayoutSize.compact,
                      template: [
                        "span_me span_me",
                        "span_me span_me",
                        "footer   footer"
                      ],
                      columnSizes: [FlexSize.flex(1), FlexSize.flex(1)],
                      rowSizes: [
                        FlexSize.flex(1),
                        FlexSize.flex(1),
                        FlexSize.fixed(50)
                      ], // Footer fixed height
                    ),
                  },
                  children: {
                    'span_me': Container(
                        key: const Key('spanMeWidget'), color: Colors.pink),
                    'footer': Container(
                        key: const Key('footerWidget'), color: Colors.grey),
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(); // Ensure everything is built

      final Rect spanMeRect =
          tester.getRect(find.byKey(const Key('spanMeWidget')));
      final Rect footerRect =
          tester.getRect(find.byKey(const Key('footerWidget')));

      // Total height 300. Footer fixed at 50. Remaining 250 for top two flex rows.
      // So, two rows should be 250 / 2 = 125 each.
      // SpanMeRect spans 2 rows, so its height should be 125 + 125 = 250.
      expect(spanMeRect.height, closeTo(250, 0.1));
      expect(spanMeRect.width,
          closeTo(300, 0.1)); // Spans 2 columns of total 300 width

      expect(spanMeRect.top, closeTo(0, 0.1));
      expect(spanMeRect.left, closeTo(0, 0.1));

      expect(footerRect.height, closeTo(50, 0.1));
      expect(footerRect.width, closeTo(300, 0.1));
      expect(footerRect.top, closeTo(250, 0.1)); // Should start after span_me
      expect(footerRect.left, closeTo(0, 0.1));
    });
  });
}
