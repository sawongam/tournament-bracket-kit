import 'package:flutter/material.dart';

import '../models/bracket_match.dart';
import '../models/bracket_round.dart';
import '../models/bracket_variant.dart';
import '../utils/bracket_layout.dart';
import 'bracket_connector.dart';
import 'bracket_round_column.dart';
import 'bracket_round_tabs.dart';
import 'default_bracket_match_card.dart';
import 'mirrored_bracket_body.dart';

/// Builder for a single match card inside [TournamentBracket].
typedef BracketMatchBuilder = Widget Function(
  BuildContext context,
  BracketMatch match,
);

/// Callback when a match card is tapped (used by the default card).
typedef BracketMatchTapCallback = void Function(BracketMatch match);

/// A single-elimination tournament bracket.
///
/// Pass ordered [rounds] (first round → final). Customize look via
/// [matchBuilder], sizing, and line colors.
///
/// With the default [BracketVariant.linear] the bracket runs left-to-right and
/// snaps round by round, and round tabs auto-follow scroll when
/// [showRoundTabs] is true — tapping a tab snaps the bracket to that round.
///
/// ```dart
/// TournamentBracket(
///   rounds: dummyBracketRounds(),
///   onMatchTap: (match) => debugPrint(match.id),
/// )
/// ```
///
/// With [BracketVariant.mirrored] the first half of each round progresses
/// left-to-right, the second half right-to-left, and the final sits in the
/// center. That layout is scaled to fit the viewport rather than scrolled, so
/// [showRoundTabs] does not apply and pinch-to-zoom is on by default.
///
/// ```dart
/// TournamentBracket(
///   rounds: dummyBracketRounds(),
///   variant: BracketVariant.mirrored,
/// )
/// ```
class TournamentBracket extends StatefulWidget {
  /// Creates a [TournamentBracket].
  const TournamentBracket({
    super.key,
    required this.rounds,
    this.variant = BracketVariant.linear,
    this.matchBuilder,
    this.onMatchTap,
    this.cardHeight = 100,
    this.cardWidth = 220,
    this.itemsMarginVertical = 24,
    this.connectorWidth = 80,
    this.lineColor,
    this.lineWidth = 1,
    this.showRoundTabs = true,
    this.enablePan = true,
    this.enableScale,
    this.minScale = 0.4,
    this.maxScale = 2.5,
    this.transformationController,
  });

  /// Bracket rounds from earliest round to final.
  final List<BracketRound> rounds;

  /// Layout to render. Defaults to [BracketVariant.linear].
  final BracketVariant variant;

  /// Custom match card. Defaults to [DefaultBracketMatchCard].
  final BracketMatchBuilder? matchBuilder;

  /// Fired when the default card is tapped. Ignored if [matchBuilder] is set
  /// (handle taps inside your builder instead).
  final BracketMatchTapCallback? onMatchTap;

  /// Height of each match card slot.
  final double cardHeight;

  /// Width of each match card / round column.
  final double cardWidth;

  /// Base vertical margin between first-round cards.
  final double itemsMarginVertical;

  /// Width of the elbow connector between rounds.
  final double connectorWidth;

  /// Bracket line color. Defaults to [ThemeData.dividerColor].
  final Color? lineColor;

  /// Bracket line stroke width.
  final double lineWidth;

  /// Whether to show the round tab bar above the bracket. Ignored by
  /// [BracketVariant.mirrored], where a round spans two columns.
  final bool showRoundTabs;

  /// Whether the bracket can be scrolled horizontally (round-by-round) in
  /// [BracketVariant.linear], or dragged around in [BracketVariant.mirrored].
  /// When false the content is shown statically.
  final bool enablePan;

  /// Whether pinch-to-zoom is enabled. Defaults to false for
  /// [BracketVariant.linear] and true for [BracketVariant.mirrored], where
  /// zooming into a fitted bracket is the primary way to read small cards.
  final bool? enableScale;

  /// Minimum zoom when [enableScale] is true.
  ///
  /// Ignored by [BracketVariant.mirrored], which can't be zoomed out past the
  /// scale that fits the whole bracket in the viewport.
  final double minScale;

  /// Maximum zoom when [enableScale] is true.
  final double maxScale;

  /// Unused – kept for API compatibility. Use [enablePan] to control scrolling.
  final TransformationController? transformationController;

