// lib/parsers/obd_parsers.dart
// All OBD-II PID parsing logic ported from Python

class OBDParsers {
  // ── Clean raw BLE buffer ──────────────────────────────────────────────────
  static String cleanBuf(String buf) {
    return buf
        .replaceAll('\r', '')
        .replaceAll('\n', '')
        .replaceAll('>', '')
        .replaceAll(' ', '')
        .toUpperCase()
        .trim();
  }

  // ── Extract PID response bytes ────────────────────────────────────────────
  static String? extractPid(String pid, String buf, int nibbles) {
    buf = cleanBuf(buf);
    final tag = '41${pid.toUpperCase()}';
    final i = buf.lastIndexOf(tag);
    if (i == -1) return null;
    final start = i + tag.length;
    if (start + nibbles > buf.length) return null;
    final chunk = buf.substring(start, start + nibbles);
    if (chunk.length != nibbles) return null;
    try {
      int.parse(chunk, radix: 16);
      return chunk;
    } catch (_) {
      return null;
    }
  }

  // ── Individual parsers ────────────────────────────────────────────────────

  static int? parseRpm(String buf) {
    final d = extractPid('0C', buf, 4);
    if (d == null) return null;
    final a = int.parse(d.substring(0, 2), radix: 16);
    final b = int.parse(d.substring(2, 4), radix: 16);
    return ((a * 256) + b) ~/ 4;
  }

  static int? parseSpeed(String buf) {
    final d = extractPid('0D', buf, 2);
    return d != null ? int.parse(d, radix: 16) : null;
  }

  static double? parsePercent(String pid, String buf) {
    final d = extractPid(pid, buf, 2);
    return d != null
        ? double.parse((int.parse(d, radix: 16) * 100 / 255).toStringAsFixed(1))
        : null;
  }

  static int? parseTemp(String pid, String buf) {
    final d = extractPid(pid, buf, 2);
    return d != null ? int.parse(d, radix: 16) - 40 : null;
  }

  static double? parseTiming(String buf) {
    final d = extractPid('0E', buf, 2);
    return d != null
        ? double.parse(
            ((int.parse(d, radix: 16) / 2) - 64).toStringAsFixed(1))
        : null;
  }

  static int? parseMap(String buf) {
    final d = extractPid('0B', buf, 2);
    return d != null ? int.parse(d, radix: 16) : null;
  }

  static double? parseMaf(String buf) {
    final d = extractPid('10', buf, 4);
    if (d == null) return null;
    final a = int.parse(d.substring(0, 2), radix: 16);
    final b = int.parse(d.substring(2, 4), radix: 16);
    return double.parse(
        (((a * 256) + b) / 100).toStringAsFixed(2));
  }

  static double? parseFuelTrim(String pid, String buf) {
    final d = extractPid(pid, buf, 2);
    return d != null
        ? double.parse(
            ((int.parse(d, radix: 16) / 128.0 - 1.0) * 100)
                .toStringAsFixed(1))
        : null;
  }

  static double? parseO2Voltage(String buf) {
    final d = extractPid('14', buf, 4);
    return d != null
        ? double.parse(
            (int.parse(d.substring(0, 2), radix: 16) / 200.0)
                .toStringAsFixed(3))
        : null;
  }

  static int? parseBaro(String buf) {
    final d = extractPid('33', buf, 2);
    return d != null ? int.parse(d, radix: 16) : null;
  }

  static double? parseBattVoltage(String buf) {
    final d = extractPid('42', buf, 4);
    if (d == null) return null;
    final a = int.parse(d.substring(0, 2), radix: 16);
    final b = int.parse(d.substring(2, 4), radix: 16);
    return double.parse(
        (((a * 256) + b) / 1000.0).toStringAsFixed(2));
  }

  static int? parseMilDist(String buf) {
    final d = extractPid('21', buf, 4);
    if (d == null) return null;
    return (int.parse(d.substring(0, 2), radix: 16) * 256) +
        int.parse(d.substring(2, 4), radix: 16);
  }

  static int? parseMilTime(String buf) {
    final d = extractPid('4D', buf, 4);
    if (d == null) return null;
    return (int.parse(d.substring(0, 2), radix: 16) * 256) +
        int.parse(d.substring(2, 4), radix: 16);
  }

  static double? parseRelTps(String buf) {
    final d = extractPid('45', buf, 2);
    return d != null
        ? double.parse(
            (int.parse(d, radix: 16) * 100 / 255).toStringAsFixed(1))
        : null;
  }

