class FarmModel {
  final String id;
  final String name;
  final String location;
  final String ownerId;
  final String? deviceId;
  final DateTime createdAt;

  FarmModel({
    required this.id,
    required this.name,
    required this.location,
    required this.ownerId,
    this.deviceId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'location': location,
        'ownerId': ownerId,
        'deviceId': deviceId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FarmModel.fromMap(Map<String, dynamic> map) => FarmModel(
        id: map['id'] as String,
        name: map['name'] as String,
        location: map['location'] as String,
        ownerId: map['ownerId'] as String,
        deviceId: map['deviceId'] as String?,
        createdAt: DateTime.parse(map['createdAt']),
      );
}
