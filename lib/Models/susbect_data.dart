class SusbectData {
  final String name;
  final String alibi;
  final String motive;
  final String gender;
  final String relation;
  final String personality;

  SusbectData(
      {required this.name,
      required this.alibi,
      required this.motive,
      required this.gender,
      required this.personality,
      required this.relation});

  factory SusbectData.fromMap(Map<String, dynamic> map) {
    return SusbectData(
      name: map['name'] ?? '',
      alibi: map['alibi'] ?? '',
      motive: map['motive'] ?? '',
      gender: map['gender'] ?? '',
      relation: map['relation'] ?? '',
      personality: map['personality'] ?? '',
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'alibi': alibi,
      'motive': motive,
      'gender': gender,
      'relation': relation,
      'personality': personality,
    };
  }
}