  // ── DTC decoder ──────────────────────────────────────────────────────────
  static List<String> decodeDtcs(String raw) {
    raw = cleanBuf(raw);
    final codes = <String>[];
    for (final ph in ['43', '47']) {
      final idx = raw.indexOf(ph);
      if (idx == -1) continue;
      final data = raw.substring(idx + 2);
      for (int i = 0; i + 4 <= data.length; i += 4) {
        final chunk = data.substring(i, i + 4);
        if (chunk.length != 4) continue;
        try {
          final b1 = int.parse(chunk.substring(0, 2), radix: 16);
          final b2 = int.parse(chunk.substring(2, 4), radix: 16);
          if (b1 == 0 && b2 == 0) continue;
          const prefixes = ['P', 'C', 'B', 'U'];
          final pre = prefixes[(b1 >> 6) & 3];
          final code =
              '$pre${(b1 & 0x3F).toRadixString(16).padLeft(2, '0').toUpperCase()}${b2.toRadixString(16).padLeft(2, '0').toUpperCase()}';
          if (!codes.contains(code)) codes.add(code);
        } catch (_) {}
      }
    }
    return codes;
  }

  // ── Count supported PIDs ─────────────────────────────────────────────────
  static int countSupportedPids(String buf) {
    final d = extractPid('00', buf, 8);
    if (d == null) return 0;
    final bits = int.parse(d, radix: 16);
    int count = 0;
    for (int i = 0; i < 32; i++) {
      if (bits & (1 << (31 - i)) != 0) count++;
    }
    return count;
  }

  static String parseFuelStatus(String buf) {
    final d = extractPid('03', buf, 4);
    if (d == null) return 'Unknown';
    const map = {
      '01': 'Open Loop (Fault)',
      '02': 'Closed Loop',
      '04': 'Open Loop (Load)',
      '08': 'Open Loop (Sys Fail)',
      '10': 'Closed Loop (Fault)',
    };
    return map[d.substring(0, 2)] ?? '0x${d.substring(0, 2)}';
  }

  static String parseObdStd(String buf) {
    final d = extractPid('1C', buf, 2);
    if (d == null) return 'Unknown';
    const map = {
      '01': 'OBD-II (CARB)',
      '02': 'OBD (EPA)',
      '06': 'EOBD',
      '07': 'EOBD + OBD-II',
      '0A': 'JOBD',
    };
    return map[d.toUpperCase()] ?? 'Std 0x$d';
  }

  // ── Gear estimator (R15 V3) ───────────────────────────────────────────────
  static String estimateGear(int rpm, int speedKmh) {
    if (rpm < 500 || speedKmh < 5) return 'N';
    const ratios = [0.0, 0.0260, 0.0455, 0.0630, 0.0790, 0.0930, 0.1055];
    final ratio = speedKmh / rpm;
    int best = 1;
    double bestDiff = double.infinity;
    for (int g = 1; g <= 6; g++) {
      final diff = (ratios[g] - ratio).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = g;
      }
    }
    return best.toString();
  }
}

// ── DTC descriptions ─────────────────────────────────────────────────────────
const Map<String, String> kDtcDesc = {
  'P0100': 'MAF Circuit Malfunction',
  'P0107': 'MAP Circuit Low',
  'P0108': 'MAP Circuit High',
  'P0110': 'IAT Circuit Malfunction',
  'P0115': 'Coolant Temp Circuit',
  'P0117': 'ECT Circuit Low',
  'P0118': 'ECT Circuit High',
  'P0120': 'TPS Malfunction',
  'P0121': 'TPS Range/Performance',
  'P0130': 'O2 Sensor Malfunction B1S1',
  'P0131': 'O2 Sensor Low Voltage',
  'P0132': 'O2 Sensor High Voltage',
  'P0133': 'O2 Sensor Slow Response',
  'P0171': 'System Too Lean',
  'P0172': 'System Too Rich',
  'P0201': 'Injector Cyl 1',
  'P0202': 'Injector Cyl 2',
  'P0203': 'Injector Cyl 3',
  'P0204': 'Injector Cyl 4',
  'P0300': 'Random Misfire',
  'P0301': 'Cylinder 1 Misfire',
  'P0302': 'Cylinder 2 Misfire',
  'P0303': 'Cylinder 3 Misfire',
  'P0304': 'Cylinder 4 Misfire',
  'P0335': 'CKP Sensor A Circuit',
  'P0340': 'CMP Sensor A Circuit',
  'P0420': 'Catalyst Efficiency Low',
  'P0442': 'EVAP Small Leak',
  'P0455': 'EVAP Large Leak',
  'P0500': 'VSS Malfunction',
  'P0505': 'Idle Control Malfunction',
  'P0700': 'TCM Malfunction',
};
