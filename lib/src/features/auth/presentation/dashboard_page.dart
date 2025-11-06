// lib/src/features/analytics/presentation/dashboard_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _timeRange = '24h';
  late List<Map<String, dynamic>> _data;

  @override
  void initState() {
    super.initState();
    _data = _generateHistoricalData(_timeRange);
  }

  List<Map<String, dynamic>> _generateHistoricalData(String range) {
    final random = Random();
    final now = DateTime.now();
    int intervals = range == '24h' ? 24 : range == '7d' ? 7 : 30;
    List<Map<String, dynamic>> data = [];
    for (int i = intervals; i >= 0; i--) {
      final time = now.subtract(Duration(
        hours: range == '24h' ? i : 0,
        days: range == '24h' ? 0 : i,
      ));
      data.add({
        'time': range == '24h' ? '${time.hour}:00' : '${time.month}/${time.day}',
        'ph': 6.0 + random.nextDouble() * 1.5,
        'temperature': 22 + random.nextDouble() * 6,
        'waterLevel': 70 + random.nextDouble() * 25,
        'nutrientLevel': 60 + random.nextDouble() * 30,
      });
    }
    return data;
  }

  final List<Map<String, String>> _stats = [
    {'title': 'Average pH', 'value': '6.4', 'change': '+2.1%', 'trend': 'up'},
    {'title': 'Avg Temperature', 'value': '24.2°C', 'change': '-1.5%', 'trend': 'down'},
    {'title': 'Water Efficiency', 'value': '94%', 'change': '+5.2%', 'trend': 'up'},
    {'title': 'Growth Rate', 'value': '12.5%', 'change': '+8.1%', 'trend': 'up'},
  ];

  void _onTimeRangeChanged(String newRange) {
    setState(() {
      _timeRange = newRange;
      _data = _generateHistoricalData(newRange);
    });
  }

  Widget _buildStatCard(Map<String, String> stat) {
    final isUp = stat['trend'] == 'up';
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(stat['title']!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(stat['value']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(children: [
            Icon(isUp ? Icons.trending_up : Icons.trending_down, color: isUp ? Colors.green : Colors.red, size: 16),
            const SizedBox(width: 6),
            Text(stat['change']!, style: TextStyle(color: isUp ? Colors.green[600] : Colors.red[600], fontSize: 12)),
          ])
        ]),
      ),
    );
  }

  Widget _buildLineChart(String title, String field, Color color, double minY, double maxY) {
    // convert data into FlSpot
    final spots = _data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value[field] as num).toDouble())).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: color,
                  spots: spots,
                  dotData: FlDotData(show: true),
                  barWidth: 2,
                )
              ],
            )),
          )
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Analytics Dashboard", style: TextStyle(color: Colors.green)),
        iconTheme: const IconThemeData(color: Colors.green),
        actions: [
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.download, size: 18), label: const Text('Export', style: TextStyle(color: Colors.black))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // time range chips
          Row(mainAxisAlignment: MainAxisAlignment.center, children: ['24h', '7d', '30d'].map((r) {
            final selected = _timeRange == r;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ChoiceChip(
                label: Text(r),
                selected: selected,
                onSelected: (_) => _onTimeRangeChanged(r),
                selectedColor: Colors.green,
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
              ),
            );
          }).toList()),
          const SizedBox(height: 20),
          GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12, children: _stats.map(_buildStatCard).toList()),
          _buildLineChart('pH Levels Over Time', 'ph', Colors.blue, 5.5, 7.5),
          _buildLineChart('Temperature Over Time', 'temperature', Colors.red, 18, 30),
          _buildLineChart('Water Level Over Time', 'waterLevel', Colors.cyan, 0, 100),
          _buildLineChart('Nutrient Levels Over Time', 'nutrientLevel', Colors.green, 0, 100),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('AI Insights', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                // these are static for now - replace with your ML output later
                Text('• Your pH levels have been stable within optimal range for the past 24 hours.'),
                SizedBox(height: 6),
                Text('• Consider increasing nutrient concentration during evening hours for better uptake.'),
                SizedBox(height: 6),
                Text('• Water efficiency has improved by 5% compared to last week.'),
              ]),
            ),
          ),
          const SizedBox(height: 120),
        ]),
      ),
    );
  }
}
