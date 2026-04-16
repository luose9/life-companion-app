/// 重要人物
class Person {
  int? id;
  String name;
  String? relationship;  // family, friend, partner, colleague, other
  String? birthday;      // MM-DD
  String? preferences;   // 喜好
  String? note;
  int? createdAt;

  Person({
    this.id,
    required this.name,
    this.relationship,
    this.birthday,
    this.preferences,
    this.note,
    this.createdAt,
  });

  factory Person.fromMap(Map<String, dynamic> m) => Person(
        id: m['id'] as int?,
        name: m['name'] as String,
        relationship: m['relationship'] as String?,
        birthday: m['birthday'] as String?,
        preferences: m['preferences'] as String?,
        note: m['note'] as String?,
        createdAt: m['created_at'] as int?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'relationship': relationship,
        'birthday': birthday,
        'preferences': preferences,
        'note': note,
        'created_at': createdAt,
      };

  static const relationshipLabels = {
    'family': '👨‍👩‍👧 家人',
    'friend': '🤝 朋友',
    'partner': '❤️ 伴侣',
    'colleague': '💼 同事',
    'other': '🌟 其他',
  };
}

/// 美好瞬间记录
class RelationshipMoment {
  int? id;
  int? personId;
  String? content;     // 做了什么
  String? note;        // 感想
  String? imagePath;   // 照片路径
  int? timestamp;

  RelationshipMoment({
    this.id,
    this.personId,
    this.content,
    this.note,
    this.imagePath,
    this.timestamp,
  });

  factory RelationshipMoment.fromMap(Map<String, dynamic> m) => RelationshipMoment(
        id: m['id'] as int?,
        personId: m['person_id'] as int?,
        content: m['content'] as String?,
        note: m['note'] as String?,
        imagePath: m['image_path'] as String?,
        timestamp: m['timestamp'] as int?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'person_id': personId,
        'content': content,
        'note': note,
        'image_path': imagePath,
        'timestamp': timestamp,
      };
}
