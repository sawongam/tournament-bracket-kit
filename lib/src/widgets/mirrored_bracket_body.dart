import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/bracket_match.dart';
import '../models/bracket_round.dart';
import '../utils/bracket_layout.dart';
import 'bracket_connector.dart';
import 'bracket_round_column.dart';

/// Renders a two-sided bracket: both halves progress toward a center final.
///
/// Unlike the linear body this does not scroll round by round — the bracket
/// is laid out at its natural size inside an [InteractiveViewer] that starts
/// zoomed out to fit the viewport, so its symmetry is visible at a glance.
/// Zooming in shows the cards at full resolution; zooming out is capped at
/// that fitted overview.
///
/// Internal to the package; use `TournamentBracket(variant:
/// BracketVariant.mirrored)`.
class MirroredBracketBody extends StatefulWidget {
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
  final Widget Function(BuildContext context, BracketMatch match) matchBuilder;

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

  /// Minimum zoom. Unused: zoom-out is capped at the fitted overview.
  final double minScale;

  /// Maximum zoom.
  final double maxScale;

  /// Space reserved around the fitted bracket.
  final EdgeInsets padding;

  @override
  State<MirroredBracketBody> createState() => _MirroredBracketBodyState();
}

class _MirroredBracketBodyState extends State<MirroredBracketBody> {
  final _transformationController = TransformationController();

  /// Viewport and content sizes the current transform was fitted for.
  Size? _fittedViewport;
  Size? _fittedContent;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  double _separatorFor(int roundIndex) => calculateSeparatorHeight(
        roundIndex: roundIndex,
        itemsMarginVertical: widget.itemsMarginVertical,
        cardHeight: widget.cardHeight,
      );

  Widget _column(BracketRound round, int roundIndex) => BracketRoundColumn(
        matches: round.matches,
        separatorHeight: _separatorFor(roundIndex),
        cardHeight: widget.cardHeight,
        cardWidth: widget.cardWidth,
        matchBuilder: widget.matchBuilder,
      );

  Widget _elbow({
    required int sourceMatchCount,
    required int roundIndex,
    required bool mirrored,
  }) =>
      BracketConnector(
        sourceMatchCount: sourceMatchCount,
        separatorHeight: _separatorFor(roundIndex),
        cardHeight: widget.cardHeight,
        lineColor: widget.lineColor,
        connectorWidth: widget.connectorWidth,
        lineWidth: widget.lineWidth,
        mirrored: mirrored,
      );

  Widget _spur({required int matchCount, required int roundIndex}) =>
      BracketStraightConnector(
        matchCount: matchCount,
        separatorHeight: _separatorFor(roundIndex),
        cardHeight: widget.cardHeight,
        lineColor: widget.lineColor,
        connectorWidth: widget.connectorWidth,
        lineWidth: widget.lineWidth,
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
      children.add(_column(center, widget.rounds.length - 1));
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
    final layout = splitBracketForMirror(widget.rounds);
    if (layout.columnCount == 0) return const SizedBox.shrink();

    final bracketHeight = calculateBracketHeight(
      firstRoundMatchCount: layout.tallestColumnMatchCount,
      cardHeight: widget.cardHeight,
      itemsMarginVertical: widget.itemsMarginVertical,
    );

    final children = _buildRow(layout);
    final connectorCount = children.length - layout.columnCount;
    final bracketWidth = (layout.columnCount * widget.cardWidth) +
        (connectorCount * widget.connectorWidth);
    final contentSize = Size(
      bracketWidth + widget.padding.horizontal,
      bracketHeight + widget.padding.vertical,
    );

    final bracket = Padding(
      padding: widget.padding,
      child: SizedBox(
        width: bracketWidth,
        height: bracketHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(
          constraints.maxWidth,
          constraints.hasBoundedHeight
              ? constraints.maxHeight
              : contentSize.height,
        );

        // Fit the whole bracket into the viewport, never above natural size.
        final fit = math.min(
          1.0,
          math.min(
            viewport.width / contentSize.width,
            viewport.height / contentSize.height,
          ),
        );

        if (!widget.enablePan && !widget.enableScale) {
          return Center(
            child: SizedBox(
              width: contentSize.width * fit,
              height: contentSize.height * fit,
              child: FittedBox(child: bracket),
            ),
          );
        }

        // Grow the child so that, at the fitted scale, it covers the whole
        // viewport. The bracket sits centered inside it, and panning is
        // clamped to the child, so the overview can't drift off-center.
        final childSize = Size(
          math.max(contentSize.width, viewport.width / fit),
          math.max(contentSize.height, viewport.height / fit),
        );

        if (viewport != _fittedViewport || contentSize != _fittedContent) {
          _fittedViewport = viewport;
          _fittedContent = contentSize;
          // Mutated in place: notifying listeners here would mark the
          // InteractiveViewer dirty mid-build, and it rebuilds anyway.
          _transformationController.value.setFrom(
            Matrix4.diagonal3Values(fit, fit, 1)
              ..setTranslationRaw(
                (viewport.width - childSize.width * fit) / 2,
                (viewport.height - childSize.height * fit) / 2,
                0,
              ),
          );
        }

        return InteractiveViewer(
          transformationController: _transformationController,
          constrained: false,
          panEnabled: widget.enablePan,
          scaleEnabled: widget.enableScale,
          minScale: fit,
          maxScale: math.max(widget.maxScale, fit),
          child: SizedBox.fromSize(
            size: childSize,
            child: Center(child: bracket),
          ),
        );
      },
    );
  }
}
