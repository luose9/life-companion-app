class LocationPoint {
  int? id;
  double? latitude;
  double? longitude;
  String? address;
  int? timestamp;

  LocationPoint({this.id, this.latitude, this.longitude, this.address, this.timestamp});

  factory LocationPoint.fromMap(Map<String, dynamic> map) => LocationPoint(
        id: map['id'] as int?,
        latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
        longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
        address: map['address'] as String?,
        timestamp: map['timestamp'] as int?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'timestamp': timestamp,
      };
}
