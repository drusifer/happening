import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/display/display_id.dart';
import 'package:happening/core/display/display_info.dart';
import 'package:happening/core/display/display_service.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/strip_state.dart';
import 'package:happening/core/window/windows_app_bar.dart';
import 'package:happening/core/window/windows_window_service.dart';
import 'package:mockito/mockito.dart';

// Reuse the generated mocks from the WindowService suite.
import 'window_service_test.mocks.dart';

/// Models the one Win32 AppBar behaviour that keeps biting us: a top AppBar
/// window resized TALLER than its reserved band gets relocated by Windows into
/// the work area (below its own strut). Shared by the WindowManager mock and the
/// AppBar fake so a unit test can actually catch the position regression — the
/// mock otherwise just records calls and never models the OS move (GEO trace
/// 2026-06-19 19:55: a +1px grow stranded the strip at y=73). dpr is 1.0 here.
class FakeWin32Desktop {
  /// Logical position/size (as window_manager uses). Physical extent is derived
  /// via [dpr], modeling window_manager's worst-case (ceil) rounding so the test
  /// catches DPI-rounding band mismatches.
  Offset position = Offset.zero;
  Size size = Size.zero;
  double dpr = 1.0;
  int? reservedBandHeightPx; // physical px; null when no AppBar reservation

  void setSize(Size s) {
    size = s;
    _maybeRelocate();
  }

  void setPosition(Offset p) {
    position = p;
    _maybeRelocate();
  }

  void reserveBand(int heightPx) {
    reservedBandHeightPx = heightPx;
    _maybeRelocate();
  }

  void releaseBand() => reservedBandHeightPx = null;

  // If the window sits at/above the band top and its PHYSICAL height exceeds the
  // band (physical px), Windows pushes it down into the work area. Window
  // physical height uses ceil — the worst case window_manager rounding — so a
  // band that merely round()s can be caught as 1px short at fractional DPI.
  void _maybeRelocate() {
    final band = reservedBandHeightPx;
    if (band == null) return;
    final windowPhysH = (size.height * dpr).ceil();
    final posPhysY = (position.dy * dpr).round();
    if (posPhysY <= band && windowPhysH > band) {
      position = Offset(position.dx, band / dpr);
    }
  }
}

/// Records the orchestration the real Win32 seam would perform, so the Windows
/// init + reservation logic is unit-testable without a desktop. When wired to a
/// [FakeWin32Desktop] it also drives the reservation band so the desktop can
/// model the AppBar relocation rule.
class FakeWindowsAppBar implements WindowsAppBar {
  FakeWindowsAppBar([this.desktop]);

  final FakeWin32Desktop? desktop;
  final List<String> calls = [];
  int rcTopToReturn = 0;
  bool _registered = false;
  int? lastWidthPx;
  int? lastHeightPx;

  @override
  bool get isRegistered => _registered;

  @override
  void register() {
    calls.add('register');
    _registered = true;
  }

  @override
  int reserveTopBand({required int widthPx, required int heightPx}) {
    calls.add('reserve');
    lastWidthPx = widthPx;
    lastHeightPx = heightPx;
    desktop?.reserveBand(heightPx);
    return rcTopToReturn;
  }

  @override
  int reassertTopBand({required int widthPx, required int heightPx}) {
    calls.add('reassert');
    desktop?.reserveBand(heightPx);
    return rcTopToReturn;
  }

  @override
  void dispose() {
    calls.add('dispose');
    _registered = false;
    desktop?.releaseBand();
  }

  @override
  void presentFrame() => calls.add('present');
}

DisplayInfo _display({double width = 1920}) => DisplayInfo(
      id: const DisplayId('0'),
      osName: 'M-0',
      size: Size(width, 1080),
      workAreaOrigin: Offset.zero,
      workAreaSize: Size(width, 1080),
      scaleFactor: 1.0,
      isPrimary: true,
    );

class _StubProbe implements DisplayProbe {
  _StubProbe(this._displays);
  final List<DisplayInfo> _displays;
  @override
  Future<List<DisplayInfo>> getAll() async => List.of(_displays);
}

