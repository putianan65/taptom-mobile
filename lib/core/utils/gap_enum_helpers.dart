enum RiskLevel {
  LOW('ต่ำ (Low)', 'LOW'),
  MEDIUM('กลาง (Medium)', 'MEDIUM'),
  HIGH('สูง (High)', 'HIGH');

  final String displayText;
  final String apiValue;
  const RiskLevel(this.displayText, this.apiValue);
  
  static String? toApi(String? displayText) {
    if (displayText == null || displayText.isEmpty) return null;
    try {
      return RiskLevel.values
          .firstWhere((e) => e.displayText == displayText)
          .apiValue;
    } catch (_) {
      return null;
    }
  }
  
  static String? fromApi(String? apiValue) {
    if (apiValue == null) return null;
    try {
      return RiskLevel.values
          .firstWhere((e) => e.apiValue == apiValue)
          .displayText;
    } catch (_) {
      return null;
    }
  }
}
