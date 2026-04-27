// lib/widgets/ew_widgets.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';

// ── Metric Card ───────────────────────────────────────────────────────────────
class EWCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color? valueColor;
  final EWTheme t;

  const EWCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.t,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: t.card,
        border: Border.all(color: t.border, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title.toUpperCase(),
              style: TextStyle(color: t.muted, fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? t.text,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace')),
          Text(unit,
              style: TextStyle(color: t.muted, fontSize: 9)),
        ],
      ),
    );
  }
}

// ── Arc Gauge (RPM) ───────────────────────────────────────────────────────────
class ArcGauge extends StatefulWidget {
  final double value;
  final double minVal;
  final double maxVal;
  final double redline;
  final String label;
  final EWTheme t;
  final double size;

  const ArcGauge({
    super.key,
    required this.value,
    required this.maxVal,
    required this.t,
    this.minVal = 0,
    this.redline = 10500,
    this.label = 'RPM',
    this.size = 280,
  });

  @override
  State<ArcGauge> createState() => _ArcGaugeState();
}

class _ArcGaugeState extends State<ArcGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _displayed = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
  }

  @override
  void didUpdateWidget(ArcGauge old) {
    super.didUpdateWidget(old);
    if ((widget.value - _displayed).abs() > 1) {
      _anim = Tween<double>(begin: _displayed, end: widget.value)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _anim.addListener(() => setState(() => _displayed = _anim.value));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _ArcPainter(
          value: _displayed,
          minVal: widget.minVal,
          maxVal: widget.maxVal,
          redline: widget.redline,
          label: widget.label,
          t: widget.t,
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double value, minVal, maxVal, redline;
  final String label;
  final EWTheme t;

  _ArcPainter({
    required this.value, required this.minVal,
    required this.maxVal, required this.redline,
    required this.label, required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final ro = size.width / 2 - 12;
    final ri = ro - 28;
    final rm = (ro + ri) / 2;
    final aw = ro - ri;

    final bgPaint = Paint()
      ..color = t.panel
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), ro, bgPaint);

    final borderPaint = Paint()
      ..color = t.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), ro, borderPaint);

    // redline zone
    final rlPct = (redline - minVal) / (maxVal - minVal);
    final rlPaint = Paint()
      ..color = EWColors.red.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = aw
      ..strokeCap = StrokeCap.butt;
    final rlStart = _degToRad(225 - 270 * rlPct);
    final rlSweep = _degToRad(-270 * (1 - rlPct));
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: rm),
        rlStart, rlSweep, false, rlPaint);

    // tick marks
    for (int i = 0; i < 9; i++) {
      final a = _degToRad(225 - i * 33.75);
      final r1 = ro - 4;
      final r2 = ro - (i % 2 == 0 ? 18 : 10);
      final tickPaint = Paint()
        ..color = i % 2 == 0 ? t.accent : t.border
        ..strokeWidth = i % 2 == 0 ? 2 : 1;
      canvas.drawLine(
        Offset(cx + r1 * cos(a), cy - r1 * sin(a)),
        Offset(cx + r2 * cos(a), cy - r2 * sin(a)),
        tickPaint,
      );
    }

    // tick labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < 9; i += 2) {
      final a = _degToRad(225 - i * 33.75);
      final rl = ro - 38;
      final val = minVal + (maxVal - minVal) * i / 8;
      final txt = val >= 1000 ? '${(val / 1000).toStringAsFixed(0)}k' : val.toInt().toString();
      tp.text = TextSpan(
          text: txt,
          style: TextStyle(color: t.muted, fontSize: 9,
              fontWeight: FontWeight.bold));
      tp.layout();
      tp.paint(canvas,
          Offset(cx + rl * cos(a) - tp.width / 2,
              cy - rl * sin(a) - tp.height / 2));
    }

    // center hole
    final holePaint = Paint()..color = t.bg;
    canvas.drawCircle(Offset(cx, cy), ri - 20, holePaint);

    // value arc
    final pct = ((value - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);
    if (pct > 0.001) {
      final arcColor = pct < 0.6 ? t.accent : pct < 0.82 ? EWColors.yellow : EWColors.red;
      final arcPaint = Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = aw
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: rm),
          _degToRad(225),
          _degToRad(-270 * pct),
          false,
          arcPaint);
    }

    // center value text
    final valTp = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
          text: value.toInt().toString(),
          style: TextStyle(
              color: t.accent,
              fontSize: 44,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace'))
      ..layout();
    valTp.paint(canvas,
        Offset(cx - valTp.width / 2, cy - valTp.height / 2 - 10));

    final lblTp = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
          text: label,
          style: TextStyle(color: t.muted, fontSize: 11,
              fontWeight: FontWeight.bold))
      ..layout();
    lblTp.paint(canvas,
        Offset(cx - lblTp.width / 2, cy + valTp.height / 2 + 2));
  }

  double _degToRad(double d) => d * pi / 180;

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.value != value || old.t.dark != t.dark;
}

