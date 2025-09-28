// lib/src/features/home/presentation/home_page.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:naihydro/src/features/auth/presentation/data/auth_service.dart';

import '../../common/widgets/status_card.dart';


class HomePage extends StatefulWidget {
  final AuthService authService;
  final Future<void> Function()? onSignOut;

  const HomePage({required this.authService, this.onSignOut, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class SensorItem {
  double value;
  String status;
  DateTime lastUpdated;
  SensorItem({required this.value, required this.status, required this.lastUpdated});
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, String>> farms = [
    {'id': 'farm1', 'name': 'Main Greenhouse', 'location': 'Building A'},
    {'id': 'farm2', 'name': 'Nursery Unit', 'location': 'Building B'},
    {'id': 'farm3', 'name': 'Research Lab', 'location': 'Building C'},
  ];

  late String selectedFarmId;
  late Map<String, SensorItem> farmData;
  String systemStatus = 'All systems operational';
  Timer? _timer;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    selectedFarmId = farms.first['id']!;
    farmData = {
      'ph': SensorItem(value: 6.2, status: 'optimal', lastUpdated: DateTime.now()),
      'temperature': SensorItem(value: 24.0, status: 'optimal', lastUpdated: DateTime.now()),
      'waterLevel': SensorItem(value: 85.0, status: 'optimal', lastUpdated: DateTime.now()),
      'nutrientLevel': SensorItem(value: 72.0, status: 'warning', lastUpdated: DateTime.now()),
    };

    // simulate updates every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final prev = Map<String, SensorItem>.fromEntries(
      farmData.entries.map((e) => MapEntry(e.key, SensorItem(value: e.value.value, status: e.value.status, lastUpdated: e.value.lastUpdated))),
    );

    setState(() {
      // perturb values
      farmData['ph']!.value = (farmData['ph']!.value + (_rand.nextDouble() - 0.5) * 0.2).clamp(5.5, 7.5);
      farmData['temperature']!.value = (farmData['temperature']!.value + (_rand.nextDouble() - 0.5) * 2).clamp(18, 30);
      farmData['waterLevel']!.value = (farmData['waterLevel']!.value - _rand.nextDouble() * 2).clamp(0, 100);
      farmData['nutrientLevel']!.value = (farmData['nutrientLevel']!.value - _rand.nextDouble() * 1.5).clamp(0, 100);

      // statuses
      farmData['ph']!.status = (farmData['ph']!.value >= 6.0 && farmData['ph']!.value <= 7.0) ? 'optimal' : 'warning';
      farmData['temperature']!.status = (farmData['temperature']!.value >= 20 && farmData['temperature']!.value <= 26) ? 'optimal' : 'warning';
      final wl = farmData['waterLevel']!.value;
      farmData['waterLevel']!.status = wl > 30 ? 'optimal' : wl > 15 ? 'warning' : 'critical';
      final nl = farmData['nutrientLevel']!.value;
      farmData['nutrientLevel']!.status = nl > 60 ? 'optimal' : nl > 30 ? 'warning' : 'critical';

      // timestamps
      final now = DateTime.now();
      farmData.forEach((_, item) => item.lastUpdated = now);

      // compute system status
      final overall = _computeOverallStatus();
      systemStatus = overall == 'optimal'
          ? 'All systems operational'
          : overall == 'warning'
              ? 'Some parameters need attention'
              : 'Critical conditions detected';

      // trigger alerts like React version (only when crossing threshold)
      if (farmData['waterLevel']!.value < 20 && prev['waterLevel']!.value >= 20) {
        _showAlert('Water level critically low: ${farmData['waterLevel']!.value.toStringAsFixed(1)}%');
      }
      if (farmData['nutrientLevel']!.value < 40 && prev['nutrientLevel']!.value >= 40) {
        _showAlert('Nutrient level low: ${farmData['nutrientLevel']!.value.toStringAsFixed(1)}%');
      }
    });
  }

  String _computeOverallStatus() {
    final statuses = farmData.values.map((s) => s.status).toList();
    if (statuses.contains('critical')) return 'critical';
    if (statuses.contains('warning')) return 'warning';
    return 'optimal';
  }

  void _showAlert(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final overall = _computeOverallStatus();
    final overallColor = overall == 'optimal'
        ? Colors.green[50]
        : overall == 'warning'
            ? Colors.yellow[50]
            : Colors.red[50];

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.eco, size: 28),
          const SizedBox(width: 8),
          const Text('naihydro'),
        ]),
        actions: [
          IconButton(
            onPressed: () async {
              // sign out via injected service
              await widget.authService.signOut();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card + farm selector + status
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.eco, size: 32, color: Colors.green),
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('naihydro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Real-time monitoring dashboard', style: TextStyle(color: Colors.grey[600])),
                      ]),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          // navigate to settings (placeholder)
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings tapped')));
                        },
                        icon: const Icon(Icons.settings),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // farm selector
                  Row(
  children: [
    Expanded(
      child: DropdownButton<String>(
        value: selectedFarmId,
        isExpanded: true, // ✅ allows text to fit
        onChanged: (value) {
          if (value != null) {
            setState(() {
              selectedFarmId = value;
            });
          }
        },
        items: farms.map((f) {
          return DropdownMenuItem<String>(
            value: f['id'],
            child: Row(
              children: [
                const Icon(Icons.eco, size: 18, color: Colors.green),
                const SizedBox(width: 8),
                Flexible( // ✅ prevents overflow
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // ✅ shrink vertically
                    children: [
                      Text(
                        f['name']!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis, // ✅ avoid text spill
                      ),
                      Text(
                        f['location']!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        overflow: TextOverflow.ellipsis, // ✅ avoid text spill
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ),
  ],
),


                      
                  const SizedBox(height: 12),
                  Card(
                    color: overallColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.run_circle, size: 36, color: overall == 'optimal' ? Colors.green[700] : overall == 'warning' ? Colors.orange[700] : Colors.red[700]),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(systemStatus, style: TextStyle(fontWeight: FontWeight.w700, color: overall == 'optimal' ? Colors.green[800] : overall == 'warning' ? Colors.orange[800] : Colors.red[800])),
                            const SizedBox(height: 4),
                            Text('Last updated: ${TimeOfDay.now().format(context)}', style: const TextStyle(fontSize: 12)),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            // farm image
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://images.unsplash.com/photo-1722119272044-fc49006131e0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 16),
            // status cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Current Conditions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StatusCard(
                      title: 'pH Level',
                      value: farmData['ph']!.value.toStringAsFixed(1),
                      icon: Icons.science,
                      status: farmData['ph']!.status,
                      lastUpdated: farmData['ph']!.lastUpdated,
                    ),
                    StatusCard(
                      title: 'Temperature',
                      value: farmData['temperature']!.value.toStringAsFixed(1),
                      unit: '°C',
                      icon: Icons.thermostat,
                      status: farmData['temperature']!.status,
                      lastUpdated: farmData['temperature']!.lastUpdated,
                    ),
                    StatusCard(
                      title: 'Water Level',
                      value: farmData['waterLevel']!.value.toStringAsFixed(1),
                      unit: '%',
                      icon: Icons.water_drop,
                      status: farmData['waterLevel']!.status,
                      lastUpdated: farmData['waterLevel']!.lastUpdated,
                    ),
                    StatusCard(
                      title: 'Nutrients',
                      value: farmData['nutrientLevel']!.value.toStringAsFixed(1),
                      unit: '%',
                      icon: Icons.eco,
                      status: farmData['nutrientLevel']!.status,
                      lastUpdated: farmData['nutrientLevel']!.lastUpdated,
                    ),
                  ],
                ),
              ]),
            ),

            const SizedBox(height: 16),
            // quick actions


           
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
     type: BottomNavigationBarType.fixed,
  currentIndex: 0,
  backgroundColor: Colors.white, // set bar background
  selectedItemColor: Colors.black, // active icon + label
  unselectedItemColor: Colors.black54, // inactive icon + label
  showUnselectedLabels: true, // keep labels visible even when inactive
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: 'Control'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analytics'),
        ],
        onTap: (i) {
          // simple nav stubs
          switch (i) {
            case 0:
              break;
            case 1:
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open Alerts')));
              break;
            case 2:
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open Control')));
              break;
            case 3:
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open Analytics')));
              break;
          }
        },
      ),
    );
  }
}
