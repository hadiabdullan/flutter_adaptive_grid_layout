import 'package:flutter/material.dart';
import 'package:flutter_adaptive_grid_layout/flutter_adaptive_grid_layout.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine the current screen size based on breakpoints
    final currentLayoutSize = AdaptiveBreakpoints.materialDesign.fromWidth(
      MediaQuery.of(context).size.width,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive Dashboard (Resize Window)')),
      body: AdaptiveLayoutSizeProvider(
        size: currentLayoutSize,
        breakpoints: AdaptiveBreakpoints.materialDesign,
        child: AdaptiveGridLayout(
          breakpoints: AdaptiveBreakpoints.materialDesign,
          layoutTemplates: {
            // Define your layout for compact screens (e.g., mobile portrait)
            AdaptiveLayoutSize.compact: AdaptiveGridTemplate(
              size: AdaptiveLayoutSize.compact,
              template: [
                "header",
                "content",
                "sidebar", // Sidebar stacks below content
                "footer",
              ],
              columnSizes: [FlexSize.flex(1)], // Single column
              rowSizes: [
                FlexSize.content(),
                FlexSize.flex(1),
                FlexSize.content(),
                FlexSize.content(),
              ],
            ),
            // Define your layout for medium screens (e.g., tablets, mobile landscape)
            AdaptiveLayoutSize.medium: AdaptiveGridTemplate(
              size: AdaptiveLayoutSize.medium,
              template: ["header header", "sidebar content", "footer footer"],
              columnSizes: [
                FlexSize.fixed(200),
                FlexSize.flex(1),
              ], // Fixed 200px sidebar, rest for content
              rowSizes: [
                FlexSize.content(),
                FlexSize.flex(1),
                FlexSize.content(),
              ],
            ),
            // Define your layout for expanded screens (e.g., small desktops)
            AdaptiveLayoutSize.expanded: AdaptiveGridTemplate(
              size: AdaptiveLayoutSize.expanded,
              template: [
                "header header header",
                "nav    content  details",
                "footer footer  footer",
              ],
              columnSizes: [
                FlexSize.fixed(150),
                FlexSize.flex(2),
                FlexSize.flex(1),
              ], // Nav fixed, content gets 2x flex, details 1x
              rowSizes: [
                FlexSize.content(),
                FlexSize.flex(1),
                FlexSize.content(),
              ],
            ),
            // Define your layout for large screens (e.g., large desktops)
            AdaptiveLayoutSize.large: AdaptiveGridTemplate(
              size: AdaptiveLayoutSize.large,
              template: [
                "header header header header",
                "nav    content  details  ads",
                "footer footer  footer  footer",
              ],
              columnSizes: [
                FlexSize.fixed(150),
                FlexSize.flex(2),
                FlexSize.flex(1),
                FlexSize.fixed(100),
              ], // Even more columns
              rowSizes: [
                FlexSize.content(),
                FlexSize.flex(1),
                FlexSize.content(),
              ],
            ),
          },
          // Provide your actual widgets for each named region
          children: {
            'header': Container(
              color: Colors.red[100],
              padding: const EdgeInsets.all(8.0),
              child: const Center(
                child: Text('App Header', style: TextStyle(fontSize: 20)),
              ),
            ),
            'sidebar': Container(
              color: Colors.green[100],
              padding: const EdgeInsets.all(8.0),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sidebar Nav'),
                  ListTile(title: Text('Item 1')),
                  ListTile(title: Text('Item 2')),
                ],
              ),
            ),
            'nav': Container(
              color: Colors.purple[100],
              padding: const EdgeInsets.all(8.0),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Main Nav'),
                  ListTile(title: Text('Dashboard')),
                  ListTile(title: Text('Settings')),
                ],
              ),
            ),
            'content': Container(
              color: Colors.blue[100],
              padding: const EdgeInsets.all(8.0),
              child: const Center(
                child: Text(
                  'Main Content Area\n(Try resizing the window!)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            'details': Container(
              color: Colors.orange[100],
              padding: const EdgeInsets.all(8.0),
              child: const Center(child: Text('Details Panel')),
            ),
            'ads': Container(
              color: Colors.yellow[100],
              padding: const EdgeInsets.all(8.0),
              child: const Center(child: Text('Advertisements')),
            ),
            'footer': Container(
              color: Colors.grey[300],
              padding: const EdgeInsets.all(8.0),
              child: const Center(child: Text('App Footer')),
            ),
          },
        ),
      ),
    );
  }
}
