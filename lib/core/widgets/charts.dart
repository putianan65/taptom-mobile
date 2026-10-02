import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../design/design.dart';
import '../utils/thai_date.dart';
import 'pressable.dart';

/// Chart colours, validated for colour-vision deficiency and surface contrast
/// (see `docs/DESIGN.md`). Status hues are reserved for status and always
/// appear with a text label.
abstract final class ChartColors {
  static Color line(BuildContext c) =>
      c.isDark ? const Color(0xFF5E9F68) : const Color(0xFF2F7041);

  static Color approved(BuildContext c) =>
      c.isDark ? const Color(0xFF3A7D4A) : const Color(0xFF2F7041);
  static Color pending(BuildContext c) =>
      c.isDark ? const Color(0xFFB58C22) : const Color(0xFFD9A21B);
  static Color rejected(BuildContext c) =>
      c.isDark ? const Color(0xFFC24650) : const Color(0xFFB8432E);
  static Color none(BuildContext c) =>
      c.isDark ? const Color(0xFF3F4A42) : const Color(0xFFCFCDC2);
}

/// One point in a time series.
class TrendPoint {
  const TrendPoint(this.date, this.value);

  final DateTime date;
  final num value;
}

/// Single-series trend: a 2px line over a faint area wash, an end marker,
/// a crosshair tooltip and an optional table view for screen readers.
class TrendLineChart extends StatefulWidget {
  const TrendLineChart({
    super.key,
    required this.title,
    required this.points,
    this.subtitle,
    this.unit = '',
    this.height = 180,
  });

  final String title;
  final String? subtitle;
  final List<TrendPoint> points;
  final String unit;
  final double height;

