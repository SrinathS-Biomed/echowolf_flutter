// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'state/app_state.dart';
import 'ble/ble_manager.dart';
import 'screens/screens.dart';
import 'theme.dart';
import 'widgets/ew_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Keep screen on while app is running
  await WakelockPlus.enable();

  // Hide status bar for full screen
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final appState = AppState();
  await appState.loadPrefs();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const EchoWolfApp(),
    ),
  );
}

class EchoWolfApp extends StatelessWidget {
  const EchoWolfApp({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    return MaterialApp(
      title: 'EchoWolf',
      debugShowCheckedModeBanner: false,
      theme: EWTheme(st.isDarkTheme).materialTheme,
      home: const MainShell(),
    );
  }
}

// ── Main shell with tabs ──────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late BLEManager _ble;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    final st = context.read<AppState>();
    _ble = BLEManager(st);
    _ble.start();
  }

  @override
  void dispose() {
    _ble.stop();
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final t  = EWTheme(st.isDarkTheme);

    return Scaffold(
      backgroundColor: t.bg,
      body: Column(
        children: [
          // ── Top bar ────────────────────────────────────────────────────
          _TopBar(t: t, ble: _ble),

          // ── Alert banner ───────────────────────────────────────────────
          AlertBanner(alerts: st.alerts),

          // ── Tab bar ────────────────────────────────────────────────────
          Container(
            color: t.dim,
            child: TabBar(
              controller: _tab,
              tabs: const [
                Tab(text: 'LIVE'),
                Tab(text: 'RIDE'),
                Tab(text: 'DIAGNOSTICS'),
                Tab(text: 'INFO'),
                Tab(text: 'SETTINGS'),
              ],
              labelStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold,
                  fontFamily: 'monospace'),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 12, fontFamily: 'monospace'),
              labelColor: t.accent,
              unselectedLabelColor: t.muted,
              indicatorColor: t.accent,
              indicatorWeight: 3,
            ),
          ),

          // ── Page content ───────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tab,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                const LiveScreen(),
                const RideScreen(),
                DiagScreen(ble: _ble),
                InfoScreen(ble: _ble),
                const SettingsScreen(),
              ],
            ),
          ),

          // ── Status bar ─────────────────────────────────────────────────
          _StatusBar(t: t),
        ],
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final EWTheme t;
  final BLEManager ble;
  const _TopBar({required this.t, required this.ble});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();

    return Container(
      color: t.panel,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // connection dot
          Icon(Icons.circle,
              size: 12,
              color: st.connected ? EWColors.green : EWColors.red),
          const SizedBox(width: 8),
          Text(
            st.connected ? 'ECU CONNECTED' : 'ECU DISCONNECTED',
            style: TextStyle(
                color: st.connected ? EWColors.green : EWColors.red,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace'),
          ),
          const Spacer(),

          // poll hz
          Text('POLL: ${st.connected ? '${st.pollHz} Hz' : '—'}',
              style: TextStyle(color: t.muted, fontSize: 10,
                  fontFamily: 'monospace')),
          const SizedBox(width: 16),

          // error text
          if (st.bleError.isNotEmpty)
            Text(
              st.bleError.length > 40
                  ? '${st.bleError.substring(0, 40)}...'
                  : st.bleError,
              style: TextStyle(color: EWColors.orange,
                  fontSize: 9, fontFamily: 'monospace'),
            ),

          const SizedBox(width: 16),

          // vehicle mode toggle
          _TopBtn(
            label: st.isBikeMode ? '🏍 BIKE' : '🚗 CAR',
            color: t.accent2,
            textColor: EWColors.white,
            onTap: () => st.toggleVehicleMode(),
          ),
          const SizedBox(width: 8),

          // theme toggle
          _TopBtn(
            label: st.isDarkTheme ? '☀ DAY' : '🌙 NIGHT',
            color: t.panel,
            textColor: t.accent,
            onTap: () => st.toggleTheme(),
          ),
          const SizedBox(width: 8),

          // quit
          _TopBtn(
            label: '[ QUIT ]',
            color: t.panel,
            textColor: t.muted,
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Exit EchoWolf'),
                content: const Text('Quit the diagnostic suite?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => SystemNavigator.pop(),
                      child: const Text('QUIT',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _TopBtn({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace')),
      ),
    );
  }
}

// ── Status Bar ────────────────────────────────────────────────────────────────
class _StatusBar extends StatelessWidget {
  final EWTheme t;
  const _StatusBar({required this.t});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    return Container(
      color: t.dim,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text('EchoWolf  v4.0  ©2025',
              style: TextStyle(color: t.muted, fontSize: 9,
                  fontFamily: 'monospace')),
          const SizedBox(width: 24),
          Expanded(
            child: Text(st.bleStatus,
                style: TextStyle(color: t.muted, fontSize: 9,
                    fontFamily: 'monospace'),
                overflow: TextOverflow.ellipsis),
          ),
          Text(
            _time(),
            style: TextStyle(color: t.muted, fontSize: 9,
                fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  String _time() {
    final n = DateTime.now();
    return 'LOCAL  ${n.hour.toString().padLeft(2,'0')}:'
        '${n.minute.toString().padLeft(2,'0')}:'
        '${n.second.toString().padLeft(2,'0')}';
  }
}
