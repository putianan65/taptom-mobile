import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class GapStatusPieChart extends StatefulWidget {
  final int approvedCount;
  final int pendingCount;
  final String title;
  final String approvedLabel;
  final String pendingLabel;

  const GapStatusPieChart({
    super.key,
    required this.approvedCount,
    required this.pendingCount,
    this.title = 'สถานะผู้ใช้งาน',
    this.approvedLabel = 'อนุมัติแล้ว',
    this.pendingLabel = 'รออนุมัติ',
  });

  @override
  State<GapStatusPieChart> createState() => _GapStatusPieChartState();
}

class _GapStatusPieChartState extends State<GapStatusPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: LuxuryTheme.glassSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: LuxuryTheme.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title.toUpperCase(),
                style: GoogleFonts.prompt(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: LuxuryTheme.cyanNeon,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection == null) {
                                      touchedIndex = -1;
                                      return;
                                    }
                                    touchedIndex = pieTouchResponse
                                        .touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 4, // Spacing between sections
                              centerSpaceRadius: 50, // Donut hole
                              sections: showingSections(),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                               Text(
                                '${((widget.approvedCount / ((widget.approvedCount + widget.pendingCount) == 0 ? 1 : (widget.approvedCount + widget.pendingCount))) * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                               Text(
                                'รวม',
                                style: GoogleFonts.prompt(
                                  fontSize: 10,
                                  color: LuxuryTheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Indicator(
                        color: LuxuryTheme.emeraldNeon,
                        text: 'อนุมัติแล้ว', // Tech name for Approved
                        subText: 'ใช้งานปกติ',
                        value: '${widget.approvedCount}',
                        isSquare: false,
                      ),
                      const SizedBox(height: 24),
                      _Indicator(
                        color: LuxuryTheme.goldNeon,
                        text: 'รอตรวจสอบ', // Tech name for Pending
                        subText: 'รอดำเนินการ',
                        value: '${widget.pendingCount}',
                        isSquare: false,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    final total = widget.approvedCount + widget.pendingCount;
    // Avoid division by zero
    final safeTotal = total == 0 ? 1 : total;

    return List.generate(2, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 0.0; // Hide percentage on chart, use center or tooltip
      final radius = isTouched ? 35.0 : 25.0; // Thinner donut
      final shadows = isTouched ? [const Shadow(color: Colors.black, blurRadius: 10)] : <Shadow>[];

      switch (i) {
        case 0:
          final value = widget.approvedCount.toDouble();
          return PieChartSectionData(
            color: LuxuryTheme.emeraldNeon,
            value: value,
            title: '',
            radius: radius,
            titleStyle: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
             badgeWidget: isTouched ? _buildBadge(LuxuryTheme.emeraldNeon, value.toInt()) : null,
             badgePositionPercentageOffset: 1.3,
          );
        case 1:
          final value = widget.pendingCount.toDouble();
          return PieChartSectionData(
            color: LuxuryTheme.goldNeon,
            value: value,
            title: '',
            radius: radius,
            titleStyle: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
             badgeWidget: isTouched ? _buildBadge(LuxuryTheme.goldNeon, value.toInt()) : null,
             badgePositionPercentageOffset: 1.3,
          );
        default:
          throw Error();
      }
    });
  }
  
   Widget _buildBadge(Color color, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: LuxuryTheme.midnightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
          )
        ]
      ),
      child: Text(
        '$value',
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final String subText;
  final String value;
  final bool isSquare;
  final double size;
  final Color textColor;

  const _Indicator({
    required this.color,
    required this.text,
    required this.subText,
    required this.value,
    this.isSquare = true,
    this.size = 12, // Diamond shape size
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Diamond Indicator
        Transform.rotate(
          angle: 0.785398, // 45 degrees
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              boxShadow: [
                 BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                 )
              ]
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: GoogleFonts.prompt(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subText,
              style: GoogleFonts.prompt(
                fontSize: 10,
                letterSpacing: 0.5,
                color: LuxuryTheme.textSecondary,
              ),
            ),
          ],
        )
      ],
    );
  }
}