// ── Speed Needle Gauge ────────────────────────────────────────────────────────
class SpeedGauge extends StatefulWidget {
  final double value;
  final double maxVal;
  final EWTheme t;
  final double size;

  const SpeedGauge({
    super.key,
    required this.value,
    required this.maxVal,
    required this.t,
    this.size = 200,
  });

  @override
  State<SpeedGauge> createState() => _SpeedGaugeState();
}

class _SpeedGaugeState extends State<SpeedGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  double _displayed = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
  }

  @override
  void didUpdateWidget(SpeedGauge old) {
    super.didUpdateWidget(old);
    if ((widget.value - _displayed).abs() > 0.5) {
      final anim = Tween<double>(begin: _displayed, end: widget.value)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      anim.addListener(() => setState(() => _displayed = anim.value));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.size,
    height: widget.size,
    child: CustomPaint(
      painter: _SpeedPainter(
          value: _displayed, maxVal: widget.maxVal, t: widget.t),
    ),
  );
}

class _SpeedPainter extends CustomPainter {
  final double value, maxVal;
  final EWTheme t;
  _SpeedPainter({required this.value, required this.maxVal, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 10;

    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = t.panel..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = t.border..style = PaintingStyle.stroke..strokeWidth = 2);

    for (int i = 0; i < 5; i++) {
      final a = _r(225 - i * 67.5);
      final rl = r - 26;
      final val = (maxVal * i / 4).toInt();
      final tp = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(text: val.toString(),
            style: TextStyle(color: t.muted, fontSize: 9,
                fontWeight: FontWeight.bold))
        ..layout();
      tp.paint(canvas, Offset(cx + rl * cos(a) - tp.width / 2,
          cy - rl * sin(a) - tp.height / 2));
    }

    // pivot
    canvas.drawCircle(Offset(cx, cy), 12,
        Paint()..color = t.accent2..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx, cy), 12,
        Paint()..color = t.accent..style = PaintingStyle.stroke..strokeWidth = 2);

    // needle
    final pct = (value / maxVal).clamp(0.0, 1.0);
    final a = _r(225 - 270 * pct);
    final col = pct < 0.7 ? t.accent : pct < 0.9 ? EWColors.yellow : EWColors.red;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + (r - 14) * cos(a), cy - (r - 14) * sin(a)),
      Paint()..color = col..strokeWidth = 3..strokeCap = StrokeCap.round,
    );

    // value
    final tp = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
          text: value.toInt().toString(),
          style: TextStyle(color: t.text, fontSize: 16,
              fontWeight: FontWeight.bold, fontFamily: 'monospace'))
      ..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy + 20));

    final utp = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(text: 'km/h',
          style: TextStyle(color: t.muted, fontSize: 9))
      ..layout();
    utp.paint(canvas, Offset(cx - utp.width / 2, cy + 42));
  }

  double _r(double d) => d * pi / 180;

  @override
  bool shouldRepaint(_SpeedPainter o) =>
      o.value != value || o.t.dark != t.dark;
}

// ── TPS Vertical Bar ──────────────────────────────────────────────────────────
class TpsBar extends StatelessWidget {
  final double value;
  final EWTheme t;
  final double width;
  final double height;

  const TpsBar({super.key, required this.value,
    required this.t, this.width = 52, this.height = 220});

