// lib/src/features/alerts/presentation/alerts_page.dart
import 'package:flutter/material.dart';
import '../../common/widgets/alert_item.dart';

class AlertsPage extends StatelessWidget {
  final List<AlertItem> alerts;
  final void Function(String id) onAcknowledgeAlert;
  final void Function(String id) onResolveAlert;
  final VoidCallback? onBack;

  const AlertsPage({
    super.key,
    required this.alerts,
    required this.onAcknowledgeAlert,
    required this.onResolveAlert,
    this.onBack,
  });

  Icon _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.water:
        return const Icon(Icons.water_drop, size: 20, color: Colors.white);
      case AlertType.temperature:
        return const Icon(Icons.thermostat, size: 20, color: Colors.white);
      case AlertType.ph:
      case AlertType.nutrient:
        return const Icon(Icons.science, size: 20, color: Colors.white);
      default:
        return const Icon(Icons.warning, size: 20, color: Colors.white);
    }
  }

  Color _severityColor(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.high:
        return Colors.red;
      case AlertSeverity.medium:
        return Colors.orange;
      case AlertSeverity.low:
        return Colors.blue;
    }
  }

  Color _cardBackground(AlertSeverity s, bool acknowledged) {
    if (acknowledged) return Colors.grey.shade50;
    switch (s) {
      case AlertSeverity.high:
        return Colors.red.shade50;
      case AlertSeverity.medium:
        return Colors.yellow.shade50;
      case AlertSeverity.low:
        return Colors.blue.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unacknowledged = alerts.where((a) => !a.acknowledged).toList();
    final acknowledged = alerts.where((a) => a.acknowledged).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (onBack != null) onBack!();
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Alerts & Notifications', style: TextStyle(color: Colors.black)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const Icon(Icons.notifications, color: Colors.grey),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                  child: Text('${unacknowledged.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary row
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _summaryCard('Critical', alerts.where((a) => a.severity == AlertSeverity.high && !a.acknowledged).length, Colors.red),
                  _summaryCard('Warning', alerts.where((a) => a.severity == AlertSeverity.medium && !a.acknowledged).length, Colors.orange),
                  _summaryCard('Info', alerts.where((a) => a.severity == AlertSeverity.low && !a.acknowledged).length, Colors.blue),
                ],
              ),
            ),

            const SizedBox(height: 12),
            // Active alerts
            if (unacknowledged.isNotEmpty) Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: const [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Active Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 8),
                ...unacknowledged.map((a) => _alertCard(context, a, false)).toList(),
              ]),
            ),

            const SizedBox(height: 16),
            // Push preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Push Notification Preview', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.notifications, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('naihydro', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('⚠️ pH dropped below 5.5', style: TextStyle(color: Colors.grey.shade700)),
                          ]),
                        ),
                        const Text('now', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 16),
            // Acknowledged
            if (acknowledged.isNotEmpty) Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: const [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Acknowledged', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 8),
                ...acknowledged.map((a) => _alertCard(context, a, true)).toList(),
              ]),
            ),

            if (alerts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: const [
                      Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No alerts', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      SizedBox(height: 6),
                      Text('All systems are running smoothly', style: TextStyle(color: Colors.grey)),
                    ]),
                  ),
                ),
              ),

            const SizedBox(height: 120),
          ],
        ),
      ),

      // bottom nav (mirrors home)
      bottomNavigationBar: BottomAppBar(
        elevation: 2,
        color: Colors.white,
        child: SafeArea(
          minimum: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {
                  if (onBack != null) onBack!();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.home_outlined),
                tooltip: 'Home',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications, color: Colors.blue),
                tooltip: 'Alerts',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.warning_outlined),
                tooltip: 'Control',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String title, int count, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(children: [
            Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
      ),
    );
  }

  Widget _alertCard(BuildContext context, AlertItem a, bool acknowledged) {
    final sevColor = _severityColor(a.severity);
    return Card(
      color: _cardBackground(a.severity, acknowledged),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: sevColor, borderRadius: BorderRadius.circular(8)),
            child: _getAlertIcon(a.type),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sevColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    a.severity.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimestamp(a.timestamp),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                )
              ]),
              const SizedBox(height: 8),
              Text(a.message, style: TextStyle(color: acknowledged ? Colors.grey.shade700 : Colors.black)),
              const SizedBox(height: 8),
              Row(children: [
                ElevatedButton.icon(
                  onPressed: acknowledged ? null : () => onAcknowledgeAlert(a.id),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Acknowledge', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: acknowledged ? Colors.grey : Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => onResolveAlert(a.id),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Resolve', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ])
            ]),
          ),
        ]),
      ),
    );
  }

  static String _formatTimestamp(DateTime ts) {
    // simple formatting; replace with intl if you prefer nicer formatting
    final local = ts.toLocal();
    return '${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
