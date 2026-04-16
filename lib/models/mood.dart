class Mood {
  int? id;
  String? emoji;
  String? moodTag;
  String? note;
  int? timestamp;
  int? locationId;
  int intensity;         // 1-10 情绪强度
  String? trigger;       // 触发事件（工作/人际/天气/健康/金钱/其他）
  String? triggerNote;   // 触发事件简要描述
  String? bodyFeeling;   // 身体感受
  String? desire;        // 想做什么

  Mood({
    this.id,
    this.emoji,
    this.moodTag,
    this.note,
    this.timestamp,
    this.locationId,
    this.intensity = 5,
    this.trigger,
    this.triggerNote,
    this.bodyFeeling,
    this.desire,
  });

  factory Mood.fromMap(Map<String, dynamic> map) => Mood(
        id: map['id'] as int?,
        emoji: map['emoji'] as String?,
        moodTag: map['mood_tag'] as String?,
        note: map['note'] as String?,
        timestamp: map['timestamp'] as int?,
        locationId: map['location_id'] as int?,
        intensity: map['intensity'] as int? ?? 5,
        trigger: map['trigger'] as String?,
        triggerNote: map['trigger_note'] as String?,
        bodyFeeling: map['body_feeling'] as String?,
        desire: map['desire'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'emoji': emoji,
        'mood_tag': moodTag,
        'note': note,
        'timestamp': timestamp,
        'location_id': locationId,
        'intensity': intensity,
        'trigger': trigger,
        'trigger_note': triggerNote,
        'body_feeling': bodyFeeling,
        'desire': desire,
      };

  static const triggerLabels = {
    'work': '工作',
    'relationship': '人际关系',
    'weather': '天气',
    'health': '健康',
    'money': '金钱',
    'hobby': '爱好',
    'rest': '休息',
    'other': '其他',
  };
}
