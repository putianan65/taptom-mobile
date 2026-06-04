import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/analytics_model.dart';

class UserTrendsChart extends StatelessWidget {
  final List<UserTrendsData> data;
  /// If true, uses dark luxury theme (Super Admin). 
  /// If false, uses light admin-friendly theme.
  final bool isDarkMode;

  const UserTrendsChart({
    super.key, 
    required this.data,
    this.isDarkMode = false, // Default to light mode (Admin)
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'ไม่พบข้อมูล',
          style: GoogleFonts.prompt(
            color: isDarkMode ? LuxuryTheme.textDisabled : Colors.grey[500],
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    // Sort by date
    final sortedData = List<UserTrendsData>.from(data)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calculate dynamic maxY
    final maxY = sortedData.fold(0, (max, e) => e.count > max ? e.count : max).toDouble();
    final interval = maxY > 0 ? (maxY / 5) : 1.0;

    // Theme-aware colors
    final accentColor = isDarkMode ? LuxuryTheme.cyanNeon : AppColors.adminPrimary;
    final titleColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? LuxuryTheme.textSecondary : Colors.black54;
    final axisLabelColor = isDarkMode ? LuxuryTheme.textSecondary : Colors.grey[600]!;
    final gridLineColor = isDarkMode 
        ? Colors.white.withOpacity(0.05) 
        : Colors.grey.withOpacity(0.15);
    final badgeBgColor = isDarkMode 
        ? LuxuryTheme.cyanNeon.withOpacity(0.1) 
        : accentColor.withOpacity(0.1);
    final badgeBorderColor = isDarkMode 
        ? LuxuryTheme.cyanNeon.withOpacity(0.3) 
        : accentColor.withOpacity(0.3);
    final containerColor = isDarkMode 
        ? LuxuryTheme.glassSurface 
        : Colors.white;
    final containerBorder = isDarkMode 
        ? LuxuryTheme.glassBorder 
        : AppColors.border;
    final tooltipBg = isDarkMode 
        ? LuxuryTheme.midnightBlue.withOpacity(0.9) 
        : Colors.white.withOpacity(0.95);
    final tooltipBorder = isDarkMode 
        ? LuxuryTheme.glassBorder 
        : Colors.grey.withOpacity(0.2);
    final tooltipDateColor = isDarkMode ? LuxuryTheme.textSecondary : Colors.grey[600]!;
    final tooltipValueColor = isDarkMode ? Colors.white : Colors.black87;

    Widget chart = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: containerBorder),
        boxShadow: isDarkMode ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'การเติบโต',
                    style: GoogleFonts.prompt(
                      fontSize: 12,
                      color: subtitleColor,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ผู้ใช้งานใหม่',
                    style: GoogleFonts.prompt(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeBorderColor),
                ),
                child: Text(
                  '+${sortedData.last.count} รายใหม่',
                  style: GoogleFonts.prompt(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: gridLineColor,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedData.length) {
                          int jump = (sortedData.length / 5).ceil();
                          if (jump < 1) jump = 1;
                          
                          if (index % jump == 0 || index == sortedData.length - 1) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                _formatDateShortTh(sortedData[index].date),
                                style: GoogleFonts.prompt(
                                  color: axisLabelColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (sortedData.length - 1).toDouble(),
                minY: 0,
                maxY: maxY * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: sortedData.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.count.toDouble());
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: accentColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    shadow: Shadow(
                      color: accentColor,
                      blurRadius: isDarkMode ? 10 : 4,
                    ),
                    dotData: FlDotData(
                      show: false,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accentColor.withOpacity(isDarkMode ? 0.2 : 0.15),
                          accentColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(color: accentColor.withOpacity(0.5), strokeWidth: 2, dashArray: [5, 5]),
                        FlDotData(
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: isDarkMode ? Colors.white : Colors.white,
                              strokeWidth: 3,
                              strokeColor: accentColor,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final index = touchedSpot.x.toInt();
                        final data = sortedData[index];
                        final dateStr = _formatDateFullTh(data.date);
                        return LineTooltipItem(
                          '$dateStr\n',
                          GoogleFonts.prompt(
                            color: tooltipDateColor,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: '${touchedSpot.y.toInt()} คน',
                              style: GoogleFonts.prompt(
                                color: tooltipValueColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ]
                        );
                      }).toList();
                    },
                    getTooltipColor: (_) => tooltipBg,
                    tooltipBorderRadius: BorderRadius.circular(12),
                    tooltipPadding: const EdgeInsets.all(12),
                    tooltipBorder: BorderSide(color: tooltipBorder),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Only use glass effect in dark mode
    if (isDarkMode) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: chart,
        ),
      );
    }
    
    return chart;
  }

  String _formatDateShortTh(DateTime date) {
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatDateFullTh(DateTime date) {
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }
}
