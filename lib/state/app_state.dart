// lib/state/app_state.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  // ── Connection ────────────────────────────────────────────────────────────
  bool connected = false;
  String bleStatus = 'Initialising...';
  String bleError = '';
  double pollHz = 0.0;

  // ── Settings ──────────────────────────────────────────────────────────────
  String bleAddress = '81:23:45:67:89:BA';
  bool isBikeMode = true;
  bool isDarkTheme = true;
  int rpmMax = 12000;
  int rpmRedline = 10500;
  int speedMax = 220;
  double alertCoolant = 110.0;
  double alertStft = 12.0;
  double alertLtft = 10.0;
  double alertBattLo = 12.0;

  // ── Live values ───────────────────────────────────────────────────────────
  int rpm = 0;
  int speed = 0;
  double tps = 0.0;
  double relTps = 0.0;
  double load = 0.0;
  double timing = 0.0;
  int iat = 0;
  int coolant = 0;
  int mapKpa = 0;
  double maf = 0.0;
  double stft = 0.0;
  double ltft = 0.0;
  double o2Voltage = 0.0;
  double battVoltage = 0.0;
  int baro = 0;
  int milDist = 0;
  int milTime = 0;

  // ── History buffers ───────────────────────────────────────────────────────
  final int histLen = 80;
  late List<double> rpmHistory;
  late List<double> stftHistory;
  late List<double> o2History;
  late List<double> speedHistory;

  // ── Trip ──────────────────────────────────────────────────────────────────
  DateTime tripStart = DateTime.now();
  int tripMaxRpm = 0;
  int tripMaxSpeed = 0;

  // ── Alerts ────────────────────────────────────────────────────────────────
  final List<String> alerts = [];

  AppState() {
    rpmHistory   = List.filled(histLen, 0.0);
    stftHistory  = List.filled(histLen, 0.0);
    o2History    = List.filled(histLen, 0.0);
    speedHistory = List.filled(histLen, 0.0);
  }

  // ── Load / save prefs ─────────────────────────────────────────────────────
  Future<void> loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    bleAddress   = p.getString('ble_address') ?? bleAddress;
    isBikeMode   = p.getBool('bike_mode')     ?? isBikeMode;
    isDarkTheme  = p.getBool('dark_theme')    ?? isDarkTheme;
    rpmMax       = p.getInt('rpm_max')        ?? rpmMax;
    rpmRedline   = p.getInt('rpm_redline')    ?? rpmRedline;
    speedMax     = p.getInt('speed_max')      ?? speedMax;
    alertCoolant = p.getDouble('alert_coolant') ?? alertCoolant;
    alertStft    = p.getDouble('alert_stft')    ?? alertStft;
    alertLtft    = p.getDouble('alert_ltft')    ?? alertLtft;
    alertBattLo  = p.getDouble('alert_batt_lo') ?? alertBattLo;
    notifyListeners();
  }

  Future<void> savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('ble_address',   bleAddress);
    await p.setBool('bike_mode',        isBikeMode);
    await p.setBool('dark_theme',       isDarkTheme);
    await p.setInt('rpm_max',           rpmMax);
    await p.setInt('rpm_redline',       rpmRedline);
    await p.setInt('speed_max',         speedMax);
    await p.setDouble('alert_coolant',  alertCoolant);
    await p.setDouble('alert_stft',     alertStft);
    await p.setDouble('alert_ltft',     alertLtft);
    await p.setDouble('alert_batt_lo',  alertBattLo);
  }

  // ── Update from BLE poll ──────────────────────────────────────────────────
  void updateFromPoll(Map<String, dynamic> data) {
    if (data.containsKey('rpm')) {
      rpm = data['rpm'] as int;
      _pushHistory(rpmHistory, rpm.toDouble());
      if (rpm > tripMaxRpm) tripMaxRpm = rpm;
    }
    if (data.containsKey('speed')) {
      speed = data['speed'] as int;
      _pushHistory(speedHistory, speed.toDouble());
      if (speed > tripMaxSpeed) tripMaxSpeed = speed;
    }
    if (data.containsKey('tps'))     tps     = data['tps'];
    if (data.containsKey('rel_tps')) relTps  = data['rel_tps'];
    if (data.containsKey('load'))    load    = data['load'];
    if (data.containsKey('timing'))  timing  = data['timing'];
    if (data.containsKey('iat'))     iat     = data['iat'];
    if (data.containsKey('coolant')) coolant = data['coolant'];
    if (data.containsKey('map_kpa')) mapKpa  = data['map_kpa'];
    if (data.containsKey('maf'))     maf     = data['maf'];
    if (data.containsKey('stft')) {
      stft = data['stft'];
      _pushHistory(stftHistory, stft);
    }
    if (data.containsKey('ltft'))      ltft       = data['ltft'];
    if (data.containsKey('o2_v')) {
      o2Voltage = data['o2_v'];
      _pushHistory(o2History, o2Voltage);
    }
    if (data.containsKey('batt_v'))    battVoltage = data['batt_v'];
    if (data.containsKey('baro'))      baro        = data['baro'];
    if (data.containsKey('mil_dist'))  milDist     = data['mil_dist'];
    if (data.containsKey('mil_time'))  milTime     = data['mil_time'];
    if (data.containsKey('poll_hz'))   pollHz      = data['poll_hz'];

    _checkAlerts();
    notifyListeners();
  }

  void setConnection(bool conn, {String status = '', String error = ''}) {
    connected = conn;
    if (status.isNotEmpty) bleStatus = status;
    if (error.isNotEmpty)  bleError  = error;
    if (conn) {
      tripStart    = DateTime.now();
      tripMaxRpm   = 0;
      tripMaxSpeed = 0;
    }
    notifyListeners();
  }

  void setBleStatus(String s) {
    bleStatus = s;
    notifyListeners();
  }

  void toggleTheme() {
    isDarkTheme = !isDarkTheme;
    savePrefs();
    notifyListeners();
  }

  void toggleVehicleMode() {
    isBikeMode = !isBikeMode;
    savePrefs();
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _pushHistory(List<double> list, double val) {
    list.removeAt(0);
    list.add(val);
  }

  void _checkAlerts() {
    _setAlert('⚠ COOLANT HIGH ${coolant}°C',
        coolant > alertCoolant);
    _setAlert('⚠ BATTERY LOW ${battVoltage.toStringAsFixed(1)}V',
        battVoltage > 0.1 && battVoltage < alertBattLo);
    _setAlert('⚠ STFT ${stft > 0 ? '+' : ''}${stft.toStringAsFixed(1)}%',
        stft.abs() > alertStft);
    _setAlert('⚠ LTFT ${ltft > 0 ? '+' : ''}${ltft.toStringAsFixed(1)}%',
        ltft.abs() > alertLtft);
  }

  void _setAlert(String msg, bool active) {
    if (active && !alerts.contains(msg)) {
      alerts.add(msg);
      if (alerts.length > 5) alerts.removeAt(0);
    } else if (!active) {
      alerts.removeWhere((a) => a.startsWith(msg.substring(0, 8)));
    }
  }

  String get tripDuration {
    final d = DateTime.now().difference(tripStart);
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  bool get isClosedLoop => coolant > 70 && o2Voltage > 0.1;
}
