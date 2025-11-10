// lib/src/features/auth/presentation/data/firebase_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add farm to user's farms in RTDB
  Future<void> addFarm(Map<String, dynamic> farmData) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    
    final farmId = farmData['id'];
    await _db.ref('users/$uid/farms/$farmId').set(farmData);
  }

  /// Stream of user's farms
  Stream<List<Map<String, dynamic>>> farmsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    
    return _db.ref('users/$uid/farms').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <Map<String, dynamic>>[];
      
      final farmsMap = Map<String, dynamic>.from(data as Map);
      return farmsMap.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    });
  }

  /// Stream latest sensor data from processed folder for a specific device
  /// ✅ FIXED: Exclude control fields (pump_state, relay_state) from sensor data
  /// to avoid reading stale control state as sensor data
  Stream<Map<String, dynamic>> sensorStream(String farmId) async* {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      yield {};
      return;
    }

    try {
      // Get farm to find its deviceId
      final farmSnapshot = await _db.ref('users/$uid/farms/$farmId').get();
      if (!farmSnapshot.exists) {
        yield {};
        return;
      }

      final farmData = Map<String, dynamic>.from(farmSnapshot.value as Map);
      final deviceId = farmData['deviceId'] as String?;

      if (deviceId == null) {
        yield {};
        return;
      }

      // Stream from processed/{deviceId} - FLAT structure from ESP32
      yield* _db.ref('processed/$deviceId').onValue.map((event) {
        final data = event.snapshot.value;
        print('🔍 Raw data from Firebase: $data');

        if (data == null) {
          return <String, dynamic>{};
        }

        try {
          // Data is now FLAT, not nested
          final sensorData = Map<String, dynamic>.from(data as Map);

          // Return renamed fields to match expected names in UI
          // ✅ IMPORTANT: Extract ONLY sensor fields, NOT control fields
          return {
            'ph': sensorData['pH'],
            'temperature': sensorData['DHT_temp'],
            'waterLevel': sensorData['water_level'],
            'nutrientLevel': _calculateNutrientLevel(sensorData['TDS']),
            'humidity': sensorData['DHT_humidity'],
            'timestamp': sensorData['timestamp'],
            'updatedAt': sensorData['timestamp'],
            // ✅ Note: pump_state and relay_state are NOT included here
            // They are control fields, not sensor fields
          };
        } catch (e) {
          print('❌ Error parsing sensor data: $e');
          return <String, dynamic>{};
        }
      });
    } catch (e) {
      print('❌ Error in sensorStream: $e');
      yield {};
      return;
    }
  }

  /// Calculate nutrient level percentage from TDS value
  double _calculateNutrientLevel(dynamic tds) {
    if (tds == null) return 0.0;

    double tdsValue;
    if (tds is int) {
      tdsValue = tds.toDouble();
    } else if (tds is double) {
      tdsValue = tds;
    } else if (tds is String) {
      tdsValue = double.tryParse(tds) ?? 0.0;
    } else {
      return 0.0;
    }

    final percentage = (tdsValue / 2000.0) * 100.0;
    return percentage.clamp(0.0, 100.0);
  }

  /// Link ESP32 device to farm
  Future<void> linkDeviceToFarm(String farmId, String deviceId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    await _db.ref('users/$uid/farms/$farmId/deviceId').set(deviceId);
  }

  /// ✅ Update pump control state in Realtime Database
  /// Writes to: /processed/{deviceId}/pump_state
  /// The ESP32 continuously reads this path and controls the relay
  Future<void> updateControl(String deviceId, String controlName, int state) async {
    try {
      final dbRef = _db.ref('processed/$deviceId/$controlName');
      await dbRef.set(state);
      print('✓ Control updated: /processed/$deviceId/$controlName = $state');
    } catch (e) {
      print('✗ Error updating control: $e');
      throw Exception('Failed to update $controlName: $e');
    }
  }

  /// ✅ Get current control state
  Future<int?> getControlState(String deviceId, String controlName) async {
    try {
      final dbRef = _db.ref('processed/$deviceId/$controlName');
      final snapshot = await dbRef.get();
      return snapshot.value as int?;
    } catch (e) {
      print('Error fetching control state: $e');
      return null;
    }
  }

  /// ✅ Stream control state in real-time from Realtime Database
  /// Read ONLY the control field, not the entire sensor object
  /// This ensures we always get the latest control value
  Stream<int> controlStateStream(String deviceId, String controlName) {
    return _db
        .ref('processed/$deviceId/$controlName')
        .onValue
        .map((event) {
      final value = event.snapshot.value;
      print('📡 Control state stream [$controlName]: $value');
      if (value is int) return value;
      if (value is bool) return value ? 1 : 0;
      return 0; // default
    });
  }
}