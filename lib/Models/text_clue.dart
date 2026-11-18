class TextClueModel {
  final String id;
  final String description;

  final String owner;

  TextClueModel({
    required this.id,
    required this.description,
    required this.owner,
  });

  factory TextClueModel.fromMap(Map<String, dynamic> map) {
    return TextClueModel(
      id: map['id'].toString(),
      description: map['description'] ?? '',
      owner: map['owner'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'owner': owner,
    };
  }
}
