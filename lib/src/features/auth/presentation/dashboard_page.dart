import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui';
import 'package:naihydro/src/features/auth/presentation/alerts_page.dart';
import 'package:naihydro/src/features/auth/presentation/control_panel.dart';
import '../presentation/data/farm_repository.dart';
import '../presentation/models/farm_model.dart';
import 'farm_details_page.dart';

const Color kPrimaryGreen = Color(0xFF558B2F);
const Color kAccentGreen = Color(0xFF8BC34A);
const Color kBackgroundColor = Color(0xFFC7CEC8);
const Color kCardColor = Colors.white10;
const Color kLightText = Colors.white;

class DashboardPage extends StatefulWidget {
  final String deviceId;
  final FarmModel? farm;
  final FarmRepository? repository;

  const DashboardPage({
    Key? key,
    required this.deviceId,
    this.farm,
    this.repository,
  }) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _timeRange = '24h';
  late List<Map<String, dynamic>> _data = [];
  late FirebaseDatabase _database;
  Map<String, dynamic> _historicalMetrics = {};
  Map<String, dynamic> _currentData = {};
  bool _isLoading = true;

  double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

  @override
  void initState() {
    super.initState();
    _database = FirebaseDatabase.instance;
    _loadCurrentData();
    _loadHistoricalData();
  }

  void _loadCurrentData() {
    _database.ref('processed/${widget.deviceId}').onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map?;
        if (data != null && mounted) {
          setState(() {
            _currentData = Map<String, dynamic>.from(data);
          });
        }
      }
    });
  }

Future<void> _loadHistoricalData() async {
  try {
    setState(() => _isLoading = true);

    // Calculate time range
    final now = DateTime.now();
    int hours = _timeRange == '24h' ? 24 : 0;
    int days = _timeRange == '24h' ? 0 : (_timeRange == '7d' ? 7 : 30);
    final startTime = now.subtract(Duration(hours: hours, days: days));
    final startTimestamp = startTime.millisecondsSinceEpoch;

    print('📊 Fetching historical data from ${startTime.toIso8601String()}');
    print('   Device: ${widget.deviceId}');
    print('   Start timestamp: $startTimestamp');

    // Query historical data from Firebase
    final snapshot = await _database
        .ref('history/${widget.deviceId}')
        .orderByKey()
        .startAt(startTimestamp.toString())
        .get();

    if (snapshot.exists) {
      final historyData = snapshot.value as Map?;
      
      if (historyData != null && historyData.isNotEmpty) {
        print('✅ Found ${historyData.length} historical records');
        
        List<Map<String, dynamic>> parsedData = [];
        
        historyData.forEach((key, value) {
          if (value is Map) {
            try {
              // Parse timestamp from key (milliseconds)
              final timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(key));
              
              parsedData.add({
                'timestamp': timestamp,
                'time': _timeRange == '24h'
                    ? '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}'
                    : '${timestamp.month}/${timestamp.day}',
                'pH': _toDouble(value['pH']) ?? 6.5,
                'temperature': _toDouble(value['DHT_temp']) ?? 24.0,
                'waterLevel': _toDouble(value['water_level']) ?? 50.0,
                'nutrientLevel': _toDouble(value['TDS']) ?? 1000.0,
              });
            } catch (e) {
              print('⚠️ Error parsing entry $key: $e');
            }
          }
        });
        
        // Sort by timestamp
        parsedData.sort((a, b) => 
          (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime)
        );
        
        if (parsedData.length < 5) {
          print('⚠️ Not enough historical data (${parsedData.length} points), generating sample data');
          _loadCurrentDataAndGenerate();
        } else {
          setState(() {
            _data = parsedData;
            _calculateMetrics();
          });
          print('✅ Loaded ${parsedData.length} data points for ${_timeRange}');
        }
      } else {
        print('⚠️ No historical data available, using current data + generation');
        _loadCurrentDataAndGenerate();
      }
    } else {
      print('⚠️ No history node exists yet, using current data + generation');
      _loadCurrentDataAndGenerate();
    }

    setState(() => _isLoading = false);
  } catch (e) {
    print('❌ Error loading historical data: $e');
    setState(() => _isLoading = false);
    _loadCurrentDataAndGenerate();
  }
}


