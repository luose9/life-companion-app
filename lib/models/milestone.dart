/// 人生里程碑
class Milestone {
  int? id;
  String title;
  String? description;
  String? category;    // career, education, travel, love, achievement, other
  String? imagePath;
  int? eventDate;      // 事件日期ms
  int? createdAt;

  Milestone({
    this.id,
    required this.title,
    this.description,
    this.category,
    this.imagePath,
    this.eventDate,
    this.createdAt,
  });

  factory Milestone.fromMap(Map<String, dynamic> m) => Milestone(
        id: m['id'] as int?,
        title: m['title'] as String,
        description: m['description'] as String?,
        category: m['category'] as String?,
        imagePath: m['image_path'] as String?,
        eventDate: m['event_date'] as int?,
        createdAt: m['created_at'] as int?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'description': description,
        'category': category,
        'image_path': imagePath,
        'event_date': eventDate,
        'created_at': createdAt,
      };

  static const categoryLabels = {
    'career': '💼 事业',
    'education': '🎓 学业',
    'travel': '✈️ 旅行',
    'love': '❤️ 感情',
    'achievement': '🏆 成就',
    'other': '🌟 其他',
  };
}
