// lib/screens/screens.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../ble/ble_manager.dart';
import '../widgets/ew_widgets.dart';
import '../theme.dart';
import '../parsers/obd_parsers.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  LIVE SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final t  = EWTheme(st.isDarkTheme);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ── Row 1: RPM + Speed + TPS ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // RPM gauge + gear
                Column(
                  children: [
                    ArcGauge(
                      value: st.rpm.toDouble(),
                      maxVal: st.rpmMax.toDouble(),
                      redline: st.rpmRedline.toDouble(),
                      t: t, size: 270,
                    ),
                    const SizedBox(height: 4),
                    Text('ENGINE SPEED',
                        style: TextStyle(color: t.muted, fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    // RPM graph
                    Text('RPM HISTORY',
                        style: TextStyle(color: t.muted, fontSize: 9,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 270,
                      child: EWGraph(
                        data: st.rpmHistory,
                        yMin: 0, yMax: st.rpmMax.toDouble(),
                        lineColor: t.accent, t: t,
                        height: 65,
                        label: '0 ─── ${st.rpmMax ~/ 1000}k RPM',
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Center: speed + coolant + cards
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SpeedGauge(
                            value: st.speed.toDouble(),
                            maxVal: st.speedMax.toDouble(),
                            t: t, size: 200,
                          ),
                          const SizedBox(width: 12),
                          // Gear display
                          Column(
                            children: [
                              const SizedBox(height: 20),
                              Text('GEAR',
                                  style: TextStyle(color: t.muted,
                                      fontSize: 9, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              GearDisplay(
                                gear: st.isBikeMode
                                    ? OBDParsers.estimateGear(st.rpm, st.speed)
                                    : '—',
                                t: t,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Coolant
                      Text('COOLANT TEMP',
                          style: TextStyle(color: t.muted, fontSize: 9,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      CoolantBar(value: st.coolant, t: t, width: 310),
                      const SizedBox(height: 12),
                      // 2×2 cards
                      Row(children: [
                        Expanded(child: EWCard(
                            title: 'Engine Load', value: '${st.load}',
                            unit: '%', t: t,
                            valueColor: t.loadColor(st.load))),
                        const SizedBox(width: 8),
                        Expanded(child: EWCard(
                            title: 'Timing', value: '${st.timing >= 0 ? '+' : ''}${st.timing}',
                            unit: 'deg', t: t,
                            valueColor: t.timingColor(st.timing))),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: EWCard(
                            title: st.isBikeMode ? 'MAP' : 'MAP',
                            value: '${st.mapKpa}',
                            unit: 'kPa', t: t)),
                        const SizedBox(width: 8),
                        Expanded(child: EWCard(
                            title: 'Battery',
                            value: st.battVoltage.toStringAsFixed(2),
                            unit: 'V', t: t,
                            valueColor: t.battColor(st.battVoltage))),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // TPS bar
                Column(
                  children: [
                    const SizedBox(height: 8),
                    Text('TPS',
                        style: TextStyle(color: t.muted, fontSize: 9,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TpsBar(value: st.tps, t: t, width: 52, height: 240),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Row 2: bottom metric cards ────────────────────────────────
            Row(children: [
              Expanded(child: EWCard(
                  title: 'Intake Air', value: '${st.iat}',
                  unit: '°C', t: t,
                  valueColor: t.iatColor(st.iat))),
              const SizedBox(width: 8),
              Expanded(child: EWCard(
                  title: 'STFT',
                  value: '${st.stft >= 0 ? '+' : ''}${st.stft.toStringAsFixed(1)}',
                  unit: '%', t: t,
                  valueColor: t.ftColor(st.stft))),
              const SizedBox(width: 8),
              Expanded(child: EWCard(
                  title: 'LTFT',
                  value: '${st.ltft >= 0 ? '+' : ''}${st.ltft.toStringAsFixed(1)}',
                  unit: '%', t: t,
                  valueColor: t.ftColor(st.ltft))),
              const SizedBox(width: 8),
              Expanded(child: EWCard(
                  title: 'O2 Voltage',
                  value: st.o2Voltage.toStringAsFixed(3),
                  unit: 'V', t: t,
                  valueColor: t.o2Color(st.o2Voltage))),
              const SizedBox(width: 8),
              Expanded(child: EWCard(
                  title: 'Barometric', value: '${st.baro}',
                  unit: 'kPa', t: t)),
            ]),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  RIDE SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class RideScreen extends StatelessWidget {
  const RideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final t  = EWTheme(st.isDarkTheme);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RIDE ANALYTICS',
              style: TextStyle(color: t.accent, fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),

          // Fuel trim + O2 row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fuel trims panel
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: t.card,
                    border: Border.all(color: t.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FUEL TRIMS',
                          style: TextStyle(color: t.accent, fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      FuelTrimBar(value: st.stft, label: 'SHORT TERM', t: t),
                      const SizedBox(height: 10),
                      FuelTrimBar(value: st.ltft, label: 'LONG TERM',  t: t),
                      const SizedBox(height: 10),
                      Text('±5% Normal  ·  >±10% Investigate  ·  >±20% Fault',
                          style: TextStyle(color: t.muted, fontSize: 9)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // O2 panel
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: t.card,
                    border: Border.all(color: t.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('O2 SENSOR  B1S1',
                          style: TextStyle(color: t.accent, fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        '${st.o2Voltage.toStringAsFixed(3)}  V',
                        style: TextStyle(
                            color: t.o2Color(st.o2Voltage),
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 4),
                      Text('<0.45V = Lean   |   >0.45V = Rich',
                          style: TextStyle(color: t.muted, fontSize: 9)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.circle,
                            size: 10,
                            color: st.isClosedLoop ? EWColors.green : EWColors.yellow),
                        const SizedBox(width: 6),
                        Text(
                          st.isClosedLoop ? 'CLOSED LOOP' : 'OPEN LOOP',
                          style: TextStyle(
                              color: st.isClosedLoop ? EWColors.green : EWColors.yellow,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // O2 graph
          Text('O2 VOLTAGE HISTORY',
              style: TextStyle(color: t.muted, fontSize: 9,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          EWGraph(data: st.o2History, yMin: 0, yMax: 1.0,
              lineColor: EWColors.green, t: t, height: 75,
              label: '0V ─── 0.45V ─── 1V'),
          const SizedBox(height: 12),

          // STFT graph
          Text('SHORT TERM FUEL TRIM HISTORY',
              style: TextStyle(color: t.muted, fontSize: 9,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          EWGraph(data: st.stftHistory, yMin: -25, yMax: 25,
              lineColor: EWColors.yellow, t: t, height: 75,
              label: '-25% ─── 0 ─── +25%'),
          const SizedBox(height: 14),

          // Trip computer
          Row(children: [
            Expanded(child: EWCard(title: 'Session Time',
                value: st.tripDuration, unit: '', t: t)),
            const SizedBox(width: 8),
            Expanded(child: EWCard(title: 'Peak RPM',
                value: '${st.tripMaxRpm}', unit: 'rpm', t: t)),
            const SizedBox(width: 8),
            Expanded(child: EWCard(title: 'Peak Speed',
                value: '${st.tripMaxSpeed}', unit: 'km/h', t: t)),
            const SizedBox(width: 8),
            Expanded(child: EWCard(title: 'MIL Distance',
                value: '${st.milDist}', unit: 'km', t: t)),
            const SizedBox(width: 8),
            Expanded(child: EWCard(title: 'MIL On Time',
                value: '${st.milTime}', unit: 'min', t: t)),
          ]),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DIAGNOSTICS SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class DiagScreen extends StatefulWidget {
  final BLEManager ble;
  const DiagScreen({super.key, required this.ble});

  @override
  State<DiagScreen> createState() => _DiagScreenState();
}

class _DiagScreenState extends State<DiagScreen> {
  final List<Map<String, String>> _results = [];
  String _status = '';
  bool _loading = false;

  Future<void> _readCodes(String cmd) async {
    final st = context.read<AppState>();
    if (!st.connected) {
      setState(() => _status = '⚠ ECU not connected');
      return;
    }
    setState(() { _loading = true; _status = 'Reading...'; _results.clear(); });
    final codes = await widget.ble.readDtcs(cmd);
    setState(() {
      _loading = false;
      _status = codes.isEmpty
          ? '✔ No fault codes found'
          : '${codes.length} code(s) found';
      for (final c in codes) {
        _results.add({
          'code': c,
          'desc': kDtcDesc[c] ?? 'No description available',
          'type': c.substring(0, 1),
        });
      }
    });
  }

  Future<void> _clearCodes() async {
    final st = context.read<AppState>();
    if (!st.connected) {
      setState(() => _status = '⚠ ECU not connected');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Fault Codes'),
        content: const Text('This will erase all stored DTCs from the ECU.\n\nAre you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('CLEAR', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() { _loading = true; _status = 'Clearing...'; });
    await widget.ble.clearDtcs();
    setState(() { _loading = false; _status = '✔ Codes cleared'; _results.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final t  = EWTheme(st.isDarkTheme);

    final codeColors = {
      'P': EWColors.red,
      'C': EWColors.yellow,
      'B': EWColors.orange,
      'U': t.accent,
    };

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DIAGNOSTICS CONSOLE',
              style: TextStyle(color: t.accent, fontSize: 18,
                  fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(children: [
            _btn('READ STORED (03)', () => _readCodes('03'), t),
            const SizedBox(width: 8),
            _btn('READ PENDING (07)', () => _readCodes('07'), t),
            const SizedBox(width: 8),
            _btn('CLEAR CODES (04)', _clearCodes, t, danger: true),
            const SizedBox(width: 12),
            if (_loading) SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: t.accent)),
            const SizedBox(width: 8),
            Text(_status, style: TextStyle(color: t.muted, fontSize: 10)),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: t.panel,
                border: Border.all(color: t.border),
                borderRadius: BorderRadius.circular(6),
              ),
              child: _results.isEmpty
                  ? Center(child: Text(
                      _status.isEmpty
                          ? 'Press a button to scan for fault codes'
                          : _status,
                      style: TextStyle(color: t.muted, fontSize: 12)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final r = _results[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (codeColors[r['type']] ?? t.accent)
                                    .withOpacity(0.15),
                                border: Border.all(
                                    color: codeColors[r['type']] ?? t.accent),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(r['code']!,
                                  style: TextStyle(
                                      color: codeColors[r['type']] ?? t.accent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace')),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(r['desc']!,
                                  style: TextStyle(
                                      color: t.muted, fontSize: 11)),
                            ),
                          ]),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, VoidCallback onTap, EWTheme t,
      {bool danger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: danger ? const Color(0xFF3a0a0a) : t.card,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(label,
            style: TextStyle(
                color: danger ? EWColors.red : t.text,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  INFO SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class InfoScreen extends StatefulWidget {
  final BLEManager ble;
  const InfoScreen({super.key, required this.ble});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  Map<String, String> _info = {};
  String _status = '';
  bool _loading = false;

  Future<void> _query() async {
    final st = context.read<AppState>();
    if (!st.connected) {
      setState(() => _status = '⚠ ECU not connected'); return;
    }
    setState(() { _loading = true; _status = 'Querying...'; });
    final info = await widget.ble.readEcuInfo();
    setState(() { _loading = false; _status = 'Done'; _info = info; });
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final t  = EWTheme(st.isDarkTheme);

    const fields = [
      ('std',   'OBD STANDARD'),
      ('fuel',  'FUEL SYSTEM'),
      ('pids',  'SUPPORTED PIDs'),
      ('batt',  'BATTERY VOLTAGE'),
      ('baro',  'BAROMETRIC'),
      ('mil_t', 'MIL ON TIME'),
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ECU INFORMATION',
              style: TextStyle(color: t.accent, fontSize: 18,
                  fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(children: [
            GestureDetector(
              onTap: _query,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: t.card,
                  border: Border.all(color: t.border),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text('QUERY ECU',
                    style: TextStyle(color: t.text, fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            if (_loading) SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: t.accent)),
            const SizedBox(width: 8),
            Text(_status, style: TextStyle(color: t.muted, fontSize: 10)),
          ]),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: fields.map((f) {
              return SizedBox(
                width: 280,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: t.card,
                    border: Border.all(color: t.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.$2,
                          style: TextStyle(color: t.muted, fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      Text(_info[f.$1] ?? '—',
                          style: TextStyle(color: t.text, fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace')),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SETTINGS SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Map<String, TextEditingController> _ctrl;
  String _msg = '';

  @override
  void initState() {
    super.initState();
    final st = context.read<AppState>();
    _ctrl = {
      'address':       TextEditingController(text: st.bleAddress),
      'rpm_max':       TextEditingController(text: st.rpmMax.toString()),
      'rpm_redline':   TextEditingController(text: st.rpmRedline.toString()),
      'speed_max':     TextEditingController(text: st.speedMax.toString()),
      'alert_coolant': TextEditingController(text: st.alertCoolant.toString()),
      'alert_stft':    TextEditingController(text: st.alertStft.toString()),
      'alert_ltft':    TextEditingController(text: st.alertLtft.toString()),
      'alert_batt_lo': TextEditingController(text: st.alertBattLo.toString()),
    };
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) c.dispose();
    super.dispose();
  }

  void _save() {
    try {
      final st = context.read<AppState>();
      st.bleAddress    = _ctrl['address']!.text.trim();
      st.rpmMax        = int.parse(_ctrl['rpm_max']!.text);
      st.rpmRedline    = int.parse(_ctrl['rpm_redline']!.text);
      st.speedMax      = int.parse(_ctrl['speed_max']!.text);
      st.alertCoolant  = double.parse(_ctrl['alert_coolant']!.text);
      st.alertStft     = double.parse(_ctrl['alert_stft']!.text);
      st.alertLtft     = double.parse(_ctrl['alert_ltft']!.text);
      st.alertBattLo   = double.parse(_ctrl['alert_batt_lo']!.text);
      st.savePrefs();
      setState(() => _msg = '✔ Saved — restart to apply BLE address change');
    } catch (e) {
      setState(() => _msg = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final t  = EWTheme(st.isDarkTheme);

    final rows = [
      ('address',       'BLE Address'),
      ('rpm_max',       'RPM Max (gauge scale)'),
      ('rpm_redline',   'RPM Redline'),
      ('speed_max',     'Speed Max (km/h)'),
      ('alert_coolant', 'Alert: Coolant (°C)'),
      ('alert_stft',    'Alert: STFT (%)'),
      ('alert_ltft',    'Alert: LTFT (%)'),
      ('alert_batt_lo', 'Alert: Battery Low (V)'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SETTINGS',
              style: TextStyle(color: t.accent, fontSize: 18,
                  fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: t.card,
                border: Border.all(color: t.border),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(children: [
                SizedBox(
                  width: 240,
                  child: Text(r.$2,
                      style: TextStyle(color: t.muted, fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _ctrl[r.$1],
                    style: TextStyle(color: t.text, fontSize: 12,
                        fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: t.dim,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: t.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ),
              ]),
            ),
          )),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _save,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: t.accent2,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text('SAVE SETTINGS',
                  style: TextStyle(color: t.bg, fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          if (_msg.isNotEmpty)
            Text(_msg, style: TextStyle(
                color: _msg.startsWith('✔') ? EWColors.green : EWColors.red,
                fontSize: 11)),
        ],
      ),
    );
  }
}
