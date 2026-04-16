/// 爱好记录
class Hobby {
  int? id;
  String name;
  String category;       // art, sport, craft, tech, music, reading, other
  String status;         // want_try, playing, abandoned, habit
  String? abandonReason;
  int totalSeconds;      // 累计投入秒数
  int? createdAt;
  String? note;

  Hobby({
    this.id,
    required this.name,
    this.category = 'other',
    this.status = 'want_try',
    this.abandonReason,
    this.totalSeconds = 0,
    this.createdAt,
    this.note,
  });

  factory Hobby.fromMap(Map<String, dynamic> m) => Hobby(
        id: m['id'] as int?,
        name: m['name'] as String,
        category: m['category'] as String? ?? 'other',
        status: m['status'] as String? ?? 'want_try',
        abandonReason: m['abandon_reason'] as String?,
        totalSeconds: m['total_seconds'] as int? ?? 0,
        createdAt: m['created_at'] as int?,
        note: m['note'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'status': status,
        'abandon_reason': abandonReason,
        'total_seconds': totalSeconds,
        'created_at': createdAt,
        'note': note,
      };

  static const categoryLabels = {
    'art': '艺术',
    'sport': '运动',
    'craft': '手工',
    'tech': '科技',
    'music': '音乐',
    'reading': '阅读',
    'cooking': '烹饪',
    'other': '其他',
  };

  static const statusLabels = {
    'want_try': '想尝试',
    'playing': '正在玩',
    'abandoned': '已放弃',
    'habit': '已成为习惯',
  };

  String get categoryLabel => categoryLabels[category] ?? category;
  String get statusLabel => statusLabels[status] ?? status;
}
