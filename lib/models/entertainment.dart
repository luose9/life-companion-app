/// 娱乐/音乐感受记录
class Entertainment {
  int? id;
  String mediaType;   // movie、tv、music、book、game、other
  String title;
  String? creator;    // 导演/歌手/作者
  double? rating;     // 1-10
  String? feeling;    // 观后感/听后感
  String? tags;       // 逗号分隔标签
  int? timestamp;
  String? imageUrl;   // 封面图片URL
  String? status;     // want, watching, done, dropped
  String? progress;   // 进度（第X集、第X页）
  String? moodAfter;  // 体验后心情
  String? memorableMoment; // 印象深刻的瞬间
  String? personalInsight; // 个人感悟

  Entertainment({
    this.id,
    required this.mediaType,
    required this.title,
    this.creator,
    this.rating,
    this.feeling,
    this.tags,
    this.timestamp,
    this.imageUrl,
    this.status,
    this.progress,
    this.moodAfter,
    this.memorableMoment,
    this.personalInsight,
  });

  factory Entertainment.fromMap(Map<String, dynamic> m) => Entertainment(
        id: m['id'] as int?,
        mediaType: m['media_type'] as String? ?? 'other',
        title: m['title'] as String,
        creator: m['creator'] as String?,
        rating: (m['rating'] as num?)?.toDouble(),
        feeling: m['feeling'] as String?,
        tags: m['tags'] as String?,
        timestamp: m['timestamp'] as int?,
        imageUrl: m['image_url'] as String?,
        status: m['status'] as String?,
        progress: m['progress'] as String?,
        moodAfter: m['mood_after'] as String?,
        memorableMoment: m['memorable_moment'] as String?,
        personalInsight: m['personal_insight'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'media_type': mediaType,
        'title': title,
        'creator': creator,
        'rating': rating,
        'feeling': feeling,
        'tags': tags,
        'timestamp': timestamp,
        'image_url': imageUrl,
        'status': status,
        'progress': progress,
        'mood_after': moodAfter,
        'memorable_moment': memorableMoment,
        'personal_insight': personalInsight,
      };

  static const statusLabels = {
    'want': '📌 想看',
    'watching': '▶️ 在看',
    'done': '✅ 看完了',
    'dropped': '⏸️ 暂时搁置',
  };

  /// 根据媒体类型返回对应的状态标签
  static Map<String, String> statusLabelsFor(String mediaType) {
    switch (mediaType) {
      case 'music':
        return {
          'want': '📌 想听',
          'watching': '🎧 在听',
          'done': '✅ 听完了',
          'dropped': '⏸️ 暂时搁置',
        };
      case 'game':
        return {
          'want': '📌 想玩',
          'watching': '🎮 在玩',
          'done': '✅ 通关了',
          'dropped': '⏸️ 暂时搁置',
        };
      case 'book':
        return {
          'want': '📌 想读',
          'watching': '📖 在读',
          'done': '✅ 读完了',
          'dropped': '⏸️ 暂时搁置',
        };
      default: // movie, tv, other
        return statusLabels;
    }
  }

  /// 根据类型获取对应的状态文本
  String get statusText {
    final labels = statusLabelsFor(mediaType);
    return labels[status] ?? '';
  }

  static const moodLabels = {
    'moved': '🥹 感动',
    'happy': '😊 开心',
    'calm': '😌 平静',
    'thoughtful': '🤔 深思',
    'disappointed': '😔 失望',
    'excited': '🤩 兴奋',
  };
}
