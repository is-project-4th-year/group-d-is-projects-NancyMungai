import 'package:cloud_firestore/cloud_firestore.dart';
import '../../presentation/models/farm_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addFarm(Map<String, dynamic> farmData) async {
    final id = farmData['id'] as String;
    await _firestore.collection('farms').doc(id).set(farmData);
  }

  /// Stream a list of farm maps for the collection 'farms'.
  Stream<List<Map<String, dynamic>>> farmsStream() {
    return _firestore.collection('farms').snapshots().map((snap) {
      return snap.docs.map((d) => d.data()).toList();
    });
  }

  /// Stream of sensor documents for a farm: returns latest snapshot mapped into a Map.
  /// Assumes sensors are stored under: farms/{farmId}/sensors/{sensorDoc}
  Stream<Map<String, dynamic>> sensorStream(String farmId) {
    final coll = _firestore.collection('farms').doc(farmId).collection('sensors');
    // Map latest docs into a single combined map: { 'ph': {...}, 'temperature': {...} }
    return coll.snapshots().map((snap) {
      final Map<String, dynamic> out = {};
      for (final doc in snap.docs) {
        out[doc.id] = doc.data();
      }
      return out;
    });
  }
}
