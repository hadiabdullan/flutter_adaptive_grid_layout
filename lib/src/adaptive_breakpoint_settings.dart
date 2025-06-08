import 'package:flutter/widgets.dart';

/// Defines predefined layout sizes based on screen width.
enum AdaptiveLayoutSize {
  compact, // e.g., mobile portrait
  medium, // e.g., mobile landscape, small tablet
  expanded, // e.g., larger tablet, small desktop
  large, // e.g., desktop
}

/// Defines the width thresholds for different [AdaptiveLayoutSize]s.
class AdaptiveBreakpoints {
  final double compactThreshold;
  final double mediumThreshold;
  final double expandedThreshold;
  final double largeThreshold;

  /// Creates a set of adaptive breakpoints.
  ///
  /// Thresholds are defined as the maximum width for a given size.
  /// For example, `compactThreshold = 600.0` means widths up to 599.99 are compact.
  const AdaptiveBreakpoints({
    this.compactThreshold = 600.0, // Max width for compact
    this.mediumThreshold = 840.0, // Max width for medium
    this.expandedThreshold = 1200.0, // Max width for expanded
    this.largeThreshold =
        double.infinity, // Max width for large (effectively no max)
  });

  /// Determines the [AdaptiveLayoutSize] based on the given width.
  AdaptiveLayoutSize fromWidth(double width) {
    if (width < compactThreshold) {
      return AdaptiveLayoutSize.compact;
    } else if (width < mediumThreshold) {
      return AdaptiveLayoutSize.medium;
    } else if (width < expandedThreshold) {
      return AdaptiveLayoutSize.expanded;
    } else {
      return AdaptiveLayoutSize.large;
    }
  }

  /// Predefined common breakpoints inspired by Material Design guidelines.
  static const AdaptiveBreakpoints materialDesign = AdaptiveBreakpoints(
    compactThreshold: 600.0,
    mediumThreshold: 840.0,
    expandedThreshold: 1200.0,
    largeThreshold: double.infinity,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveBreakpoints &&
          runtimeType == other.runtimeType &&
          compactThreshold == other.compactThreshold &&
          mediumThreshold == other.mediumThreshold &&
          expandedThreshold == other.expandedThreshold &&
          largeThreshold == other.largeThreshold;

  @override
  int get hashCode =>
      compactThreshold.hashCode ^
      mediumThreshold.hashCode ^
      expandedThreshold.hashCode ^
      largeThreshold.hashCode;
}

/// Provides the current [AdaptiveLayoutSize] and [AdaptiveBreakpoints] to its children.
///
/// Use `AdaptiveLayoutSizeProvider.of(context).size` to get the current layout size.
class AdaptiveLayoutSizeProvider extends InheritedWidget {
  final AdaptiveLayoutSize size;
  final AdaptiveBreakpoints breakpoints;

  const AdaptiveLayoutSizeProvider({
    super.key,
    required this.size,
    required this.breakpoints,
    required super.child,
  });

  /// Retrieves the nearest [AdaptiveLayoutSizeProvider] from the widget tree.
  static AdaptiveLayoutSizeProvider of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<AdaptiveLayoutSizeProvider>();
    assert(
        result != null, 'No AdaptiveLayoutSizeProvider found in widget tree');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant AdaptiveLayoutSizeProvider oldWidget) {
    return size != oldWidget.size || breakpoints != oldWidget.breakpoints;
  }
}