class _StubEvents implements DisplayEvents {
  @override
  void Function() subscribe(void Function() onChange) => () {};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockWindowManager mockWM;
  late MockScreenRetriever mockSR;
  late DisplayService displayService;
  late FakeWindowsAppBar appBar;
  late FakeWin32Desktop desktop;

  WindowsWindowService makeService() => WindowsWindowService(
        windowManager: mockWM,
        screenRetriever: mockSR,
        displayService: displayService,
        appBar: appBar,
      );

  setUp(() async {
    mockWM = MockWindowManager();
    mockSR = MockScreenRetriever();
    desktop = FakeWin32Desktop();
    appBar = FakeWindowsAppBar(desktop);

    displayService = DisplayService(
      probe: _StubProbe([_display()]),
      events: _StubEvents(),
      sleep: (_) async {},
    );
    await displayService.initialize();

    when(mockWM.ensureInitialized()).thenAnswer((_) => Future.value());
    when(mockWM.getDevicePixelRatio()).thenReturn(1.0);
    when(mockWM.setResizable(any)).thenAnswer((_) => Future.value());
    when(mockWM.setMinimumSize(any)).thenAnswer((_) => Future.value());
    when(mockWM.setMaximumSize(any)).thenAnswer((_) => Future.value());
    // Drive the modelled desktop so getPosition/getSize reflect the AppBar
    // relocation rule (not just the values we asked for).
    when(mockWM.setSize(any, animate: anyNamed('animate'))).thenAnswer(
        (inv) async => desktop.setSize(inv.positionalArguments[0] as Size));
    when(mockWM.getSize()).thenAnswer((_) async => desktop.size);
    when(mockWM.getPosition()).thenAnswer((_) async => desktop.position);
    when(mockWM.setPosition(any, animate: anyNamed('animate'))).thenAnswer(
        (inv) async =>
            desktop.setPosition(inv.positionalArguments[0] as Offset));
    when(mockWM.setAlwaysOnTop(any)).thenAnswer((_) => Future.value());
    when(mockWM.setAsFrameless()).thenAnswer((_) => Future.value());
    when(mockWM.setBackgroundColor(any)).thenAnswer((_) => Future.value());
    when(mockWM.show(inactive: anyNamed('inactive')))
        .thenAnswer((_) => Future.value());
    when(mockWM.focus()).thenAnswer((_) => Future.value());
    when(mockWM.waitUntilReadyToShow(any, any)).thenAnswer((invocation) async {
      final callback = invocation.positionalArguments[1] as dynamic;
      if (callback != null) await callback();
    });
  });

  group('WindowsWindowService init (post-show apply)', () {
    test('registers + reserves during init; present is deferred to first frame',
        () async {
      final service = makeService();
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);

      // present() is scheduled via addPostFrameCallback (Flutter has no frame
      // yet at init time), so it must NOT have fired synchronously here.
      expect(appBar.calls, ['register', 'reserve']);
    });

    // The strip is a top AppBar: reservation (ABM_SETPOS) must happen BEFORE the
    // window is positioned, because ABM_SETPOS can move the AppBar window. If we
    // positioned first and reserved after, the strip lands below its own strut
    // (the init bug Drew caught 2026-06-19). Lock register → reserve → resize in.
    test('init order: register → reserve → resize; present deferred', () async {
      // Fold wm.setSize into the same timeline as the AppBar ops so their
      // relative order is observable.
      when(mockWM.setSize(any, animate: anyNamed('animate')))
          .thenAnswer((_) async => appBar.calls.add('setSize'));

      final service = makeService();
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);

      expect(appBar.calls.indexOf('register'),
          lessThan(appBar.calls.indexOf('reserve')));
      expect(appBar.calls.indexOf('reserve'),
          lessThan(appBar.calls.indexOf('setSize')),
          reason: 'reserve BEFORE positioning so ABM_SETPOS cannot strand the '
              'strip below its strut');
      expect(appBar.calls, isNot(contains('present')),
          reason:
              'present is deferred to the first frame, not run during init');
    });