  @override
  State<TournamentBracket> createState() => _TournamentBracketState();
}

class _TournamentBracketState extends State<TournamentBracket>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  TabController? _tabController;

  /// Whether the tab bar triggered the current scroll (to avoid feedback loop).
  bool _tabDrivenScroll = false;

  /// Column width including the connector.
  double get _columnStride => widget.cardWidth + widget.connectorWidth;

  bool get _isMirrored => widget.variant == BracketVariant.mirrored;

  /// Zoom defaults to on for the mirrored variant, which is fitted to the
  /// viewport and therefore often too small to read without zooming.
  bool get _scaleEnabled => widget.enableScale ?? _isMirrored;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant TournamentBracket oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rounds.length != widget.rounds.length ||
        oldWidget.variant != widget.variant ||
        oldWidget.showRoundTabs != widget.showRoundTabs) {
      _disposeTabController();
      _initTabController();
    }
  }

  void _initControllers() {
    _scrollController = ScrollController()..addListener(_onScroll);
    _initTabController();
  }

  void _initTabController() {
    _tabDrivenScroll = false;
    if (widget.showRoundTabs && widget.rounds.isNotEmpty && !_isMirrored) {
      _tabController = TabController(length: widget.rounds.length, vsync: this)
        ..addListener(_onTabChanged);
    } else {
      _tabController = null;
    }
  }

  void _disposeControllers() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _disposeTabController();
  }

  void _disposeTabController() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _tabController = null;
  }

  // ── Scroll → Tab sync ───────────────────────────────────────────────────────

  void _onScroll() {
    if (_tabDrivenScroll) return;
    final controller = _tabController;
    if (controller == null) return;

    final offset = _scrollController.offset;
    final stride = _columnStride;
    if (stride <= 0) return;

    // Nearest round index based on current scroll position.
    final nearest =
        (offset / stride).round().clamp(0, widget.rounds.length - 1);
    if (nearest != controller.index) {
      controller.animateTo(nearest);
    }
  }

  // ── Tab → Scroll sync ───────────────────────────────────────────────────────

  void _onTabChanged() {
    final controller = _tabController;
    if (controller == null || controller.indexIsChanging) return;
    _scrollToRound(controller.index);
  }

  void _scrollToRound(int index) {
    if (!_scrollController.hasClients) return;
    _tabDrivenScroll = true;
    final target = (index * _columnStride).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController
        .animateTo(
          target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        )
        .whenComplete(() => _tabDrivenScroll = false);
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  BracketMatchBuilder get _resolvedMatchBuilder {
    return widget.matchBuilder ??
        (context, match) => DefaultBracketMatchCard(
              match: match,
              onTap: widget.onMatchTap == null
                  ? null
                  : () => widget.onMatchTap!(match),
            );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rounds.isEmpty) {
      return const SizedBox.shrink();
    }

    final lineColor = widget.lineColor ?? Theme.of(context).dividerColor;

    if (_isMirrored) {
      return MirroredBracketBody(
        rounds: widget.rounds,
        matchBuilder: _resolvedMatchBuilder,
        cardHeight: widget.cardHeight,
        cardWidth: widget.cardWidth,
        itemsMarginVertical: widget.itemsMarginVertical,
        connectorWidth: widget.connectorWidth,
        lineColor: lineColor,
        lineWidth: widget.lineWidth,
        enablePan: widget.enablePan,
        enableScale: _scaleEnabled,
        minScale: widget.minScale,
        maxScale: widget.maxScale,
      );
    }

    final firstRoundCount = widget.rounds.first.matches.length;
    final bracketHeight = calculateBracketHeight(
      firstRoundMatchCount: firstRoundCount,
      cardHeight: widget.cardHeight,
      itemsMarginVertical: widget.itemsMarginVertical,
    );

    // LayoutBuilder gives us the real viewport width so we can add trailing
    // padding that makes the Final column fully scrollable into view.
    //
    // WHY: maxScrollExtent = totalContentWidth - viewportWidth.
    // Offset to reach the Final = (N-1) * stride.
    // Without padding: maxScrollExtent = (N-1)*stride + cardWidth - viewportWidth
    //   which is always LESS than (N-1)*stride because viewportWidth > cardWidth.
    // Fix: add trailingPadding = viewportWidth - cardWidth so
    //   maxScrollExtent = (N-1)*stride + viewportWidth - viewportWidth = (N-1)*stride ✓
    final bracketBody = LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final trailingPadding =
            (viewportWidth - widget.cardWidth).clamp(0.0, double.infinity);

        final bracketList = ListView.separated(
          controller: widget.enablePan ? _scrollController : null,
          scrollDirection: Axis.horizontal,
          physics: widget.enablePan
              ? _RoundSnappingPhysics(stride: _columnStride)
              : const NeverScrollableScrollPhysics(),
          // Trailing padding ensures Final column reaches maxScrollExtent.
          padding: EdgeInsets.only(left: 16.0, right: trailingPadding),
          itemCount: widget.rounds.length,
          itemBuilder: (context, index) {
            final round = widget.rounds[index];
            final separatorHeight = calculateSeparatorHeight(
              roundIndex: index,
              itemsMarginVertical: widget.itemsMarginVertical,
              cardHeight: widget.cardHeight,
            );
            return BracketRoundColumn(
              matches: round.matches,
              separatorHeight: separatorHeight,
              cardHeight: widget.cardHeight,
              cardWidth: widget.cardWidth,
              matchBuilder: _resolvedMatchBuilder,
            );
          },
          separatorBuilder: (context, index) {
            final source = widget.rounds[index];
            final separatorHeight = calculateSeparatorHeight(
              roundIndex: index,
              itemsMarginVertical: widget.itemsMarginVertical,
              cardHeight: widget.cardHeight,
            );
            return BracketConnector(
              sourceMatchCount: source.matches.length,
              separatorHeight: separatorHeight,
              cardHeight: widget.cardHeight,
              lineColor: lineColor,
              connectorWidth: widget.connectorWidth,
              lineWidth: widget.lineWidth,
            );
          },
        );

        return SizedBox(height: bracketHeight, child: bracketList);
      },
    );

    // Wrap in scale support when requested.
    final scrollable = _scaleEnabled
        ? InteractiveViewer(
            constrained: false,
            scaleEnabled: true,
            panEnabled: false,
            minScale: widget.minScale,
            maxScale: widget.maxScale,
            child: bracketBody,
          )
        : bracketBody;

    if (!widget.showRoundTabs || _tabController == null) {
      // Wrap in vertical scroll in case bracketHeight > available height.
      return SingleChildScrollView(child: scrollable);
    }

    // Column fills available height. Expanded + SingleChildScrollView lets
    // the bracket scroll vertically when bracketHeight > remaining space
    // (e.g. Round of 16 on a small screen) instead of overflowing.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BracketRoundTabs(
          titles: [for (final r in widget.rounds) r.title],
          controller: _tabController!,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16.0),
                scrollable,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Snapping scroll physics that locks the list to the nearest full column.
