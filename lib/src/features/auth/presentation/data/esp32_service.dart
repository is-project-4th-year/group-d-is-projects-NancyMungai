import 'dart:async';

// lib/src/features/auth/presentation/data/esp32_service.dart
class Esp32Service {
  /// Simulate connecting an ESP32 device to a farm id.
  Future<void> connectToFarm(String farmId) async {
    await Future.delayed(const Duration(seconds: 1));
    // In production: call backend API or send MQTT message to instruct the ESP32.
    // For now, simulated success.
    return;
  }
}
