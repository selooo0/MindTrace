class ClueModel {
  final String id;

  final String description;
  final String found_at;
  final String relevance;
  final String owner;

  ClueModel({
    required this.id,
    required this.description,
    required this.found_at,
    required this.relevance,
    required this.owner,
  });

  factory ClueModel.fromMap(Map<String, dynamic> map) {
    return ClueModel(
      id: map['clue_id'].toString(),
      description: map['description'] ?? '',
      found_at: map['found_at'] ?? '',
      relevance: map['relevance'] ?? '',
      owner: map['owner'] ?? '',
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'found_at': found_at,
      'relevance': relevance,
      'owner': owner,
    };
  }
}
