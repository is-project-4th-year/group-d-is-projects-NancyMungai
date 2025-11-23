import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:naihydro/src/features/auth/presentation/data/auth_service.dart';
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
  final AuthService authService;

  const DashboardPage({
    Key? key,
    required this.deviceId,
    this.farm,
    this.repository,
    required this.authService,
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

      final now = DateTime.now();
      int hours = _timeRange == '24h' ? 24 : 0;
      int days = _timeRange == '24h' ? 0 : (_timeRange == '7d' ? 7 : 30);
      final startTime = now.subtract(Duration(hours: hours, days: days));
      final startTimestamp = startTime.millisecondsSinceEpoch;

      print('📊 Fetching historical data from ${startTime.toIso8601String()}');

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
                final timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(key));

                parsedData.add({
                  'timestamp': timestamp,
                  'time': _timeRange == '24h'
                      ? '${timestamp.hour.toString().padLeft(2, '0')}:00'
                      : _timeRange == '7d'
                          ? _getDayLabel(timestamp)
                          : '${timestamp.month}/${timestamp.day}',
                  'pH': _toDouble(value['pH'] ?? value['ph']) ?? 6.5,
                  'temperature':
                      _toDouble(value['DHT_temp'] ?? value['temperature'] ?? value['temp']) ?? 24.0,
                  'waterLevel': _toDouble(value['water_level'] ?? value['waterLevel']) ?? 50.0,
                  'nutrientLevel':
                      _toDouble(value['TDS'] ?? value['tds'] ?? value['nutrientLevel']) ?? 1000.0,
                  'humidityLevel': _toDouble(value['DHT_humidity'] ?? value['humidity']) ?? 60.0,
                });
              } catch (e) {
                print('⚠️ Error parsing entry $key: $e');
              }
            }
          });

          parsedData.sort((a, b) =>
              (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));

          if (parsedData.length < 3) {
            print('⚠️ Not enough data, generating supplementary data');
            _loadCurrentDataAndGenerate();
          } else {
            setState(() {
              _data = parsedData;
              _calculateMetrics();
            });
            print('✅ Loaded ${parsedData.length} data points');
          }
        } else {
          _loadCurrentDataAndGenerate();
        }
      } else {
        _loadCurrentDataAndGenerate();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error: $e');
      setState(() => _isLoading = false);
      _loadCurrentDataAndGenerate();
    }
  }

  String _getDayLabel(DateTime date) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }

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

    final basePh = double.tryParse(latestData['pH']?.toString() ?? latestData['ph']?.toString() ?? '') ?? 6.5;
    final baseTemp = double.tryParse(latestData['DHT_temp']?.toString() ?? latestData['temperature']?.toString() ?? '') ?? 24.0;
    final baseWater = double.tryParse(latestData['water_level']?.toString() ?? latestData['waterLevel']?.toString() ?? '') ?? 50.0;
    final baseTds = double.tryParse(latestData['TDS']?.toString() ?? latestData['nutrientLevel']?.toString() ?? '') ?? 1000.0;
    final baseHumidity = double.tryParse(latestData['DHT_humidity']?.toString() ?? latestData['humidity']?.toString() ?? '') ?? 60.0;

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
            : _timeRange == '7d'
                ? _getDayLabel(time)
                : '${time.month}/${time.day}',
        'pH': (basePh + (random.nextDouble() - 0.5) * 1.0).clamp(7, 12.0),
        'temperature': (baseTemp + (random.nextDouble() - 0.5) * 4).clamp(15.0, 32.0),
        'waterLevel': (baseWater + (random.nextDouble() - 0.5) * 10).clamp(0.0, 100.0),
        'nutrientLevel': (baseTds + (random.nextDouble() - 0.5) * 200).clamp(10.0, 700.0),
        'humidityLevel': (baseHumidity + (random.nextDouble() - 0.5) * 10).clamp(100.0, 90.0),
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
            : range == '7d'
                ? _getDayLabel(time)
                : '${time.month}/${time.day}',
        'pH': 6.0 + random.nextDouble() * 1.5,
        'temperature': 22 + random.nextDouble() * 6,
        'waterLevel': 70 + random.nextDouble() * 25,
        'nutrientLevel': 1000 + random.nextDouble() * 500,
        'humidityLevel': 60 + random.nextDouble() * 20,
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

    final phChange = _calculateChange(phValues.last, phValues.first);
    final tempChange = _calculateChange(tempValues.last, tempValues.first);
    final waterChange = _calculateChange(waterValues.last, waterValues.first);
    final nutrientChange = _calculateChange(nutrientValues.last, nutrientValues.first);

    _historicalMetrics = {
      'avgPh': avgPh.toStringAsFixed(2),
      'avgTemp': avgTemp.toStringAsFixed(1),
      'waterEfficiency': ((avgWater / 100) * 100).toStringAsFixed(0),
      'growthRate': (((avgNutrient / 1500) * 100).clamp(0, 100)).toStringAsFixed(1),
      'phTrend': phValues.last > phValues.first ? 'up' : 'down',
      'tempTrend': tempValues.last > tempValues.first ? 'up' : 'down',
      'waterTrend': waterValues.last > waterValues.first ? 'up' : 'down',
      'nutrientTrend': nutrientValues.last > nutrientValues.first ? 'up' : 'down',
      'phChange': phChange,
      'tempChange': tempChange,
      'waterChange': waterChange,
      'nutrientChange': nutrientChange,
      'minPh': phValues.reduce(min).toStringAsFixed(2),
      'maxPh': phValues.reduce(max).toStringAsFixed(2),
      'minTemp': tempValues.reduce(min).toStringAsFixed(1),
      'maxTemp': tempValues.reduce(max).toStringAsFixed(1),
    };
  }

  String _calculateChange(double current, double previous) {
    if (previous == 0) return '0%';
    final change = ((current - previous) / previous * 100);
    return '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%';
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
      String csv =
          'Timestamp,Time,pH,Temperature (°C),Water Level (cm),Nutrient Level (ppm),Humidity (%)\n';

      for (var entry in _data) {
        csv +=
            '${entry['timestamp']},${entry['time']},${(entry['pH'] as double).toStringAsFixed(2)},${(entry['temperature'] as double).toStringAsFixed(1)},${(entry['waterLevel'] as double).toStringAsFixed(1)},${(entry['nutrientLevel'] as double).toStringAsFixed(0)},${(entry['humidityLevel'] as double).toStringAsFixed(0)}\n';
      }

      final directory = await getTemporaryDirectory();
      final farmName = widget.farm?.name ?? 'farm';
      final filterLabel = _timeRange == '24h' ? '24hours' : _timeRange == '7d' ? '7days' : '30days';
      final fileName =
          '${farmName}_report_${filterLabel}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'NaiHydro Dashboard Report - $_timeRange',
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
        .map((e) => FlSpot(e.key.toDouble(), _toDouble(e.value[field]) ?? 0.0))
        .toList();

    final xInterval = _calculateXInterval(_data.length);
    final yInterval = _calculateYInterval(minY, maxY);

    return _buildGlassCard(
      padding: const EdgeInsets.all(12),
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
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: yInterval,
                    verticalInterval: xInterval,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.white.withOpacity(0.08),
                        strokeWidth: 0.8,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.white.withOpacity(0.08),
                        strokeWidth: 0.8,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: xInterval,
                        reservedSize: 38,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= _data.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              _data[index]['time'].toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 8.5,
                                color: Colors.white60,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: yInterval,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 8.5,
                              color: Colors.white60,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: color,
                      spots: spots,
                      dotData: FlDotData(
                        show: _data.length <= 12,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 2.5,
                            color: color,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: false,
                      ),
                    )
                  ],
                  clipData: const FlClipData.all(),
                  lineTouchData: LineTouchData(enabled: false),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  double _calculateXInterval(int dataLength) {
    if (dataLength <= 5) return 1;
    if (dataLength <= 12) return 2;
    if (dataLength <= 24) return 3;
    return (dataLength / 6).ceilToDouble();
  }

  double _calculateYInterval(double minY, double maxY) {
    final range = maxY - minY;
    if (range < 1) return 0.1;
    if (range < 5) return 0.5;
    if (range < 10) return 1;
    if (range < 50) return 5;
    if (range < 100) return 10;
    return (range / 5).roundToDouble();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> stats = [
      {
        'title': 'Average pH',
        'value': '${_historicalMetrics['avgPh'] ?? '-'}',
        'change': _historicalMetrics['phChange'] ?? '+0.0%',
        'trend': _historicalMetrics['phTrend'] ?? 'up'
      },
      {
        'title': 'Average Temperature',
        'value': '${_historicalMetrics['avgTemp'] ?? '-'}°C',
        'change': _historicalMetrics['tempChange'] ?? '+0.0%',
        'trend': _historicalMetrics['tempTrend'] ?? 'up'
      },
      {
        'title': 'Water Efficiency',
        'value': '${_historicalMetrics['waterEfficiency'] ?? '-'}%',
        'change': _historicalMetrics['waterChange'] ?? '+0.0%',
        'trend': _historicalMetrics['waterTrend'] ?? 'up'
      },
      {
        'title': 'Growth Rate',
        'value': '${_historicalMetrics['growthRate'] ?? '-'}%',
        'change': _historicalMetrics['nutrientChange'] ?? '+0.0%',
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
                      const SizedBox(width: 8),
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
                          'Report',
                          style: GoogleFonts.poppins(color: kLightText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

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
                      backgroundColor: kPrimaryGreen.withOpacity(0.5),
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
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: stats.map(_buildStatCard).toList(),
                          ),

                          const SizedBox(height: 20),

                          _buildLineChart(
                            'pH Levels',
                            'pH',
                            Colors.blue[300]!,
                            7,
                            12.0,
                          ),
                          const SizedBox(height: 16),
                          _buildLineChart(
                            'Temperature',
                            'temperature',
                            Colors.red[300]!,
                            15.0,
                            32.0,
                          ),
                          const SizedBox(height: 16),
                          _buildLineChart(
                            'Water Level',
                            'waterLevel',
                            Colors.cyan[300]!,
                            0.0,
                            100.0,
                          ),
                          const SizedBox(height: 16),
                          _buildLineChart(
                            'Nutrients',
                            'nutrientLevel',
                            kAccentGreen,
                            10.0,
                            700.0,
                          ),
                          const SizedBox(height: 16),
                          _buildLineChart(
                            'Humidity',
                            'humidityLevel',
                            Colors.lightBlue[300]!,
                            30.0,
                            90.0,
                          ),

                          const SizedBox(height: 20),

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
          borderRadius: const BorderRadius.only(
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
                          authService: widget.authService,
                        ),
                      ),
                    );
                  }
                }),
                _buildNavItem(Icons.notifications, 'Alerts', false, () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AlertsPage(
                        authService: widget.authService,
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
                          authService: widget.authService,
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
          const SizedBox(height: 4),
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