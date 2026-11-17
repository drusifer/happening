// Production adapters from screen_retriever to DisplayProbe + DisplayEvents.
//
// TLDR:
// Overview: Bridges the screen_retriever package to the DisplayService DI
//           interfaces so test code can inject fakes while production wires
//           the real platform plugin.
// Problem:  DisplayService is testable only when its inputs are abstract;
//           but production needs a concrete subscriber to screen_retriever.
// Solution: ScreenRetrieverDisplayProbe + ScreenRetrieverDisplayEvents
//           implement the two interfaces using DisplayManager.instance
//           from screen_retriever 0.4.0+.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'package:logging/logging.dart';
import 'package:screen_retriever/screen_retriever.dart' as sr;

import 'display_id.dart';
import 'display_info.dart';
import 'display_service.dart';

class ScreenRetrieverDisplayProbe implements DisplayProbe {
  ScreenRetrieverDisplayProbe(this._dm);
  final sr.DisplayManager _dm;

  static final _log = Logger('ScreenRetrieverDisplayProbe');

  @override
  Future<List<DisplayInfo>> getAll() async {
    final all = _dm.getAll();
    final primary = _dm.getPrimary();
    try {
      final result = all.map((d) => _toInfo(d, primary)).toList();
      _log.fine('getAll: primaryId=${primary?.id} displays=$result');
      return result;
    } finally {
      primary?.dispose();
      for (final d in all) {
        d.dispose();
      }
    }
  }

  DisplayInfo _toInfo(sr.Display d, sr.Display? primary) {
    final size = d.size.toSize();
    final workArea = d.workArea.toRect();
    return DisplayInfo(
      id: DisplayId('${d.id}'),
      osName: d.name,
      size: size,
      workAreaOrigin: workArea.topLeft,
      workAreaSize: workArea.size,
      scaleFactor: d.scaleFactor,
      isPrimary: d.isPrimary ||
          (primary != null &&
              d.id == primary.id &&
              size == primary.size.toSize() &&
              workArea.topLeft == primary.workArea.toRect().topLeft),
    );
  }
}

/// Subscribes to screen_retriever's display event stream and fires the
/// DisplayService refresh callback on any display add/remove/metrics-change.
class ScreenRetrieverDisplayEvents implements DisplayEvents {
  ScreenRetrieverDisplayEvents(this._dm);
  final sr.DisplayManager _dm;

  @override
  void Function() subscribe(void Function() onChange) {
    final listenerId = _dm.addListener((_) {
      onChange();
    });
    return () {
      _dm.removeListener(listenerId);
    };
  }
}
