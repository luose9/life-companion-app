/// 小确幸与感恩
class Gratitude {
  int? id;
  String recordType;   // joy, gratitude
  String? content;
  String? imagePath;
  int? timestamp;

  Gratitude({
    this.id,
    required this.recordType,
    this.content,
    this.imagePath,
    this.timestamp,
  });

  factory Gratitude.fromMap(Map<String, dynamic> m) => Gratitude(
        id: m['id'] as int?,
        recordType: m['record_type'] as String? ?? 'joy',
        content: m['content'] as String?,
        imagePath: m['image_path'] as String?,
        timestamp: m['timestamp'] as int?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'record_type': recordType,
        'content': content,
        'image_path': imagePath,
        'timestamp': timestamp,
      };
}