  @override
  Widget build(BuildContext context) {
    final pct = (value / 100).clamp(0.0, 1.0);
    final color = pct < 0.6 ? t.accent : pct < 0.85 ? EWColors.yellow : EWColors.red;
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: t.dim,
              border: Border.all(color: t.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: width - 4,
                  height: (height - 4) * pct,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text('${value.toStringAsFixed(0)}%',
              style: TextStyle(color: t.muted, fontSize: 9,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── Coolant Bar ───────────────────────────────────────────────────────────────
class CoolantBar extends StatelessWidget {
  final int value;
  final EWTheme t;
  final double width;

  const CoolantBar({super.key, required this.value,
    required this.t, this.width = 300});

  @override
  Widget build(BuildContext context) {
    final pct = ((value + 40) / 190.0).clamp(0.0, 1.0);
    final color = pct < 0.3
        ? t.accent2
        : pct < 0.7 ? EWColors.green : EWColors.red;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              width: width, height: 24,
              decoration: BoxDecoration(
                color: t.dim,
                border: Border.all(color: t.border),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: width * pct,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(
              width: width,
              height: 24,
              child: Center(
                child: Text('$value°C',
                    style: TextStyle(
                        color: pct > 0.15 ? t.bg : t.text,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('COLD', style: TextStyle(color: t.muted, fontSize: 8)),
              Text('WARM', style: TextStyle(color: t.muted, fontSize: 8)),
              Text('HOT',  style: TextStyle(color: t.muted, fontSize: 8)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Fuel Trim Bar ─────────────────────────────────────────────────────────────
class FuelTrimBar extends StatelessWidget {
  final double value;
  final String label;
  final EWTheme t;
  final double width;

  const FuelTrimBar({super.key, required this.value,
    required this.label, required this.t, this.width = 280});

  @override
  Widget build(BuildContext context) {
    final pct = (value / 25.0).clamp(-1.0, 1.0);
    final color = pct.abs() < 0.4
        ? EWColors.green
        : pct.abs() < 0.7 ? EWColors.yellow : EWColors.red;
    final barW = (width / 2 * pct.abs()).clamp(0.0, width / 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              width: width, height: 20,
              decoration: BoxDecoration(
                color: t.dim,
                border: Border.all(color: t.border),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            if (pct.abs() > 0.01)
              Positioned(
                left: pct > 0 ? width / 2 : (width / 2 - barW),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: barW,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            // center line
            Positioned(
              left: width / 2 - 1,
              child: Container(width: 2, height: 20, color: t.muted),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(color: t.muted, fontSize: 8,
                    fontWeight: FontWeight.bold)),
            Text('${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%',
                style: TextStyle(color: t.text, fontSize: 8,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

// ── Line Graph ────────────────────────────────────────────────────────────────
class EWGraph extends StatelessWidget {
  final List<double> data;
  final double yMin;
  final double yMax;
  final Color lineColor;
  final EWTheme t;
  final String label;
  final double height;

  const EWGraph({
    super.key,
    required this.data,
    required this.yMin,
    required this.yMax,
    required this.lineColor,
    required this.t,
    this.label = '',
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    final spots = data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.clamp(yMin, yMax)))
        .toList();

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: t.panel,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: LineChart(
        LineChartData(
          minY: yMin, maxY: yMax,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (yMax - yMin) / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: t.dim, strokeWidth: 1, dashArray: [4, 6]),
          ),
          titlesData: FlTitlesData(
            show: label.isNotEmpty,
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: label.isNotEmpty,
                getTitlesWidget: (_, __) => Text(label,
                    style: TextStyle(color: t.muted, fontSize: 8)),
              ),
            ),
            rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withOpacity(0.08),
              ),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}

// ── Gear Display ──────────────────────────────────────────────────────────────
class GearDisplay extends StatelessWidget {
  final String gear;
  final EWTheme t;

  const GearDisplay({super.key, required this.gear, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70, height: 80,
      decoration: BoxDecoration(
        color: t.card,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(gear,
            style: TextStyle(
                color: t.accent,
                fontSize: 52,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace')),
      ),
    );
  }
}

// ── Alert Banner ──────────────────────────────────────────────────────────────
class AlertBanner extends StatelessWidget {
  final List<String> alerts;

  const AlertBanner({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Container(
      color: const Color(0xFF1a0505),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: EWColors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alerts.join('   ·   '),
              style: const TextStyle(
                  color: EWColors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
