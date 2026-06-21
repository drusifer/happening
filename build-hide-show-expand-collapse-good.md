=== make run-windows @ 2026-06-20 20:14:47 ===
make[1]: Entering directory 'C:/Users/drusi/VSCode_Projects/happening'
==> Flutter SDK not found �?" cloning stable into .flutter/flutter ...
mkdir : An item with the specified name C:\Users\drusi\VSCode_Projects\happening\.flutter already exists.
At line:1 char:120
+ ...  cloning stable into .flutter/flutter ...'; mkdir -p .flutter; git cl ...
+                                                 ~~~~~~~~~~~~~~~~~
    + CategoryInfo          : ResourceExists: (C:\Users\drusi\...pening\.flutter:String) [New-Item], IOException
    + FullyQualifiedErrorId : DirectoryExist,Microsoft.PowerShell.Commands.NewItemCommand
 
fatal: destination path '.flutter/flutter' already exists and is not an empty directory.
�o" flutter SDK cloned
cd app && flutter pub get
Resolving dependencies...
Downloading packages...
  _fe_analyzer_shared 100.0.0 (104.0.0 available)
  analysis_server_plugin 0.3.15 (0.3.19 available)
  analyzer 13.0.0 (14.0.0 available)
  analyzer_plugin 0.14.9 (0.14.13 available)
  cli_util 0.4.2 (0.5.1 available)
  dart_code_linter 4.1.3 (4.1.5 available)
  flutter_secure_storage_darwin 0.3.2 (0.4.0 available)
  matcher 0.12.19 (0.12.20 available)
  meta 1.18.0 (1.18.3 available)
  package_config 2.2.0 (3.0.0 available)
  test_api 0.7.11 (0.7.12 available)
  vector_math 2.2.0 (2.4.0 available)
Got dependencies!
12 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
cd app && flutter run -d windows
Resolving dependencies...
Downloading packages...
  _fe_analyzer_shared 100.0.0 (104.0.0 available)
  analysis_server_plugin 0.3.15 (0.3.19 available)
  analyzer 13.0.0 (14.0.0 available)
  analyzer_plugin 0.14.9 (0.14.13 available)
  cli_util 0.4.2 (0.5.1 available)
  dart_code_linter 4.1.3 (4.1.5 available)
  flutter_secure_storage_darwin 0.3.2 (0.4.0 available)
  matcher 0.12.19 (0.12.20 available)
  meta 1.18.0 (1.18.3 available)
  package_config 2.2.0 (3.0.0 available)
  test_api 0.7.11 (0.7.12 available)
  vector_math 2.2.0 (2.4.0 available)
Got dependencies!
12 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Launching lib\main.dart on Windows in debug mode...
Building Windows application...                                    10.6s
√ Built build\windows\x64\runner\Debug\happening.exe
[2026-06-20T20:15:05.135770] [DBG] [main] Main entry point: WidgetsFlutterBinding initialized.
[2026-06-20T20:15:05.155771] [DBG] [main] Settings loaded.
[2026-06-20T20:15:05.172771] [WRN] [main] DisplayService: weak fingerprint match — persisted=\\.\DISPLAY1 matched DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001) (\\.\DISPLAY1). User can re-pick in Settings.
[2026-06-20T20:15:05.177771] [DBG] [main] DisplayService initialized: active=DisplayInfo(id=DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001), osName=\\.\DISPLAY1, size=Size(3840.0, 2160.0), workArea=(Offset(0.0, 0.0), Size(3840.0, 2112.0)), scale=1.0, primary=true)
[2026-06-20T20:15:05.178771] [INF] [main] WindowService.initialize() start
[2026-06-20T20:15:05.188771] [DBG] [WindowService] WindowService.initialize: dpr=1.0 activeDisplay=DisplayInfo(id=DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001), osName=\\.\DISPLAY1, size=Size(3840.0, 2160.0), workArea=(Offset(0.0, 0.0), Size(3840.0, 2112.0)), scale=1.0, primary=true) size=Size(3840.0, 57.5) collapsedHeight=57.5 expandedHeight=330.0
[2026-06-20T20:15:05.189772] [DBG] [WindowService] WindowService.initialize: calling waitUntilReadyToShow
[2026-06-20T20:15:05.189772] [DBG] [WindowService] WindowService.initialize: awaiting readyToShow
[2026-06-20T20:15:05.425917] [DBG] [WindowService] WindowService.initialize: readyToShow callback — calling strategy.initialize
[2026-06-20T20:15:05.426918] [DBG] [WindowService] WindowService.initialize: readyToShow complete, calling afterReadyToShow
[2026-06-20T20:15:05.426918] [DBG] [WindowService] WindowService.initialize: afterReadyToShow complete
[2026-06-20T20:15:05.426918] [DBG] [WindowService] WindowService.initialize: registering WidgetsBindingObserver
[2026-06-20T20:15:05.426918] [INF] [main] WindowService.initialize() done — calling runApp()
[2026-06-20T20:15:05.432424] [INF] [main] runApp() returned
[2026-06-20T20:15:05.469430] [DBG] [_HappeningAppState] HappeningApp._initServices starting...
Syncing files to device Windows...                                 102ms

