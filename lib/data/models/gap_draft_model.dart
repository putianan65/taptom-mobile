class GapDraftModel {
  final int? id;
  final String category; // e.g., 'general', 'inputs'
  final String jsonData; // The form data serialized
  final String lastUpdated;

  GapDraftModel({
    this.id,
    required this.category,
    required this.jsonData,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'jsonData': jsonData,
      'lastUpdated': lastUpdated,
    };
  }

  factory GapDraftModel.fromMap(Map<String, dynamic> map) {
    return GapDraftModel(
      id: map['id'],
      category: map['category'],
      jsonData: map['jsonData'],
      lastUpdated: map['lastUpdated'],
    );
  }
}
