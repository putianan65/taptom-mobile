import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/analytics_model.dart';

class GapAnalyticsCard extends StatelessWidget {
  final GapAnalytics data;

  const GapAnalyticsCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Prevent division by zero
    final total = data.totalPlots == 0 ? 1 : data.totalPlots;
    final otherPlots = total - data.plotsWithGap;
    
    // Calculate percentage for display
    final percentage = (data.plotsWithGap / total * 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ภาพรวม GAP',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        color: AppColors.primary,
                        value: data.plotsWithGap.toDouble(),
                        title: '${percentage.toStringAsFixed(0)}%',
                        radius: 50,
                        titleStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        color: Colors.grey[200],
                        value: otherPlots.toDouble(),
                        title: '',
                        radius: 40,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ทั้งหมด',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${data.totalPlots}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildLegend(
            color: AppColors.primary,
            label: 'ได้มาตรฐาน GAP',
            value: '${data.plotsWithGap} แปลง',
          ),
          const SizedBox(height: 8),
          _buildLegend(
            color: Colors.grey[300]!,
            label: 'ยังไม่ได้มาตรฐาน',
            value: '$otherPlots แปลง',
          ),
        ],
      ),
    );
  }

  Widget _buildLegend({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