  @override
  State<TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends State<TrendLineChart> {
  bool _table = false;

  static double _niceMax(double v) {
    if (v <= 4) return 4;
    final magnitude = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    for (final step in [1, 2, 2.5, 5, 10]) {
      final candidate = step * magnitude;
      if (candidate >= v) return candidate;
    }
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final points = [...widget.points]..sort((a, b) => a.date.compareTo(b.date));
    final total = points.fold<num>(0, (s, e) => s + e.value);
    final color = ChartColors.line(context);
    final maxY = _niceMax(points.fold<double>(0, (m, e) => math.max(m, e.value.toDouble())));
    final number = NumberFormat.decimalPattern('th');

    return Container(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, Space.md),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.card,
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: context.text.titleSmall),
                    if (widget.subtitle != null)
                      Text(widget.subtitle!, style: context.text.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    number.format(total),
                    style: context.text.headlineSmall?.copyWith(
                      fontFamily: AppFonts.text,
                      fontWeight: FontWeight.w700,
                    ).tabular,
                  ),
                  Text('รวม${widget.unit}', style: context.text.labelSmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          if (points.isEmpty)
            SizedBox(
              height: widget.height * 0.6,
              child: Center(
                child: Text('ยังไม่มีข้อมูลในช่วงนี้', style: context.text.bodySmall),
              ),
            )
          else if (_table)
            _TableView(points: points, unit: widget.unit)
          else
            SizedBox(
              height: widget.height,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: math.max(1, points.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (_) => FlLine(color: p.line, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(bottom: BorderSide(color: p.lineStrong)),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: maxY / 4,
                        getTitlesWidget: (v, meta) => Text(
                          number.format(v.round()),
                          style: context.text.labelSmall?.copyWith(letterSpacing: 0),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 1,
                        getTitlesWidget: (v, meta) {
                          final i = v.round();
                          if (i < 0 || i >= points.length) return const SizedBox.shrink();
                          final every = math.max(1, (points.length / 5).ceil());
                          if (i % every != 0 && i != points.length - 1) {
                            return const SizedBox.shrink();
                          }
                          final d = points[i].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${d.day} ${ThaiDate.monthsShort[d.month - 1]}',
                              style: context.text.labelSmall?.copyWith(letterSpacing: 0),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    getTouchedSpotIndicator: (bar, indexes) => [
                      for (final _ in indexes)
                        TouchedSpotIndicatorData(
                          FlLine(color: p.lineStrong, strokeWidth: 1),
                          FlDotData(
                            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                              radius: 5,
                              color: color,
                              strokeWidth: 2,
                              strokeColor: p.surface,
                            ),
                          ),
                        ),
                    ],
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => p.ink,
                      tooltipBorderRadius: BorderRadius.circular(8),
                      getTooltipItems: (spots) => [
                        for (final s in spots)
                          LineTooltipItem(
                            '${ThaiDate.short(points[s.x.round()].date)}\n',
                            context.text.labelSmall!.copyWith(color: p.inkInverse.withValues(alpha: 0.75)),
                            children: [
                              TextSpan(
                                text: '${number.format(s.y)} ${widget.unit}',
                                style: context.text.labelLarge!.copyWith(color: p.inkInverse),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < points.length; i++)
                          FlSpot(i.toDouble(), points[i].value.toDouble()),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.25,
                      preventCurveOverShooting: true,
                      color: color,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      isStrokeJoinRound: true,
                      dotData: FlDotData(
                        checkToShowDot: (spot, bar) => spot.x == bar.spots.last.x,
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 4,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: p.surface,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
                duration: Motion.slow,
                curve: Motion.emphasized,
              ),
            ),
          if (points.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _table = !_table),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(_table ? 'ดูเป็นกราฟ' : 'ดูเป็นตาราง'),
              ),
            ),
        ],
      ),
    );
  }
}

class _TableView extends StatelessWidget {
  const _TableView({required this.points, required this.unit});

  final List<TrendPoint> points;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final number = NumberFormat.decimalPattern('th');
    return Column(
      children: [
        for (final pt in points.reversed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(child: Text(ThaiDate.short(pt.date), style: context.text.bodyMedium)),
                Text(
                  '${number.format(pt.value)} $unit',
                  style: context.text.bodyMedium?.w600.tabular,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One segment of a [StatusBreakdownBar].
class StatusSegment {
  const StatusSegment(this.label, this.value, this.color);

  final String label;
  final num value;
  final Color color;
}

/// Part-to-whole for a handful of statuses: one 100% bar with 2px gaps and
/// a labelled legend that doubles as the table view.
class StatusBreakdownBar extends StatelessWidget {
  const StatusBreakdownBar({
    super.key,
    required this.title,
    required this.segments,
    this.subtitle,
    this.onTapSegment,
  });

  final String title;
  final String? subtitle;
  final List<StatusSegment> segments;
  final ValueChanged<int>? onTapSegment;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final total = segments.fold<num>(0, (s, e) => s + e.value);
    final number = NumberFormat.decimalPattern('th');

    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.card,
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleSmall),
                    if (subtitle != null) Text(subtitle!, style: context.text.bodySmall),
                  ],
                ),
              ),
              Text(
                number.format(total),
                style: context.text.headlineSmall?.copyWith(
                  fontFamily: AppFonts.text,
                  fontWeight: FontWeight.w700,
                ).tabular,
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 14,
              child: total == 0
                  ? ColoredBox(color: p.surfaceSunken)
                  : Row(
                      children: [
                        for (var i = 0; i < segments.length; i++)
                          if (segments[i].value > 0) ...[
                            Expanded(
                              flex: math.max(1, (segments[i].value / total * 1000).round()),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: context.reduceMotion ? Duration.zero : Motion.slower,
                                curve: Motion.emphasized,
                                builder: (_, t, __) => FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: t,
                                  child: ColoredBox(color: segments[i].color),
                                ),
                              ),
                            ),
                            if (i < segments.length - 1)
                              const SizedBox(width: 2),
                          ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: Space.md),
          for (var i = 0; i < segments.length; i++)
            Pressable(
              onTap: onTapSegment == null ? null : () => onTapSegment!(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: segments[i].color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(child: Text(segments[i].label, style: context.text.bodyMedium)),
                    Text(
                      number.format(segments[i].value),
                      style: context.text.bodyMedium?.w600.tabular,
                    ),
                    SizedBox(
                      width: 52,
                      child: Text(
                        total == 0 ? '-' : '${(segments[i].value / total * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: context.text.bodySmall?.tabular,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
