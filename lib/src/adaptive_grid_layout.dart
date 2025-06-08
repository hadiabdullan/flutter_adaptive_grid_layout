import 'package:flutter/material.dart';
import 'adaptive_breakpoint_settings.dart';
import 'adaptive_grid_template.dart';

/// A widget for building declarative adaptive grid layouts based on screen size.
///
/// This widget uses a [AdaptiveGridTemplate] to define layout structure
/// for different screen sizes and places children widgets into named regions.
///
/// **Note on current implementation:**
/// The current implementation uses a `Stack` and `Positioned` widgets to place
/// children based on calculated grid positions and spans. This is a basic
/// approximation. For true CSS Grid-like behavior (especially for `FlexSize.content()`
/// and advanced layout calculations), a custom `RenderObjectWidget` or
/// `CustomMultiChildLayout` with a robust `MultiChildLayoutDelegate` would be
/// required.
class AdaptiveGridLayout extends StatelessWidget {
  /// A map where keys are [AdaptiveLayoutSize] and values are the corresponding [AdaptiveGridTemplate].
  final Map<AdaptiveLayoutSize, AdaptiveGridTemplate> layoutTemplates;

  /// A map of string region names to the widgets that should be placed in those regions.
  final Map<String, Widget> children;

  /// Custom breakpoint settings. Defaults to [AdaptiveBreakpoints.materialDesign].
  final AdaptiveBreakpoints breakpoints;

  const AdaptiveGridLayout({
    super.key,
    required this.layoutTemplates,
    required this.children,
    this.breakpoints = AdaptiveBreakpoints.materialDesign,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final currentLayoutSize = breakpoints.fromWidth(screenWidth);

    final activeTemplate = layoutTemplates[currentLayoutSize];

    if (activeTemplate == null) {
      // Fallback if no template for current size, or provide a default error widget
      return Center(
        child: Text(
          'No adaptive layout defined for size: $currentLayoutSize',
          textAlign: TextAlign.center,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
          return const SizedBox.shrink(); // Avoid division by zero
        }

        // Calculate actual pixel sizes for rows and columns based on template and constraints
        final List<double> columnPixelWidths = _calculateFlexSizes(
          activeTemplate.columnSizes,
          constraints.maxWidth,
          activeTemplate.numColumns,
        );
        final List<double> rowPixelHeights = _calculateFlexSizes(
          activeTemplate.rowSizes,
          constraints.maxHeight,
          activeTemplate.numRows,
        );
        // Build a list of Positioned widgets for each region
        final List<Widget> positionedChildren = [];

        for (final cell in activeTemplate.cells) {
          final widgetForRegion = children[cell.name];
          if (widgetForRegion == null) {
            continue;
          }

          // Calculate the top-left corner and total width/height for this cell
          double left = 0;
          for (int i = 0; i < cell.column; i++) {
            left += columnPixelWidths[i];
          }

          double top = 0;
          for (int i = 0; i < cell.row; i++) {
            top += rowPixelHeights[i];
          }

          double width = 0;
          for (int i = 0; i < cell.columnSpan; i++) {
            // Ensure index is within bounds for columnPixelWidths
            if (cell.column + i < columnPixelWidths.length) {
              width += columnPixelWidths[cell.column + i];
            } else {
              // Removed debugPrint, consider throwing an error or handling gracefully if this is a critical error
            }
          }

          double height = 0;
          for (int i = 0; i < cell.rowSpan; i++) {
            // Ensure index is within bounds for rowPixelHeights
            if (cell.row + i < rowPixelHeights.length) {
              height += rowPixelHeights[cell.row + i];
            } else {
              // Removed debugPrint, consider throwing an error or handling gracefully if this is a critical error
            }
          }

          positionedChildren.add(
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: SizedBox(
                // Use SizedBox to force widget into calculated size
                width: width,
                height: height,
                child: widgetForRegion,
              ),
            ),
          );
        }

        // Use a Stack to position all children
        return Stack(
          children: positionedChildren,
        );
      },
    );
  }

  /// Calculates the actual pixel sizes for rows or columns based on [FlexSize] definitions.
  ///
  /// This is a simplified calculation. A full implementation for `FlexSize.content()`
  /// would require measuring the intrinsic content size of the widgets.
  List<double> _calculateFlexSizes(
      List<FlexSize> definitions, double totalExtent, int count) {
    if (count == 0) return [];
    if (totalExtent <= 0) return List.filled(count, 0.0);

    final List<double> sizes = List.filled(count, 0.0);
    double remainingExtent = totalExtent;
    double totalEffectiveFlexFactor = 0;

    // First pass: Allocate fixed sizes and sum up effective flex factors
    for (int i = 0; i < count; i++) {
      final def =
          i < definitions.length ? definitions[i] : const FlexSize.auto();
      if (def.isFixed) {
        sizes[i] = def.fixed!;
        remainingExtent -= def.fixed!;
      } else {
        // For FlexSize.flex, use its value. For content/auto, treat as flex(1) by default
        totalEffectiveFlexFactor += def.flex ?? 1.0;
      }
    }

    // Ensure remainingExtent doesn't go negative from fixed sizes
    if (remainingExtent < 0) remainingExtent = 0;

    // Second pass: Distribute remaining space among all flexible units (flex, content, or auto with default flex)
    if (totalEffectiveFlexFactor > 0 && remainingExtent > 0) {
      final flexUnit = remainingExtent / totalEffectiveFlexFactor;
      for (int i = 0; i < count; i++) {
        final def =
            i < definitions.length ? definitions[i] : const FlexSize.auto();
        if (!def.isFixed) {
          // If it's not fixed, it's flexible (flex, content, or auto)
          sizes[i] = (def.flex ?? 1.0) * flexUnit;
        }
      }
    }

    // Final clamping
    final clampedSizes =
        sizes.map((s) => s.clamp(0.0, double.infinity)).toList();
    return clampedSizes;
  }
}
