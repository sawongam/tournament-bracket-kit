import 'dart:math' as math;

import '../models/bracket_round.dart';

/// Vertical gap between match cards for a given round index.
///
/// Spacing grows as `2^roundIndex` so later rounds stay centered between
/// their parent matches — the same layout math used by classic bracket UIs.
double calculateSeparatorHeight({
  required int roundIndex,
  required double itemsMarginVertical,
  required double cardHeight,
}) {
  var separatorHeight = 0.0;
  for (var i = 0; i <= roundIndex; i++) {
    final factor = math.pow(2, i).toDouble();
    separatorHeight = (cardHeight * (factor - 1)) +
        (itemsMarginVertical * ((factor - 1) + 1));
  }
  return separatorHeight;
}

/// Total height of a bracket given the first round's match count.
double calculateBracketHeight({
  required int firstRoundMatchCount,
  required double cardHeight,
  required double itemsMarginVertical,
}) {
  final count = firstRoundMatchCount < 1 ? 1 : firstRoundMatchCount;
  return (count * cardHeight) + ((count - 1) * itemsMarginVertical);
}

/// One match column of a mirrored bracket, tagged with the round it came from.
///
/// The [roundIndex] is kept because vertical spacing is a function of the
/// round's position in the original bracket, not of the column's position in
/// its half.
class MirroredBracketColumn {
  /// Creates a [MirroredBracketColumn].
  const MirroredBracketColumn({
    required this.round,
    required this.roundIndex,
  });

  /// The half-round rendered in this column.
  final BracketRound round;

  /// Index of the source round in the original `rounds` list.
  final int roundIndex;
}

/// The left half, right half, and center column of a mirrored bracket.
///
/// Produced by [splitBracketForMirror]. Both [left] and [right] are ordered
/// outermost round → nearest the center; [right] is rendered in reverse.
class MirroredBracketLayout {
  /// Creates a [MirroredBracketLayout].
  const MirroredBracketLayout({
    required this.left,
    required this.right,
    required this.center,
  });

  /// Columns flowing left-to-right toward the center.
  final List<MirroredBracketColumn> left;

  /// Columns flowing right-to-left toward the center. Rendered in reverse.
  final List<MirroredBracketColumn> right;

  /// The final round, drawn as the single center column. Null only when the
  /// bracket had no rounds.
  final BracketRound? center;

  /// Number of match columns (excluding connectors) the layout renders.
  int get columnCount => left.length + right.length + (center == null ? 0 : 1);

  /// Matches in the tallest column, which drives the bracket's total height.
  int get tallestColumnMatchCount {
    var tallest = center?.matches.length ?? 0;
    for (final column in [...left, ...right]) {
      final count = column.round.matches.length;
      if (count > tallest) tallest = count;
    }
    return tallest;
  }
}

/// Splits [rounds] into the two halves of a mirrored bracket.
///
/// The last round becomes the center column. Every earlier round is cut in
/// half by list order — the first `ceil(n / 2)` matches go left, the rest go
/// right — with each half keeping its original top-to-bottom order. A half
/// that would be empty is dropped, so degenerate input renders instead of
/// throwing.
MirroredBracketLayout splitBracketForMirror(List<BracketRound> rounds) {
  if (rounds.isEmpty) {
    return const MirroredBracketLayout(left: [], right: [], center: null);
  }

  final left = <MirroredBracketColumn>[];
  final right = <MirroredBracketColumn>[];

  for (var i = 0; i < rounds.length - 1; i++) {
    final round = rounds[i];
    final matches = round.matches;
    final half = (matches.length + 1) ~/ 2;

    final leftMatches = matches.sublist(0, half);
    final rightMatches = matches.sublist(half);

    if (leftMatches.isNotEmpty) {
      left.add(MirroredBracketColumn(
        round: BracketRound(title: round.title, matches: leftMatches),
        roundIndex: i,
      ));
    }
    if (rightMatches.isNotEmpty) {
      right.add(MirroredBracketColumn(
        round: BracketRound(title: round.title, matches: rightMatches),
        roundIndex: i,
      ));
    }
  }

  return MirroredBracketLayout(left: left, right: right, center: rounds.last);
}
