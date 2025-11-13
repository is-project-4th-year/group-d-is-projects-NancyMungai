// lib/src/features/home/presentation/models/sensor_reading.dart

class SensorReading {
  final double? temperature;    // DHT_temp
  final double? humidity;       // DHT_humidity
  final double? ph;             // pH
  final double? tds;            // TDS (nutrients in ppm)
  final double? waterLevel;     // water_level
  final int? mlPrediction;      // 0 = good, 1 = alert
  final DateTime? timestamp;

  SensorReading({
    this.temperature,
    this.humidity,
    this.ph,
    this.tds,
    this.waterLevel,
    this.mlPrediction,
    this.timestamp,
  });

  /// Parse from dynamic map (Firebase returns dynamic keys/values)
  factory SensorReading.fromMap(Map<String, dynamic> map) {
    print('🔍 Parsing SensorReading from map...');
    
    try {
      final temperature = _toDouble(map['DHT_temp'] ?? map['temperature']);
      final humidity = _toDouble(map['DHT_humidity'] ?? map['humidity']);
      final ph = _toDouble(map['pH'] ?? map['ph']);
      final tds = _toDouble(map['TDS'] ?? map['tds']);
      final waterLevel = _toDouble(map['water_level'] ?? map['waterLevel']);
      final mlPrediction = _toInt(map['prediction'] ?? map['ml_prediction']);
      
      DateTime? timestamp;
      final tsValue = map['timestamp'];
      if (tsValue != null) {
        if (tsValue is int) {
          timestamp = DateTime.fromMillisecondsSinceEpoch(tsValue);
          print('   ⏰ Parsed timestamp from int: $timestamp');
        } else if (tsValue is String) {
          timestamp = DateTime.tryParse(tsValue);
          print('   ⏰ Parsed timestamp from string: $timestamp');
        }
      }

      final reading = SensorReading(
        temperature: temperature,
        humidity: humidity,
        ph: ph,
        tds: tds,
        waterLevel: waterLevel,
        mlPrediction: mlPrediction,
        timestamp: timestamp,
      );

      print('   ✅ Successfully created SensorReading');
      print('   📊 $reading');
      
      return reading;
    } catch (e) {
      print('   ❌ Error in SensorReading.fromMap: $e');
      print('   📋 Map contents: $map');
      rethrow;
    }
  }

  /// Safely convert to double
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    
    print('   ⚠️ Could not convert to double: $value (${value.runtimeType})');
    return null;
  }

  /// Safely convert to int
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    
    print('   ⚠️ Could not convert to int: $value (${value.runtimeType})');
    return null;
  }

  /// Check if all values are null
  bool get isEmpty => temperature == null && humidity == null && ph == null && 
                       tds == null && waterLevel == null;

  /// User-friendly string representation
  @override
  String toString() => 
      'SensorReading(\n'
      '  🌡️  Temp: ${temperature?.toStringAsFixed(1)}°C\n'
      '  💧 Humidity: ${humidity?.toStringAsFixed(1)}%\n'
      '  🧪 pH: ${ph?.toStringAsFixed(2)}\n'
      '  🌿 TDS: ${tds?.toStringAsFixed(0)} ppm\n'
      '  💦 Water: ${waterLevel?.toStringAsFixed(2)}L\n'
      '  🤖 ML: ${mlPrediction == 1 ? "⚠️ ALERT" : "✅ OK"}\n'
      '  ⏰ Time: ${timestamp?.toLocal()}\n'
      ')';
}

