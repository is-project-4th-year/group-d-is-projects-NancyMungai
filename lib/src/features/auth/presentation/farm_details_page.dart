// lib/src/features/home/presentation/farm_details_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../presentation/data/farm_repository.dart';
import '../presentation/models/farm_model.dart';
import 'dart:async';

class FarmDetailsPage extends StatefulWidget {
  final FarmRepository repository;
  final FarmModel farm;

  const FarmDetailsPage({
    required this.repository,
    required this.farm,
    Key? key,
  }) : super(key: key);

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

  String _getOverallStatus(Map<String, dynamic> sensors) {
    // Check critical conditions
    final waterLevel = _toDouble(sensors['waterLevel']);
    final nutrientLevel = _toDouble(
  sensors['nutrientLevel'] ?? sensors['TDS'] ?? sensors['tds']
);

    
    if (waterLevel != null && waterLevel < 20) return 'critical';
    if (nutrientLevel != null && nutrientLevel < 30) return 'critical';
    
    // Check warnings
    final ph = _toDouble(sensors['ph']);
    final temp = _toDouble(sensors['temperature']);
    
    if (ph != null && (ph < 6.0 || ph > 7.0)) return 'warning';
    if (temp != null && (temp < 20 || temp > 26)) return 'warning';
    if (waterLevel != null && waterLevel < 30) return 'warning';
    if (nutrientLevel != null && nutrientLevel < 60) return 'warning';
    
    return 'optimal';
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      DateTime dt;
      if (timestamp is String) {
        dt = DateTime.parse(timestamp);
      } else if (timestamp is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        return 'Unknown';
      }
      
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _sensorStream,
        builder: (context, snapshot) {
          final sensors = snapshot.data ?? {};
          final hasData = sensors.isNotEmpty;
          final overallStatus = hasData ? _getOverallStatus(sensors) : 'unknown';

          return Column(
            children: [
              // Header
              Container(
                color: Colors.white,
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            Icon(Icons.eco, color: Color(0xFF22c55e), size: 32),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.farm.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF22c55e),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          widget.farm.location,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.settings),
                              onPressed: () {
                                // Settings
                              },
                            ),
                          ],
                        ),
                      ),

                      // Status Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: overallStatus == 'optimal'
                                ? Colors.green[50]
                                : overallStatus == 'warning'
                                    ? Colors.yellow[50]
                                    : Colors.red[50],
                            border: Border.all(
                              color: overallStatus == 'optimal'
                                  ? Colors.green[200]!
                                  : overallStatus == 'warning'
                                      ? Colors.yellow[200]!
                                      : Colors.red[200]!,
                              width: 2,
                            ),

                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.dashboard,
                                color: overallStatus == 'optimal'
                                    ? Colors.green[600]
                                    : overallStatus == 'warning'
                                        ? Colors.yellow[700]
                                        : Colors.red[600],
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      overallStatus == 'optimal'
                                          ? 'All systems operational'
                                          : overallStatus == 'warning'
                                              ? 'Some parameters need attention'
                                              : overallStatus == 'critical'
                                                  ? 'Critical conditions detected'
                                                  : 'No data available',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: overallStatus == 'optimal'
                                            ? Colors.green[800]
                                            : overallStatus == 'warning'
                                                ? Colors.yellow[800]
                                                : Colors.red[800],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Last updated: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: !hasData
                    ? _buildNoDataState()
                    : _buildSensorData(sensors),
              ),

              // Bottom Navigation
              _buildBottomNav(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No Sensor Data',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Waiting for data from ${widget.farm.deviceId ?? "ESP32 device"}...',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorData(Map<String, dynamic> sensors) {
    final ph = _toDouble(sensors['ph']);
    final temp = _toDouble(sensors['temperature']);
    final water = _toDouble(sensors['waterLevel']);
    final nutrients = _toDouble(
      sensors['TDS'] ?? sensors['tds'] ?? sensors['nutrientLevel']
    );
    final timestamp = sensors['updatedAt'] ?? sensors['timestamp'];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farm Image (optional - can be removed or customized)
            if (widget.farm.cropType != null)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Color(0xFF22c55e).withOpacity(0.3), Color(0xFF16a34a).withOpacity(0.5)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.grass, size: 48, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        widget.farm.cropType!,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 16),

            // Current Conditions Header
            Text(
              'Current Conditions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),

            // Sensor Cards Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildStatusCard(
                  title: 'pH Level',
                  value: ph?.toStringAsFixed(1) ?? '-',
                  icon: Icons.science,
                  status: _getPhStatus(ph),
                  lastUpdated: _formatTime(timestamp),
                ),
                _buildStatusCard(
                  title: 'Temperature',
                  value: temp != null ? '${temp.toStringAsFixed(1)}°C' : '-',
                  icon: Icons.thermostat,
                  status: _getTempStatus(temp),
                  lastUpdated: _formatTime(timestamp),
                ),
                _buildStatusCard(
                  title: 'Water Level',
                  value: water != null ? '${water.toStringAsFixed(1)}cm' : '-',
                  icon: Icons.water_drop,
                  status: _getWaterStatus(water),
                  lastUpdated: _formatTime(timestamp),
                ),
                _buildStatusCard(
                  title: 'Nutrients',
                  value: nutrients != null ? '${nutrients.toStringAsFixed(0)} ppm' : '-',
                  icon: Icons.eco,
                  status: _getNutrientStatus(nutrients),
                  lastUpdated: _formatTime(timestamp),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2,
              children: [
                _buildActionButton(
                  icon: Icons.bar_chart,
                  label: 'Analytics',
                  onTap: () {
                    // Navigate to analytics
                  },
                ),
                _buildActionButton(
                  icon: Icons.flash_on,
                  label: 'Controls',
                  onTap: () {
                    // Navigate to controls
                  },
                ),
                _buildActionButton(
                  icon: Icons.notifications,
                  label: 'Alerts',
                  onTap: () {
                    // Navigate to alerts
                  },
                ),
                _buildActionButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () {
                    // Navigate to settings
                  },
                ),
              ],
            ),
            SizedBox(height: 80), // Space for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required IconData icon,
    required String status,
    required String lastUpdated,
  }) {
    Color statusColor;
    Color bgColor;
    Color borderColor;

    if (status == 'optimal') {
      statusColor = Colors.green[600]!;
      bgColor = Colors.green[50]!;
      borderColor = Colors.green[200]!;
    } else if (status == 'warning') {
      statusColor = Colors.yellow[700]!;
      bgColor = Colors.yellow[50]!;
      borderColor = Colors.yellow[300]!;
    } else {
      statusColor = Colors.red[600]!;
      bgColor = Colors.red[50]!;
      borderColor = Colors.red[200]!;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: statusColor, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            lastUpdated,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', true, () {
                Navigator.of(context).pop();
              }),
              _buildNavItem(Icons.notifications, 'Alerts', false, () {}),
              _buildNavItem(Icons.flash_on, 'Control', false, () {}),
              _buildNavItem(Icons.bar_chart, 'Analytics', false, () {}),
            ],
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
            color: isActive ? Color(0xFF22c55e) : Colors.grey[600],
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isActive ? Color(0xFF22c55e) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getPhStatus(double? ph) {
    if (ph == null) return 'unknown';
    if (ph >= 6.0 && ph <= 7.0) return 'optimal';
    return 'warning';
  }

  String _getTempStatus(double? temp) {
    if (temp == null) return 'unknown';
    if (temp >= 20 && temp <= 26) return 'optimal';
    return 'warning';
  }

  String _getWaterStatus(double? water) {
    if (water == null) return 'unknown';
    if (water > 30) return 'optimal';
    if (water > 15) return 'warning';
    return 'critical';
  }

 String _getNutrientStatus(double? value) {
  if (value == null) return 'unknown';
  if (value < 700) return 'critical';     // too low
  if (value < 1000) return 'warning';     // moderate
  if (value <= 1500) return 'optimal';    // healthy range
  if (value > 1800) return 'critical';    // too concentrated
  return 'warning';                       // fallback
}

}