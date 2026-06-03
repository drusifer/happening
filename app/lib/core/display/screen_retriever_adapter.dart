// Production adapters from screen_retriever to DisplayProbe + DisplayEvents.
//
// TLDR:
// Overview: Bridges the screen_retriever package to the DisplayService DI
//           interfaces so test code can inject fakes while production wires
//           the real platform plugin.
// Problem:  DisplayService is testable only when its inputs are abstract;
//           but production needs a concrete subscriber to screen_retriever.
// Solution: ScreenRetrieverDisplayProbe + ScreenRetrieverDisplayEvents
//           implement the two interfaces using the singleton screenRetriever
//           and the ScreenListener mixin contract.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:ui';

import 'package:screen_retriever/screen_retriever.dart' as sr;

import 'display_id.dart';
import 'display_info.dart';
import 'display_service.dart';

class ScreenRetrieverDisplayProbe implements DisplayProbe {
  ScreenRetrieverDisplayProbe(this._sr);
  final sr.ScreenRetriever _sr;

  @override
  Future<List<DisplayInfo>> getAll() async {
    final all = await _sr.getAllDisplays();
    final primary = await _sr.getPrimaryDisplay();
    return all.map((d) => _toInfo(d, primary)).toList();
  }

  DisplayInfo _toInfo(sr.Display d, sr.Display primary) {
    return DisplayInfo(
      id: DisplayId(d.id),
      osName: d.name,
      size: d.size,
      workAreaOrigin: d.visiblePosition ?? Offset.zero,
      workAreaSize: d.visibleSize ?? d.size,
      scaleFactor: (d.scaleFactor ?? 1).toDouble(),
      isPrimary: d.id == primary.id &&
          d.size == primary.size &&
          (d.visiblePosition ?? Offset.zero) ==
              (primary.visiblePosition ?? Offset.zero),
    );
  }
}

/// Subscribes to screen_retriever's flat event stream and fires the
/// DisplayService refresh callback on any display add/remove/metrics-change.
class ScreenRetrieverDisplayEvents
    with sr.ScreenListener
    implements DisplayEvents {
  ScreenRetrieverDisplayEvents(this._sr);
  final sr.ScreenRetriever _sr;

  void Function()? _onChange;

  @override
  void Function() subscribe(void Function() onChange) {
    _onChange = onChange;
    _sr.addListener(this);
    return () {
      _sr.removeListener(this);
      _onChange = null;
    };
  }

  @override
  void onScreenEvent(String eventName) {
    _onChange?.call();
  }
}
