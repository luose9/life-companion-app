/// 灵感与思考
class Inspiration {
  int? id;
  String recordType;   // idea, book_note, thought
  String? content;
  String? source;      // 来源（书名、场景等）
  String? tags;        // 逗号分隔
  int? timestamp;

  Inspiration({
    this.id,
    required this.recordType,
    this.content,
    this.source,
    this.tags,
    this.timestamp,
  });

  factory Inspiration.fromMap(Map<String, dynamic> m) => Inspiration(
        id: m['id'] as int?,
        recordType: m['record_type'] as String? ?? 'idea',
        content: m['content'] as String?,
        source: m['source'] as String?,
        tags: m['tags'] as String?,
        timestamp: m['timestamp'] as int?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'record_type': recordType,
        'content': content,
        'source': source,
        'tags': tags,
        'timestamp': timestamp,
      };

  static const typeLabels = {
    'idea': '💡 灵感',
    'book_note': '📖 读书笔记',
    'thought': '🤔 人生思考',
  };
}
