// lib/ble/ble_manager.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../state/app_state.dart';
import '../parsers/obd_parsers.dart';

// ── PID descriptor ────────────────────────────────────────────────────────────
class PidDesc {
  final String cmd;
  final String key;
  final Function(String) parser;
  final int tier; // 0=FAST 1=MED 2=SLOW 3=RARE

  const PidDesc({
    required this.cmd,
    required this.key,
    required this.parser,
    required this.tier,
  });
}

// ── Tier config ───────────────────────────────────────────────────────────────
const kTierWait = [200, 250, 350, 500]; // ms
const kTierFreq = [1,   2,   5,   20 ]; // every N cycles

// ── PID lists ─────────────────────────────────────────────────────────────────
final kBikePids = [
  PidDesc(cmd:'010C', key:'rpm',     parser: OBDParsers.parseRpm,   tier:0),
  PidDesc(cmd:'010D', key:'speed',   parser: OBDParsers.parseSpeed, tier:0),
  PidDesc(cmd:'0111', key:'tps',     parser:(b)=>OBDParsers.parsePercent('11',b), tier:0),
  PidDesc(cmd:'0104', key:'load',    parser:(b)=>OBDParsers.parsePercent('04',b), tier:1),
  PidDesc(cmd:'010E', key:'timing',  parser: OBDParsers.parseTiming, tier:1),
  PidDesc(cmd:'0145', key:'rel_tps', parser: OBDParsers.parseRelTps, tier:1),
  PidDesc(cmd:'010F', key:'iat',     parser:(b)=>OBDParsers.parseTemp('0F',b), tier:2),
  PidDesc(cmd:'0105', key:'coolant', parser:(b)=>OBDParsers.parseTemp('05',b), tier:2),
  PidDesc(cmd:'010B', key:'map_kpa', parser: OBDParsers.parseMap,    tier:2),
  PidDesc(cmd:'0106', key:'stft',    parser:(b)=>OBDParsers.parseFuelTrim('06',b), tier:2),
  PidDesc(cmd:'0107', key:'ltft',    parser:(b)=>OBDParsers.parseFuelTrim('07',b), tier:2),
  PidDesc(cmd:'0114', key:'o2_v',    parser: OBDParsers.parseO2Voltage, tier:2),
  PidDesc(cmd:'0142', key:'batt_v',  parser: OBDParsers.parseBattVoltage, tier:3),
  PidDesc(cmd:'0133', key:'baro',    parser: OBDParsers.parseBaro,   tier:3),
  PidDesc(cmd:'0121', key:'mil_dist',parser: OBDParsers.parseMilDist, tier:3),
  PidDesc(cmd:'014D', key:'mil_time',parser: OBDParsers.parseMilTime, tier:3),
];

final kCarPids = [
  PidDesc(cmd:'010C', key:'rpm',     parser: OBDParsers.parseRpm,   tier:0),
  PidDesc(cmd:'010D', key:'speed',   parser: OBDParsers.parseSpeed, tier:0),
  PidDesc(cmd:'0111', key:'tps',     parser:(b)=>OBDParsers.parsePercent('11',b), tier:0),
  PidDesc(cmd:'0104', key:'load',    parser:(b)=>OBDParsers.parsePercent('04',b), tier:1),
  PidDesc(cmd:'010E', key:'timing',  parser: OBDParsers.parseTiming, tier:1),
  PidDesc(cmd:'010F', key:'iat',     parser:(b)=>OBDParsers.parseTemp('0F',b), tier:2),
  PidDesc(cmd:'0105', key:'coolant', parser:(b)=>OBDParsers.parseTemp('05',b), tier:2),
  PidDesc(cmd:'0110', key:'maf',     parser: OBDParsers.parseMaf,   tier:2),
  PidDesc(cmd:'010B', key:'map_kpa', parser: OBDParsers.parseMap,   tier:2),
  PidDesc(cmd:'0106', key:'stft',    parser:(b)=>OBDParsers.parseFuelTrim('06',b), tier:2),
  PidDesc(cmd:'0107', key:'ltft',    parser:(b)=>OBDParsers.parseFuelTrim('07',b), tier:2),
  PidDesc(cmd:'0114', key:'o2_v',    parser: OBDParsers.parseO2Voltage, tier:2),
  PidDesc(cmd:'0142', key:'batt_v',  parser: OBDParsers.parseBattVoltage, tier:3),
  PidDesc(cmd:'0133', key:'baro',    parser: OBDParsers.parseBaro,  tier:3),
];

// ── BLE Manager ───────────────────────────────────────────────────────────────
class BLEManager {
  final AppState state;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxChar;
  BluetoothCharacteristic? _txChar;
  String _rxBuf = '';
  bool _running = true;
  int _cycle = 0;
  Timer? _watchdog;

  static const rxUuid = '0000fff1-0000-1000-8000-00805f9b34fb';
  static const txUuid = '0000fff2-0000-1000-8000-00805f9b34fb';

  BLEManager(this.state);

  void start() {
    _connectLoop();
  }

  void stop() {
    _running = false;
    _watchdog?.cancel();
    _device?.disconnect();
  }

