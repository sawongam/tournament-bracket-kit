import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/bracket_match.dart';
import '../models/bracket_round.dart';
import '../utils/bracket_layout.dart';
import 'bracket_connector.dart';
import 'bracket_round_column.dart';

/// Renders a two-sided bracket: both halves progress toward a center final.
///
/// Unlike the linear body this does not scroll round by round — the whole
/// bracket is scaled down to fit the viewport so its symmetry is visible at a
/// glance, then optionally panned and zoomed with [InteractiveViewer].
///
/// Internal to the package; use `TournamentBracket(variant:
/// BracketVariant.mirrored)`.
class MirroredBracketBody extends StatelessWidget {
  /// Creates a [MirroredBracketBody].
  const MirroredBracketBody({
    super.key,
    required this.rounds,
    required this.matchBuilder,
    required this.cardHeight,
    required this.cardWidth,
    required this.itemsMarginVertical,
    required this.connectorWidth,
    required this.lineColor,
    required this.lineWidth,
    required this.enablePan,
    required this.enableScale,
    required this.minScale,
    required this.maxScale,
    this.padding = const EdgeInsets.all(16),
  });

  /// Bracket rounds from earliest round to final.
  final List<BracketRound> rounds;

  /// Builds a single match card.
  final Widget Function(BuildContext context, BracketMatch match)
      matchBuilder;

  /// Height of each match card slot.
  final double cardHeight;

  /// Width of each match card / round column.
  final double cardWidth;

  /// Base vertical margin between outermost-round cards.
  final double itemsMarginVertical;

  /// Width of each connector column.
  final double connectorWidth;

  /// Bracket line color.
  final Color lineColor;

  /// Bracket line stroke width.
  final double lineWidth;

  /// Whether the bracket can be dragged around once zoomed.
  final bool enablePan;

  /// Whether pinch-to-zoom is enabled.
  final bool enableScale;

  /// Minimum zoom.
  final double minScale;

  /// Maximum zoom.
  final double maxScale;

  /// Space reserved around the fitted bracket.
  final EdgeInsets padding;

  double _separatorFor(int roundIndex) => calculateSeparatorHeight(
        roundIndex: roundIndex,
        itemsMarginVertical: itemsMarginVertical,
        cardHeight: cardHeight,
      );

  Widget _column(BracketRound round, int roundIndex) => BracketRoundColumn(
        matches: round.matches,
        separatorHeight: _separatorFor(roundIndex),
        cardHeight: cardHeight,
        cardWidth: cardWidth,
        matchBuilder: matchBuilder,
      );

  Widget _elbow({
    required int sourceMatchCount,
    required int roundIndex,
    required bool mirrored,
  }) =>
      BracketConnector(
        sourceMatchCount: sourceMatchCount,
        separatorHeight: _separatorFor(roundIndex),
        cardHeight: cardHeight,
        lineColor: lineColor,
        connectorWidth: connectorWidth,
        lineWidth: lineWidth,
        mirrored: mirrored,
      );

  Widget _spur({required int matchCount, required int roundIndex}) =>
      BracketStraightConnector(
        matchCount: matchCount,
        separatorHeight: _separatorFor(roundIndex),
        cardHeight: cardHeight,
        lineColor: lineColor,
        connectorWidth: connectorWidth,
        lineWidth: lineWidth,
      );

  /// Builds the columns and connectors, left edge → center → right edge.
  List<Widget> _buildRow(MirroredBracketLayout layout) {
    final children = <Widget>[];

    // Left half: outermost round in, elbows pointing right.
    for (var i = 0; i < layout.left.length; i++) {
      final column = layout.left[i];
      children.add(_column(column.round, column.roundIndex));
      if (i < layout.left.length - 1) {
        children.add(_elbow(
          sourceMatchCount: column.round.matches.length,
          roundIndex: column.roundIndex,
          mirrored: false,
        ));
      }
    }

    final center = layout.center;
    if (center != null) {
      if (layout.left.isNotEmpty) {
        final inner = layout.left.last;
        children.add(_spur(
          matchCount: inner.round.matches.length,
          roundIndex: inner.roundIndex,
        ));
      }
      children.add(_column(center, rounds.length - 1));
      if (layout.right.isNotEmpty) {
        final inner = layout.right.last;
        children.add(_spur(
          matchCount: inner.round.matches.length,
          roundIndex: inner.roundIndex,
        ));
      }
    }

    // Right half: rendered center → outermost, elbows pointing left. The
    // connector's source is always the round further from the center, which
    // here is the *next* column we are about to add.
    for (var i = layout.right.length - 1; i >= 0; i--) {
      final column = layout.right[i];
      children.add(_column(column.round, column.roundIndex));
      if (i > 0) {
        final source = layout.right[i - 1];
        children.add(_elbow(
          sourceMatchCount: source.round.matches.length,
          roundIndex: source.roundIndex,
          mirrored: true,
        ));
      }
    }

    return children;
  }

  @override
  Widget build(BuildContext context) {
    final layout = splitBracketForMirror(rounds);
    if (layout.columnCount == 0) return const SizedBox.shrink();

    final bracketHeight = calculateBracketHeight(
      firstRoundMatchCount: layout.tallestColumnMatchCount,
      cardHeight: cardHeight,
      itemsMarginVertical: itemsMarginVertical,
    );

    final children = _buildRow(layout);
    final connectorCount = children.length - layout.columnCount;
    final bracketWidth =
        (layout.columnCount * cardWidth) + (connectorCount * connectorWidth);

    final bracket = SizedBox(
      width: bracketWidth,
      height: bracketHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            (constraints.maxWidth - padding.horizontal).clamp(1.0, 1e6);

        // Fit by width, and by height too when the parent bounds us. Never
        // scale above 1.0 — a small bracket stays at its natural card size.
        var fit = availableWidth / bracketWidth;
        if (constraints.hasBoundedHeight) {
          final availableHeight =
              (constraints.maxHeight - padding.vertical).clamp(1.0, 1e6);
          fit = math.min(fit, availableHeight / bracketHeight);
        }
        fit = math.min(fit, 1.0);

        final fitted = Padding(
          padding: padding,
          child: Center(
            child: SizedBox(
              width: bracketWidth * fit,
              height: bracketHeight * fit,
              child: FittedBox(
                fit: BoxFit.contain,
                child: bracket,
              ),
            ),
          ),
        );

        if (!enablePan && !enableScale) return fitted;

        return InteractiveViewer(
          panEnabled: enablePan,
          scaleEnabled: enableScale,
          minScale: minScale,
          maxScale: maxScale,
          child: fitted,
        );
      },
    );
  }
}
