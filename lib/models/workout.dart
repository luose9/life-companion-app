/// 一次运动记录
class Workout {
  int? id;
  String type;       // 跑步、步行、骑行、游泳、瑜伽、力量训练、其他
  int? startTime;    // ms since epoch
  int? endTime;
  double? distanceKm;
  int? steps;
  int? calories;
  String? note;
  String? routeJson;
  String? bodyFeeling;   // relaxed, refreshed, tired, sore, energized
  String? moodBefore;    // 运动前心情
  String? moodAfter;     // 运动后心情
  String? customTags;    // 逗号分隔自定义标签

  Workout({
    this.id,
    required this.type,
    this.startTime,
    this.endTime,
    this.distanceKm,
    this.steps,
    this.calories,
    this.note,
    this.routeJson,
    this.bodyFeeling,
    this.moodBefore,
    this.moodAfter,
    this.customTags,
  });

  int get durationMinutes {
    if (startTime == null || endTime == null) return 0;
    return ((endTime! - startTime!) / 60000).round();
  }

  factory Workout.fromMap(Map<String, dynamic> m) => Workout(
        id: m['id'] as int?,
        type: m['type'] as String? ?? '其他',
        startTime: m['start_time'] as int?,
        endTime: m['end_time'] as int?,
        distanceKm: (m['distance_km'] as num?)?.toDouble(),
        steps: m['steps'] as int?,
        calories: m['calories'] as int?,
        note: m['note'] as String?,
        routeJson: m['route_json'] as String?,
        bodyFeeling: m['body_feeling'] as String?,
        moodBefore: m['mood_before'] as String?,
        moodAfter: m['mood_after'] as String?,
        customTags: m['custom_tags'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'type': type,
        'start_time': startTime,
        'end_time': endTime,
        'distance_km': distanceKm,
        'steps': steps,
        'calories': calories,
        'note': note,
        'route_json': routeJson,
        'body_feeling': bodyFeeling,
        'mood_before': moodBefore,
        'mood_after': moodAfter,
        'custom_tags': customTags,
      };

  static const bodyFeelingLabels = {
    'relaxed': '😌 轻松',
    'refreshed': '🌊 舒畅',
    'tired': '😴 疲惫',
    'sore': '💪 酸痛',
    'energized': '⚡ 精力充沛',
  };

  static const moodLabels = {
    'great': '😊 很好',
    'good': '🙂 不错',
    'normal': '😐 一般',
    'low': '😔 低落',
    'stressed': '😰 压力大',
  };
}
