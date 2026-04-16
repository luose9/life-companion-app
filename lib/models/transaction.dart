class TransactionEntry {
  int? id;
  double amount;
  String type; // income / expense
  String? category;
  String? note;
  int? timestamp;
  int? locationId;
  String? feeling;       // happy, neutral, regret

  TransactionEntry({
    this.id,
    required this.amount,
    required this.type,
    this.category,
    this.note,
    this.timestamp,
    this.locationId,
    this.feeling,
  });

  factory TransactionEntry.fromMap(Map<String, dynamic> map) => TransactionEntry(
        id: map['id'] as int?,
        amount: (map['amount'] as num).toDouble(),
        type: map['type'] as String,
        category: map['category'] as String?,
        note: map['note'] as String?,
        timestamp: map['timestamp'] as int?,
        locationId: map['location_id'] as int?,
        feeling: map['feeling'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'amount': amount,
        'type': type,
        'category': category,
        'note': note,
        'timestamp': timestamp,
        'location_id': locationId,
        'feeling': feeling,
      };

  static const feelingLabels = {'happy': '😊 开心', 'neutral': '😐 一般', 'regret': '😕 后悔'};
  static const feelingEmoji = {'happy': '😊', 'neutral': '😐', 'regret': '😕'};
}
