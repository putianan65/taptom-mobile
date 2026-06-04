class GapSummaryBuilder {
  static String buildGeneral(Map<String, dynamic> data) {
    final items = <String>[];
    
    if (data['farmerName'] != null) {
      items.add('👤 ${data['farmerName']}');
    }
    
    if (data['farmingSystem'] != null) {
      const systemMap = {
        'ORGANIC': 'อินทรีย์',
        'TRANSITION': 'ปรับเปลี่ยน',
        'NON_ORGANIC': 'เคมี',
      };
      final system = systemMap[data['farmingSystem']] ?? 'ไม่ระบุ';
      items.add('🌱 $system');
    }
    
    if (data['waterSource'] != null) {
      items.add('💧 ${data['waterSource']}');
    }
    
    return items.isNotEmpty ? items.join(' • ') : 'มีข้อมูล';
  }
  
  static String buildHarvest(Map<String, dynamic> data) {
    final items = <String>[];
    
    if (data['yieldAmount'] != null) {
      items.add('⚖️ ${data['yieldAmount']} ${data['yieldUnit'] ?? 'กก.'}');
    }
    
    if (data['qualityGrade'] != null) {
      items.add('⭐ ${data['qualityGrade']}');
    }
    
    return items.isNotEmpty ? items.join(' • ') : 'มีข้อมูลเก็บเกี่ยว';
  }
  
  // Placeholder for other sections - can be expanded as needed
  static String buildInputs(List<dynamic> data) {
    return 'บันทึก ${data.length} รายการ';
  }

  static String buildManagement(Map<String, dynamic> data) {
     final items = <String>[];
     if (data['action'] != null) items.add('📝 ${data['action']}');
     if (data['riskLevel'] != null) items.add('⚠️ ${data['riskLevel']}');
     return items.isNotEmpty ? items.join(' • ') : 'บันทึกข้อมูลการจัดการแปลงแล้ว';
  }

  static String buildPostHarvest(List<dynamic> data) {
    return 'บันทึก ${data.length} รายการ';
  }

  static String buildSafety(Map<String, dynamic> data) {
    return 'บันทึกข้อมูลความปลอดภัยแล้ว';
  }

  static String buildTraceability(List<dynamic> data) {
    return 'มี ${data.length} ล็อตผลผลิต';
  }
}
