// Root timeline widget with interactivity and layout management.
//
// TLDR:
// Overview: A stateful widget that integrates the clock, the painter, and the window resizing logic.
// Problem: Need to handle mouse hover and dynamically resize the window to show event details.
// Solution: Uses a Stack with MouseRegion and ExpansionLogic for state determination.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:happening/core/astro/astro_data_service.dart';
import 'package:happening/core/display/display_service.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/time/clock_service.dart';
import 'package:happening/core/window/expansion_controller.dart';
import 'package:happening/core/window/physical_window_state.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:happening/core/window/window_service_resize_executor.dart';
import 'package:happening/features/calendar/calendar_controller.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/countdown_display.dart';
import 'package:happening/features/timeline/display_fallback_indicator.dart';
import 'package:happening/features/timeline/expansion_logic.dart';
import 'package:happening/features/timeline/focus/timeline_focus_controller.dart';
import 'package:happening/features/timeline/hover_detail_overlay.dart';
import 'package:happening/features/timeline/painters/astro_objects.dart';
import 'package:happening/features/timeline/painters/astronomical_background_layer.dart';
import 'package:happening/features/timeline/settings_panel.dart';
import 'package:happening/features/timeline/timeline_layout.dart';
import 'package:happening/features/timeline/timeline_painter.dart';
import 'package:logging/logging.dart';

/// Minimum strip width needed to host the astro tooltip: its left position
/// clamps to `[4, stripWidth - 184]`, so anything narrower (188 = 184 + 4) has
/// no valid placement and the tooltip is suppressed instead.
const double _kMinAstroTooltipStripWidth = 188.0;

/// Root timeline widget. Driven by [clockService] stream.
class TimelineStrip extends StatefulWidget {
  const TimelineStrip({
    super.key,
    required this.events,
    required this.clockService,
    required this.settingsService,
    required this.onSignOut,
    required this.windowService,
    this.displayService,
    this.calendarController,
    this.onSignIn,
    this.onCancelSignIn,
    this.isLoading = false,
    this.enableAnimations = true,
    this.platformOverride,
  });

  final List<CalendarEvent> events;
  final ClockService clockService;
  final CalendarController? calendarController;
  final SettingsService settingsService;
  final VoidCallback onSignOut;
  final WindowService windowService;
  final DisplayService? displayService;

  /// When set, the strip renders a sign-in prompt instead of calendar content.
  final VoidCallback? onSignIn;

  /// When set, sign-in is in progress — strip shows "tap to cancel" and calls this on tap.
  final VoidCallback? onCancelSignIn;

  /// Whether calendar data is still being fetched for the first time.
  final bool isLoading;

  /// Whether to run repeating animations. Disable in tests to allow pumpAndSettle.
  final bool enableAnimations;
  final TargetPlatform? platformOverride;

  @override
  State<TimelineStrip> createState() => _TimelineStripState();
}

