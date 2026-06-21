=== make run-windows @ 2026-06-20 19:48:30 ===
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
Launching lib\main.dart on Windows in debug mode...
Building Windows application...                                     8.0s
√ Built build\windows\x64\runner\Debug\happening.exe
[2026-06-20T19:48:44.702034] [DBG] [main] Main entry point: WidgetsFlutterBinding initialized.
[2026-06-20T19:48:44.720545] [DBG] [main] Settings loaded.
[2026-06-20T19:48:44.736544] [WRN] [main] DisplayService: weak fingerprint match — persisted=\\.\DISPLAY1 matched DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001) (\\.\DISPLAY1). User can re-pick in Settings.
[2026-06-20T19:48:44.742544] [DBG] [main] DisplayService initialized: active=DisplayInfo(id=DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001), osName=\\.\DISPLAY1, size=Size(3840.0, 2160.0), workArea=(Offset(0.0, 0.0), Size(3840.0, 2112.0)), scale=1.0, primary=true)
[2026-06-20T19:48:44.743549] [INF] [main] WindowService.initialize() start
[2026-06-20T19:48:44.754545] [DBG] [WindowService] WindowService.initialize: dpr=1.0 activeDisplay=DisplayInfo(id=DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001), osName=\\.\DISPLAY1, size=Size(3840.0, 2160.0), workArea=(Offset(0.0, 0.0), Size(3840.0, 2112.0)), scale=1.0, primary=true) size=Size(3840.0, 72.5) collapsedHeight=72.5 expandedHeight=390.0
[2026-06-20T19:48:44.754545] [DBG] [WindowService] WindowService.initialize: calling waitUntilReadyToShow
[2026-06-20T19:48:44.755546] [DBG] [WindowService] WindowService.initialize: awaiting readyToShow
[2026-06-20T19:48:44.989365] [DBG] [WindowService] WindowService.initialize: readyToShow callback — calling strategy.initialize
[2026-06-20T19:48:44.989365] [DBG] [WindowService] WindowService.initialize: readyToShow complete, calling afterReadyToShow
[2026-06-20T19:48:44.989365] [DBG] [WindowService] WindowService.initialize: afterReadyToShow complete
[2026-06-20T19:48:44.989365] [DBG] [WindowService] WindowService.initialize: registering WidgetsBindingObserver
[2026-06-20T19:48:44.989365] [INF] [main] WindowService.initialize() done — calling runApp()
[2026-06-20T19:48:44.995366] [INF] [main] runApp() returned
[2026-06-20T19:48:45.031877] [DBG] [_HappeningAppState] HappeningApp._initServices starting...
Syncing files to device Windows...                              
[2026-06-20T19:48:45.359436] [DBG] [WindowService] WindowService.initialize: readyToShow callback — calling strategy.moveToDisplay DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)
Syncing files to device Windows...                                 136ms

Flutter run key commands.
r Hot reload. 
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

