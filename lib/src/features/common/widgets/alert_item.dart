// lib/src/features/alerts/domain/alert_item.dart
import 'package:flutter/foundation.dart';

enum AlertType { water, temperature, nutrient, ph, unknown }
enum AlertSeverity { low, medium, high }

class AlertItem {
  final String id;
  final AlertType type;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  bool acknowledged;

  AlertItem({
    required this.id,
    required this.type,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.acknowledged = false,
  });
}