Flutter run key commands.
r Hot reload. 
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

A Dart VM Service on Windows is available at: http://127.0.0.1:58248/ZDZDLG-T3r8=/
The Flutter DevTools debugger and profiler on Windows is available at: http://127.0.0.1:58248/ZDZDLG-T3r8=/devtools/?uri=ws://127.0.0.1:58248/ZDZDLG-T3r8=/ws
[2026-06-20T20:15:05.789584] [DBG] [WindowService] WindowService.initialize: readyToShow callback — calling strategy.moveToDisplay DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)
[2026-06-20T20:15:05.804585] [DBG] [WindowService] WindowService.initialize: readyToShow callback — calling beforeShow
[2026-06-20T20:15:05.804585] [DBG] [WindowService] WindowService.initialize: readyToShow callback — calling setAsFrameless
[2026-06-20T20:15:05.807586] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:05.807586] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:05.826591] [DBG] [WindowService] WindowService.initialize: readyToShow callback — calling performShow
[2026-06-20T20:15:05.827590] [DBG] [WindowService] WindowService.initialize: readyToShow callback — calling afterWindowShown
[2026-06-20T20:15:05.828595] [DBG] [WindowsWindowService] afterWindowShown: applyState(collapsedShown); present deferred to first frame
[2026-06-20T20:15:05.837098] [DBG] [Win32AppBar] loading SHAppBarMessage from shell32.dll
[2026-06-20T20:15:05.839099] [DBG] [Win32AppBar] register: ABM_NEW hWnd=0x58276e
[2026-06-20T20:15:05.846099] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:05.846099] [DBG] [WindowsWindowService] applyReservation: StripState.collapsedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:05.846099] [DBG] [WindowService] applyState: StripState.collapsedShown → size=Size(3840.0, 57.5) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:05.871101] [DBG] [_HappeningAppState] Secure storage verified.
[2026-06-20T20:15:05.873101] [DBG] [_HappeningAppState] AuthService initialized. Attempting restore...
[2026-06-20T20:15:05.902101] [DBG] [_HappeningAppState] Auth restored successfully.
[2026-06-20T20:15:05.903101] [DBG] [_HappeningAppState] HappeningApp._startCalendar called.
[2026-06-20T20:15:05.904104] [DBG] [CalendarController] CalendarController.start() called.
[2026-06-20T20:15:05.905101] [DBG] [CalendarController] CalendarController._fetch() started (forceRefresh: false)
[2026-06-20T20:15:05.905101] [DBG] [CalendarController] Fetching 9 configured calendars
[2026-06-20T20:15:05.931105] [DBG] [_HappeningAppState] CalendarController started.
[2026-06-20T20:15:05.932612] [DBG] [_HappeningAppState] AuthState changed to: authenticated
[2026-06-20T20:15:05.974619] [DBG] [_HappeningAppState] app StreamBuilder: state=ConnectionState.waiting hasData=false dataLen=null lastEvents=null
[2026-06-20T20:15:05.977619] [DBG] [AstroDataService] _onSettingsChanged: theme=astronomical hasLocation=true lat=40.71427 lng=-74.00597
[2026-06-20T20:15:05.977619] [DBG] [AstroDataService] _recalculate: lat=40.71427 lng=-74.00597 dateKey=2026-6-20
[2026-06-20T20:15:05.980623] [DBG] [AstroDataService] _recalculate: civilTwilightBegin=2026-06-20 08:51:33.647Z sunrise=2026-06-20 09:30:10.662Z solarNoon=2026-06-20 12:57:51.312 sunset=2026-06-21 00:25:31.961Z civilTwilightEnd=2026-06-21 01:04:09.302Z
[2026-06-20T20:15:05.982622] [DBG] [AstroDataService] _recalculate: moonIllum={fraction: 0.3993760417768437, phase: 0.21775015756747523, angle: -1.1681761984612082}
[2026-06-20T20:15:05.982622] [DBG] [AstroDataService] _recalculate: AstroData built — notifying listeners
[2026-06-20T20:15:05.983622] [DBG] [_TimelineStripState] TimelineStrip: astroData changed → current=AstroData(sunrise=2026-06-20 09:30:10.662Z)
[2026-06-20T20:15:05.983622] [DBG] [_TimelineStripState] Timestrip: _updatgeHeights called:  strip height is to 57.5
[2026-06-20T20:15:05.984619] [DBG] [_TimelineStripState] TimelineStrip: Initializing
[2026-06-20T20:15:05.992619] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=true layout=true events=0 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:06.055135] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=0 hovered=false loading=true signIn=false
[2026-06-20T20:15:06.118141] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:06.118141] [DBG] [WindowService] WindowService.initialize: readyToShow callback — calling interactionStrategy.initialize
[2026-06-20T20:15:06.119142] [DBG] [WindowService] WindowService.initialize: readyToShow callback — done
[2026-06-20T20:15:06.122141] [DBG] [WindowsWindowService] presentInitialFrame: 1px shrink-settle 56.5→57.5, pin=Offset(0.0, 0.0)
[2026-06-20T20:15:06.124142] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:06.124142] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:06.199650] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=true layout=true events=0 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=56.0
[2026-06-20T20:15:06.219656] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:06.219656] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:06.227656] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=true layout=true events=0 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:06.272687] [DBG] [Win32AppBar] presentFrame: RedrawWindow(RDW_INVALIDATE|RDW_UPDATENOW) hwnd=0x58276e
[2026-06-20T20:15:06.274690] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:06.274690] [DBG] [WindowService] GEO[presentInitialFrame:after]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:06.428205] [DBG] [WindowService] GEO[presentInitialFrame +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:06.612228] [DBG] [GoogleCalendarService] [CalendarFetch] fetched 0 raw items, 0 timed items
[2026-06-20T20:15:06.613228] [DBG] [CalendarController] Fetched configured calendar: 0 events
[2026-06-20T20:15:06.620232] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:06.777256] [DBG] [WindowService] GEO[presentInitialFrame +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:06.926773] [DBG] [GoogleCalendarService] [CalendarFetch] fetched 0 raw items, 0 timed items
[2026-06-20T20:15:06.926773] [DBG] [CalendarController] Fetched configured calendar: 0 events
[2026-06-20T20:15:07.320342] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:07.335853] [DBG] [GoogleCalendarService] [CalendarFetch] fetched 0 raw items, 0 timed items
[2026-06-20T20:15:07.335853] [DBG] [CalendarController] Fetched configured calendar: 0 events
[2026-06-20T20:15:07.477365] [DBG] [WindowService] GEO[presentInitialFrame +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:07.810908] [DBG] [GoogleCalendarService] [CalendarFetch] fetched 3 raw items, 2 timed items
[2026-06-20T20:15:07.811912] [DBG] [CalendarController] Fetched configured calendar: 2 events
[2026-06-20T20:15:08.217963] [DBG] [GoogleCalendarService] [CalendarFetch] fetched 0 raw items, 0 timed items
[2026-06-20T20:15:08.217963] [DBG] [CalendarController] Fetched configured calendar: 0 events
[2026-06-20T20:15:08.558014] [DBG] [GoogleCalendarService] [CalendarFetch] fetched 0 raw items, 0 timed items
[2026-06-20T20:15:08.558014] [DBG] [CalendarController] Fetched configured calendar: 0 events
[2026-06-20T20:15:08.976621] [DBG] [GoogleCalendarService] [CalendarFetch] fetched 0 raw items, 0 timed items
[2026-06-20T20:15:08.976621] [DBG] [CalendarController] Fetched configured calendar: 0 events
[2026-06-20T20:15:09.495314] [DBG] [GoogleCalendarService] [CalendarFetch] fetched 8 raw items, 8 timed items
[2026-06-20T20:15:09.495314] [DBG] [CalendarController] Fetched configured calendar: 8 events
[2026-06-20T20:15:09.988882] [DBG] [GoogleCalendarService] [CalendarFetch] fetched 8 raw items, 8 timed items
[2026-06-20T20:15:09.989882] [DBG] [CalendarController] Fetched configured calendar: 8 events
[2026-06-20T20:15:09.990882] [DBG] [CalendarController] Fetch complete. Found 18 events (18 deduped).
[2026-06-20T20:15:09.990882] [DBG] [CalendarController] Emitted events to stream.
[2026-06-20T20:15:09.991882] [DBG] [_HappeningAppState] app StreamBuilder: state=ConnectionState.active hasData=true dataLen=18 lastEvents=18
[2026-06-20T20:15:09.992882] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:09.997882] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=18 hovered=false loading=false signIn=false
[2026-06-20T20:15:13.062197] [DBG] [_TimelineStripState] [TS] expansion → expanded mouseX=0.0 mouseY=52.0 isExit=false
[2026-06-20T20:15:13.063197] [DBG] [EC] sendAndAwait intent=expanded
[2026-06-20T20:15:13.067197] [DBG] [EC] execute START intent=expanded target=330.0
[2026-06-20T20:15:13.067197] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:13.068198] [DBG] [WindowsWindowService] applyReservation: StripState.expandedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:13.068198] [DBG] [WindowService] applyState: StripState.expandedShown → size=Size(3840.0, 330.0) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:13.072198] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=true
[2026-06-20T20:15:13.072198] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:13.077197] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:13.080197] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=18 hovered=true loading=false signIn=false
[2026-06-20T20:15:13.097198] [DBG] [WindowService] GEO[applyState:StripState.expandedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:13.097198] [DBG] [EC] execute DONE intent=expanded target=330.0
[2026-06-20T20:15:13.103198] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=true settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:13.248051] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:13.598105] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:13.794641] [INF] [_TimelineStripState] TimelineStrip: hiding strip (preHideSentToBack=false, settingsOpen=false, hoveredEvent=CalendarEvent(id: 79vrq54d6isgvg5u6738c8pn16_20260620T223000Z, title: Exactly Overlaps, start: 2026-06-20 18:30:00.000, isTask: false))
[2026-06-20T20:15:13.796643] [DBG] [_TimelineStripState] TimelineStrip: ensuring strip is collapsed before hiding
[2026-06-20T20:15:13.796643] [DBG] [EC] sendAndAwait intent=collapsed
[2026-06-20T20:15:13.797644] [DBG] [EC] execute START intent=collapsed target=57.5
[2026-06-20T20:15:13.798644] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:13.798644] [DBG] [WindowsWindowService] applyReservation: StripState.collapsedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:13.798644] [DBG] [WindowService] applyState: StripState.collapsedShown → size=Size(3840.0, 57.5) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:13.799643] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:13.803641] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=18 hovered=false loading=false signIn=false
[2026-06-20T20:15:13.817643] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:13.817643] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:13.824649] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:13.834153] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:13.834153] [DBG] [EC] execute DONE intent=collapsed target=57.5
[2026-06-20T20:15:13.834153] [DBG] [_TimelineStripState] TimelineStrip: reversing hide animation
[2026-06-20T20:15:13.986673] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:14.147700] [INF] [_TimelineStripState] TimelineStrip: hiding window via windowService.hideStrip()
[2026-06-20T20:15:14.148700] [DBG] [WindowsWindowService] hideStrip: applyState(hidden) (converged onto the applier)
[2026-06-20T20:15:14.154700] [DBG] [Win32AppBar] dispose: ABM_REMOVE done
[2026-06-20T20:15:14.154700] [DBG] [WindowService] applyState: StripState.hidden → size=Size(214.0, 57.5) origin=Offset(0.0, 0.0) (reserved=null)
[2026-06-20T20:15:14.199702] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:14.199702] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:14.221709] [DBG] [WindowService] GEO[applyState:StripState.hidden]: pos=Offset(0.0, 0.0) size=Size(214.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:14.222709] [INF] [_TimelineStripState] TimelineStrip: hide complete
[2026-06-20T20:15:14.298223] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(214.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:14.336737] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(214.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:14.373738] [DBG] [WindowService] GEO[applyState:StripState.hidden +150ms]: pos=Offset(0.0, 0.0) size=Size(214.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:14.724281] [DBG] [WindowService] GEO[applyState:StripState.hidden +500ms]: pos=Offset(0.0, 0.0) size=Size(214.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:14.753790] [INF] [_TimelineStripState] TimelineStrip: restoring strip
[2026-06-20T20:15:14.755790] [DBG] [_TimelineStripState] TimelineStrip: restoring window via windowService.showStrip()
[2026-06-20T20:15:14.755790] [DBG] [WindowsWindowService] showStrip: applyState(collapsedShown) + presentInitialFrame (converged onto the init path)
[2026-06-20T20:15:14.756790] [DBG] [Win32AppBar] register: ABM_NEW hWnd=0x58276e
[2026-06-20T20:15:14.762790] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:14.762790] [DBG] [WindowsWindowService] applyReservation: StripState.collapsedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:14.763792] [DBG] [WindowService] applyState: StripState.collapsedShown → size=Size(3840.0, 57.5) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:14.811791] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:14.811791] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:14.842310] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:14.842310] [DBG] [WindowsWindowService] presentInitialFrame: 1px shrink-settle 56.5→57.5, pin=Offset(0.0, 0.0)
[2026-06-20T20:15:14.861308] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:14.861308] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:14.887309] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:14.887309] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:14.897310] [DBG] [Win32AppBar] presentFrame: RedrawWindow(RDW_INVALIDATE|RDW_UPDATENOW) hwnd=0x58276e
[2026-06-20T20:15:14.899309] [DBG] [WindowService] GEO[presentInitialFrame:after]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:14.899309] [DBG] [_TimelineStripState] TimelineStrip: playing show animation
[2026-06-20T20:15:14.994831] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:15.036340] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:15.050342] [DBG] [WindowService] GEO[presentInitialFrame +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:15.207858] [INF] [_TimelineStripState] TimelineStrip: show complete
[2026-06-20T20:15:15.208858] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:15.214860] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=18 hovered=false loading=false signIn=false
[2026-06-20T20:15:15.223869] [DBG] [_TimelineStripState] [TS] expansion → expanded mouseX=20.0 mouseY=42.0 isExit=false
[2026-06-20T20:15:15.223869] [DBG] [EC] sendAndAwait intent=expanded
[2026-06-20T20:15:15.224871] [DBG] [EC] execute START intent=expanded target=330.0
[2026-06-20T20:15:15.225869] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:15.225869] [DBG] [WindowsWindowService] applyReservation: StripState.expandedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:15.225869] [DBG] [WindowService] applyState: StripState.expandedShown → size=Size(3840.0, 330.0) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:15.229868] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:15.242378] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=true
[2026-06-20T20:15:15.242378] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:15.251374] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:15.260375] [DBG] [WindowService] GEO[applyState:StripState.expandedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:15.260375] [DBG] [EC] execute DONE intent=expanded target=330.0
[2026-06-20T20:15:15.263375] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=true settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:15.343888] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:15.400890] [DBG] [WindowService] GEO[presentInitialFrame +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:15.411890] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:15.423898] [DBG] [WindowService] GEO[applyState:StripState.hidden +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:15.679944] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=true settings=false hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:15.712945] [DBG] [_TimelineStripState] [TS] expansion → collapsed mouseX=48.0 mouseY=210.0 isExit=false
[2026-06-20T20:15:15.712945] [DBG] [EC] sendAndAwait intent=collapsed
[2026-06-20T20:15:15.712945] [DBG] [EC] execute START intent=collapsed target=57.5
[2026-06-20T20:15:15.713948] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:15.713948] [DBG] [WindowsWindowService] applyReservation: StripState.collapsedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:15.713948] [DBG] [WindowService] applyState: StripState.collapsedShown → size=Size(3840.0, 57.5) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:15.716944] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:15.716944] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:15.722949] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:15.726952] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=18 hovered=false loading=false signIn=false
[2026-06-20T20:15:15.742461] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:15.742461] [DBG] [EC] execute DONE intent=collapsed target=57.5
[2026-06-20T20:15:15.748462] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:15.763459] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:15.894977] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:15.994489] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=18 hovered=false loading=false signIn=false
[2026-06-20T20:15:16.044626] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:16.100628] [DBG] [WindowService] GEO[presentInitialFrame +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:16.243653] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:16.291654] [DBG] [_TimelineStripState] [TS] expansion → expanded mouseX=815.0 mouseY=56.0 isExit=false
[2026-06-20T20:15:16.291654] [DBG] [EC] sendAndAwait intent=expanded
[2026-06-20T20:15:16.292654] [DBG] [EC] execute START intent=expanded target=330.0
[2026-06-20T20:15:16.292654] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:16.293656] [DBG] [WindowsWindowService] applyReservation: StripState.expandedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:16.293656] [DBG] [WindowService] applyState: StripState.expandedShown → size=Size(3840.0, 330.0) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:16.295654] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=true
[2026-06-20T20:15:16.295654] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:16.298654] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:16.301658] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=18 hovered=true loading=false signIn=false
[2026-06-20T20:15:16.313655] [DBG] [WindowService] GEO[applyState:StripState.expandedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:16.313655] [DBG] [EC] execute DONE intent=expanded target=330.0
[2026-06-20T20:15:16.317655] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=true settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:16.462681] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:16.465681] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:16.815226] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:16.874740] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=true settings=false hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:16.927747] [DBG] [_TimelineStripState] [TS] expansion → collapsed mouseX=819.0 mouseY=192.0 isExit=false
[2026-06-20T20:15:16.927747] [DBG] [EC] sendAndAwait intent=collapsed
[2026-06-20T20:15:16.927747] [DBG] [EC] execute START intent=collapsed target=57.5
[2026-06-20T20:15:16.928745] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:16.929745] [DBG] [WindowsWindowService] applyReservation: StripState.collapsedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:16.929745] [DBG] [WindowService] applyState: StripState.collapsedShown → size=Size(3840.0, 57.5) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:16.932748] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:16.932748] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:16.936255] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:16.940256] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=18 hovered=false loading=false signIn=false
[2026-06-20T20:15:16.948255] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:16.953257] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:16.953257] [DBG] [EC] execute DONE intent=collapsed target=57.5
[2026-06-20T20:15:16.957256] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:17.105769] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:17.454822] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:17.514824] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:18.155417] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:18.188418] [DBG] [_TimelineStripState] [TS] expansion → expanded mouseX=784.0 mouseY=56.0 isExit=false
[2026-06-20T20:15:18.189418] [DBG] [EC] sendAndAwait intent=expanded
[2026-06-20T20:15:18.189418] [DBG] [EC] execute START intent=expanded target=330.0
[2026-06-20T20:15:18.190422] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:18.190422] [DBG] [WindowsWindowService] applyReservation: StripState.expandedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:18.190422] [DBG] [WindowService] applyState: StripState.expandedShown → size=Size(3840.0, 330.0) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:18.193418] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=true
[2026-06-20T20:15:18.193418] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:18.195419] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:18.198418] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=18 hovered=true loading=false signIn=false
[2026-06-20T20:15:18.210422] [DBG] [WindowService] GEO[applyState:StripState.expandedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:18.210422] [DBG] [EC] execute DONE intent=expanded target=330.0
[2026-06-20T20:15:18.217421] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=true settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:18.362454] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:18.713996] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:18.737508] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=true settings=false hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:18.769509] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=18 hovered=true loading=false signIn=false
[2026-06-20T20:15:18.817510] [DBG] [_TimelineStripState] [TS] expansion → collapsed mouseX=486.0 mouseY=185.0 isExit=false
[2026-06-20T20:15:18.817510] [DBG] [EC] sendAndAwait intent=collapsed
[2026-06-20T20:15:18.818510] [DBG] [EC] execute START intent=collapsed target=57.5
[2026-06-20T20:15:18.818510] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:18.818510] [DBG] [WindowsWindowService] applyReservation: StripState.collapsedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:18.818510] [DBG] [WindowService] applyState: StripState.collapsedShown → size=Size(3840.0, 57.5) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:18.820518] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:18.832516] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:18.832516] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:18.836026] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:18.844028] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:18.845026] [DBG] [EC] execute DONE intent=collapsed target=57.5
[2026-06-20T20:15:18.849026] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:18.997541] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:19.268083] [DBG] [_TimelineStripState] [TS] expansion → expanded mouseX=3.0 mouseY=56.0 isExit=false
[2026-06-20T20:15:19.268083] [DBG] [EC] sendAndAwait intent=expanded
[2026-06-20T20:15:19.269083] [DBG] [EC] execute START intent=expanded target=330.0
[2026-06-20T20:15:19.270085] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:19.270085] [DBG] [WindowsWindowService] applyReservation: StripState.expandedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:19.270085] [DBG] [WindowService] applyState: StripState.expandedShown → size=Size(3840.0, 330.0) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:19.271088] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:19.273083] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=18 hovered=true loading=false signIn=false
[2026-06-20T20:15:19.283084] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=true
[2026-06-20T20:15:19.283084] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:19.292084] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:19.301087] [DBG] [WindowService] GEO[applyState:StripState.expandedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:19.301087] [DBG] [EC] execute DONE intent=expanded target=330.0
[2026-06-20T20:15:19.306085] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=true settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:19.346134] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:19.413135] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:19.452648] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:19.770828] [INF] [_TimelineStripState] TimelineStrip: hiding strip (preHideSentToBack=false, settingsOpen=false, hoveredEvent=CalendarEvent(id: 79vrq54d6isgvg5u6738c8pn16_20260620T223000Z, title: Exactly Overlaps, start: 2026-06-20 18:30:00.000, isTask: false))
[2026-06-20T20:15:19.772829] [DBG] [_TimelineStripState] TimelineStrip: ensuring strip is collapsed before hiding
[2026-06-20T20:15:19.772829] [DBG] [EC] sendAndAwait intent=collapsed
[2026-06-20T20:15:19.772829] [DBG] [EC] execute START intent=collapsed target=57.5
[2026-06-20T20:15:19.773829] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:19.773829] [DBG] [WindowsWindowService] applyReservation: StripState.collapsedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:19.773829] [DBG] [WindowService] applyState: StripState.collapsedShown → size=Size(3840.0, 57.5) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:19.774829] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:19.777828] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=18 hovered=false loading=false signIn=false
[2026-06-20T20:15:19.787830] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:19.787830] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:19.792829] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:19.800831] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:19.801829] [DBG] [EC] execute DONE intent=collapsed target=57.5
[2026-06-20T20:15:19.801829] [DBG] [_TimelineStripState] TimelineStrip: reversing hide animation
[2026-06-20T20:15:19.801829] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:19.953790] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:20.046303] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:20.114304] [INF] [_TimelineStripState] TimelineStrip: hiding window via windowService.hideStrip()
[2026-06-20T20:15:20.115305] [DBG] [WindowsWindowService] hideStrip: applyState(hidden) (converged onto the applier)
[2026-06-20T20:15:20.120305] [DBG] [Win32AppBar] dispose: ABM_REMOVE done
[2026-06-20T20:15:20.121308] [DBG] [WindowService] applyState: StripState.hidden → size=Size(214.0, 57.5) origin=Offset(0.0, 0.0) (reserved=null)
[2026-06-20T20:15:20.166818] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:20.166818] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:20.189820] [DBG] [WindowService] GEO[applyState:StripState.hidden]: pos=Offset(0.0, 0.0) size=Size(214.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:20.189820] [INF] [_TimelineStripState] TimelineStrip: hide complete
[2026-06-20T20:15:20.303337] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(214.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:20.341848] [DBG] [WindowService] GEO[applyState:StripState.hidden +150ms]: pos=Offset(0.0, 0.0) size=Size(214.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:20.476363] [INF] [_TimelineStripState] TimelineStrip: restoring strip
[2026-06-20T20:15:20.478364] [DBG] [_TimelineStripState] TimelineStrip: restoring window via windowService.showStrip()
[2026-06-20T20:15:20.478364] [DBG] [WindowsWindowService] showStrip: applyState(collapsedShown) + presentInitialFrame (converged onto the init path)
[2026-06-20T20:15:20.479365] [DBG] [Win32AppBar] register: ABM_NEW hWnd=0x58276e
[2026-06-20T20:15:20.485367] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:20.485367] [DBG] [WindowsWindowService] applyReservation: StripState.collapsedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:20.485367] [DBG] [WindowService] applyState: StripState.collapsedShown → size=Size(3840.0, 57.5) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:20.532371] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:20.532371] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:20.552882] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(214.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:20.561879] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:20.561879] [DBG] [WindowsWindowService] presentInitialFrame: 1px shrink-settle 56.5→57.5, pin=Offset(0.0, 0.0)
[2026-06-20T20:15:20.573881] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:20.574882] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:20.603883] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:20.603883] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:20.616881] [DBG] [Win32AppBar] presentFrame: RedrawWindow(RDW_INVALIDATE|RDW_UPDATENOW) hwnd=0x58276e
[2026-06-20T20:15:20.617880] [DBG] [WindowService] GEO[presentInitialFrame:after]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:20.617880] [DBG] [_TimelineStripState] TimelineStrip: playing show animation
[2026-06-20T20:15:20.691396] [DBG] [WindowService] GEO[applyState:StripState.hidden +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:20.715397] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:20.769908] [DBG] [WindowService] GEO[presentInitialFrame +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:20.929428] [INF] [_TimelineStripState] TimelineStrip: show complete
[2026-06-20T20:15:20.930427] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:20.936938] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=18 hovered=false loading=false signIn=false
[2026-06-20T20:15:20.943938] [DBG] [_TimelineStripState] [TS] expansion → expanded mouseX=10.0 mouseY=28.0 isExit=false
[2026-06-20T20:15:20.943938] [DBG] [EC] sendAndAwait intent=expanded
[2026-06-20T20:15:20.946940] [DBG] [EC] execute START intent=expanded target=330.0
[2026-06-20T20:15:20.947938] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:20.947938] [DBG] [WindowsWindowService] applyReservation: StripState.expandedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:20.947938] [DBG] [WindowService] applyState: StripState.expandedShown → size=Size(3840.0, 330.0) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:20.956938] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:20.967941] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=true
[2026-06-20T20:15:20.967941] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:20.971939] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:20.979939] [DBG] [WindowService] GEO[applyState:StripState.expandedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:20.980939] [DBG] [EC] execute DONE intent=expanded target=330.0
[2026-06-20T20:15:20.984939] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=true settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:21.002939] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:21.064452] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:21.119453] [DBG] [WindowService] GEO[presentInitialFrame +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:21.132457] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:21.391993] [DBG] [WindowService] GEO[applyState:StripState.hidden +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:21.482508] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:21.579019] [DBG] [_TimelineStripState] [TS] expansion → collapsed mouseX=63.0 mouseY=31.0 isExit=false
[2026-06-20T20:15:21.579019] [DBG] [EC] sendAndAwait intent=collapsed
[2026-06-20T20:15:21.580019] [DBG] [EC] execute START intent=collapsed target=57.5
[2026-06-20T20:15:21.581020] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:21.581020] [DBG] [WindowsWindowService] applyReservation: StripState.collapsedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:21.581020] [DBG] [WindowService] applyState: StripState.collapsedShown → size=Size(3840.0, 57.5) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:21.581020] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:21.585022] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=18 hovered=false loading=false signIn=false
[2026-06-20T20:15:21.595022] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:21.596020] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:21.604019] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:21.613021] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:21.613021] [DBG] [EC] execute DONE intent=collapsed target=57.5
[2026-06-20T20:15:21.618020] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:21.763049] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:21.764049] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:21.820050] [DBG] [WindowService] GEO[presentInitialFrame +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:21.893563] [DBG] [_TimelineStripState] [TS] expansion → expanded mouseX=710.0 mouseY=52.0 isExit=false
[2026-06-20T20:15:21.893563] [DBG] [EC] sendAndAwait intent=expanded
[2026-06-20T20:15:21.894563] [DBG] [EC] execute START intent=expanded target=330.0
[2026-06-20T20:15:21.895565] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:21.895565] [DBG] [WindowsWindowService] applyReservation: StripState.expandedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:21.895565] [DBG] [WindowService] applyState: StripState.expandedShown → size=Size(3840.0, 330.0) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:21.898564] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=true
[2026-06-20T20:15:21.898564] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:21.902564] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:21.904566] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=18 hovered=true loading=false signIn=false
[2026-06-20T20:15:21.916564] [DBG] [WindowService] GEO[applyState:StripState.expandedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:21.916564] [DBG] [EC] execute DONE intent=expanded target=330.0
[2026-06-20T20:15:21.923567] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=true settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:22.068607] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:22.115608] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:22.182120] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:22.298635] [DBG] [_TimelineStripState] [TS] expansion → collapsed mouseX=1018.0 mouseY=46.0 isExit=false
[2026-06-20T20:15:22.298635] [DBG] [EC] sendAndAwait intent=collapsed
[2026-06-20T20:15:22.299635] [DBG] [EC] execute START intent=collapsed target=57.5
[2026-06-20T20:15:22.299635] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:22.299635] [DBG] [WindowsWindowService] applyReservation: StripState.collapsedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:22.300636] [DBG] [WindowService] applyState: StripState.collapsedShown → size=Size(3840.0, 57.5) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:22.303638] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:22.303638] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:22.305635] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:22.308635] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=18 hovered=false loading=false signIn=false
[2026-06-20T20:15:22.319636] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:22.320635] [DBG] [EC] execute DONE intent=collapsed target=57.5
[2026-06-20T20:15:22.326639] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:22.336146] [DBG] [_TimelineStripState] [TS] expansion → expanded mouseX=1204.0 mouseY=42.0 isExit=false
[2026-06-20T20:15:22.336146] [DBG] [EC] sendAndAwait intent=expanded
[2026-06-20T20:15:22.337151] [DBG] [EC] execute START intent=expanded target=330.0
[2026-06-20T20:15:22.337151] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:22.337151] [DBG] [WindowsWindowService] applyReservation: StripState.expandedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:22.337151] [DBG] [WindowService] applyState: StripState.expandedShown → size=Size(3840.0, 330.0) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:22.340149] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=true
[2026-06-20T20:15:22.340149] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:22.342150] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:22.355151] [DBG] [WindowService] GEO[applyState:StripState.expandedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:22.356150] [DBG] [EC] execute DONE intent=expanded target=330.0
[2026-06-20T20:15:22.362150] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=true settings=false hovered=true hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T20:15:22.419151] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:22.472665] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:22.507666] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 330.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:22.733696] [DBG] [_TimelineStripState] [TS] expansion → collapsed mouseX=1512.0 mouseY=24.0 isExit=false
[2026-06-20T20:15:22.733696] [DBG] [EC] sendAndAwait intent=collapsed
[2026-06-20T20:15:22.734696] [DBG] [EC] execute START intent=collapsed target=57.5
[2026-06-20T20:15:22.734696] [DBG] [Win32AppBar] reserveTopBand: req=3840x58 → rect=[0,0,3840,58]
[2026-06-20T20:15:22.734696] [DBG] [WindowsWindowService] applyReservation: StripState.collapsedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T20:15:22.734696] [DBG] [WindowService] applyState: StripState.collapsedShown → size=Size(3840.0, 57.5) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T20:15:22.738205] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T20:15:22.738205] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T20:15:22.740205] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:22.743206] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=18 hovered=false loading=false signIn=false
[2026-06-20T20:15:22.755205] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:22.755205] [DBG] [EC] execute DONE intent=collapsed target=57.5
[2026-06-20T20:15:22.756208] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:22.775206] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:22.814207] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:22.822213] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:22.857720] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:22.880720] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:22.906721] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:23.119747] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:23.193259] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:23.256772] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:23.398285] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=18 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T20:15:23.522803] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T20:15:23.557313] [DBG] [WindowService] GEO[applyState:StripState.expandedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 57.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
Lost connection to device.
make[1]: Leaving directory 'C:/Users/drusi/VSCode_Projects/happening'