A Dart VM Service on Windows is available at: http://127.0.0.1:61591/p8d3vXSEdYk=/
The Flutter DevTools debugger and profiler on Windows is available at: http://127.0.0.1:61591/p8d3vXSEdYk=/devtools/?uri=ws://127.0.0.1:61591/p8d3vXSEdYk=/ws
[2026-06-20T19:48:45.382437] [DBG] [WindowService] WindowService.initialize: readyToShow callback — calling beforeShow
[2026-06-20T19:48:45.382437] [DBG] [WindowService] WindowService.initialize: readyToShow callback — calling setAsFrameless
[2026-06-20T19:48:45.386436] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T19:48:45.387436] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:48:45.414959] [DBG] [WindowService] WindowService.initialize: readyToShow callback — calling performShow
[2026-06-20T19:48:45.416960] [DBG] [WindowService] WindowService.initialize: readyToShow callback — calling afterWindowShown
[2026-06-20T19:48:45.417958] [DBG] [WindowsWindowService] afterWindowShown: applyState(collapsedShown); present deferred to first frame
[2026-06-20T19:48:45.429960] [DBG] [Win32AppBar] loading SHAppBarMessage from shell32.dll
[2026-06-20T19:48:45.431959] [DBG] [Win32AppBar] register: ABM_NEW hWnd=0x1d06a6
[2026-06-20T19:48:45.438957] [DBG] [Win32AppBar] reserveTopBand: req=3840x73 → rect=[0,0,3840,73]
[2026-06-20T19:48:45.438957] [DBG] [WindowsWindowService] applyReservation: StripState.collapsedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T19:48:45.438957] [DBG] [WindowService] applyState: StripState.collapsedShown → size=Size(3840.0, 72.5) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T19:48:45.454961] [DBG] [_HappeningAppState] Secure storage verified.
[2026-06-20T19:48:45.456959] [DBG] [_HappeningAppState] AuthService initialized. Attempting restore...
[2026-06-20T19:48:45.486960] [DBG] [_HappeningAppState] Auth restored successfully.
[2026-06-20T19:48:45.486960] [DBG] [_HappeningAppState] HappeningApp._startCalendar called.
[2026-06-20T19:48:45.488961] [DBG] [CalendarController] CalendarController.start() called.
[2026-06-20T19:48:45.489959] [DBG] [CalendarController] CalendarController._fetch() started (forceRefresh: false)
[2026-06-20T19:48:45.489959] [DBG] [CalendarController] Fetching 7 configured calendars
[2026-06-20T19:48:45.519482] [DBG] [_HappeningAppState] CalendarController started.
[2026-06-20T19:48:45.520484] [DBG] [_HappeningAppState] AuthState changed to: authenticated
[2026-06-20T19:48:45.564488] [DBG] [_HappeningAppState] app StreamBuilder: state=ConnectionState.waiting hasData=false dataLen=null lastEvents=null
[2026-06-20T19:48:45.569484] [DBG] [AstroDataService] _onSettingsChanged: theme=astronomical hasLocation=true lat=40.71427 lng=-74.00597
[2026-06-20T19:48:45.570485] [DBG] [AstroDataService] _recalculate: lat=40.71427 lng=-74.00597 dateKey=2026-6-20
[2026-06-20T19:48:45.572485] [DBG] [AstroDataService] _recalculate: civilTwilightBegin=2026-06-20 08:51:33.647Z sunrise=2026-06-20 09:30:10.662Z solarNoon=2026-06-20 12:57:51.312 sunset=2026-06-21 00:25:31.961Z civilTwilightEnd=2026-06-21 01:04:09.302Z
[2026-06-20T19:48:45.574486] [DBG] [AstroDataService] _recalculate: moonIllum={fraction: 0.3974283357794274, phase: 0.21711697365072097, angle: -1.1685444137016572}
[2026-06-20T19:48:45.574486] [DBG] [AstroDataService] _recalculate: AstroData built — notifying listeners
[2026-06-20T19:48:45.575486] [DBG] [_TimelineStripState] TimelineStrip: astroData changed → current=AstroData(sunrise=2026-06-20 09:30:10.662Z)
[2026-06-20T19:48:45.575486] [DBG] [_TimelineStripState] Timestrip: _updatgeHeights called:  strip height is to 72.5
[2026-06-20T19:48:45.576487] [DBG] [_TimelineStripState] TimelineStrip: Initializing
[2026-06-20T19:48:45.584484] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=true layout=true events=0 collapsedH=72.5 expandedH=390.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=72.0
[2026-06-20T19:48:45.657004] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x72.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=0 hovered=false loading=true signIn=false
[2026-06-20T19:48:45.725548] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:45.725548] [DBG] [WindowService] WindowService.initialize: readyToShow callback — calling interactionStrategy.initialize
[2026-06-20T19:48:45.725548] [DBG] [WindowService] WindowService.initialize: readyToShow callback — done
[2026-06-20T19:48:45.728529] [DBG] [WindowsWindowService] presentInitialFrame: 1px shrink-settle 71.5→72.5, pin=Offset(0.0, 0.0)
[2026-06-20T19:48:45.734525] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T19:48:45.734525] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:48:45.811531] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=true layout=true events=0 collapsedH=72.5 expandedH=390.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=71.0
[2026-06-20T19:48:45.837043] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T19:48:45.837043] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:48:45.846039] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=true layout=true events=0 collapsedH=72.5 expandedH=390.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=72.0
[2026-06-20T19:48:45.894057] [DBG] [Win32AppBar] presentFrame: RedrawWindow(RDW_INVALIDATE|RDW_UPDATENOW) hwnd=0x1d06a6
[2026-06-20T19:48:45.896046] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:45.897046] [DBG] [WindowService] GEO[presentInitialFrame:after]: pos=Offset(0.0, 0.0) size=Size(3840.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:46.048789] [DBG] [WindowService] GEO[presentInitialFrame +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:46.148303] [DBG] [GoogleCalendarService] [CalendarFetch] fetched 0 raw items, 0 timed items
[2026-06-20T19:48:46.149305] [DBG] [CalendarController] Fetched configured calendar: 0 events
[2026-06-20T19:48:46.227819] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:46.397820] [DBG] [WindowService] GEO[presentInitialFrame +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:46.451339] [DBG] [GoogleCalendarService] [CalendarFetch] fetched 0 raw items, 0 timed items
[2026-06-20T19:48:46.451339] [DBG] [CalendarController] Fetched configured calendar: 0 events
[2026-06-20T19:48:46.833404] [DBG] [GoogleCalendarService] [CalendarFetch] fetched 0 raw items, 0 timed items
[2026-06-20T19:48:46.833404] [DBG] [CalendarController] Fetched configured calendar: 0 events
[2026-06-20T19:48:46.926916] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:47.098434] [DBG] [WindowService] GEO[presentInitialFrame +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:47.313468] [DBG] [GoogleCalendarService] [CalendarFetch] fetched 3 raw items, 2 timed items
[2026-06-20T19:48:47.313976] [DBG] [CalendarController] Fetched configured calendar: 2 events
[2026-06-20T19:48:47.631522] [DBG] [GoogleCalendarService] [CalendarFetch] fetched 0 raw items, 0 timed items
[2026-06-20T19:48:47.631522] [DBG] [CalendarController] Fetched configured calendar: 0 events
[2026-06-20T19:48:47.937066] [DBG] [GoogleCalendarService] [CalendarFetch] fetched 0 raw items, 0 timed items
[2026-06-20T19:48:47.937066] [DBG] [CalendarController] Fetched configured calendar: 0 events
[2026-06-20T19:48:48.268610] [DBG] [GoogleCalendarService] [CalendarFetch] fetched 0 raw items, 0 timed items
[2026-06-20T19:48:48.268610] [DBG] [CalendarController] Fetched configured calendar: 0 events
[2026-06-20T19:48:48.269610] [DBG] [CalendarController] Fetch complete. Found 2 events (2 deduped).
[2026-06-20T19:48:48.269610] [DBG] [CalendarController] Emitted events to stream.
[2026-06-20T19:48:48.277612] [DBG] [_HappeningAppState] app StreamBuilder: state=ConnectionState.active hasData=true dataLen=2 lastEvents=2
[2026-06-20T19:48:48.278613] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=72.5 expandedH=390.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=72.0
[2026-06-20T19:48:48.284611] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x72.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=false loading=false signIn=false
[2026-06-20T19:48:49.549903] [DBG] [_TimelineStripState] [TS] expansion → collapsed mouseX=0.0 mouseY=70.0 isExit=false
[2026-06-20T19:48:49.549903] [DBG] [EC] sendAndAwait intent=collapsed
[2026-06-20T19:48:49.553900] [DBG] [EC] execute START intent=collapsed target=72.5
[2026-06-20T19:48:49.553900] [DBG] [WindowService] WindowService._doCollapse() target=w3840.0×h72.5
[2026-06-20T19:48:49.555902] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=72.5 expandedH=390.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=72.0
[2026-06-20T19:48:49.560901] [DBG] [WindowService] WindowService._doCollapse() complete
[2026-06-20T19:48:49.561900] [DBG] [EC] execute DONE intent=collapsed target=72.5
[2026-06-20T19:48:50.064481] [INF] [_TimelineStripState] TimelineStrip: hiding strip (preHideSentToBack=false, settingsOpen=false, hoveredEvent=null)
[2026-06-20T19:48:50.066478] [DBG] [_TimelineStripState] TimelineStrip: ensuring strip is collapsed before hiding
[2026-06-20T19:48:50.066478] [DBG] [_TimelineStripState] TimelineStrip: calling windowService.prepareToHide
[2026-06-20T19:48:50.073478] [DBG] [Win32AppBar] dispose: ABM_REMOVE done
[2026-06-20T19:48:50.073478] [DBG] [_TimelineStripState] TimelineStrip: reversing hide animation
[2026-06-20T19:48:50.392675] [INF] [_TimelineStripState] TimelineStrip: resizing to mini strip (fontSize=22.0)
[2026-06-20T19:48:50.393679] [DBG] [WindowService] resizeToMiniStrip: target=Size(268.0, 72.5) origin=Offset(0.0, 0.0)
[2026-06-20T19:48:50.401684] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T19:48:50.402689] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:48:50.416197] [DBG] [WindowService] GEO[resizeToMiniStrip]: pos=Offset(0.0, 0.0) size=Size(268.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:50.417195] [INF] [_TimelineStripState] TimelineStrip: hide complete
[2026-06-20T19:48:50.568715] [DBG] [WindowService] GEO[resizeToMiniStrip +150ms]: pos=Offset(0.0, 0.0) size=Size(268.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:50.618231] [INF] [_TimelineStripState] TimelineStrip: restoring strip
[2026-06-20T19:48:50.620230] [DBG] [_TimelineStripState] TimelineStrip: restoring window via windowService.showStrip()
[2026-06-20T19:48:50.620230] [DBG] [WindowsWindowService] showStrip: applyState(collapsedShown) + presentInitialFrame (converged onto the init path)
[2026-06-20T19:48:50.622234] [DBG] [Win32AppBar] register: ABM_NEW hWnd=0x1d06a6
[2026-06-20T19:48:50.628233] [DBG] [Win32AppBar] reserveTopBand: req=3840x73 → rect=[0,0,3840,73]
[2026-06-20T19:48:50.628233] [DBG] [WindowsWindowService] applyReservation: StripState.collapsedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T19:48:50.629232] [DBG] [WindowService] applyState: StripState.collapsedShown → size=Size(3840.0, 72.5) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T19:48:50.682232] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T19:48:50.682232] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:48:50.817840] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:50.818840] [DBG] [WindowsWindowService] presentInitialFrame: 1px shrink-settle 71.5→72.5, pin=Offset(0.0, 0.0)
[2026-06-20T19:48:50.822840] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T19:48:50.823841] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:48:50.849840] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T19:48:50.850838] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:48:50.863837] [DBG] [Win32AppBar] presentFrame: RedrawWindow(RDW_INVALIDATE|RDW_UPDATENOW) hwnd=0x1d06a6
[2026-06-20T19:48:50.864839] [DBG] [WindowService] GEO[presentInitialFrame:after]: pos=Offset(0.0, 0.0) size=Size(3840.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:50.864839] [DBG] [_TimelineStripState] TimelineStrip: playing show animation
[2026-06-20T19:48:50.921359] [DBG] [WindowService] GEO[resizeToMiniStrip +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:50.971364] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:51.017875] [DBG] [WindowService] GEO[presentInitialFrame +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:51.175393] [INF] [_TimelineStripState] TimelineStrip: show complete
[2026-06-20T19:48:51.176392] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=72.5 expandedH=390.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=72.0
[2026-06-20T19:48:51.184397] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x72.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=false loading=false signIn=false
[2026-06-20T19:48:51.198393] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=72.5 expandedH=390.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=72.0
[2026-06-20T19:48:51.299914] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=72.5 expandedH=390.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=72.0
[2026-06-20T19:48:51.319421] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:51.367426] [DBG] [WindowService] GEO[presentInitialFrame +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:51.529449] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=72.5 expandedH=390.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=72.0
[2026-06-20T19:48:51.618970] [DBG] [WindowService] GEO[resizeToMiniStrip +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:52.019026] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:52.067027] [DBG] [WindowService] GEO[presentInitialFrame +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 72.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:52.387572] [DBG] [EC] sendAndAwait intent=expanded
[2026-06-20T19:48:52.388573] [DBG] [EC] execute START intent=expanded target=390.0
[2026-06-20T19:48:52.388573] [DBG] [WindowService] WindowService._doExpand() target=w3840.0×h390.0
[2026-06-20T19:48:52.391572] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=true
[2026-06-20T19:48:52.391572] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:48:52.394572] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=true hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=72.5 expandedH=390.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=390.0
[2026-06-20T19:48:52.592605] [DBG] [EC] execute DONE intent=expanded target=390.0
[2026-06-20T19:48:52.597603] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=72.5 expandedH=390.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=390.0
[2026-06-20T19:48:52.922258] [DBG] [_TimelineStripState] [TS] expansion → expanded mouseX=154.0 mouseY=45.0 isExit=false
[2026-06-20T19:48:53.010262] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=72.5 expandedH=390.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=390.0
[2026-06-20T19:48:53.029770] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x72.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=true loading=false signIn=false
[2026-06-20T19:48:54.475546] [DBG] [_TimelineStripState] Timestrip: _updatgeHeights called:  strip height is to 72.5
[2026-06-20T19:48:54.475546] [DBG] [WindowService] WindowService.updateHeights: fontSizePx=11.0 isExpanded=true
[2026-06-20T19:48:54.475546] [DBG] [WindowService] WindowService._doExpand() target=w3840.0×h280.0
[2026-06-20T19:48:54.476548] [DBG] [AstroDataService] _onSettingsChanged: theme=astronomical hasLocation=true lat=40.71427 lng=-74.00597
[2026-06-20T19:48:54.476548] [DBG] [AstroDataService] _recalculate: lat=40.71427 lng=-74.00597 dateKey=2026-6-20
[2026-06-20T19:48:54.476548] [DBG] [AstroDataService] _recalculate: cache hit
[2026-06-20T19:48:54.483549] [DBG] [_HappeningAppState] app StreamBuilder: state=ConnectionState.active hasData=true dataLen=2 lastEvents=2
[2026-06-20T19:48:54.484551] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=45.0 expandedH=280.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=390.0
[2026-06-20T19:48:54.509552] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x45.0 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=true loading=false signIn=false
[2026-06-20T19:48:54.521064] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=true
[2026-06-20T19:48:54.521064] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:48:54.524066] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=45.0 expandedH=280.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=280.0
[2026-06-20T19:48:54.560062] [DBG] [WindowService] WindowService.updateHeights: _doExpand complete
[2026-06-20T19:48:54.723095] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=45.0 expandedH=280.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=280.0
[2026-06-20T19:48:55.210162] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=45.0 expandedH=280.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=280.0
[2026-06-20T19:48:55.224678] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x45.0 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=true loading=false signIn=false
[2026-06-20T19:48:55.495708] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=45.0 expandedH=280.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=280.0
[2026-06-20T19:48:55.508720] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x45.0 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=false loading=false signIn=false
[2026-06-20T19:48:56.242840] [DBG] [EC] sendAndAwait intent=collapsed
[2026-06-20T19:48:56.242840] [DBG] [EC] execute START intent=collapsed target=45.0
[2026-06-20T19:48:56.242840] [DBG] [WindowService] WindowService._doCollapse() target=w3840.0×h45.0
[2026-06-20T19:48:56.245831] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T19:48:56.245831] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:48:56.251833] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=45.0 expandedH=280.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=45.0
[2026-06-20T19:48:56.274831] [DBG] [WindowService] WindowService._doCollapse() complete
[2026-06-20T19:48:56.274831] [DBG] [EC] execute DONE intent=collapsed target=45.0
[2026-06-20T19:48:56.280831] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=45.0 expandedH=280.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=45.0
[2026-06-20T19:48:56.347346] [DBG] [_TimelineStripState] [TS] expansion → collapsed mouseX=84.0 mouseY=21.0 isExit=false
[2026-06-20T19:48:56.639511] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=45.0 expandedH=280.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=45.0
[2026-06-20T19:48:56.756026] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=45.0 expandedH=280.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=45.0
[2026-06-20T19:48:57.015814] [INF] [_TimelineStripState] TimelineStrip: hiding strip (preHideSentToBack=false, settingsOpen=false, hoveredEvent=null)
[2026-06-20T19:48:57.016320] [DBG] [_TimelineStripState] TimelineStrip: ensuring strip is collapsed before hiding
[2026-06-20T19:48:57.016320] [DBG] [_TimelineStripState] TimelineStrip: calling windowService.prepareToHide
[2026-06-20T19:48:57.022327] [DBG] [Win32AppBar] dispose: ABM_REMOVE done
[2026-06-20T19:48:57.022327] [DBG] [_TimelineStripState] TimelineStrip: reversing hide animation
[2026-06-20T19:48:57.336880] [INF] [_TimelineStripState] TimelineStrip: resizing to mini strip (fontSize=11.0)
[2026-06-20T19:48:57.337882] [DBG] [WindowService] resizeToMiniStrip: target=Size(169.0, 45.0) origin=Offset(0.0, 0.0)
[2026-06-20T19:48:57.341883] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T19:48:57.342884] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:48:57.359884] [DBG] [WindowService] GEO[resizeToMiniStrip]: pos=Offset(0.0, 0.0) size=Size(169.0, 45.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:57.359884] [INF] [_TimelineStripState] TimelineStrip: hide complete
[2026-06-20T19:48:57.511403] [DBG] [WindowService] GEO[resizeToMiniStrip +150ms]: pos=Offset(0.0, 0.0) size=Size(169.0, 45.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:57.690426] [INF] [_TimelineStripState] TimelineStrip: restoring strip
[2026-06-20T19:48:57.691426] [DBG] [_TimelineStripState] TimelineStrip: restoring window via windowService.showStrip()
[2026-06-20T19:48:57.692427] [DBG] [WindowsWindowService] showStrip: applyState(collapsedShown) + presentInitialFrame (converged onto the init path)
[2026-06-20T19:48:57.693428] [DBG] [Win32AppBar] register: ABM_NEW hWnd=0x1d06a6
[2026-06-20T19:48:57.698427] [DBG] [Win32AppBar] reserveTopBand: req=3840x45 → rect=[0,0,3840,45]
[2026-06-20T19:48:57.698427] [DBG] [WindowsWindowService] applyReservation: StripState.collapsedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T19:48:57.699430] [DBG] [WindowService] applyState: StripState.collapsedShown → size=Size(3840.0, 45.0) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T19:48:57.744943] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T19:48:57.744943] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:48:57.764943] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 45.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:57.764943] [DBG] [WindowsWindowService] presentInitialFrame: 1px shrink-settle 44.0→45.0, pin=Offset(0.0, 0.0)
[2026-06-20T19:48:57.781943] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T19:48:57.782943] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:48:57.808949] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T19:48:57.809948] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:48:57.822464] [DBG] [Win32AppBar] presentFrame: RedrawWindow(RDW_INVALIDATE|RDW_UPDATENOW) hwnd=0x1d06a6
[2026-06-20T19:48:57.823465] [DBG] [WindowService] GEO[presentInitialFrame:after]: pos=Offset(0.0, 0.0) size=Size(3840.0, 45.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:57.823465] [DBG] [_TimelineStripState] TimelineStrip: playing show animation
[2026-06-20T19:48:57.863465] [DBG] [WindowService] GEO[resizeToMiniStrip +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 45.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:57.917977] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 45.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:57.975979] [DBG] [WindowService] GEO[presentInitialFrame +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 45.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:58.134004] [INF] [_TimelineStripState] TimelineStrip: show complete
[2026-06-20T19:48:58.135006] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=45.0 expandedH=280.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=45.0
[2026-06-20T19:48:58.141009] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x45.0 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=false loading=false signIn=false
[2026-06-20T19:48:58.154010] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=45.0 expandedH=280.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=45.0
[2026-06-20T19:48:58.266519] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 45.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:58.325035] [DBG] [WindowService] GEO[presentInitialFrame +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 45.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:58.561065] [DBG] [WindowService] GEO[resizeToMiniStrip +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 45.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:58.967167] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 45.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:59.024680] [DBG] [WindowService] GEO[presentInitialFrame +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 45.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:48:59.527246] [DBG] [EC] sendAndAwait intent=expanded
[2026-06-20T19:48:59.527246] [DBG] [EC] execute START intent=expanded target=280.0
[2026-06-20T19:48:59.528250] [DBG] [WindowService] WindowService._doExpand() target=w3840.0×h280.0
[2026-06-20T19:48:59.530246] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=true
[2026-06-20T19:48:59.530246] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:48:59.532249] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=true hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=45.0 expandedH=280.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=280.0
[2026-06-20T19:48:59.559251] [DBG] [EC] execute DONE intent=expanded target=280.0
[2026-06-20T19:48:59.564248] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=45.0 expandedH=280.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=280.0
[2026-06-20T19:48:59.819561] [DBG] [_TimelineStripState] [TS] expansion → expanded mouseX=164.0 mouseY=27.0 isExit=false
[2026-06-20T19:48:59.861561] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=45.0 expandedH=280.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=280.0
[2026-06-20T19:48:59.872562] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x45.0 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=true loading=false signIn=false
[2026-06-20T19:48:59.953077] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=45.0 expandedH=280.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=280.0
[2026-06-20T19:49:00.173104] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=45.0 expandedH=280.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=280.0
[2026-06-20T19:49:00.184108] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x45.0 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=true loading=false signIn=false
[2026-06-20T19:49:01.462794] [DBG] [_TimelineStripState] Timestrip: _updatgeHeights called:  strip height is to 45.0
[2026-06-20T19:49:01.462794] [DBG] [WindowService] WindowService.updateHeights: fontSizePx=21.0 isExpanded=true
[2026-06-20T19:49:01.462794] [DBG] [WindowService] WindowService._doExpand() target=w3840.0×h380.0
[2026-06-20T19:49:01.462794] [DBG] [AstroDataService] _onSettingsChanged: theme=astronomical hasLocation=true lat=40.71427 lng=-74.00597
[2026-06-20T19:49:01.462794] [DBG] [AstroDataService] _recalculate: lat=40.71427 lng=-74.00597 dateKey=2026-6-20
[2026-06-20T19:49:01.462794] [DBG] [AstroDataService] _recalculate: cache hit
[2026-06-20T19:49:01.466795] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=true
[2026-06-20T19:49:01.466795] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:49:01.471796] [DBG] [_HappeningAppState] app StreamBuilder: state=ConnectionState.active hasData=true dataLen=2 lastEvents=2
[2026-06-20T19:49:01.472797] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=380.0
[2026-06-20T19:49:01.496795] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x70.0 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=true loading=false signIn=false
[2026-06-20T19:49:01.510800] [DBG] [WindowService] WindowService.updateHeights: _doExpand complete
[2026-06-20T19:49:02.993131] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=380.0
[2026-06-20T19:49:03.003135] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x70.0 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=false loading=false signIn=false
[2026-06-20T19:49:03.549475] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=380.0
[2026-06-20T19:49:04.674120] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=380.0
[2026-06-20T19:49:04.685121] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x70.0 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=true loading=false signIn=false
[2026-06-20T19:49:04.849149] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=380.0
[2026-06-20T19:49:05.593759] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x70.0 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=false loading=false signIn=false
[2026-06-20T19:49:05.647275] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=380.0
[2026-06-20T19:49:05.883303] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=380.0
[2026-06-20T19:49:05.893303] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x70.0 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=false loading=false signIn=false
[2026-06-20T19:49:06.589898] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=380.0
[2026-06-20T19:49:06.600901] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x70.0 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=true loading=false signIn=false
[2026-06-20T19:49:06.764931] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=380.0
[2026-06-20T19:49:08.422190] [DBG] [_TimelineStripState] Timestrip: _updatgeHeights called:  strip height is to 70.0
[2026-06-20T19:49:08.422190] [DBG] [AstroDataService] _onSettingsChanged: theme=astronomical hasLocation=true lat=40.71427 lng=-74.00597
[2026-06-20T19:49:08.422190] [DBG] [AstroDataService] _recalculate: lat=40.71427 lng=-74.00597 dateKey=2026-6-20
[2026-06-20T19:49:08.422190] [DBG] [AstroDataService] _recalculate: cache hit
[2026-06-20T19:49:08.430191] [DBG] [_HappeningAppState] app StreamBuilder: state=ConnectionState.active hasData=true dataLen=2 lastEvents=2
[2026-06-20T19:49:08.441193] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x70.0 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=false loading=false signIn=false
[2026-06-20T19:49:08.460194] [DBG] [_TimelineStripState] Timestrip: _updatgeHeights called:  strip height is to 70.0
[2026-06-20T19:49:08.460194] [DBG] [AstroDataService] _onSettingsChanged: theme=astronomical hasLocation=true lat=40.71427 lng=-74.00597
[2026-06-20T19:49:08.460194] [DBG] [AstroDataService] _recalculate: lat=40.71427 lng=-74.00597 dateKey=2026-6-20
[2026-06-20T19:49:08.460194] [DBG] [AstroDataService] _recalculate: cache hit
[2026-06-20T19:49:08.468193] [DBG] [_HappeningAppState] app StreamBuilder: state=ConnectionState.active hasData=true dataLen=2 lastEvents=2
[2026-06-20T19:49:08.486194] [DBG] [_TimelineStripState] Timestrip: _updatgeHeights called:  strip height is to 70.0
[2026-06-20T19:49:08.487194] [DBG] [AstroDataService] _onSettingsChanged: theme=astronomical hasLocation=true lat=40.71427 lng=-74.00597
[2026-06-20T19:49:08.487194] [DBG] [AstroDataService] _recalculate: lat=40.71427 lng=-74.00597 dateKey=2026-6-20
[2026-06-20T19:49:08.487194] [DBG] [AstroDataService] _recalculate: cache hit
[2026-06-20T19:49:08.490192] [DBG] [_TimelineStripState] Timestrip: _updatgeHeights called:  strip height is to 70.0
[2026-06-20T19:49:08.490192] [DBG] [AstroDataService] _onSettingsChanged: theme=astronomical hasLocation=true lat=40.71427 lng=-74.00597
[2026-06-20T19:49:08.490192] [DBG] [AstroDataService] _recalculate: lat=40.71427 lng=-74.00597 dateKey=2026-6-20
[2026-06-20T19:49:08.490192] [DBG] [AstroDataService] _recalculate: cache hit
[2026-06-20T19:49:08.494197] [DBG] [_HappeningAppState] app StreamBuilder: state=ConnectionState.active hasData=true dataLen=2 lastEvents=2
[2026-06-20T19:49:08.514198] [DBG] [_TimelineStripState] Timestrip: _updatgeHeights called:  strip height is to 70.0
[2026-06-20T19:49:08.514198] [DBG] [AstroDataService] _onSettingsChanged: theme=astronomical hasLocation=true lat=40.71427 lng=-74.00597
[2026-06-20T19:49:08.514198] [DBG] [AstroDataService] _recalculate: lat=40.71427 lng=-74.00597 dateKey=2026-6-20
[2026-06-20T19:49:08.514198] [DBG] [AstroDataService] _recalculate: cache hit
[2026-06-20T19:49:08.517196] [DBG] [_HappeningAppState] app StreamBuilder: state=ConnectionState.active hasData=true dataLen=2 lastEvents=2
[2026-06-20T19:49:08.538708] [DBG] [_TimelineStripState] Timestrip: _updatgeHeights called:  strip height is to 70.0
[2026-06-20T19:49:08.539711] [DBG] [AstroDataService] _onSettingsChanged: theme=astronomical hasLocation=true lat=40.71427 lng=-74.00597
[2026-06-20T19:49:08.539711] [DBG] [AstroDataService] _recalculate: lat=40.71427 lng=-74.00597 dateKey=2026-6-20
[2026-06-20T19:49:08.539711] [DBG] [AstroDataService] _recalculate: cache hit
[2026-06-20T19:49:08.542711] [DBG] [_TimelineStripState] Timestrip: _updatgeHeights called:  strip height is to 70.0
[2026-06-20T19:49:08.542711] [DBG] [AstroDataService] _onSettingsChanged: theme=astronomical hasLocation=true lat=40.71427 lng=-74.00597
[2026-06-20T19:49:08.542711] [DBG] [AstroDataService] _recalculate: lat=40.71427 lng=-74.00597 dateKey=2026-6-20
[2026-06-20T19:49:08.542711] [DBG] [AstroDataService] _recalculate: cache hit
[2026-06-20T19:49:08.546708] [DBG] [_HappeningAppState] app StreamBuilder: state=ConnectionState.active hasData=true dataLen=2 lastEvents=2
[2026-06-20T19:49:08.564708] [DBG] [_TimelineStripState] Timestrip: _updatgeHeights called:  strip height is to 70.0
[2026-06-20T19:49:08.565708] [DBG] [AstroDataService] _onSettingsChanged: theme=astronomical hasLocation=true lat=40.71427 lng=-74.00597
[2026-06-20T19:49:08.565708] [DBG] [AstroDataService] _recalculate: lat=40.71427 lng=-74.00597 dateKey=2026-6-20
[2026-06-20T19:49:08.565708] [DBG] [AstroDataService] _recalculate: cache hit
[2026-06-20T19:49:08.574708] [DBG] [_HappeningAppState] app StreamBuilder: state=ConnectionState.active hasData=true dataLen=2 lastEvents=2
[2026-06-20T19:49:08.590710] [DBG] [_TimelineStripState] Timestrip: _updatgeHeights called:  strip height is to 70.0
[2026-06-20T19:49:08.590710] [DBG] [AstroDataService] _onSettingsChanged: theme=astronomical hasLocation=true lat=40.71427 lng=-74.00597
[2026-06-20T19:49:08.590710] [DBG] [AstroDataService] _recalculate: lat=40.71427 lng=-74.00597 dateKey=2026-6-20
[2026-06-20T19:49:08.590710] [DBG] [AstroDataService] _recalculate: cache hit
[2026-06-20T19:49:08.595712] [DBG] [_TimelineStripState] Timestrip: _updatgeHeights called:  strip height is to 70.0
[2026-06-20T19:49:08.595712] [DBG] [AstroDataService] _onSettingsChanged: theme=astronomical hasLocation=true lat=40.71427 lng=-74.00597
[2026-06-20T19:49:08.595712] [DBG] [AstroDataService] _recalculate: lat=40.71427 lng=-74.00597 dateKey=2026-6-20
[2026-06-20T19:49:08.595712] [DBG] [AstroDataService] _recalculate: cache hit
[2026-06-20T19:49:08.599709] [DBG] [_HappeningAppState] app StreamBuilder: state=ConnectionState.active hasData=true dataLen=2 lastEvents=2
[2026-06-20T19:49:08.617715] [DBG] [_TimelineStripState] Timestrip: _updatgeHeights called:  strip height is to 70.0
[2026-06-20T19:49:08.617715] [DBG] [AstroDataService] _onSettingsChanged: theme=astronomical hasLocation=true lat=40.71427 lng=-74.00597
[2026-06-20T19:49:08.617715] [DBG] [AstroDataService] _recalculate: lat=40.71427 lng=-74.00597 dateKey=2026-6-20
[2026-06-20T19:49:08.617715] [DBG] [AstroDataService] _recalculate: cache hit
[2026-06-20T19:49:08.626028] [DBG] [_HappeningAppState] app StreamBuilder: state=ConnectionState.active hasData=true dataLen=2 lastEvents=2
[2026-06-20T19:49:09.215611] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=380.0
[2026-06-20T19:49:09.225120] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x70.0 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=true loading=false signIn=false
[2026-06-20T19:49:09.382635] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=380.0
[2026-06-20T19:49:09.840202] [INF] [_TimelineStripState] TimelineStrip: hiding strip (preHideSentToBack=false, settingsOpen=true, hoveredEvent=null)
[2026-06-20T19:49:09.843202] [DBG] [_TimelineStripState] TimelineStrip: ensuring strip is collapsed before hiding
[2026-06-20T19:49:09.843202] [DBG] [EC] sendAndAwait intent=collapsed
[2026-06-20T19:49:09.843202] [DBG] [EC] execute START intent=collapsed target=70.0
[2026-06-20T19:49:09.843202] [DBG] [WindowService] WindowService._doCollapse() target=w3840.0×h70.0
[2026-06-20T19:49:09.844207] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=380.0
[2026-06-20T19:49:09.854206] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T19:49:09.854206] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:49:09.862207] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=70.0
[2026-06-20T19:49:09.868208] [DBG] [WindowService] WindowService._doCollapse() complete
[2026-06-20T19:49:09.868208] [DBG] [EC] execute DONE intent=collapsed target=70.0
[2026-06-20T19:49:09.868208] [DBG] [_TimelineStripState] TimelineStrip: calling windowService.prepareToHide
[2026-06-20T19:49:09.874204] [DBG] [Win32AppBar] dispose: ABM_REMOVE done
[2026-06-20T19:49:09.874204] [DBG] [_TimelineStripState] TimelineStrip: reversing hide animation
[2026-06-20T19:49:10.184318] [INF] [_TimelineStripState] TimelineStrip: resizing to mini strip (fontSize=21.0)
[2026-06-20T19:49:10.185321] [DBG] [WindowService] resizeToMiniStrip: target=Size(259.0, 70.0) origin=Offset(0.0, 0.0)
[2026-06-20T19:49:10.190321] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T19:49:10.191320] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:49:10.205329] [DBG] [WindowService] GEO[resizeToMiniStrip]: pos=Offset(0.0, 0.0) size=Size(259.0, 70.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:49:10.205329] [INF] [_TimelineStripState] TimelineStrip: hide complete
[2026-06-20T19:49:10.357350] [DBG] [WindowService] GEO[resizeToMiniStrip +150ms]: pos=Offset(0.0, 0.0) size=Size(259.0, 70.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:49:10.706572] [DBG] [WindowService] GEO[resizeToMiniStrip +500ms]: pos=Offset(0.0, 0.0) size=Size(259.0, 70.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:49:11.153139] [INF] [_TimelineStripState] TimelineStrip: restoring strip
[2026-06-20T19:49:11.154139] [DBG] [_TimelineStripState] TimelineStrip: restoring window via windowService.showStrip()
[2026-06-20T19:49:11.154139] [DBG] [WindowsWindowService] showStrip: applyState(collapsedShown) + presentInitialFrame (converged onto the init path)
[2026-06-20T19:49:11.156138] [DBG] [Win32AppBar] register: ABM_NEW hWnd=0x1d06a6
[2026-06-20T19:49:11.161139] [DBG] [Win32AppBar] reserveTopBand: req=3840x70 → rect=[0,0,3840,70]
[2026-06-20T19:49:11.162138] [DBG] [WindowsWindowService] applyReservation: StripState.collapsedShown reserved → origin=Offset(0.0, 0.0) (rcTop=0)
[2026-06-20T19:49:11.162138] [DBG] [WindowService] applyState: StripState.collapsedShown → size=Size(3840.0, 70.0) origin=Offset(0.0, 0.0) (reserved=Offset(0.0, 0.0))
[2026-06-20T19:49:11.208148] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T19:49:11.208148] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:49:11.232663] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown]: pos=Offset(0.0, 0.0) size=Size(3840.0, 70.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:49:11.232663] [DBG] [WindowsWindowService] presentInitialFrame: 1px shrink-settle 69.0→70.0, pin=Offset(0.0, 0.0)
[2026-06-20T19:49:11.245663] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T19:49:11.245663] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:49:11.267663] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T19:49:11.267663] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:49:11.284660] [DBG] [Win32AppBar] presentFrame: RedrawWindow(RDW_INVALIDATE|RDW_UPDATENOW) hwnd=0x1d06a6
[2026-06-20T19:49:11.285662] [DBG] [WindowService] GEO[presentInitialFrame:after]: pos=Offset(0.0, 0.0) size=Size(3840.0, 70.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:49:11.286659] [DBG] [_TimelineStripState] TimelineStrip: playing show animation
[2026-06-20T19:49:11.386184] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 70.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:49:11.407182] [DBG] [WindowService] GEO[resizeToMiniStrip +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 70.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:49:11.438692] [DBG] [WindowService] GEO[presentInitialFrame +150ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 70.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:49:11.592504] [INF] [_TimelineStripState] TimelineStrip: show complete
[2026-06-20T19:49:11.593503] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=70.0
[2026-06-20T19:49:11.598502] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x70.0 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=false loading=false signIn=false
[2026-06-20T19:49:11.735541] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 70.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:49:11.787542] [DBG] [WindowService] GEO[presentInitialFrame +500ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 70.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:49:12.435137] [DBG] [WindowService] GEO[applyState:StripState.collapsedShown +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 70.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:49:12.488138] [DBG] [WindowService] GEO[presentInitialFrame +1200ms]: pos=Offset(0.0, 0.0) size=Size(3840.0, 70.0) workAreaOrigin=Offset(0.0, 0.0) dpr=1.0
[2026-06-20T19:49:13.584324] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=70.0
[2026-06-20T19:49:14.347618] [DBG] [EC] sendAndAwait intent=expanded
[2026-06-20T19:49:14.347618] [DBG] [EC] execute START intent=expanded target=380.0
[2026-06-20T19:49:14.348620] [DBG] [WindowService] WindowService._doExpand() target=w3840.0×h380.0
[2026-06-20T19:49:14.350619] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=true
[2026-06-20T19:49:14.350619] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:49:14.357619] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=true hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=380.0
[2026-06-20T19:49:14.384620] [DBG] [EC] execute DONE intent=expanded target=380.0
[2026-06-20T19:49:14.389620] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=380.0
[2026-06-20T19:49:14.610655] [DBG] [_TimelineStripState] [TS] expansion → expanded mouseX=157.0 mouseY=41.0 isExit=false
[2026-06-20T19:49:14.653163] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=380.0
[2026-06-20T19:49:14.659163] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x70.0 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=true loading=false signIn=false
[2026-06-20T19:49:14.812680] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=380.0
[2026-06-20T19:49:15.090222] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=70.0 expandedH=380.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=380.0
[2026-06-20T19:49:15.100223] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x70.0 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=true loading=false signIn=false
[2026-06-20T19:49:15.590797] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x70.0 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=true loading=false signIn=false
[2026-06-20T19:49:16.598960] [DBG] [_TimelineStripState] Timestrip: _updatgeHeights called:  strip height is to 70.0
[2026-06-20T19:49:16.598960] [DBG] [WindowService] WindowService.updateHeights: fontSizePx=16.0 isExpanded=true
[2026-06-20T19:49:16.598960] [DBG] [WindowService] WindowService._doExpand() target=w3840.0×h330.0
[2026-06-20T19:49:16.598960] [DBG] [AstroDataService] _onSettingsChanged: theme=astronomical hasLocation=true lat=40.71427 lng=-74.00597
[2026-06-20T19:49:16.598960] [DBG] [AstroDataService] _recalculate: lat=40.71427 lng=-74.00597 dateKey=2026-6-20
[2026-06-20T19:49:16.599964] [DBG] [AstroDataService] _recalculate: cache hit
[2026-06-20T19:49:16.603963] [DBG] [_HappeningAppState] app StreamBuilder: state=ConnectionState.active hasData=true dataLen=2 lastEvents=2
[2026-06-20T19:49:16.603963] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=380.0
[2026-06-20T19:49:16.624075] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=true loading=false signIn=false
[2026-06-20T19:49:16.635078] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=true
[2026-06-20T19:49:16.635078] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:49:16.641075] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T19:49:16.658075] [DBG] [WindowService] WindowService.updateHeights: _doExpand complete
[2026-06-20T19:49:18.163793] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T19:49:18.171793] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=false loading=false signIn=false
[2026-06-20T19:49:25.591936] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=false loading=false signIn=false
[2026-06-20T19:49:27.486319] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T19:49:27.496319] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=true loading=false signIn=false
[2026-06-20T19:49:27.541841] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T19:49:27.891380] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=true hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T19:49:27.900383] [DBG] [TimelinePainter] TimelinePainter.paint size=3840.0x57.5 bg=#ff1a1a2e surfaceOpacity=1.00 emphasisOpacity=1.00 events=2 hovered=true loading=false signIn=false
[2026-06-20T19:49:28.077407] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=true hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T19:49:28.553974] [DBG] [EC] sendAndAwait intent=collapsed
[2026-06-20T19:49:28.553974] [DBG] [EC] execute START intent=collapsed target=57.5
[2026-06-20T19:49:28.553974] [DBG] [WindowService] WindowService._doCollapse() target=w3840.0×h57.5
[2026-06-20T19:49:28.554975] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=330.0
[2026-06-20T19:49:28.564974] [DBG] [WindowService] WindowService._onDisplayChangedInner: dpr=1.0→1.0 width=3840.0→3840.0 activeChanged=false (DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)→DisplayId(MONITOR\GBT2800\{4d36e96e-e325-11ce-bfc1-08002be10318}\0001)) isExpanded=false
[2026-06-20T19:49:28.564974] [DBG] [WindowService] WindowService._onDisplayChangedInner: no change, skipping
[2026-06-20T19:49:28.572975] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=true card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T19:49:28.580976] [DBG] [WindowService] WindowService._doCollapse() complete
[2026-06-20T19:49:28.580976] [DBG] [EC] execute DONE intent=collapsed target=57.5
[2026-06-20T19:49:28.583981] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T19:49:28.801002] [DBG] [_TimelineStripState] [TS] expansion → collapsed mouseX=3812.0 mouseY=35.0 isExit=false
[2026-06-20T19:49:28.821007] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=false sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
[2026-06-20T19:49:30.702786] [DBG] [_TimelineStripState] TimelineStrip.paint-state expanded=false card=false settings=false hovered=false hovering=true sentToBack=false signIn=false cancelSignIn=false loading=false layout=true events=2 collapsedH=57.5 expandedH=330.0 backdrop=#00000000 painterBg=#ff1a1a2e maxH=57.0
Lost connection to device.
make[1]: Leaving directory 'C:/Users/drusi/VSCode_Projects/happening'
