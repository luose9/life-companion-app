class TaskItem {
  int? id;
  int? goalId;
  String title;
  int done; // 0 or 1
  int? dueDate;

  TaskItem({this.id, this.goalId, required this.title, this.done = 0, this.dueDate});

  factory TaskItem.fromMap(Map<String, dynamic> map) => TaskItem(
        id: map['id'] as int?,
        goalId: map['goal_id'] as int?,
        title: map['title'] as String,
        done: map['done'] as int? ?? 0,
        dueDate: map['due_date'] as int?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'goal_id': goalId,
        'title': title,
        'done': done,
        'due_date': dueDate,
      };
}