// Fallback: Load current data and generate historical estimates
Future<void> _loadCurrentDataAndGenerate() async {
  try {
    final snapshot = await _database.ref('processed/${widget.deviceId}').get();

    if (snapshot.exists) {
      final data = snapshot.value as Map?;
      if (data != null) {
        _generateDataFromFirebase(Map<String, dynamic>.from(data));
      } else {
        _generateHistoricalData(_timeRange);
      }
    } else {
      _generateHistoricalData(_timeRange);
    }
  } catch (e) {
    print('❌ Error loading current data: $e');
    _generateHistoricalData(_timeRange);
  }
}
  void _generateDataFromFirebase(Map<String, dynamic> latestData) {
    final now = DateTime.now();
    List<Map<String, dynamic>> generatedData = [];

    int intervals = _timeRange == '24h' ? 24 : _timeRange == '7d' ? 7 : 30;

    final basePh = double.tryParse(latestData['pH'].toString()) ?? 6.5;
    final baseTemp = double.tryParse(latestData['DHT_temp'].toString()) ?? 24.0;
    final baseWater = double.tryParse(latestData['water_level'].toString()) ?? 50.0;
    final baseTds = double.tryParse(latestData['TDS'].toString()) ?? 1000.0;

    final random = Random();

    for (int i = intervals; i >= 0; i--) {
      final time = now.subtract(Duration(
        hours: _timeRange == '24h' ? i : 0,
        days: _timeRange == '24h' ? 0 : i,
      ));

      generatedData.add({
        'timestamp': time,
        'time': _timeRange == '24h'
            ? '${time.hour.toString().padLeft(2, '0')}:00'
            : '${time.month}/${time.day}',
        'pH': (basePh + (random.nextDouble() - 0.5) * 1.0).clamp(5.5, 8.0),
        'temperature': (baseTemp + (random.nextDouble() - 0.5) * 4).clamp(15.0, 32.0),
        'waterLevel': (baseWater + (random.nextDouble() - 0.5) * 10).clamp(0.0, 100.0),
        'nutrientLevel': (baseTds + (random.nextDouble() - 0.5) * 200).clamp(400.0, 2000.0),
      });
    }

    setState(() {
      _data = generatedData;
      _calculateMetrics();
    });
  }

  void _generateHistoricalData(String range) {
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
        'timestamp': time,
        'time': range == '24h'
            ? '${time.hour.toString().padLeft(2, '0')}:00'
            : '${time.month}/${time.day}',
        'pH': 6.0 + random.nextDouble() * 1.5,
        'temperature': 22 + random.nextDouble() * 6,
        'waterLevel': 70 + random.nextDouble() * 25,
        'nutrientLevel': 60 + random.nextDouble() * 30,
      });
    }

    setState(() {
      _data = data;
      _calculateMetrics();
    });
  }

  void _calculateMetrics() {
    if (_data.isEmpty) return;

    final phValues = _data.map((d) => (d['pH'] as num).toDouble()).toList();
    final tempValues = _data.map((d) => (d['temperature'] as num).toDouble()).toList();
    final waterValues = _data.map((d) => (d['waterLevel'] as num).toDouble()).toList();
    final nutrientValues = _data.map((d) => (d['nutrientLevel'] as num).toDouble()).toList();

    final avgPh = phValues.reduce((a, b) => a + b) / phValues.length;
    final avgTemp = tempValues.reduce((a, b) => a + b) / tempValues.length;
    final avgWater = waterValues.reduce((a, b) => a + b) / waterValues.length;
    final avgNutrient = nutrientValues.reduce((a, b) => a + b) / nutrientValues.length;

    _historicalMetrics = {
      'avgPh': avgPh.toStringAsFixed(2),
      'avgTemp': avgTemp.toStringAsFixed(1),
      'waterEfficiency': ((avgWater / 100) * 100).toStringAsFixed(0),
      'growthRate': (((avgNutrient / 1500) * 100).clamp(0, 100)).toStringAsFixed(1),
      'phTrend': phValues.last > phValues.first ? 'up' : 'down',
      'tempTrend': tempValues.last > tempValues.first ? 'up' : 'down',
      'waterTrend': waterValues.last > waterValues.first ? 'up' : 'down',
      'nutrientTrend': nutrientValues.last > nutrientValues.first ? 'up' : 'down',
      'minPh': phValues.reduce(min).toStringAsFixed(2),
      'maxPh': phValues.reduce(max).toStringAsFixed(2),
      'minTemp': tempValues.reduce(min).toStringAsFixed(1),
      'maxTemp': tempValues.reduce(max).toStringAsFixed(1),
    };
  }

  void _onTimeRangeChanged(String newRange) {
    setState(() {
      _timeRange = newRange;
      _data = [];
    });
    _loadHistoricalData();
  }

  Future<void> _exportData() async {
    try {
      String csv = 'Timestamp,Time,pH,Temperature (°C),Water Level (%),Nutrient Level (ppm)\n';

      for (var entry in _data) {
        csv +=
            '${entry['timestamp']},${entry['time']},${(entry['pH'] as double).toStringAsFixed(2)},${(entry['temperature'] as double).toStringAsFixed(1)},${(entry['waterLevel'] as double).toStringAsFixed(1)},${(entry['nutrientLevel'] as double).toStringAsFixed(0)}\n';
      }

      final directory = await getTemporaryDirectory();
      final fileName = 'naihydro_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'NaiHydro Dashboard Export',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data exported successfully!'),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    final isUp = stat['trend'] == 'up';
    return _buildGlassCard(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat['title']!,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat['value']!,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isUp ? Icons.trending_up : Icons.trending_down,
                color: isUp ? kAccentGreen : Colors.red[300],
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                stat['change']!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isUp ? kAccentGreen : Colors.red[300],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLineChart(
    String title,
    String field,
    Color color,
    double minY,
    double maxY,
  ) {
    if (_data.isEmpty) {
      return _buildGlassCard(
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Loading data...',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

    final spots = _data
        .asMap()
        .entries
        .map((e) => FlSpot(
        e.key.toDouble(), 
        _toDouble(e.value[field]) ?? 0.0
    ))
        .toList();

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
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
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> stats = [
      {
        'title': 'Average pH',
        'value': '${_historicalMetrics['avgPh'] ?? '-'}',
        'change': '+0.2',
        'trend': _historicalMetrics['phTrend'] ?? 'up'
      },
      {
        'title': 'Avg Temperature',
        'value': '${_historicalMetrics['avgTemp'] ?? '-'}°C',
        'change': '-0.5',
        'trend': _historicalMetrics['tempTrend'] ?? 'up'
      },
      {
        'title': 'Water Efficiency',
        'value': '${_historicalMetrics['waterEfficiency'] ?? '-'}%',
        'change': '+2.1',
        'trend': _historicalMetrics['waterTrend'] ?? 'up'
      },
      {
        'title': 'Growth Rate',
        'value': '${_historicalMetrics['growthRate'] ?? '-'}%',
        'change': '+5.3',
        'trend': _historicalMetrics['nutrientTrend'] ?? 'up'
      },
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: kBackgroundColor,
          image: const DecorationImage(
            image: AssetImage('assets/images/detailspg.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.transparent,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: kLightText),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Icon(Icons.bar_chart, color: kPrimaryGreen, size: 32),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Analytics Dashboard",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: kLightText,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _exportData,
                        icon: Icon(Icons.download, size: 18, color: kPrimaryGreen),
                        label: Text(
                          'Export',
                          style: GoogleFonts.poppins(color: kLightText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Time Range Chips - ALWAYS VISIBLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['24h', '7d', '30d'].map((r) {
                  final selected = _timeRange == r;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ChoiceChip(
                      label: Text(r),
                      selected: selected,
                      onSelected: (_) => _onTimeRangeChanged(r),
                      selectedColor: kPrimaryGreen,
                      backgroundColor: Colors.white24,
                      labelStyle: GoogleFonts.poppins(
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: kPrimaryGreen,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats Grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: stats.map(_buildStatCard).toList(),
                          ),

                          const SizedBox(height: 16),

                          // Charts
                          _buildLineChart('pH Levels Over Time', 'pH', Colors.blue[300]!, 5.5, 8.0),
                          const SizedBox(height: 12),
                          _buildLineChart('Temperature Over Time', 'temperature', Colors.red[300]!, 15.0, 32.0),
                          const SizedBox(height: 12),
                          _buildLineChart('Water Level Over Time', 'waterLevel', Colors.cyan[300]!, 0, 100),
                          const SizedBox(height: 12),
                          _buildLineChart('Nutrient Levels Over Time', 'nutrientLevel', kAccentGreen, 400.0, 2000.0),

                          const SizedBox(height: 16),

                          // AI Insights
                          _buildGlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Insights',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '• pH levels: ${_historicalMetrics['avgPh']} (Range: ${_historicalMetrics['minPh']} - ${_historicalMetrics['maxPh']})',
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '• Temperature: ${_historicalMetrics['avgTemp']}°C (Range: ${_historicalMetrics['minTemp']} - ${_historicalMetrics['maxTemp']}°C)',
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '• Nutrient concentration at ${_historicalMetrics['growthRate']}% - ${double.parse(_historicalMetrics['growthRate'] ?? '0') > 70 ? 'Consider dilution' : 'Optimal for growth'}.',
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '• Water efficiency: ${_historicalMetrics['waterEfficiency']}%',
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
            ),

            // Bottom Navigation
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return _buildGlassCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Home', false, () {
                  if (widget.farm != null && widget.repository != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FarmDetailsPage(
                          repository: widget.repository!,
                          farm: widget.farm!,
                        ),
                      ),
                    );
                  } else {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                }),
                _buildNavItem(Icons.notifications, 'Alerts', false, () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AlertsPage(
                        deviceId: widget.deviceId,
                        farm: widget.farm,
                        repository: widget.repository,
                      ),
                    ),
                  );
                }),
                _buildNavItem(Icons.flash_on, 'Control', false, () {
                  if (widget.farm != null && widget.repository != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ControlPanelPage(
                          farm: widget.farm!,
                          repository: widget.repository!,
                        ),
                      ),
                    );
                  }
                }),
                _buildNavItem(Icons.bar_chart, 'Analytics', true, () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? kPrimaryGreen : Colors.white70,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isActive ? kPrimaryGreen : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}