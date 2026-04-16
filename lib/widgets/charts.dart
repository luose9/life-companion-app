import 'dart:math' as math;
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════
//  BarChart — 垂直柱状图
// ═══════════════════════════════════════════════════════════
class BarChart extends StatefulWidget {
  final List<double> values;
  final List<String> labels;
  final List<Color>? colors;
  final double height;
  final double maxValue;

  const BarChart({
    super.key,
    required this.values,
    required this.labels,
    this.colors,
    this.height = 160,
    this.maxValue = 0,
  });

  @override
  State<BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<BarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(BarChart old) {
    super.didUpdateWidget(old);
    if (old.values != widget.values) {
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
    final maxV = widget.maxValue > 0
        ? widget.maxValue
        : (widget.values.isEmpty ? 1.0 : widget.values.reduce(math.max));
    final defaultColors = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.red, Colors.teal, Colors.amber, Colors.indigo,
    ];
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        painter: _BarPainter(
          values: widget.values,
          labels: widget.labels,
          colors: widget.colors ??
              List.generate(
                  widget.values.length, (i) => defaultColors[i % defaultColors.length]),
          maxV: maxV,
          progress: _anim.value,
        ),
        size: Size(double.infinity, widget.height),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final List<Color> colors;
  final double maxV;
  final double progress;

  _BarPainter({
    required this.values,
    required this.labels,
    required this.colors,
    required this.maxV,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const bottomPad = 32.0;
    const topPad = 12.0;
    final chartH = size.height - bottomPad - topPad;
    final barW = (size.width / values.length) * 0.55;
    final gap = size.width / values.length;

    for (int i = 0; i < values.length; i++) {
      final x = gap * i + gap / 2;
      final barH = maxV > 0 ? (values[i] / maxV) * chartH * progress : 0.0;
      final top = topPad + chartH - barH;

      // bar
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      final rr = RRect.fromRectAndCorners(
        Rect.fromLTWH(x - barW / 2, top, barW, barH),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(rr, paint);

      // value label above bar
      if (progress > 0.6 && values[i] > 0) {
        final vStr = values[i] >= 1000
            ? '${(values[i] / 1000).toStringAsFixed(1)}k'
            : values[i] % 1 == 0
                ? values[i].toInt().toString()
                : values[i].toStringAsFixed(1);
        _drawText(canvas, vStr, x, top - 14, 10,
            color: colors[i % colors.length]);
      }

      // bottom label
      _drawText(canvas, labels[i], x, size.height - bottomPad + 4, 10,
          color: Colors.grey.shade600);
    }

    // baseline
    final linePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(0, topPad + chartH), Offset(size.width, topPad + chartH), linePaint);
  }

  void _drawText(Canvas canvas, String text, double cx, double cy, double fs,
      {Color color = Colors.black87}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: fs, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy));
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.values != values || old.progress != progress;
}

// ═══════════════════════════════════════════════════════════
//  DonutChart — 环形图
// ═══════════════════════════════════════════════════════════
class DonutChart extends StatefulWidget {
  final Map<String, double> data; // label → value
  final List<Color>? colors;
  final double size;
  final String centerLabel;
  final String centerValue;

