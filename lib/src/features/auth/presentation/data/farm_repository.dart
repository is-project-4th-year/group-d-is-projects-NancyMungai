// lib/src/features/auth/presentation/data/farm_repository.dart
import 'dart:async';
import '../models/farm_model.dart';
import 'firebase_service.dart'; // your existing
import 'esp32_service.dart'; // your existing
import '../control_panel.dart';



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

  /// ✅ NEW: Update control state via deviceId
  /// This sends the control command to Firebase Realtime DB
  /// The ESP32 reads from this path and triggers the relay
  Future<void> updateControlState(
    String farmId,
    String controlName,
    bool state,
    String? deviceId,
  ) async {
    try {
          if (deviceId == null || deviceId.isEmpty) {
        throw Exception('Device ID is required to control the pump');
      }
       int stateValue = state ? 1 : 0;

      // Pass farmId (which contains deviceId in your case)
      // OR if you need actual deviceId, add it to FarmModel and pass it here
    await _firebaseService.updateControl(deviceId, controlName, stateValue);
    } catch (e) {
      throw Exception('Failed to update $controlName: $e');
    }
  }

  /// ✅ NEW: Stream control state in real-time
  /// Use this to show real-time feedback from ESP32
  Stream<int> getControlStateStream(String deviceId, String controlName) {
    return _firebaseService.controlStateStream(deviceId, controlName);
  }


}
