// lib/src/features/home/presentation/models/farm_model.dart
class FarmModel {
  final String id;
  final String name;
  final String location;
  final String? description;
  final String? cropType;
  final String ownerId;
  final String? deviceId; // ESP32 ID
  final DateTime createdAt;

  FarmModel({
    required this.id,
    required this.name,
    required this.location,
    this.description,
    this.cropType,
    required this.ownerId,
    this.deviceId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'description': description,
      'cropType': cropType,
      'ownerId': ownerId,
      'deviceId': deviceId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FarmModel.fromMap(Map<String, dynamic> map) {
    return FarmModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      description: map['description'],
      cropType: map['cropType'],
      ownerId: map['ownerId'] ?? '',
      deviceId: map['deviceId'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }
}