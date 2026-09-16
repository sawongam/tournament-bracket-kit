/// Visual layout used by a tournament bracket.
enum BracketVariant {
  /// Classic left-to-right bracket: every round is one column, the final sits
  /// on the far right, and the view scrolls/snaps round by round.
  linear,

  /// Two-sided ("mirrored") bracket: the first half of each round progresses
  /// left-to-right, the second half progresses right-to-left, and the final
  /// sits in the center.
  ///
  /// ```text
  /// Player A ────────┐                          ┌──────── Player H
  ///                  ├───────┐          ┌───────┤
  /// Player B ────────┘       │          │       └──────── Player G
  ///                          ├───Final──┤
  /// Player C ────────┐       │          │       ┌──────── Player F
  ///                  ├───────┘          └───────┤
  /// Player D ────────┘                          └──────── Player E
  /// ```
  ///
  /// The whole bracket is scaled to fit the viewport instead of scrolling
  /// round by round, so the symmetry is visible at a glance.
  mirrored,
}
