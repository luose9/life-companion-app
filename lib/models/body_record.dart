/// 身体感知记录（睡眠、饮食、健康）
class BodyRecord {
  int? id;
  String recordType;   // sleep, diet, health
  int? timestamp;
  // 睡眠
  int? sleepTime;      // 入睡时间ms
  int? wakeTime;       // 起床时间ms
  int? sleepQuality;   // 1-10
  // 饮食
  String? dietContent; // 吃了什么
  String? dietFeeling; // happy, neutral, uncomfortable
  // 健康
  String? healthNote;  // 身体状况描述
  String? note;        // 通用备注

  BodyRecord({
    this.id,
    required this.recordType,
    this.timestamp,
    this.sleepTime,
    this.wakeTime,
    this.sleepQuality,
    this.dietContent,
    this.dietFeeling,
    this.healthNote,
    this.note,
  });

  factory BodyRecord.fromMap(Map<String, dynamic> m) => BodyRecord(
        id: m['id'] as int?,
        recordType: m['record_type'] as String? ?? 'health',
        timestamp: m['timestamp'] as int?,
        sleepTime: m['sleep_time'] as int?,
        wakeTime: m['wake_time'] as int?,
        sleepQuality: m['sleep_quality'] as int?,
        dietContent: m['diet_content'] as String?,
        dietFeeling: m['diet_feeling'] as String?,
        healthNote: m['health_note'] as String?,
        note: m['note'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'record_type': recordType,
        'timestamp': timestamp,
        'sleep_time': sleepTime,
        'wake_time': wakeTime,
        'sleep_quality': sleepQuality,
        'diet_content': dietContent,
        'diet_feeling': dietFeeling,
        'health_note': healthNote,
        'note': note,
      };

  static const dietFeelingLabels = {
    'happy': '😊 开心',
    'neutral': '😐 一般',
    'uncomfortable': '😣 不舒服',
  };
}