    test(
        'positions the window at the reserved band origin, not work-area origin',
        () async {
      final service = makeService();
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);
      // Simulate Windows assigning a non-zero reserved band top.
      appBar.rcTopToReturn = 100;
      clearInteractions(mockWM);

      await service.applyState(StripState.collapsedShown);

      // The window must be placed at the reserved top (0,100), applied AFTER the
      // reservation — this is what keeps the strip inside its own strut.
      verify(mockWM.setPosition(const Offset(0, 100))).called(1);
    });

    // NOTE: verifies the CALL sequence only. It canNOT verify the window stays
    // in its strut — whether a resize gets relocated by Windows is OS behaviour
    // the mock can't model (that's caught by the GEO trace / a real run, see
    // 2026-06-19 19:55 where a +1px grow stranded the strip at y=73). The nudge
    // therefore shrinks (h-1) to stay within the reserved band, and pins origin.
    test('presentInitialFrame shrink-settles 1px and pins to the reserved top',
        () async {
      final service = makeService();
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);
      appBar.calls.clear();
      clearInteractions(mockWM);

      await service.presentInitialFrame();

      final h = service.getCollapsedHeight();
      // Shrink down then settle back — never grows past the band.
      verify(mockWM.setSize(Size(1920, h - 1))).called(1);
      verify(mockWM.setSize(Size(1920, h))).called(1);
      verify(mockWM.setPosition(const Offset(0, 0)))
          .called(greaterThanOrEqualTo(1));
      expect(appBar.calls, contains('present'));
    });

    test('reserves the band at screenWidth × collapsedHeight in physical px',
        () async {
      final service = makeService();
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);

      // dpr=1.0, width=1920, collapsedHeight = font*2.5 + 17.5. Band uses ceil
      // (>= window physical height) so DPI rounding can't strand the strip.
      expect(appBar.lastWidthPx, 1920);
      expect(appBar.lastHeightPx, service.getCollapsedHeight().ceil());
    });

    // REGRESSION (DPI scale change): build-chage-dpr.out 2026-06-22. A 3840px
    // PHYSICAL monitor switched to 150%. screen_retriever keeps reporting 3840
    // (physical, scale-invariant), but window_manager.setSize wants LOGICAL
    // pixels — so the strip must be 3840/1.5 = 2560 logical (= 3840 physical,
    // full screen) and the band must span the full 3840 physical width. The bug
    // sized 3840 logical (5760 physical, 1.5× too wide) and reserved 5760px.
    test('DPI scale: sizes to logical width, reserves full physical band',
        () async {
      when(mockWM.getDevicePixelRatio()).thenReturn(1.5);
      desktop.dpr = 1.5;
      final ds = DisplayService(
        probe: _StubProbe([_display(width: 3840)]),
        events: _StubEvents(),
        sleep: (_) async {},
      );
      await ds.initialize();
      final service = WindowsWindowService(
        windowManager: mockWM,
        screenRetriever: mockSR,
        displayService: ds,
        appBar: appBar,
      );
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);

      expect(desktop.size.width, 3840 / 1.5,
          reason: 'window logical width = physical / dpr (fills the screen)');
      expect(appBar.lastWidthPx, 3840,
          reason: 'reserved band spans the full physical screen width');
    });

    test('the AppBar ends up registered after init', () async {
      final service = makeService();
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);

      expect(appBar.isRegistered, isTrue);
    });

    // REGRESSION (Drew, 2026-06-19): the present nudge grew the window past its
    // reserved band, and Windows relocated it below the strut. The modelled
    // desktop reproduces that relocation, so this fails if the nudge ever grows
    // past the band again (or forgets to pin the origin).
    test('init + present leaves the strip IN the strut (modelled position)',
        () async {
      final service = makeService();
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);
      // The present is deferred to the first frame in the app; invoke directly.
      await service.presentInitialFrame();

      expect(desktop.position, Offset.zero,
          reason: 'strip must stay at the reserved band top; a grow-past-band '
              'nudge would strand it at the band height (below its own strut)');
      expect(
          desktop.size.height.round(), lessThanOrEqualTo(appBar.lastHeightPx!),
          reason: 'window must never end taller than its reserved band');
    });

    // REGRESSION (DPI rounding): at fractional DPI the window's physical height
    // can round UP while a round()-based band rounds DOWN, leaving the window
    // 1px taller than its band → Windows relocates it. The band uses ceil() to
    // prevent this; the modelled desktop (ceil window physical) catches it.
    test('init + present stays in the strut at fractional DPI', () async {
      // dpr=1.1, font=16 → collapsedHeight=57.5; window physical=ceil(63.25)=64.
      // round()-band would be 63 (1px short); ceil()-band is 64 (safe).
      when(mockWM.getDevicePixelRatio()).thenReturn(1.1);
      desktop.dpr = 1.1;

      final service = makeService();
      await service.initialize(initialFontSizePx: 16);
      await service.presentInitialFrame();

      expect(desktop.position, Offset.zero,
          reason: 'fractional DPI must not strand the strip below its band');
      expect(appBar.lastHeightPx, greaterThanOrEqualTo((57.5 * 1.1).ceil()),
          reason: 'reserved band must be >= window physical height');
    });
  });

  group('WindowsWindowService applyReservation (state machine)', () {
    test('hidden releases the reservation', () async {
      final service = makeService();
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);
      appBar.calls.clear();

      await service.applyState(StripState.hidden);

      expect(appBar.calls, contains('dispose'));
      expect(appBar.calls, isNot(contains('reserve')));
      expect(appBar.isRegistered, isFalse);
    });

    test('expandedShown keeps the reservation (reserves, does not dispose)',
        () async {
      final service = makeService();
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);
      appBar.calls.clear();

      await service.applyState(StripState.expandedShown);

      expect(appBar.calls, contains('reserve'));
      expect(appBar.calls, isNot(contains('dispose')));
    });

    test('overlay mode never reserves; releases instead', () async {
      final service = makeService();
      await service.initialize(
        initialFontSizePx: kDefaultFontSizePx,
        initialWindowMode: WindowMode.overlay,
      );
      appBar.calls.clear();

      await service.applyState(StripState.collapsedShown);

      expect(appBar.calls, isNot(contains('reserve')));
      expect(appBar.calls, contains('dispose'));
    });

    test('registers only once across repeated shown applies', () async {
      final service = makeService();
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);
      appBar.calls.clear();

      await service.applyState(StripState.collapsedShown);
      await service.applyState(StripState.expandedShown);

      expect(appBar.calls.where((c) => c == 'register'), isEmpty);
      expect(appBar.calls.where((c) => c == 'reserve').length, 2);
    });
  });

  group('WindowsWindowService display change (re-apply path)', () {
    // REGRESSION (DPI strut drift): build-chage-dpr-fix1.out 2026-06-22 line
    // 234. A DPI change re-applied geometry via applyState only — no present —
    // so a late Win32 re-evaluation relocated the AppBar window to its band
    // bottom (pos (0,0)→(0,60), below its own strut). The re-apply must mirror
    // init/show: reserve AND present (the metrics-settle + origin re-pin).
    test('DPI change re-presents (converges onto the init/show path)',
        () async {
      final service = makeService();
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);
      appBar.calls.clear();

      // Same monitor, scale 1.0 → 2.0.
      when(mockWM.getDevicePixelRatio()).thenReturn(2.0);
      desktop.dpr = 2.0;
      service.didChangeMetrics();
      for (var i = 0; i < 6; i++) {
        await Future.delayed(Duration.zero);
      }

      expect(appBar.calls, contains('reserve'),
          reason: 'the display change must re-reserve the band');
      expect(appBar.calls, contains('present'),
          reason: 'and present, the way init/show do, to re-pin the origin');
      expect(desktop.position, Offset.zero,
          reason: 'strip must stay at the strut top, not drift to the band '
              'bottom');
    });
  });

  group('WindowsWindowService reassert (refresh path)', () {
    test(
        'reassertAppBar re-broadcasts via dispose → register → reserve, then '
        'positions at the reserved origin', () async {
      final service = makeService();
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);
      appBar.rcTopToReturn = 100; // simulate a non-zero band top
      appBar.calls.clear();
      clearInteractions(mockWM);

      await service.reassertAppBar();

      // Same unified flow as init: drop the bar (re-broadcast), re-register,
      // reserve, then position AFTER reserving.
      expect(appBar.calls, ['dispose', 'register', 'reserve']);
      verify(mockWM.setPosition(const Offset(0, 100))).called(1);
    });
  });

  // CONVERGENCE (Drew, 2026-06-20, build-still-below-strut.out): init keeps the
  // strip in its strut; SHOW stranded it below. Root divergence — the old show
  // path (resizeToFullStrip → onShowStrip) sized the window BEFORE reserving and
  // never presented, while init reserves FIRST, sizes at the reserved origin,
  // then presents. Fix = make show take init's path (showStrip = applyState +
  // presentInitialFrame). These tests lock that convergence in.
  //
  // NOTE (L-006): the modelled desktop catches a window grown PAST its band
  // (rule a). Whether the OS async-relocates a same-size re-registration is not
  // something the unit harness can decide — that is the manual Windows gate. So
  // these assert the converged CALL SEQUENCE + that the window stays within its
  // band, not the async OS move.
  group('WindowsWindowService show converged onto init path', () {
    test('showStrip reserves BEFORE sizing, then presents (same order as init)',
        () async {
      // Fold wm.setSize into the AppBar timeline so the relative order shows.
      when(mockWM.setSize(any, animate: anyNamed('animate')))
          .thenAnswer((_) async => appBar.calls.add('setSize'));

      final service = makeService();
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);
      await service.hideStrip(); // hide releases the strut (ABM_REMOVE)
      appBar.calls.clear();

      await service.showStrip();

      // The init invariant, now on show too: reserve before positioning so
      // ABM_SETPOS cannot strand the strip below its strut, then present.
      expect(appBar.calls.indexOf('register'),
          lessThan(appBar.calls.indexOf('reserve')));
      expect(appBar.calls.indexOf('reserve'),
          lessThan(appBar.calls.indexOf('setSize')),
          reason: 'show must reserve BEFORE sizing (init order); the old path '
              'sized first (resizeToFullStrip) then reserved (onShowStrip)');
      expect(appBar.calls, contains('present'),
          reason: 'show must force the present like init — the old show path '
              'never presented');
    });

    test('showStrip re-registers, reserves, and stays within the band',
        () async {
      final service = makeService();
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);
      await service.hideStrip();
      expect(appBar.isRegistered, isFalse);
      appBar.calls.clear();

      await service.showStrip();

      expect(appBar.isRegistered, isTrue);
      expect(appBar.calls, containsAllInOrder(['register', 'reserve']));
      // Window never ends taller than its reserved band (rule a) → not relocated.
      expect(
          desktop.size.height.round(), lessThanOrEqualTo(appBar.lastHeightPx!));
      expect(desktop.position, Offset.zero,
          reason: 'collapsed show stays at the reserved band origin');
    });

    // Hide is the mirror: applyState(hidden) releases the strut and sizes the
    // mini pill in one applier call (replaces prepareToHide + resizeToMiniStrip).
    test('hideStrip releases the strut and sizes the mini pill (one applier)',
        () async {
      final service = makeService();
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);
      appBar.calls.clear();

      await service.hideStrip();

      expect(appBar.calls, contains('dispose'));
      expect(appBar.calls, isNot(contains('reserve')));
      expect(appBar.isRegistered, isFalse);
      // Mini footprint: narrower than the full screen, collapsed height.
      expect(desktop.size.width, service.getMiniWidth(kDefaultFontSizePx));
      expect(desktop.size.height, service.getCollapsedHeight());
    });

    test('hide → show round-trips through the applier and re-reserves',
        () async {
      final service = makeService();
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);

      await service.hideStrip();
      expect(appBar.isRegistered, isFalse);

      await service.showStrip();
      expect(appBar.isRegistered, isTrue);
      expect(desktop.size.width, 1920, reason: 'back to full screen width');
      expect(desktop.position, Offset.zero);
    });
  });
}
