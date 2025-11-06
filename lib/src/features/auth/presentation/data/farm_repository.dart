// lib/src/features/auth/presentation/data/ui_farm_repository.dart
import 'dart:async';
import '../models/farm_model.dart';
import 'firebase_service.dart'; // your existing
import 'esp32_service.dart'; // your existing


class FarmRepository {
  final FirebaseService _firebaseService;
  final Esp32Service _esp32Service;

  FarmRepository({FirebaseService? firebaseService, Esp32Service? esp32Service})
      : _firebaseService = firebaseService ?? FirebaseService(),
        _esp32Service = esp32Service ?? Esp32Service();

  /// Save farm to firestore (map) and attempt to link ESP32.
  Future<void> addFarm(FarmModel farm) async {
    await _firebaseService.addFarm(farm.toMap());
    try {
      await _esp32Service.connectToFarm(farm.id);
    } catch (e) {
      // linking failed: log and continue (farm still saved)
      // You may choose to rethrow or return error state to UI
      print('ESP32 link failed: $e');
    }
  }

  /// Stream FarmModel list
  Stream<List<FarmModel>> getFarmsStream() {
    return _firebaseService.farmsStream().map((list) {
      return list.map((m) => FarmModel.fromMap(Map<String, dynamic>.from(m))).toList();
    });
  }

  /// Stream sensors for a farm id
  Stream<Map<String, dynamic>> sensorsForFarm(String farmId) {
    return _firebaseService.sensorStream(farmId);
  }
}
