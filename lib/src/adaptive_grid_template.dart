import 'adaptive_breakpoint_settings.dart';

/// Represents a single cell or a contiguous block of cells in the adaptive grid layout.
class GridCell {
  final String name;
  final int row;
  final int column;
  final int rowSpan;
  final int columnSpan;

  GridCell({
    required this.name,
    required this.row,
    required this.column,
    this.rowSpan = 1,
    this.columnSpan = 1,
  });

  @override
  String toString() {
    return 'GridCell(name: $name, row: $row, column: $column, rowSpan: $rowSpan, columnSpan: $columnSpan)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridCell &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          row == other.row &&
          column == other.column &&
          rowSpan == other.rowSpan &&
          columnSpan == other.columnSpan;

  @override
  int get hashCode =>
      name.hashCode ^
      row.hashCode ^
      column.hashCode ^
      rowSpan.hashCode ^
      columnSpan.hashCode;
}

/// Defines a sizing strategy for rows and columns in an adaptive grid.
class FlexSize {
  final double? flex;
  final double? fixed;

  const FlexSize.flex([this.flex = 1.0]) : fixed = null;
  const FlexSize.content()
      : flex = null,
        fixed = null;
  const FlexSize.auto()
      : flex = 0.0,
        fixed = null;
  const FlexSize.fixed(this.fixed) : flex = null;

  bool get isFlex => flex != null;
  bool get isFixed => fixed != null;
  bool get isContent => !isFlex && !isFixed;

  @override
  String toString() {
    if (isFlex) return 'FlexSize.flex(${flex ?? 1.0})';
    if (isFixed) return 'FlexSize.fixed($fixed)';
    return 'FlexSize.content()';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlexSize &&
          runtimeType == other.runtimeType &&
          flex == other.flex &&
          fixed == other.fixed;

  @override
  int get hashCode => flex.hashCode ^ fixed.hashCode;
}

/// Helper class to represent a point in a 2D grid.
class _Point {
  final int row;
  final int column;
  _Point(this.row, this.column);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Point &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          column == other.column;

  @override
  int get hashCode => row.hashCode ^ column.hashCode;
}

/// Defines a declarative grid layout template for a specific [AdaptiveLayoutSize].
class AdaptiveGridTemplate {
  final AdaptiveLayoutSize size;
  final List<String> template;
  final List<FlexSize> columnSizes;
  final List<FlexSize> rowSizes;

  List<GridCell> _cells = [];
  int _numRows = 0;
  int _numColumns = 0;

  AdaptiveGridTemplate({
    required this.size,
    required this.template,
    List<FlexSize>? columnSizes,
    List<FlexSize>? rowSizes,
  })  : columnSizes = columnSizes ?? const [],
        rowSizes = rowSizes ?? const [] {
    _parseTemplateInternal();
  }

  void _parseTemplateInternal() {
    if (template.isEmpty) {
      _numRows = 0;
      _numColumns = 0;
      _cells = [];
      return;
    }

    _numRows = template.length;

    // Pre-parse all rows into lists of cleaned names for easier access
    final List<List<String>> parsedTemplate = [];
    for (final rowString in template) {
      final rowParts = rowString.split(' ').where((s) => s.isNotEmpty).toList();
      parsedTemplate.add(rowParts);
    }

    // Determine number of columns from the first parsed row
    _numColumns = parsedTemplate.first.length;

    // Validate if the first row actually had parts
    if (_numColumns == 0 || parsedTemplate.first.every((name) => name == '.')) {
      throw ArgumentError(
          'Template rows must contain at least one non-empty region name.');
    }

    // Validate consistent column count across all parsed rows
    for (int r = 0; r < _numRows; r++) {
      if (parsedTemplate[r].length != _numColumns) {
        throw ArgumentError(
            'All rows in the template must have the same number of columns. '
            'Row $r has ${parsedTemplate[r].length} columns, expected $_numColumns.');
      }
    }

    // --- Rectangularity Validation and Cell Extraction ---
    final Map<String, List<_Point>> namedRegionPoints = {};
    // Populate namedRegionPoints with all coordinates for each named region
    for (int r = 0; r < _numRows; r++) {
      for (int c = 0; c < _numColumns; c++) {
        final name = parsedTemplate[r][c];
        if (name != '.') {
          namedRegionPoints.putIfAbsent(name, () => []).add(_Point(r, c));
        }
      }
    }

    final List<GridCell> computedCells = [];
    final Set<String> processedRegionNames = {};

    for (final entry in namedRegionPoints.entries) {
      final String name = entry.key;
      final List<_Point> points = entry.value;

      if (processedRegionNames.contains(name)) {
        continue; // Already processed this region
      }

      // Find the bounding box for all occurrences of this name
      int minRow = _numRows;
      int maxRow = -1;
      int minCol = _numColumns;
      int maxCol = -1;

      for (final p in points) {
        if (p.row < minRow) minRow = p.row;
        if (p.row > maxRow) maxRow = p.row;
        if (p.column < minCol) minCol = p.column;
        if (p.column > maxCol) maxCol = p.column;
      }

      final int expectedRowSpan = maxRow - minRow + 1;
      final int expectedColSpan = maxCol - minCol + 1;

      // Validate that all cells within this bounding box belong to the same name
      // and that the count of actual points matches the expected area.
      int actualPointsInBoundingBox = 0;
      for (int r = minRow; r <= maxRow; r++) {
        for (int c = minCol; c <= maxCol; c++) {
          if (parsedTemplate[r][c] != name) {
            // Found a cell inside the bounding box that does NOT belong to this name
            throw ArgumentError(
                'Invalid template: cells for "$name" must form a contiguous rectangular block. '
                'Discrepancy at row $r, column $c. Found "${parsedTemplate[r][c]}", expected "$name".');
          }
          // Only count points that actually match the current name
          actualPointsInBoundingBox++;
        }
      }

      // Final check: Does the number of points collected for this name
      // match the area of the bounding box? This catches cases like:
      // "a a"
      // "a ." (where 'a' is not filled in bottom-right)
      if (actualPointsInBoundingBox != (expectedRowSpan * expectedColSpan)) {
        // This specific check might be redundant if the above `parsedTemplate[r][c] != name` already covers it,
        // but it serves as a sanity check for complex parsing issues.
        // The previous check is usually sufficient.
        throw ArgumentError(
            'Invalid template: cells for "$name" must form a contiguous rectangular block. '
            'Calculated area (${expectedRowSpan * expectedColSpan}) does not match actual cells found (${points.length}).');
      }

      // If all validations pass, add the cell
      computedCells.add(GridCell(
        name: name,
        row: minRow,
        column: minCol,
        rowSpan: expectedRowSpan,
        columnSpan: expectedColSpan,
      ));

      // Mark this name as processed so we don't re-process its parts
      // This is crucial for avoiding multiple GridCell entries for the same logical area.
      processedRegionNames.add(name);
    }

    _cells = computedCells;
  }

  List<GridCell> get cells => _cells;
  int get numRows => _numRows;
  int get numColumns => _numColumns;
}
