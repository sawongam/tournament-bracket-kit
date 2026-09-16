import 'package:flutter/material.dart';

import '../models/bracket_variant.dart';

/// Elbow connectors drawn between two adjacent bracket rounds.
///
/// By default the elbows face right — two source matches on the left join into
/// one parent on the right. Set [mirrored] to flip them for the right half of
/// a [BracketVariant.mirrored] bracket, where the source round sits on the
/// *right* of the connector and progress runs toward the center.
class BracketConnector extends StatelessWidget {
  /// Creates a [BracketConnector].
  const BracketConnector({
    super.key,
    required this.sourceMatchCount,
    required this.separatorHeight,
    required this.cardHeight,
    required this.lineColor,
    this.connectorWidth = 80,
    this.lineWidth = 2,
    this.cornerRadius = 7,
    this.mirrored = false,
  });

  /// Number of matches in the *source* round — the one with two matches per
  /// pair. That is the left round normally, the right round when [mirrored].
  final int sourceMatchCount;

  /// Vertical gap used by the source round (drives elbow height).
  final double separatorHeight;

  /// Match card height.
  final double cardHeight;

  /// Color of the bracket lines.
  final Color lineColor;

  /// Total width of the connector column.
  final double connectorWidth;

  /// Stroke width of the lines.
  final double lineWidth;

  /// Corner radius on the elbow joints.
  final double cornerRadius;

  /// Whether the elbows point left instead of right.
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    final pairCount = sourceMatchCount ~/ 2;
    if (pairCount <= 0) return SizedBox(width: connectorWidth);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: SizedBox(
            width: connectorWidth,
            child: ListView.separated(
              itemCount: pairCount,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (_, __) {
                final elbow = Container(
                  height: separatorHeight + cardHeight,
                  width: connectorWidth / 2,
                  decoration: BoxDecoration(
                    borderRadius: mirrored
                        ? BorderRadius.only(
                            topLeft: Radius.circular(cornerRadius),
                            bottomLeft: Radius.circular(cornerRadius),
                          )
                        : BorderRadius.only(
                            topRight: Radius.circular(cornerRadius),
                            bottomRight: Radius.circular(cornerRadius),
                          ),
                    border: Border(
                      top: BorderSide(color: lineColor, width: lineWidth),
                      left: mirrored
                          ? BorderSide(color: lineColor, width: lineWidth)
                          : BorderSide.none,
                      right: mirrored
                          ? BorderSide.none
                          : BorderSide(color: lineColor, width: lineWidth),
                      bottom: BorderSide(color: lineColor, width: lineWidth),
                    ),
                  ),
                );

                final stem = Expanded(
                  child: Divider(
                    thickness: lineWidth,
                    color: lineColor,
                  ),
                );

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: mirrored ? [stem, elbow] : [elbow, stem],
                );
              },
              separatorBuilder: (_, __) =>
                  SizedBox(height: cardHeight + separatorHeight),
            ),
          ),
        ),
      ],
    );
  }
}

/// Straight horizontal connectors, one per match in the adjacent column.
///
/// Used on either side of the center column in a [BracketVariant.mirrored]
/// bracket, where each semi-final feeds the final directly and there is no
/// pair of matches to join with an elbow.
class BracketStraightConnector extends StatelessWidget {
  /// Creates a [BracketStraightConnector].
  const BracketStraightConnector({
    super.key,
    required this.matchCount,
    required this.separatorHeight,
    required this.cardHeight,
    required this.lineColor,
    this.connectorWidth = 80,
    this.lineWidth = 2,
  });

  /// Number of matches in the column this connector feeds from.
  final int matchCount;

  /// Vertical gap between those matches, so the lines stay card-aligned.
  final double separatorHeight;

  /// Match card height.
  final double cardHeight;

  /// Color of the bracket lines.
  final Color lineColor;

  /// Total width of the connector column.
  final double connectorWidth;

  /// Stroke width of the lines.
  final double lineWidth;

  @override
  Widget build(BuildContext context) {
    if (matchCount <= 0) return SizedBox(width: connectorWidth);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: SizedBox(
            width: connectorWidth,
            child: ListView.separated(
              itemCount: matchCount,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (_, __) => SizedBox(
                height: cardHeight,
                child: Center(
                  child: Container(
                    height: lineWidth,
                    color: lineColor,
                  ),
                ),
              ),
              separatorBuilder: (_, __) => SizedBox(height: separatorHeight),
            ),
          ),
        ),
      ],
    );
  }
}
