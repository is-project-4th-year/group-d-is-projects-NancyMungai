import 'package:flutter/material.dart';
import '../presentation/models/farm_model.dart';

import '../presentation/data/farm_repository.dart';

class FarmDetailsPage extends StatefulWidget {
  final FarmRepository repository;
  final FarmModel farm;

  const FarmDetailsPage({required this.repository, required this.farm, Key? key}) : super(key: key);

  @override
  State<FarmDetailsPage> createState() => _FarmDetailsPageState();
}

class _FarmDetailsPageState extends State<FarmDetailsPage> {
  late final Stream<Map<String, dynamic>> _sensorStream;

  @override
  void initState() {
    super.initState();
    _sensorStream = widget.repository.sensorsForFarm(widget.farm.id);
  }

  Widget _statusTile(String title, String value, String lastUpdated) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Text(lastUpdated, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _fmtTime(dynamic ts) {
    if (ts == null) return '-';
    if (ts is String) {
      try {
        final dt = DateTime.parse(ts);
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        return ts;
      }
    } else if (ts is int) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (ts is DateTime) {
      return '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.farm.name),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _sensorStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sensors = snapshot.data;
          if (sensors == null || sensors.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No sensor data available yet for ${widget.farm.name}.'),
            );
          }

          final ph = sensors['ph']?.toString() ?? '-';
          final temp = sensors['temperature']?.toString() ?? '-';
          final water = sensors['waterLevel']?.toString() ?? '-';
          final nutrients = sensors['nutrientLevel']?.toString() ?? '-';
          final updatedAt = _fmtTime(sensors['updatedAt'] ?? sensors['timestamp']);

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _statusTile('pH Level', ph, updatedAt),
                const SizedBox(height: 8),
                _statusTile('Temperature (°C)', temp, updatedAt),
                const SizedBox(height: 8),
                _statusTile('Water Level (%)', water, updatedAt),
                const SizedBox(height: 8),
                _statusTile('Nutrient Level (%)', nutrients, updatedAt),
              ],
            ),
          );
        },
      ),
    );
  }
}
