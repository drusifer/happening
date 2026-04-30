import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const ClickThroughTestApp());
}

class ClickThroughTestApp extends StatelessWidget {
  const ClickThroughTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Click-Through Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  static const _ch = MethodChannel(
    'com.example.click_through_test/click_through',
  );

  String _displayServer = '…';
  bool _clickThrough = false;
  final List<String> _log = [];

  // Focus node so the KeyboardListener can capture key events.
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _getDisplayServer();
    _getWindowInfo();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _getDisplayServer() async {
    try {
      final v = await _ch.invokeMethod<String>('getDisplayServer');
      setState(() => _displayServer = v ?? 'unknown');
      _addLog('display-server: $_displayServer');
    } catch (e) {
      _addLog('getDisplayServer ERROR: $e');
    }
  }

  Future<void> _getWindowInfo() async {
    try {
      final info =
          await _ch.invokeMapMethod<String, dynamic>('getWindowInfo');
      if (info != null) {
        info.forEach((k, v) => _addLog('info.$k = $v'));
      }
    } on MissingPluginException {
      _addLog('getWindowInfo → not implemented');
    } catch (e) {
      _addLog('getWindowInfo ERROR: $e');
    }
  }

  Future<void> _setClickThrough(bool enable) async {
    try {
      await _ch
          .invokeMethod<bool>('setIgnoreMouseEvents', {'ignore': enable});
      setState(() => _clickThrough = enable);
      _addLog('setIgnoreMouseEvents($enable) → OK');
      // Re-query window state so log shows what changed.
      await _getWindowInfoQuiet();
    } on MissingPluginException {
      _addLog('setIgnoreMouseEvents → MissingPluginException');
    } on PlatformException catch (e) {
      _addLog('setIgnoreMouseEvents ERROR: ${e.code} ${e.message}');
    }
  }

  Future<void> _getWindowInfoQuiet() async {
    try {
      final info =
          await _ch.invokeMapMethod<String, dynamic>('getWindowInfo');
      if (info != null) {
        final acceptFocus = info['acceptFocus'];
        final focusOnMap = info['focusOnMap'];
        final isActive = info['isActive'];
        _addLog(
          'post-change: acceptFocus=$acceptFocus  '
          'focusOnMap=$focusOnMap  isActive=$isActive',
        );
      }
    } catch (_) {}
  }

  void _toggle() => _setClickThrough(!_clickThrough);

  void _addLog(String msg) {
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    setState(() {
      _log.insert(0, '[$ts] $msg');
      if (_log.length > 40) _log.removeLast();
    });
  }

  // Handle Escape key → disable click-through so the user can interact with
  // the window again without needing a mouse click.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _clickThrough) {
      _addLog('Escape pressed — disabling click-through');
      _setClickThrough(false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final active = _clickThrough;
    final bgColor = active
        ? Colors.indigo.withOpacity(0.18)
        : Colors.indigo.withOpacity(0.82);
    final borderColor =
        active ? Colors.lightBlueAccent : Colors.indigoAccent;
    final statusText = active
        ? 'CLICK-THROUGH ON — pointer events pass through'
        : 'CLICK-THROUGH OFF — window receives pointer events';

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── header ───────────────────────────────────────────────
              Container(
                color: Colors.black38,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Text(
                      'Linux Click-Through Test',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    _Badge(_displayServer.toUpperCase()),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.info_outline,
                          size: 18, color: Colors.white54),
                      tooltip: 'Refresh diagnostics',
                      onPressed: _getWindowInfo,
                    ),
                  ],
                ),
              ),

              // ── status ───────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: active ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      active ? Icons.check_circle : Icons.cancel,
                      color: active ? Colors.greenAccent : Colors.redAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        statusText,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              // ── toggle button ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ElevatedButton.icon(
                  onPressed: _toggle,
                  icon: Icon(
                      active ? Icons.visibility_off : Icons.visibility),
                  label: Text(
                    active
                        ? 'Disable Click-Through'
                        : 'Enable Click-Through',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: active
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── escape hint (shown only when click-through is ON) ─────
              if (active)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.keyboard, size: 16, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Press  Esc  to disable click-through',
                          style: TextStyle(
                              color: Colors.orange, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── test instructions ────────────────────────────────────
              if (!active)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  child: const Text(
                    'How to test:\n'
                    '1. Open a terminal behind this window.\n'
                    '2. Press "Enable Click-Through".\n'
                    '3. Click on the dimmed window area — clicks should reach the terminal.\n'
                    '4. Press Esc to get mouse control back.',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 11, height: 1.5),
                  ),
                ),

              const SizedBox(height: 8),

              // ── log ──────────────────────────────────────────────────
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ListView.builder(
                    itemCount: _log.length,
                    itemBuilder: (_, i) => Text(
                      _log[i],
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
