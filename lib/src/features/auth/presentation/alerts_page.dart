import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({Key? key}) : super(key: key);

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  List<Map<String, dynamic>> alerts = [
    {
      'id': '1',
      'type': 'water',
      'message': 'Water level is low in Farm A',
      'severity': 'high',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      'acknowledged': false,
    },
    {
      'id': '2',
      'type': 'temperature',
      'message': 'Temperature exceeded 30°C',
      'severity': 'medium',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
      'acknowledged': true,
    },
  ];

  void acknowledgeAlert(String id) {
    setState(() {
      alerts.firstWhere((a) => a['id'] == id)['acknowledged'] = true;
    });
  }

  void resolveAlert(String id) {
    setState(() {
      alerts.removeWhere((a) => a['id'] == id);
    });
  }

  Color getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red.shade100;
      case 'medium':
        return Colors.yellow.shade100;
      case 'low':
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  IconData getIcon(String type) {
    switch (type) {
      case 'water':
        return Icons.water_drop;
      case 'temperature':
        return Icons.thermostat;
      case 'nutrient':
      case 'ph':
        return Icons.science;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unacknowledged = alerts.where((a) => a['acknowledged'] == false).toList();
    final acknowledged = alerts.where((a) => a['acknowledged'] == true).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Alerts & Notifications"),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Active Alerts (${unacknowledged.length})",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                )),
            const SizedBox(height: 10),

            // Active Alerts
            ...unacknowledged.map((alert) => Card(
                  color: getSeverityColor(alert['severity']),
                  child: ListTile(
                    leading: Icon(getIcon(alert['type']),
                        color: Colors.green.shade700),
                    title: Text(alert['message']),
                    subtitle: Text(
                      DateFormat('MMM d, h:mm a').format(alert['timestamp']),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () => acknowledgeAlert(alert['id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => resolveAlert(alert['id']),
                        ),
                      ],
                    ),
                  ),
                )),

            const SizedBox(height: 20),

            // Acknowledged Alerts
            if (acknowledged.isNotEmpty)
              Text("Acknowledged (${acknowledged.length})",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 16)),
            ...acknowledged.map((alert) => Card(
                  color: Colors.grey.shade200,
                  child: ListTile(
                    leading: Icon(getIcon(alert['type']),
                        color: Colors.grey.shade600),
                    title: Text(alert['message']),
                    subtitle: Text(
                      DateFormat('MMM d, h:mm a').format(alert['timestamp']),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => resolveAlert(alert['id']),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
