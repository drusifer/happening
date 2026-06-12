// On-strip indicator that the user's chosen display is unavailable.
//
// TLDR:
// Overview: A small icon rendered immediately left of the settings gear that
//           visualises DisplayService.isInFallback. Tap → opens Settings and
//           auto-scrolls the Display section into view.
// Problem:  Users with multi-monitor preferences need a visible cue that the
//           strip has fallen back to primary because their chosen display
//           disconnected.
// Solution: ListenableBuilder around DisplayService renders an Icon when in
//           fallback. On IN_FALLBACK → AUTO_RETURNING transition (signalled
//           by `wasJustAutoReturned`) the icon fades + slides toward the gear
//           over 600ms. Tap fires a caller-supplied callback.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:happening/core/display/display_service.dart';

/// Width of the indicator's icon at the maximum strip height. Scales down via
/// `min(_kMaxIconSize, stripHeight - _kSizeHeadroom)` to keep the icon legible
/// at small strip heights.
const double _kMaxIconSize = 14.0;
const double _kSizeHeadroom = 8.0;

/// Duration of the auto-return fade + slide animation.
const Duration kFallbackIndicatorAnimationDuration =
    Duration(milliseconds: 600);

/// Logical-pixel slide distance the icon travels toward the settings gear
/// during the auto-return animation.
const double _kSlideDistance = 24.0;

class DisplayFallbackIndicator extends StatefulWidget {
  const DisplayFallbackIndicator({
    super.key,
    required this.displayService,
    required this.stripHeight,
    required this.onTap,
    this.color,
  });

  final DisplayService displayService;
  final double stripHeight;
  final VoidCallback onTap;

  /// Override for the icon color. Defaults to a soft amber visible on the
  /// dark strip background.
  final Color? color;

  @override
  State<DisplayFallbackIndicator> createState() =>
      _DisplayFallbackIndicatorState();
}

class _DisplayFallbackIndicatorState extends State<DisplayFallbackIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _autoReturnController;

  @override
  void initState() {
    super.initState();
    _autoReturnController = AnimationController(
      vsync: this,
      duration: kFallbackIndicatorAnimationDuration,
    );
    widget.displayService.addListener(_onDisplayChanged);
  }

  @override
  void didUpdateWidget(DisplayFallbackIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.displayService != widget.displayService) {
      oldWidget.displayService.removeListener(_onDisplayChanged);
      widget.displayService.addListener(_onDisplayChanged);
    }
  }

  @override
  void dispose() {
    widget.displayService.removeListener(_onDisplayChanged);
    _autoReturnController.dispose();
    super.dispose();
  }

  void _onDisplayChanged() {
    // Auto-return: chosen display reconnected after a fallback period.
    // Play the fade + slide animation once.
    if (widget.displayService.wasJustAutoReturned) {
      unawaited(_autoReturnController.forward(from: 0.0));
    }
  }

  double _iconSize() {
    final scaled = widget.stripHeight - _kSizeHeadroom;
    return scaled < _kMaxIconSize
        ? scaled.clamp(0.0, _kMaxIconSize)
        : _kMaxIconSize;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
        [widget.displayService, _autoReturnController],
      ),
      builder: (context, _) {
        final inFallback = widget.displayService.isInFallback;
        final animating = _autoReturnController.isAnimating;

        // Visible iff we're either in fallback OR currently playing the
        // auto-return exit animation.
        if (!inFallback && !animating) {
          return const SizedBox.shrink();
        }

        // When animating the exit, fade 1→0 and slide rightward toward the gear.
        final t = _autoReturnController.value;
        final opacity = animating ? 1.0 - t : 1.0;
        final dx = animating ? _kSlideDistance * t : 0.0;

        final size = _iconSize();
        final color = widget.color ?? Colors.amberAccent.shade100;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Chosen display unavailable — showing on primary.',
              child: GestureDetector(
                onTap: widget.onTap,
                child: Transform.translate(
                  offset: Offset(dx, 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      Icons.desktop_access_disabled,
                      size: size,
                      color: color.withValues(alpha: opacity),
                      semanticLabel: 'Chosen display unavailable',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
          ],
        );
      },
    );
  }
}
