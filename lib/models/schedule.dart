class Schedule {
  int? id;
  String title;
  String? description;
  int? startTime;
  int? endTime;
  String? repeatRule;
  int? remindMinutes;
  String energy;         // high, medium, low
  String priority;       // important, normal
  String status;         // pending, done, postponed
  int? goalId;           // 关联目标ID
  String? soundPath;     // null=默认, 'silent'=静音, file path=自定义
  int vibrate;           // 0=跟随系统, 1=强制振动, 2=无振动

  Schedule({
    this.id,
    required this.title,
    this.description,
    this.startTime,
    this.endTime,
    this.repeatRule,
    this.remindMinutes,
    this.energy = 'medium',
    this.priority = 'normal',
    this.status = 'pending',
    this.goalId,
    this.soundPath,
    this.vibrate = 1,
  });

  factory Schedule.fromMap(Map<String, dynamic> map) => Schedule(
        id: map['id'] as int?,
        title: map['title'],
        description: map['description'] as String?,
        startTime: map['start_time'] as int?,
        endTime: map['end_time'] as int?,
        repeatRule: map['repeat_rule'] as String?,
        remindMinutes: map['remind_minutes'] as int?,
        energy: map['energy'] as String? ?? 'medium',
        priority: map['priority'] as String? ?? 'normal',
        status: map['status'] as String? ?? 'pending',
        goalId: map['goal_id'] as int?,
        soundPath: map['sound_path'] as String?,
        vibrate: map['vibrate'] as int? ?? 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'description': description,
        'start_time': startTime,
        'end_time': endTime,
        'repeat_rule': repeatRule,
        'remind_minutes': remindMinutes,
        'energy': energy,
        'priority': priority,
        'status': status,
        'goal_id': goalId,
        'sound_path': soundPath,
        'vibrate': vibrate,
      };

  static const energyLabels = {'high': '高精力', 'medium': '中精力', 'low': '低精力'};
  static const priorityLabels = {'important': '重要', 'normal': '普通'};
}
