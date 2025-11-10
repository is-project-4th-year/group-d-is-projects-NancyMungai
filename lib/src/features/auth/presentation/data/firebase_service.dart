// lib/src/features/auth/presentation/data/firebase_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
  /// Handles nested structure: processed/{deviceId}/{pushId}/sensor_readings
  Stream<Map<String, dynamic>> sensorStream(String farmId) async* {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      yield {};
      return;
    }

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

    // Stream from processed/{deviceId} and get the LATEST entry
    yield* _db.ref('processed/$deviceId').onValue.map((event) {
      final data = event.snapshot.value;
      print('🔍 Raw data from Firebase: $data');

      if (data == null) 
      
      return <String, dynamic>{};
      
      try {
        // Data is nested: {pushId: {sensor_readings: {...}, prediction: ...}}
        final entriesMap = Map<String, dynamic>.from(data as Map);
        
        // Get all entries and sort by timestamp to find latest
        final entries = entriesMap.entries.toList();
        if (entries.isEmpty) return <String, dynamic>{};
        
        // Sort by timestamp (assuming each entry has a timestamp)
        entries.sort((a, b) {
          final aData = a.value as Map;
          final bData = b.value as Map;
          final aTime = aData['timestamp'] ?? 0;
          final bTime = bData['timestamp'] ?? 0;
          return (bTime as int).compareTo(aTime as int);
        });
        
        // Get the latest entry
        final latestEntry = Map<String, dynamic>.from(entries.first.value as Map);
        
        // Extract sensor_readings
        final sensorReadings = latestEntry['sensor_readings'];
        if (sensorReadings == null) return <String, dynamic>{};
        
        final readings = Map<String, dynamic>.from(sensorReadings as Map);
        
        // Add prediction and timestamp to the returned data
        readings['prediction'] = latestEntry['prediction'];
        readings['timestamp'] = latestEntry['timestamp'];
        readings['updatedAt'] = latestEntry['timestamp'];
        
        // Rename fields to match expected names
        return {
          'ph': readings['pH'],
          'temperature': readings['DHT_temp'],
          'waterLevel': readings['water_level'],
          'nutrientLevel': _calculateNutrientLevel(readings['TDS']),
          'humidity': readings['DHT_humidity'],
          'prediction': readings['prediction'],
          'timestamp': readings['timestamp'],
          'updatedAt': readings['updatedAt'],
        };
      } catch (e) {
        print('Error parsing sensor data: $e');
        return <String, dynamic>{};
      }
    });
  }

  /// Calculate nutrient level percentage from TDS value
  /// TDS (Total Dissolved Solids) typically ranges from 0-2000 ppm for hydroponics
  /// Convert to percentage: 0 ppm = 0%, 2000 ppm = 100%
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
    
    // Convert TDS (0-2000) to percentage (0-100)
    // Optimal range for most hydroponic crops: 800-1500 ppm
    final percentage = (tdsValue / 2000.0) * 100.0;
    return percentage.clamp(0.0, 100.0);
  }

  /// Link ESP32 device to farm
  Future<void> linkDeviceToFarm(String farmId, String deviceId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    
    await _db.ref('users/$uid/farms/$farmId/deviceId').set(deviceId);
  }
}
