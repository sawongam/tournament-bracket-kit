## 1.0.0

* Added `BracketVariant.mirrored` - a two-sided bracket where the left half
  progresses left-to-right, the right half progresses right-to-left, and the
  final sits in the center. Select it with the new `variant` parameter on
  `TournamentBracket`; existing brackets keep the default
  `BracketVariant.linear` layout and are unaffected.
* The mirrored variant scales to fit its viewport instead of scrolling round by
  round, and enables pinch-to-zoom by default.
* `BracketConnector` gained a `mirrored` flag for left-facing elbows, and a new
  `BracketStraightConnector` draws the lines feeding the center final.
* Added `splitBracketForMirror()` for splitting rounds into the two halves.
* `TournamentBracket.enableScale` is now `bool?` so it can default per variant.
  Passing a `bool` works exactly as before.
* Added a layout switcher to the example app.

## 0.1.0

* Initial release.