class _TimelineStripState extends State<TimelineStrip>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static final _log = Logger('_TimelineStripState');
  late final WindowService _windowService;
  late final ExpansionController _expansionController;
  late final TimelineFocusController _focusController;
  late final FocusNode _keyboardFocusNode;
  final _flashNotifier = ValueNotifier<double>(0.0);
  Timer? _flashTimer;
  late final AstroDataService _astroDataService;
  CalendarEvent? _hoveredEvent;
  AstroHit? _astroHit;
  bool _isHoveringStrip = false;
  PointerEvent? _lastPointerEvent;
  bool _isSettingsOpen = false;
  final GlobalKey _displaySectionKey = GlobalKey(debugLabel: 'DisplaySection');
  ExpansionState? _lastSentExpansionState;
  late Stream<DateTime> _paintTicks;
  late Stream<DateTime> _countdownTicks;
  String? _lastPaintStateDebug;

  void _updateAnimationTimer(Duration countdown) {
    if (!widget.enableAnimations) return;

    final needsAnimation = countdown.inSeconds > 0 && countdown.inMinutes < 2;

    if (needsAnimation && _flashTimer == null) {
      _flashTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        _flashNotifier.value = (_flashNotifier.value + 0.2) % 1.0;
      });
    } else if (!needsAnimation && _flashTimer != null) {
      _flashTimer?.cancel();
      _flashTimer = null;
      _flashNotifier.value = 0.0;
    }
  }

  @override
  void initState() {
    super.initState();
    _windowService = widget.windowService;
    _paintTicks = widget.clockService.tick10s;
    _countdownTicks = widget.clockService.tick1s;
    _expansionController = ExpansionController(
      executor: WindowServiceResizeExecutor(_windowService),
    )..start();
    _hideAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    )..addListener(_onHideAnimTick);
    _keyboardFocusNode = FocusNode(debugLabel: 'TimelineStripFocus');
    _focusController = TimelineFocusController(
      windowService: _windowService,
    );
    _focusController.isSentToBackNotifier.addListener(_onSentToBackChanged);

    // S5-FIX: Listen to settings changes to update heights and trigger rebuild
    widget.settingsService.addListener(_onSettingsChanged);

    _astroDataService =
        AstroDataService(settingsService: widget.settingsService);
    _astroDataService.addListener(_onAstroDataChanged);
    _astroDataService.initialize();

    WidgetsBinding.instance.addObserver(this);
    _updateHeights();
    unawaited(_syncWindowBehavior());
    _collidingIds = detectCollisions(widget.events);
    _log.fine('TimelineStrip: Initializing');
  }

  void _onAstroDataChanged() {
    _log.fine('TimelineStrip: astroData changed → '
        'current=${_astroDataService.current != null ? "AstroData(sunrise=${_astroDataService.current!.sunrise})" : "null"}');
    if (mounted) {
      setState(() {
        return;
      });
    }
  }

  void _onSettingsChanged() {
    if (mounted) {
      _updateHeights();
      unawaited(_syncWindowBehavior());
      setState(() {
        return;
      });
    }
  }

  @override
  void didUpdateWidget(TimelineStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settingsService != widget.settingsService) {
      oldWidget.settingsService.removeListener(_onSettingsChanged);
      widget.settingsService.addListener(_onSettingsChanged);
      _updateHeights();
    }

    if (oldWidget.events != widget.events) {
      _collidingIds = detectCollisions(widget.events);
    }

    // When loading clears and the cursor is already over the strip, re-evaluate
    // hover with the stored pointer position.  Without this, the strip stays
    // collapsed until the user makes a new mouse move because _handleMouse only
    // fires on pointer events — it does not react to state changes on its own.
    if (oldWidget.isLoading && !widget.isLoading) {
      final last = _lastPointerEvent;
      if (_isHoveringStrip && last != null) {
        _handleMouse(last);
      }
    }

    if (oldWidget.clockService != widget.clockService) {
      _paintTicks = widget.clockService.tick10s;
      _countdownTicks = widget.clockService.tick1s;
      _now = widget.clockService.now;
    }
  }

  @override
  void dispose() {
    _hideAnim.dispose();
    _expansionController.dispose();
    _focusController.isSentToBackNotifier.removeListener(_onSentToBackChanged);
    widget.settingsService.removeListener(_onSettingsChanged);
    _astroDataService.removeListener(_onAstroDataChanged);
    _astroDataService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _flashTimer?.cancel();

    _flashNotifier.dispose();
    _keyboardFocusNode.dispose();
    _focusController.dispose();
    super.dispose();
  }

  TargetPlatform get _targetPlatform {
    if (widget.platformOverride != null) return widget.platformOverride!;
    if (Platform.isMacOS) return TargetPlatform.macOS;
    if (Platform.isWindows) return TargetPlatform.windows;
    if (Platform.isLinux) return TargetPlatform.linux;
    return TargetPlatform.linux;
  }

  WindowMode _effectiveWindowMode() =>
      widget.settingsService.current.effectiveWindowMode;

  Future<void> _syncWindowBehavior() async {
    final effectiveMode = _effectiveWindowMode();
    await _focusController.setWindowMode(effectiveMode);
  }

  Future<void> _resetToFreshCollapsedState() async {
    final hadHoveredEvent = _hoveredEvent != null;
    _log.fine('TimelineStrip.resetFreshCollapsed START '
        'hovered=$hadHoveredEvent hovering=$_isHoveringStrip '
        'settings=$_isSettingsOpen '
        'sentToBack=${_focusController.isSentToBack} '
        'layout=${_layout != null} events=${widget.events.length}');

    _lastPaintStateDebug = null;
    if (mounted) {
      setState(() {
        _isSettingsOpen = false;
        _isHoveringStrip = false;
        _hoveredEvent = null;
        _layout = null;
      });
    }
    await _expansionController.sendAndAwait(ExpansionState.collapsed);

    _log.fine('TimelineStrip.resetFreshCollapsed DONE '
        'hovered=${_hoveredEvent != null} hovering=$_isHoveringStrip '
        'settings=$_isSettingsOpen '
        'sentToBack=${_focusController.isSentToBack} '
        'layout=${_layout != null} events=${widget.events.length}');
  }

  void _onHideAnimTick() {
    if (mounted) {
      setState(() {
        return;
      });
    }
  }

  void _onSentToBackChanged() {
    if (mounted) {
      setState(() {
        return;
      });
    }
  }

  bool _isHidden = false;
  bool _preHideSentToBack = false;
  late AnimationController _hideAnim;

  TimelineLayout? _layout;
  DateTime _now = DateTime.now();
  Set<String> _collidingIds = const {};

  // WindowService owns the authoritative collapsed height; the strip content
  // height IS that value — no separate formula. (Previously this subtracted a
  // magic 3px, leaving the painter 3px shorter than the OS window.)
  double get _collapsedHeight => _windowService.getCollapsedHeight();

  void _updateHeights() {
    _log.fine(
        'Timestrip: _updatgeHeights called:  strip height is to $_collapsedHeight');
    final settings = widget.settingsService.current;
    unawaited(_windowService.updateHeights(settings.fontSizePx));
  }

  // ── Focus / lifecycle handlers ────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !_isSettingsOpen) {
      setState(() {
        _isHoveringStrip = false;
        _hoveredEvent = null;
      });
      _expansionController.send(ExpansionState.collapsed);
    }
  }

  // ── Mouse handlers ───────────────────────────────────────────────────────

  void _onMouseEnter(PointerEnterEvent event) {
    _handleMouse(event);
  }

  void _onMouseExit(PointerExitEvent event) {
    _handleMouse(event);
  }

  void _handleMouse(PointerEvent details) {
    _lastPointerEvent = details;
    if (_focusController.isSentToBack) return;
    final layout = _layout;
    if (layout == null) return;

    final mouseX = details.localPosition.dx;
    final mouseY = details.localPosition.dy;
    final isOverStripZone = mouseY < _collapsedHeight;

    // Overlap ranks computed before bounds so effectiveEndX trims stacked cards,
    // and before sort so rank breaks duration ties.
    final overlapRanks = layout.computeExactOverlapRanks(widget.events, _now);

    // Sort ascending by duration so shorter events win hit-testing; within same
    // duration, higher rank (topmost card) comes first.
    final sortedEvents = [...widget.events]..sort((a, b) {
        final durCmp = a.duration.compareTo(b.duration);
        if (durCmp != 0) return durCmp;
        final aRank = overlapRanks[a.id]?.rank ?? 0;
        final bRank = overlapRanks[b.id]?.rank ?? 0;
        return bRank.compareTo(aRank);
      });

    final boundsMap = _computeEventBoundsMap(
        layout, sortedEvents, overlapRanks, isOverStripZone);

    final state = ExpansionLogic.determineState(
      details: details,
      eventBounds: boundsMap.values.toList(),
      stripHeight: _collapsedHeight,
      isSettingsOpen: _isSettingsOpen,
    );

    final isOverStrip = details is! PointerExitEvent && isOverStripZone;
    final hit =
        _findHoveredEvent(sortedEvents, boundsMap, mouseX, mouseY, state);

    if (state != _lastSentExpansionState) {
      _lastSentExpansionState = state;
      _log.fine(
          '[TS] expansion → ${state.name} mouseX=${mouseX.toStringAsFixed(1)} mouseY=${mouseY.toStringAsFixed(1)} isExit=${details is PointerExitEvent}');
    }
    _expansionController.send(state);

    final settings = widget.settingsService.current;
    final astroData = _astroDataService.current;
    final newAstroHit = (isOverStripZone &&
            settings.theme == AppTheme.astronomical &&
            astroData != null)
        ? AstronomicalBackgroundLayer(
            astroData: astroData,
            layout: layout,
            now: _now,
            lat: settings.astroSettings.latitude,
            lng: settings.astroSettings.longitude,
          ).hitTest(
            Offset(mouseX, mouseY), Size(layout.stripWidth, _collapsedHeight))
        : null;

    if (isOverStrip != _isHoveringStrip ||
        hit?.id != _hoveredEvent?.id ||
        newAstroHit?.time != _astroHit?.time) {
      setState(() {
        _isHoveringStrip = isOverStrip;
        _hoveredEvent = hit;
        _astroHit = newAstroHit;
      });
    }
  }

  Map<String, EventBounds> _computeEventBoundsMap(
    TimelineLayout layout,
    List<CalendarEvent> sortedEvents,
    Map<String, ({int rank, int groupSize})> overlapRanks,
    bool isOverStripZone,
  ) {
    final boundsMap = <String, EventBounds>{};
    for (final e in sortedEvents) {
      if (isOverStripZone) {
        final startX = layout.effectiveStartX(e, _now, overlapRanks);
        final endX = layout.effectiveEndX(e, _now, overlapRanks);
        boundsMap[e.id] = EventBounds(
            left: startX, right: endX, top: 0, bottom: _collapsedHeight);
      } else {
        final cardW = _cardWidth(layout.stripWidth, event: e);
        final cardL = _cardLeft(layout.stripWidth, event: e);
        boundsMap[e.id] = EventBounds(
            left: cardL,
            right: cardL + cardW,
            top: _collapsedHeight,
            bottom: 175);
      }
    }
    return boundsMap;
  }

  CalendarEvent? _findHoveredEvent(
    List<CalendarEvent> sortedEvents,
    Map<String, EventBounds> boundsMap,
    double mouseX,
    double mouseY,
    ExpansionState state,
  ) {
    // S5-FIX: Only latch in the card zone (below strip). On the strip, use
    // precision switching so shorter events can be reached.
    final shouldLatch = _hoveredEvent != null &&
        ExpansionLogic.shouldPrioritizeLatch(mouseY, _collapsedHeight);
    if (shouldLatch &&
        boundsMap[_hoveredEvent!.id]?.contains(mouseX, mouseY) == true) {
      return _hoveredEvent;
    }

    if (state != ExpansionState.expanded) return null;
    for (final e in sortedEvents) {
      if (boundsMap[e.id]!.contains(mouseX, mouseY)) return e;
    }
    return null;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  double _cardLeft(double screenWidth, {CalendarEvent? event}) {
    final layout = _layout;
    final target = event ?? _hoveredEvent;
    if (layout == null || target == null) return 4.0;
    final startX = layout.xForTime(target.startTime, _now);
    final cardWidth = _cardWidth(screenWidth, event: target);
    return startX.clamp(4.0, math.max(4.0, screenWidth - cardWidth - 4.0));
  }

  double _cardWidth(double screenWidth, {CalendarEvent? event}) {
    const minCardWidth = 260.0;
    final layout = _layout;
    final target = event ?? _hoveredEvent;
    if (layout == null || target == null) return minCardWidth;
    final startX = layout.xForTime(target.startTime, _now);
    final endX = layout.xForTime(target.endTime, _now);
    return (endX - startX).abs().clamp(minCardWidth, double.infinity);
  }

  Future<void> _hideStrip() async {
    _log.info(
        'TimelineStrip: hiding strip (preHideSentToBack=$_preHideSentToBack, settingsOpen=$_isSettingsOpen, hoveredEvent=$_hoveredEvent)');
    _preHideSentToBack = _focusController.isSentToBack;
    if (_preHideSentToBack) {
      _log.fine(
          'TimelineStrip: strip was sent-to-back, restoring to front first');
      await _focusController.restoreToFront();
    }

    // Collapse before hiding to reset OS min/max window constraints!
    _log.fine('TimelineStrip: ensuring strip is collapsed before hiding');
    setState(() {
      _hoveredEvent = null;
      _isSettingsOpen = false;
    });
    _lastSentExpansionState = ExpansionState.collapsed;
    await _expansionController.sendAndAwait(ExpansionState.collapsed);

    _log.fine('TimelineStrip: calling windowService.prepareToHide');
    await _windowService.prepareToHide();
    setState(() {
      _isHidden = true;
    });
    _log.fine('TimelineStrip: reversing hide animation');
    await _hideAnim.reverse();
    final double fontSize = widget.settingsService.current.fontSizePx;
    _log.info('TimelineStrip: resizing to mini strip (fontSize=$fontSize)');
    await _windowService.resizeToMiniStrip(fontSize);
    _log.info('TimelineStrip: hide complete');
  }

  Future<void> _showStrip() async {
    _log.info('TimelineStrip: restoring strip');
    // Rebuild the full-strip content first so the present composites the right
    // frame.
    setState(() {
      _isHidden = false;
      _isHoveringStrip = false;
    });
    _expansionController.send(ExpansionState.collapsed);
    // Restore via the SAME sequence init uses (reserve→size→present) — the one
    // path that keeps the strip in its strut. Replaces the divergent
    // resizeToFullStrip + completeShow/onShowStrip (sized before reserving, no
    // present → the strip drifted below the strut: build-still-below-strut.out).
    _log.fine('TimelineStrip: restoring window via windowService.showStrip()');
    await _windowService.showStrip();
    _log.fine('TimelineStrip: playing show animation');
    await _hideAnim.forward();
    if (_preHideSentToBack) {
      _log.info('TimelineStrip: restoring sent-to-back state');
      await _focusController.sendToBack();
      _preHideSentToBack = false;
    }
    _log.info('TimelineStrip: show complete');
  }

  void _toggleSettings() {
    setState(() {
      _isSettingsOpen = !_isSettingsOpen;
      _hoveredEvent = null;
    });
    if (_isSettingsOpen) {
      _expansionController.send(ExpansionState.expanded);
      unawaited(_windowService.focus());
    } else {
      _expansionController.send(ExpansionState.collapsed);
    }
  }

  Color _resolveCountdownColor(
      Duration remaining, Color base, double flashValue) {
    if (remaining <= Duration.zero) return Colors.red;
    if (remaining.inMinutes >= 5) return base;
    if (remaining.inMinutes < 2 && widget.enableAnimations) {
      return HSVColor.fromAHSV(1.0, flashValue * 360, 0.7, 1.0).toColor();
    }
    final factor = (5 - (remaining.inMilliseconds / 60000)).clamp(0.0, 1.0);
    return Color.lerp(base, Colors.red, factor)!;
  }

  void _debugPaintState({
    required bool isExpanded,
    required BoxConstraints constraints,
    required Color backdropColor,
    required Color painterBackgroundColor,
  }) {
    final cardVisible = widget.onSignIn == null &&
        widget.onCancelSignIn == null &&
        isExpanded &&
        !_isSettingsOpen &&
        _hoveredEvent != null;
    final settingsVisible = widget.onSignIn == null &&
        widget.onCancelSignIn == null &&
        _isSettingsOpen;
    final signature = [
      'expanded=$isExpanded',
      'card=$cardVisible',
      'settings=$settingsVisible',
      'hovered=${_hoveredEvent != null}',
      'hovering=$_isHoveringStrip',
      'sentToBack=${_focusController.isSentToBack}',
      'signIn=${widget.onSignIn != null}',
      'cancelSignIn=${widget.onCancelSignIn != null}',
      'loading=${widget.isLoading}',
      'layout=${_layout != null}',
      'events=${widget.events.length}',
      'collapsedH=${_collapsedHeight.toStringAsFixed(1)}',
      'expandedH=${_windowService.getExpandedHeight().toStringAsFixed(1)}',
      'backdrop=#${backdropColor.toARGB32().toRadixString(16).padLeft(8, '0')}',
      'painterBg=#${painterBackgroundColor.toARGB32().toRadixString(16).padLeft(8, '0')}',
      'maxH=${constraints.maxHeight.toStringAsFixed(1)}',
    ].join(' ');
    if (signature == _lastPaintStateDebug) return;
    _lastPaintStateDebug = signature;
    _log.fine('TimelineStrip.paint-state $signature');
  }

  // ── Build ────────────────────────────────────────────────────────────────

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PhysicalWindowState>(
      stream: _expansionController.stateStream,
      initialData: PhysicalWindowState.collapsed,
      builder: (context, expansionSnapshot) {
        final isExpanded = expansionSnapshot.data!.isExpanded;
        return StreamBuilder<DateTime>(
          stream: _paintTicks,
          initialData: widget.clockService.now,
          builder: (context, snapshot) {
            _now = snapshot.data!;
            return LayoutBuilder(
              builder: (ctx, constraints) =>
                  _buildLayout(ctx, isExpanded, constraints),
            );
          },
        );
      },
    );
  }

  Widget _buildLayout(
      BuildContext context, bool isExpanded, BoxConstraints constraints) {
    final theme = Theme.of(context);
    final settings = widget.settingsService.current;
    final fontSize = settings.fontSizePx;
    final stripBg = theme.brightness == Brightness.dark
        ? const Color(0xFF1A1A2E)
        : Colors.white;
    final stripWidth = constraints.maxWidth;
    final now = _now;

    // Left toolbar: left:40 (clears 36px hide button) + 3×(pad6+icon24+pad6) + 2×4px spacers,
    // plus 15px extra clearance.
    const double leftToolbarRight = 40.0 + 3 * 36.0 + 2 * 4.0 + 15.0;
    // CountdownDisplay (untilNext mode) sits just left of the now line.
    // Its width is padding(12) + text — longest format "X h YY min" ≈ fontSize × 6.0.
    // Now line must clear: toolbar + 8px gap + countdown widget + 8px gap.
    final double countdownEst = fontSize * 6.0 + 12.0;
    final double nowIndicatorX =
        (leftToolbarRight + 16.0 + countdownEst).clamp(0.0, stripWidth * 0.35);
    final double actualFraction = nowIndicatorX / stripWidth;

    final layout = TimelineLayout(
      stripWidth: stripWidth,
      nowIndicatorX: nowIndicatorX,
      windowStart: now.subtract(Duration(
          milliseconds:
              (settings.timeWindowHours * 3600000 * actualFraction).toInt())),
      windowEnd: now.add(Duration(
          milliseconds:
              (settings.timeWindowHours * 3600000 * (1.0 - actualFraction))
                  .toInt())),
    );
    _layout = layout;

    if (_isHidden || _hideAnim.value < 1.0) {
      return _buildMiniWidget(context, constraints);
    }

    final outerMode = layout.activeEvent(widget.events, now) != null
        ? CountdownMode.untilEnd
        : CountdownMode.untilNext;
    _debugPaintState(
      isExpanded: isExpanded,
      constraints: constraints,
      backdropColor: Colors.transparent,
      painterBackgroundColor: stripBg,
    );

    final isAuthPrompt =
        widget.onSignIn != null || widget.onCancelSignIn != null;

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) => KeyEventResult.ignored,
      child: MouseRegion(
        onEnter: _onMouseEnter,
        onHover: _handleMouse,
        onExit: _onMouseExit,
        hitTestBehavior: HitTestBehavior.translucent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: isExpanded
                  ? _windowService.getExpandedHeight()
                  : constraints.maxHeight,
              child: const ColoredBox(color: Colors.transparent),
            ),
            _buildPainterPositioned(context, layout),
            if (isAuthPrompt)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () =>
                      (widget.onCancelSignIn ?? widget.onSignIn)?.call(),
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox.expand(),
                ),
              ),
            if (!isAuthPrompt)
              _buildCountdownPositioned(context, layout, outerMode),
            if (!isAuthPrompt) _buildLeftToolbar(context),
            if (!isAuthPrompt)
              Positioned(
                right: 8,
                top: 0,
                height: _collapsedHeight,
                child: Center(
                  child: _IconButton(
                    icon: Icons.power_settings_new,
                    onTap: () => exit(0),
                    stripBackgroundColor: stripBg,
                  ),
                ),
              ),
            // Only host the astro tooltip when the strip is wide enough to
            // place it; skips a transient narrow frame during a hide/show
            // resize (where layout.stripWidth can momentarily be the mini width).
            if (_astroHit != null && stripWidth >= _kMinAstroTooltipStripWidth)
              _buildAstroTooltip(context, layout),
            if (!isAuthPrompt &&
                isExpanded &&
                !_isSettingsOpen &&
                _hoveredEvent != null)
              Positioned(
                top: _collapsedHeight,
                left: _cardLeft(stripWidth),
                child: HoverDetailOverlay(
                  event: _hoveredEvent!,
                  width: _cardWidth(stripWidth),
                  fontSize: fontSize,
                ),
              ),
            if (!isAuthPrompt && _isSettingsOpen) ..._buildSettingsWidgets(),
            // Hide button is last (topmost z-order) so it stays accessible
            // even when the settings backdrop covers the strip.
            if (!isAuthPrompt)
              Positioned(
                left: 8.0,
                top: 0,
                height: _collapsedHeight,
                child: Center(
                  child: _IconButton(
                    icon: Icons.arrow_left,
                    onTap: () => unawaited(_hideStrip()),
                    stripBackgroundColor: stripBg,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniWidget(BuildContext context, BoxConstraints constraints) {
    final theme = Theme.of(context);
    final settings = widget.settingsService.current;
    final stripBg = theme.brightness == Brightness.dark
        ? const Color(0xFF1A1A2E)
        : Colors.white;
    final double miniWidth = _windowService.getMiniWidth(settings.fontSizePx);

    return Align(
      alignment: Alignment.topLeft,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => unawaited(_showStrip()),
          child: Container(
            width: miniWidth,
            height: _collapsedHeight,
            color: stripBg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: _IconButton(
                    icon: Icons.arrow_right,
                    onTap: () => unawaited(_showStrip()),
                    stripBackgroundColor: stripBg,
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: StreamBuilder<DateTime>(
                      stream: _countdownTicks,
                      initialData: _now,
                      builder: (context, timeSnapshot) {
                        final tickNow = timeSnapshot.data!;
                        final tickActive =
                            _layout?.activeEvent(widget.events, tickNow);
                        final tickNextOverlap = tickActive != null
                            ? (widget.events
                                    .where((e) =>
                                        e.startTime.isAfter(tickNow) &&
                                        e.startTime
                                            .isBefore(tickActive.endTime))
                                    .toList()
                                  ..sort((a, b) =>
                                      a.startTime.compareTo(b.startTime)))
                                .firstOrNull
                            : null;
                        final tickNextToStart = tickActive == null
                            ? (widget.events
                                    .where((e) => e.startTime.isAfter(tickNow))
                                    .toList()
                                  ..sort((a, b) =>
                                      a.startTime.compareTo(b.startTime)))
                                .firstOrNull
                            : null;
                        final tickTarget = tickActive != null
                            ? (tickNextOverlap?.startTime ?? tickActive.endTime)
                            : tickNextToStart?.startTime;
                        final tickMode = tickActive != null
                            ? CountdownMode.untilEnd
                            : CountdownMode.untilNext;
                        final tickBaseColor = tickMode == CountdownMode.untilEnd
                            ? (theme.brightness == Brightness.dark
                                ? Colors.amber
                                : Colors.orange[800]!)
                            : theme.textTheme.bodyMedium?.color ?? Colors.white;
                        final countdown = tickTarget != null
                            ? (_layout?.countdownTo(tickTarget, tickNow) ??
                                Duration.zero)
                            : Duration.zero;
                        _updateAnimationTimer(countdown);
                        return ValueListenableBuilder<double>(
                          valueListenable: _flashNotifier,
                          builder: (context, flashValue, _) {
                            final countdownColor = _resolveCountdownColor(
                                countdown, tickBaseColor, flashValue);
                            return _buildCountdownContent(
                                countdown,
                                tickMode,
                                countdownColor,
                                flashValue,
                                settings.fontSizePx * 1.5,
                                stripBg,
                                Alignment.centerRight);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPainterPositioned(BuildContext context, TimelineLayout layout) {
    final theme = Theme.of(context);
    final settings = widget.settingsService.current;
    final stripBg = theme.brightness == Brightness.dark
        ? const Color(0xFF1A1A2E)
        : Colors.white;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: _collapsedHeight,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: TimelinePainter(
            events: widget.events,
            now: _now,
            nowIndicatorX: layout.nowIndicatorX,
            windowStart: layout.windowStart,
            windowEnd: layout.windowEnd,
            hoveredEventId: _hoveredEvent?.id,
            collidingIds: _collidingIds,
            fontSize: settings.fontSizePx,
            backgroundColor: stripBg,
            pastOverlayColor: theme.brightness == Brightness.dark
                ? Colors.black26
                : Colors.black12,
            nowLineColor: const Color(0xFFB71C1C),
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
            tickColor:
                theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75) ??
                    Colors.grey,
            isLoading: widget.isLoading,
            loadingTextColor: theme.textTheme.bodyMedium?.color ?? Colors.white,
            isSignIn: widget.onSignIn != null || widget.onCancelSignIn != null,
            isSigningIn: widget.onCancelSignIn != null,
            signInTextColor: theme.textTheme.bodyMedium?.color ?? Colors.white,
            surfaceOpacity: 1.0,
            emphasisOpacity: 1.0,
            stripOpacity: settings.idleTimelineOpacity,
            astroData: _astroDataService.current,
            isAstroTheme: settings.theme == AppTheme.astronomical,
            astroLat: settings.astroSettings.latitude,
            astroLng: settings.astroSettings.longitude,
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownPositioned(
      BuildContext context, TimelineLayout layout, CountdownMode outerMode) {
    final theme = Theme.of(context);
    final settings = widget.settingsService.current;
    final stripBg = theme.brightness == Brightness.dark
        ? const Color(0xFF1A1A2E)
        : Colors.white;
    final nowIndicatorX = layout.nowIndicatorX;
    final stripWidth = layout.stripWidth;
    return Positioned(
      left: outerMode == CountdownMode.untilEnd ? nowIndicatorX + 8 : null,
      right: outerMode == CountdownMode.untilNext
          ? stripWidth - nowIndicatorX + 8
          : null,
      top: 0,
      height: _collapsedHeight,
      child: StreamBuilder<DateTime>(
        stream: _countdownTicks,
        initialData: _now,
        builder: (context, timeSnapshot) {
          final tickNow = timeSnapshot.data!;
          final tickActive = _layout?.activeEvent(widget.events, tickNow);
          final tickNextOverlap = tickActive != null
              ? (widget.events
                      .where((e) =>
                          e.startTime.isAfter(tickNow) &&
                          e.startTime.isBefore(tickActive.endTime))
                      .toList()
                    ..sort((a, b) => a.startTime.compareTo(b.startTime)))
                  .firstOrNull
              : null;
          final tickNextToStart = tickActive == null
              ? (widget.events
                      .where((e) => e.startTime.isAfter(tickNow))
                      .toList()
                    ..sort((a, b) => a.startTime.compareTo(b.startTime)))
                  .firstOrNull
              : null;
          final tickTarget = tickActive != null
              ? (tickNextOverlap?.startTime ?? tickActive.endTime)
              : tickNextToStart?.startTime;
          final tickMode = tickActive != null
              ? CountdownMode.untilEnd
              : CountdownMode.untilNext;
          final tickBaseColor = tickMode == CountdownMode.untilEnd
              ? (theme.brightness == Brightness.dark
                  ? Colors.amber
                  : Colors.orange[800]!)
              : theme.textTheme.bodyMedium?.color ?? Colors.white;

          final countdown = tickTarget != null
              ? layout.countdownTo(tickTarget, tickNow)
              : Duration.zero;
          _updateAnimationTimer(countdown);

          return ValueListenableBuilder<double>(
            valueListenable: _flashNotifier,
            builder: (context, flashValue, _) {
              final countdownColor =
                  _resolveCountdownColor(countdown, tickBaseColor, flashValue);
              return Center(
                child: _buildCountdownContent(countdown, tickMode,
                    countdownColor, flashValue, settings.fontSizePx, stripBg),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCountdownContent(Duration countdown, CountdownMode mode,
      Color color, double flashValue, double fontSize, Color stripBg,
      [Alignment alignment = Alignment.center]) {
    double scale = 1.0;
    Offset shake = Offset.zero;
    if (countdown.inSeconds > 0 && widget.enableAnimations) {
      if (countdown.inSeconds <= 120 && countdown.inSeconds > 30) {
        scale = 1.0 + (120 - countdown.inSeconds) / 90.0 * 2.0;
      } else if (countdown.inSeconds <= 30) {
        scale = 3.0;
      }
      if (countdown.inSeconds <= 60) {
        shake = Offset(math.sin(flashValue * 8 * math.pi) * 2.0, 0);
      }
    }
    return Transform.translate(
      offset: shake,
      child: Transform.scale(
        scale: scale,
        alignment: alignment,
        child: CountdownDisplay(
          remaining: countdown,
          mode: mode,
          color: color,
          fontSize: fontSize,
          backgroundColor: stripBg,
        ),
      ),
    );
  }

  Widget _buildLeftToolbar(BuildContext context) {
    final stripBg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A2E)
        : Colors.white;
    return Positioned(
      left: 54,
      top: 0,
      height: _collapsedHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconButton(
            icon: Icons.refresh,
            onTap: () {
              // Refresh = reload calendars + reset the view to fresh-collapsed.
              // It deliberately does NOT touch the strut/AppBar anymore: the old
              // reassertAppBar here was a band-aid for non-deterministic strut
              // behavior, and tearing the AppBar down (ABM_REMOVE→NEW) is exactly
              // what stranded the strip below the strut. See
              // docs/WINDOW_ENTRYPOINT_CONVERGENCE_PLAN.md.
              unawaited(widget.calendarController!.refresh());
              unawaited(_resetToFreshCollapsedState());
            },
            stripBackgroundColor: stripBg,
          ),
          const SizedBox(width: 8),
          _IconButton(
            icon: Icons.flip_to_back,
            active: _focusController.isSentToBack,
            onTap: () {
              if (_focusController.isSentToBack) {
                unawaited(_focusController.restoreToFront());
              } else {
                unawaited(_focusController.sendToBack());
              }
            },
            stripBackgroundColor: stripBg,
          ),
          const SizedBox(width: 8),
          if (widget.displayService != null)
            DisplayFallbackIndicator(
              displayService: widget.displayService!,
              stripHeight: _collapsedHeight,
              onTap: _openSettingsToDisplaySection,
            ),
          _IconButton(
            icon: Icons.settings,
            onTap: _toggleSettings,
            stripBackgroundColor: stripBg,
          ),
        ],
      ),
    );
  }

  void _openSettingsToDisplaySection() {
    if (!_isSettingsOpen) {
      _toggleSettings();
    }
    // Allow the panel a frame to mount, then ensure the Display section is
    // visible. The widget tree wires the scroll target via a GlobalKey held
    // inside SettingsPanel.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _displaySectionKey.currentContext;
      if (ctx != null) {
        unawaited(Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 250)));
      }
    });
  }

  Widget _buildAstroTooltip(BuildContext context, TimelineLayout layout) {
    final hit = _astroHit!;
    final stripWidth = layout.stripWidth;
    return Positioned(
      // math.max guards against a narrow strip (e.g. the mini/hidden window)
      // making the upper limit < lower limit, which makes clamp() throw.
      left: (hit.glyphX - 90).clamp(4.0, math.max(4.0, stripWidth - 184.0)),
      top: math.max(2.0, hit.glyphCy - kAstroIconRadius - 38),
      child: _AstroTooltip(
        hit: hit,
        now: _now,
        fontSize: widget.settingsService.current.fontSizePx,
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      ),
    );
  }

  List<Widget> _buildSettingsWidgets() {
    return [
      Positioned.fill(
        child: GestureDetector(
          onTap: _toggleSettings,
          behavior: HitTestBehavior.opaque,
          child: Container(color: Colors.transparent),
        ),
      ),
      Positioned(
        top: _collapsedHeight,
        left: 8,
        bottom: 8,
        child: SettingsPanel(
          settingsService: widget.settingsService,
          calendarController: widget.calendarController!,
          onSignOut: widget.onSignOut,
          platformOverride: _targetPlatform,
          displayService: widget.displayService,
          displaySectionKey: _displaySectionKey,
        ),
      ),
    ];
  }
}

class _AstroTooltip extends StatelessWidget {
  const _AstroTooltip({
    required this.hit,
    required this.now,
    required this.fontSize,
    required this.alwaysUse24HourFormat,
  });

  final AstroHit hit;
  final DateTime now;
  final double fontSize;
  final bool alwaysUse24HourFormat;

  String _fmtTime(BuildContext context) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(hit.time.toLocal()),
        alwaysUse24HourFormat: alwaysUse24HourFormat,
      );

  String _fmtDelta() {
    final diff = hit.time.difference(now);
    final abs = diff.abs();
    final h = abs.inHours;
    final m = abs.inMinutes % 60;
    final parts = [if (h > 0) '${h}h', if (m > 0 || h == 0) '${m}m'].join(' ');
    return diff.isNegative ? '$parts ago' : 'in $parts';
  }

  @override
  Widget build(BuildContext context) {
    final small = fontSize * 0.8;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 4, offset: Offset(2, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(hit.label,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: small,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Text('${_fmtTime(context)}  ·  ${_fmtDelta()}',
                    style: TextStyle(color: Colors.white60, fontSize: small)),
              ],
            ),
            if (hit.fraction != null)
              Text('${(hit.fraction! * 100).round()}% illuminated',
                  style:
                      TextStyle(color: Colors.white54, fontSize: small * 0.9)),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatefulWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
    required this.stripBackgroundColor,
    this.active = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color stripBackgroundColor;
  final bool active;

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = widget.active
        ? theme.colorScheme.primary
        : (isDark ? Colors.white70 : Colors.black54);
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      // Base button click feedback: press in (scale down) + sink the shadow.
      child: AnimatedScale(
        scale: _pressed ? 0.86 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: widget.active
                ? theme.colorScheme.primary.withValues(alpha: 0.25)
                : widget.stripBackgroundColor
                    .withValues(alpha: _pressed ? 1.0 : 0.92),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.active
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.white70 : Colors.black54),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _pressed ? 0.15 : 0.35),
                blurRadius: _pressed ? 1 : 3,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          child: Icon(widget.icon, color: iconColor, size: 24),
        ),
      ),
    );
  }
}
