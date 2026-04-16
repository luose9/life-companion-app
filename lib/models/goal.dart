/// 五级分层：vision / yearly / quarterly / weekly / daily
class Goal {
  int? id;
  String title;
  String? description;
  String level;          // vision, yearly, quarterly, weekly, daily
  int? parentId;         // 上层目标ID
  int? startDate;
  int? endDate;
  int priority;
  int progress;
  String status;         // active, paused, archived, completed
  int? createdAt;
  int? remindMinutes;
  String? repeatRule;
  int? remindTime;
  String? meaning;       // 目标意义锚定
  int difficulty;        // 1-10难度
  int checkinFrequency;  // 每周打卡次数 1-7
  String? checkinDays;   // 具体打卡日 e.g. "1,3,5" (周一三五)
  String? microActions;  // JSON list of micro-action strings

  Goal({
    this.id,
    required this.title,
    this.description,
    this.level = 'daily',
    this.parentId,
    this.startDate,
    this.endDate,
    this.priority = 0,
    this.progress = 0,
    this.status = 'active',
    this.createdAt,
    this.remindMinutes,
    this.repeatRule,
    this.remindTime,
    this.meaning,
    this.difficulty = 5,
    this.checkinFrequency = 5,
    this.checkinDays,
    this.microActions,
  });

  factory Goal.fromMap(Map<String, dynamic> map) => Goal(
        id: map['id'] as int?,
        title: map['title'],
        description: map['description'],
        level: map['level'] as String? ?? 'daily',
        parentId: map['parent_id'] as int?,
        startDate: map['start_date'] as int?,
        endDate: map['end_date'] as int?,
        remindMinutes: map['remind_minutes'] as int?,
        repeatRule: map['repeat_rule'] as String?,
        remindTime: map['remind_time'] as int?,
        priority: map['priority'] ?? 0,
        progress: map['progress'] ?? 0,
        status: map['status'] ?? 'active',
        createdAt: map['created_at'] as int?,
        meaning: map['meaning'] as String?,
        difficulty: map['difficulty'] as int? ?? 5,
        checkinFrequency: map['checkin_frequency'] as int? ?? 5,
        checkinDays: map['checkin_days'] as String?,
        microActions: map['micro_actions'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'description': description,
        'level': level,
        'parent_id': parentId,
        'start_date': startDate,
        'end_date': endDate,
        'remind_minutes': remindMinutes,
        'repeat_rule': repeatRule,
        'remind_time': remindTime,
        'priority': priority,
        'progress': progress,
        'status': status,
        'created_at': createdAt,
        'meaning': meaning,
        'difficulty': difficulty,
        'checkin_frequency': checkinFrequency,
        'checkin_days': checkinDays,
        'micro_actions': microActions,
      };

  static const levelLabels = {
    'vision': '人生愿景',
    'yearly': '年度目标',
    'quarterly': '季度里程碑',
    'weekly': '周计划',
    'daily': '今日行动',
  };

  static const levelLimits = {
    'yearly': 3,
    'quarterly': 5,
    'daily': 3,
  };

  String get levelLabel => levelLabels[level] ?? level;
}
