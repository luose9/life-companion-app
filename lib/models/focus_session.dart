class FocusSession {
  int? id;
  int goalId;
  String label;
  int startTime;
  int? endTime;
  int durationSeconds;

  FocusSession({
    this.id,
    required this.goalId,
    required this.label,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
  });

  factory FocusSession.fromMap(Map<String, dynamic> m) => FocusSession(
        id: m['id'] as int?,
        goalId: m['goal_id'] as int,
        label: m['label'] as String? ?? '',
        startTime: m['start_time'] as int,
        endTime: m['end_time'] as int?,
        durationSeconds: m['duration_seconds'] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'goal_id': goalId,
        'label': label,
        'start_time': startTime,
        'end_time': endTime,
        'duration_seconds': durationSeconds,
      };
}