  const DonutChart({
    super.key,
    required this.data,
    this.colors,
    this.size = 160,
    this.centerLabel = '',
    this.centerValue = '',
  });

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(DonutChart old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const List<Color> _kDefault = [
    Color(0xFF4E79A7), Color(0xFFF28E2B), Color(0xFFE15759),
    Color(0xFF76B7B2), Color(0xFF59A14F), Color(0xFFEDC948),
    Color(0xFFB07AA1), Color(0xFFFF9DA7), Color(0xFF9C755F),
  ];

  @override
  Widget build(BuildContext context) {
    final cols = widget.colors ?? _kDefault;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _DonutPainter(
            data: widget.data,
            colors: cols,
            progress: _anim.value,
            centerLabel: widget.centerLabel,
            centerValue: widget.centerValue,
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Map<String, double> data;
  final List<Color> colors;
  final double progress;
  final String centerLabel;
  final String centerValue;

  _DonutPainter({
    required this.data,
    required this.colors,
    required this.progress,
    required this.centerLabel,
    required this.centerValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 4;
    final innerR = r * 0.55;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    var startAngle = -math.pi / 2;
    int i = 0;
    for (final entry in data.entries) {
      final sweep = (entry.value / total) * 2 * math.pi * progress;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweep, true, paint);
      startAngle += sweep;
      i++;
    }

    // hole
    canvas.drawCircle(Offset(cx, cy), innerR,
        Paint()..color = Colors.white..style = PaintingStyle.fill);

    // center text
    if (centerValue.isNotEmpty) {
      _drawText(canvas, centerValue, cx, cy - 9, 14, bold: true);
    }
    if (centerLabel.isNotEmpty) {
      _drawText(canvas, centerLabel, cx, cy + 7, 10,
          color: Colors.grey.shade600);
    }
  }

  void _drawText(Canvas canvas, String text, double cx, double cy, double fs,
      {bool bold = false, Color? color}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color ?? Colors.black87,
              fontSize: fs,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.data != data || old.progress != progress;
}

// ═══════════════════════════════════════════════════════════
//  LineChart — 折线图
// ═══════════════════════════════════════════════════════════
class LineChart extends StatefulWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double height;
  final bool showArea;

  const LineChart({
    super.key,
    required this.values,
    required this.labels,
    this.color = Colors.blue,
    this.height = 140,
    this.showArea = true,
  });

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(LineChart old) {
    super.didUpdateWidget(old);
    if (old.values != widget.values) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        painter: _LinePainter(
          values: widget.values,
          labels: widget.labels,
          color: widget.color,
          progress: _anim.value,
          showArea: widget.showArea,
        ),
        size: Size(double.infinity, widget.height),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double progress;
  final bool showArea;

  _LinePainter({
    required this.values,
    required this.labels,
    required this.color,
    required this.progress,
    required this.showArea,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    const bottomPad = 24.0;
    const topPad = 12.0;
    final chartH = size.height - bottomPad - topPad;
    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final range = (maxV - minV).clamp(1.0, double.infinity);

    // compute points
    final pts = <Offset>[];
    final segW = size.width / (values.length - 1);
    for (int i = 0; i < values.length; i++) {
      final x = segW * i;
      final y = topPad + chartH - ((values[i] - minV) / range) * chartH;
      pts.add(Offset(x, y));
    }

    // clip to animation progress
    final totalLen = pts.length - 1;
    final drawUpTo = (totalLen * progress).floor();
    final fraction = (totalLen * progress) - drawUpTo;

    // Area fill
    if (showArea && pts.isNotEmpty) {
      final areaPath = Path();
      areaPath.moveTo(pts[0].dx, topPad + chartH);
      areaPath.lineTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i <= math.min(drawUpTo, totalLen); i++) {
        areaPath.lineTo(pts[i].dx, pts[i].dy);
      }
      if (drawUpTo < totalLen) {
        final partial = Offset.lerp(pts[drawUpTo], pts[drawUpTo + 1], fraction)!;
        areaPath.lineTo(partial.dx, partial.dy);
        areaPath.lineTo(partial.dx, topPad + chartH);
      } else {
        areaPath.lineTo(pts[drawUpTo].dx, topPad + chartH);
      }
      areaPath.close();
      canvas.drawPath(
        areaPath,
        Paint()
          ..shader = LinearGradient(
            colors: [color.withOpacity(0.35), color.withOpacity(0.02)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, topPad, size.width, chartH))
          ..style = PaintingStyle.fill,
      );
    }

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i <= math.min(drawUpTo, totalLen); i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    if (drawUpTo < totalLen) {
      final partial = Offset.lerp(pts[drawUpTo], pts[drawUpTo + 1], fraction)!;
      path.lineTo(partial.dx, partial.dy);
    }
    canvas.drawPath(path, linePaint);

    // Dots
    for (int i = 0; i <= math.min(drawUpTo, totalLen); i++) {
      canvas.drawCircle(pts[i], 3.5,
          Paint()..color = Colors.white..style = PaintingStyle.fill);
      canvas.drawCircle(pts[i], 3.5,
          Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    // Labels
    for (int i = 0; i < values.length; i++) {
      if (i % math.max(1, (values.length / 7).ceil()) == 0 ||
          i == values.length - 1) {
        final tp = TextPainter(
          text: TextSpan(
              text: labels[i],
              style: TextStyle(color: Colors.grey.shade600, fontSize: 9)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas,
            Offset(pts[i].dx - tp.width / 2, size.height - bottomPad + 4));
      }
    }

    // baseline
    canvas.drawLine(
      Offset(0, topPad + chartH),
      Offset(size.width, topPad + chartH),
      Paint()..color = Colors.grey.shade200..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values || old.progress != progress;
}

// ═══════════════════════════════════════════════════════════
//  MoodHeatmap — 心情热图（按天）
// ═══════════════════════════════════════════════════════════
class MoodHeatmap extends StatelessWidget {
  /// key: 'yyyy-MM-dd', value: mood index 0-9 (maps to color)
  final Map<String, int> dayMoodIndex;
  final int year;
  final int month;

  const MoodHeatmap({
    super.key,
    required this.dayMoodIndex,
    required this.year,
    required this.month,
  });

  static const List<Color> _moodColors = [
    Color(0xFFFFD700), // 开心
    Color(0xFFFFA500), // 非常高兴
    Color(0xFF90EE90), // 平静
    Color(0xFF6495ED), // 难过
    Color(0xFFFF6347), // 愤怒
    Color(0xFFDDA0DD), // 焦虑
    Color(0xFFB0C4DE), // 疲惫
    Color(0xFFFF69B4), // 兴奋
    Color(0xFF708090), // 失落
    Color(0xFFFF8C94), // 感动
  ];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday % 7; // 0=Sun
    final cells = firstWeekday + daysInMonth;
    final rows = (cells / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weekday header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['日', '一', '二', '三', '四', '五', '六']
              .map((d) => SizedBox(
                    width: 32,
                    child: Text(d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade500)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        for (int r = 0; r < rows; r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (c) {
                final cellIdx = r * 7 + c;
                final day = cellIdx - firstWeekday + 1;
                if (day < 1 || day > daysInMonth) {
                  return const SizedBox(width: 32, height: 32);
                }
                final key =
                    '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                final moodIdx = dayMoodIndex[key];
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: moodIdx != null
                        ? _moodColors[moodIdx % _moodColors.length]
                            .withOpacity(0.75)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text('$day',
                        style: TextStyle(
                            fontSize: 11,
                            color: moodIdx != null
                                ? Colors.white
                                : Colors.grey.shade400,
                            fontWeight: moodIdx != null
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ChartCard — 通用容器
// ═══════════════════════════════════════════════════════════
class ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const ChartCard({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  LegendRow
// ═══════════════════════════════════════════════════════════
class LegendRow extends StatelessWidget {
  final List<String> labels;
  final List<Color> colors;

  const LegendRow({super.key, required this.labels, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: List.generate(
        math.min(labels.length, colors.length),
        (i) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colors[i],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(labels[i],
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}
