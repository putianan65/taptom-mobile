
class GapAnalytics {
  final int totalPlots;
  final int plotsWithGap;
  final double completionRate;

  GapAnalytics({
    required this.totalPlots,
    required this.plotsWithGap,
    required this.completionRate,
  });

  factory GapAnalytics.fromJson(Map<String, dynamic> json) {
    return GapAnalytics(
      totalPlots: json['totalPlots'] as int? ?? 0,
      plotsWithGap: json['plotsWithGap'] as int? ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class UserTrendsData {
  final DateTime date;
  final int count;

  UserTrendsData({required this.date, required this.count});

  factory UserTrendsData.fromJson(Map<String, dynamic> json) {
    return UserTrendsData(
      date: DateTime.parse(json['date'] as String),
      count: json['count'] as int? ?? 0,
    );
  }
}
