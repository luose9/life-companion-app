class CheckinRecord {
  int? id;
  int goalId;
  int timestamp;
  String? note;
  String? emotion; // happy, calm, tired, etc.

  CheckinRecord({
    this.id,
    required this.goalId,
    required this.timestamp,
    this.note,
    this.emotion,
  });

  factory CheckinRecord.fromMap(Map<String, dynamic> m) => CheckinRecord(
        id: m['id'] as int?,
        goalId: m['goal_id'] as int,
        timestamp: m['timestamp'] as int,
        note: m['note'] as String?,
        emotion: m['emotion'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'goal_id': goalId,
        'timestamp': timestamp,
        'note': note,
        'emotion': emotion,
      };
}