  // ── Connection loop ───────────────────────────────────────────────────────
  Future<void> _connectLoop() async {
    while (_running) {
      state.setBleStatus('Connecting to ${state.bleAddress}...');
      try {
        // scan for device
        final target = BluetoothDevice.fromId(state.bleAddress);
        state.setBleStatus('Connecting...');
        await target.connect(timeout: const Duration(seconds: 15));
        _device = target;

        state.setConnection(true, status: 'Connected — init ELM327...');
        await _initElm();
        state.setBleStatus('Polling');
        _startWatchdog();
        await _pollLoop();
      } catch (e) {
        state.setConnection(false,
            status: 'Error: ${e.toString().substring(0, e.toString().length.clamp(0, 55))}',
            error: e.toString());
      } finally {
        _watchdog?.cancel();
        _rxChar = null;
        _txChar = null;
        _rxBuf  = '';
        try { await _device?.disconnect(); } catch (_) {}
        _device = null;
        state.setConnection(false);
      }

      if (!_running) break;
      for (int i = 5; i > 0; i--) {
        state.setBleStatus('Reconnecting in ${i}s...');
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  // ── ELM327 init ───────────────────────────────────────────────────────────
  Future<void> _initElm() async {
    // discover services
    final services = await _device!.discoverServices();
    for (final svc in services) {
      for (final ch in svc.characteristics) {
        final uuid = ch.uuid.toString().toLowerCase();
        if (uuid == rxUuid) _rxChar = ch;
        if (uuid == txUuid) _txChar = ch;
      }
    }

    if (_rxChar == null || _txChar == null) {
      throw Exception('Required BLE characteristics not found');
    }

    // subscribe to notifications
    await _rxChar!.setNotifyValue(true);
    _rxChar!.onValueReceived.listen((data) {
      _rxBuf += utf8.decode(data, allowMalformed: true);
      if (_rxBuf.length > 12000) {
        _rxBuf = _rxBuf.substring(_rxBuf.length - 12000);
      }
    });

    await Future.delayed(const Duration(milliseconds: 300));

    // send init commands
    for (final cmd in ['ATZ','ATE0','ATL0','ATS0','ATH0','ATSP0']) {
      state.setBleStatus('Init: $cmd');
      await _send(cmd, 600);
    }

    // burn through SEARCHING...
    state.setBleStatus('Protocol search — please wait...');
    await _send('010C', 4500);
    await _send('010D', 500);
  }

  // ── Poll loop with priority tiers ─────────────────────────────────────────
  Future<void> _pollLoop() async {
    final pids = state.isBikeMode ? kBikePids : kCarPids;

    while (state.connected && _running) {
      final t0 = DateTime.now();
      final updates = <String, dynamic>{};

      for (final pid in pids) {
        if (_cycle % kTierFreq[pid.tier] != 0) continue;
        final resp = await _send(pid.cmd, kTierWait[pid.tier]);
        final val  = pid.parser(resp);
        if (val != null) {
          updates[pid.key] = val;
          _resetWatchdog();
        }
      }

      final elapsed = DateTime.now().difference(t0).inMilliseconds;
      updates['poll_hz'] = elapsed > 0
          ? double.parse((1000 / elapsed).toStringAsFixed(1))
          : 0.0;

      state.updateFromPoll(updates);
      _cycle++;
    }
  }

  // ── Send command and wait for response ────────────────────────────────────
  Future<String> _send(String cmd, int waitMs) async {
    if (_txChar == null) return '';
    _rxBuf = '';
    try {
      await _txChar!.write(
        utf8.encode('$cmd\r'),
        withoutResponse: _txChar!.properties.writeWithoutResponse,
      );
      await Future.delayed(Duration(milliseconds: waitMs));
    } catch (_) {}
    return _rxBuf;
  }

  // ── Watchdog — detect frozen poll loop ────────────────────────────────────
  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 10), (_) {
      if (state.connected) {
        state.setBleStatus('No data — reconnecting...');
        _device?.disconnect();
      }
    });
  }

  void _resetWatchdog() {
    _startWatchdog();
  }

  // ── One-off commands for diag/info pages ──────────────────────────────────
  Future<List<String>> readDtcs(String modeCmd) async {
    final raw = await _send(modeCmd, 2500);
    return OBDParsers.decodeDtcs(raw);
  }

  Future<void> clearDtcs() async {
    await _send('04', 1500);
  }

  Future<Map<String, String>> readEcuInfo() async {
    final info = <String, String>{};
    var r = await _send('0100', 1500);
    info['pids'] = OBDParsers.countSupportedPids(r).toString();
    r = await _send('0103', 1000);
    info['fuel'] = OBDParsers.parseFuelStatus(r);
    r = await _send('011C', 1000);
    info['std']  = OBDParsers.parseObdStd(r);
    r = await _send('0142', 800);
    final b = OBDParsers.parseBattVoltage(r);
    info['batt'] = b != null ? '${b}V' : 'N/A';
    r = await _send('0133', 800);
    final br = OBDParsers.parseBaro(r);
    info['baro'] = br != null ? '$br kPa' : 'N/A';
    r = await _send('014D', 800);
    final mt = OBDParsers.parseMilTime(r);
    info['mil_t'] = mt != null ? '$mt min' : 'N/A';
    return info;
  }
}
