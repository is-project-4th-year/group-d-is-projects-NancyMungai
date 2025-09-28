// lib/src/features/common/widgets/status_card.dart
import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final String? unit;
  final IconData icon;
  final String status;
  final DateTime lastUpdated;

  const StatusCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.status,
    required this.lastUpdated,
    this.unit,
  });

  Color _statusColor() {
    switch (status) {
      case 'optimal':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(icon, size: 26, color: statusColor),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            unit == null ? value : '$value $unit',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text('Updated: ${TimeOfDay.fromDateTime(lastUpdated).format(context)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ]),
      ),
    );
  }
}