///
/// This gives the "page-by-round" feel without using a [PageView], so that
/// the connector lines between rounds are still visible during the swipe.
class _RoundSnappingPhysics extends ScrollPhysics {
  const _RoundSnappingPhysics({required this.stride, super.parent});

  /// Width of one bracket column (card + connector).
  final double stride;

  @override
  _RoundSnappingPhysics applyTo(ScrollPhysics? ancestor) =>
      _RoundSnappingPhysics(stride: stride, parent: buildParent(ancestor));

  double _snapOffset(double offset) {
    if (stride <= 0) return offset;
    return (offset / stride).round() * stride;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Let the parent physics generate momentum, then override the target.
    final parent = super.createBallisticSimulation(position, velocity);
    final currentOffset = position.pixels;

    // Determine snap target: if velocity is significant, move one round in
    // that direction; otherwise snap to nearest.
    double targetOffset;
    if (velocity.abs() > 200) {
      final direction = velocity > 0 ? 1 : -1;
      targetOffset = _snapOffset(currentOffset + direction * stride * 0.5);
    } else {
      targetOffset = _snapOffset(currentOffset);
    }

    targetOffset = targetOffset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if ((targetOffset - currentOffset).abs() < 0.5) return null;

    return ScrollSpringSimulation(
      SpringDescription.withDampingRatio(
        mass: 1.0,
        stiffness: 300.0,
        ratio: 1.2,
      ),
      currentOffset,
      targetOffset,
      velocity,
      tolerance:
          parent?.tolerance ?? const Tolerance(velocity: 1.0, distance: 0.5),
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
