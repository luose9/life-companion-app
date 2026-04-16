class TrackPoint {
  int? id;
  int? trackId;
  double latitude;
  double longitude;
  int? timestamp;

  TrackPoint({this.id, this.trackId, required this.latitude, required this.longitude, this.timestamp});

  factory TrackPoint.fromMap(Map<String, dynamic> map) => TrackPoint(
        id: map['id'] as int?,
        trackId: map['track_id'] as int?,
        latitude: map['latitude'] as double,
        longitude: map['longitude'] as double,
        timestamp: map['timestamp'] as int?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'track_id': trackId,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp,
      };
}
