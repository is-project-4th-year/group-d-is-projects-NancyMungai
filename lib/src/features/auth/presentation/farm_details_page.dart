import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naihydro/src/features/auth/presentation/settings_page.dart';
import 'dart:ui'; 
import '../presentation/data/farm_repository.dart';
import '../presentation/models/farm_model.dart';
import 'dart:async';
import '../../common/widgets/bottom_nav.dart';
import 'control_panel.dart';
import 'package:naihydro/src/features/auth/presentation/dashboard_page.dart';
import 'package:naihydro/src/features/auth/presentation/alerts_page.dart';

// --- CUSTOM THEME COLORS & CONSTANTS ---
const Color kPrimaryGreen = Color(0xFF558B2F); // A deep, earthy green
const Color kAccentGreen = Color(0xFF8BC34A); // A lighter, vibrant green
const Color kBackgroundColor = Color(0xFFC7CEC8); // Muted gray-green background from image
const Color kCardColor = Colors.white10; // Transparent white for glass effect
const Color kDarkText = Colors.white70; // Dark text
const Color kLightText = Colors.white;

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
  DateTime? _lastUpdateTime;
  late final FarmRepository _repo;
   late final Stream<List<FarmModel>> _farmsStream;

  @override
  void initState() {
    super.initState();
     _repo = FarmRepository();
      _farmsStream = _repo.getFarmsStream();
    _sensorStream = widget.repository.sensorsForFarm(widget.farm.id);
  }

  String _getOverallStatus(Map<String, dynamic> sensors) {
    // Check critical conditions
    final waterLevel = _toDouble(sensors['waterLevel']);
    final nutrientLevel = _toDouble(
      sensors['TDS'] ?? sensors['TDS'] ?? sensors['nutrientLevel']
    );

    
    if (waterLevel != null && waterLevel < 20) return 'critical';
    if (nutrientLevel != null && nutrientLevel < 700) return 'critical';
    
    // Check warnings
    final ph = _toDouble(sensors['ph']);
    final temp = _toDouble(sensors['temperature']);
    
    if (ph != null && (ph < 6.0 || ph > 7.0)) return 'warning';
    if (temp != null && (temp < 20 || temp > 26)) return 'warning';
    if (waterLevel != null && waterLevel < 30) return 'warning';
    if (nutrientLevel != null && (nutrientLevel < 1000 || nutrientLevel > 1800)) return 'warning';
    
    return 'optimal';
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }
//  Extract timestamp from sensors data
  DateTime? _extractTimestamp(Map<String, dynamic> sensors) {
    try {
      final timestamp = sensors['timestamp'];
      if (timestamp == null) return null;
 DateTime dt;

     if (timestamp is String) {
      dt = DateTime.parse(timestamp);
    } else if (timestamp is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      return null;
    }

    // Convert to local time
    return dt.toLocal();

  } catch (e) {
    return null;
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
            color: kCardColor, // Semi-transparent background
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3), // Light border
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Set Scaffold background to transparent or the base color
      backgroundColor: Colors.transparent, 
      body: Container(
        // 2. Wrap the entire body with a Container for the background image
        decoration: BoxDecoration(
          color: kBackgroundColor,
          image: const DecorationImage(
            // **NOTE**: Update this path to your specific background image asset.
            image: AssetImage('assets/images/detailspg.jpeg'), 
            fit: BoxFit.cover,
          ),
        ),
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _sensorStream,
          builder: (context, snapshot) {
            final sensors = snapshot.data ?? {};
            final hasData = sensors.isNotEmpty;
            final overallStatus = hasData ? _getOverallStatus(sensors) : 'unknown';
          
            if (hasData) {
              _lastUpdateTime = _extractTimestamp(sensors);
            }

            return Column(
              children: [
                // Header
                Container(
                  // Use a subtle color or keep it mostly transparent against the background
                  color: Colors.transparent, 
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back, color: kDarkText),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              Icon(Icons.eco, color: kPrimaryGreen, size: 32),
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
                                        color: Colors.white70,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 12, color: Colors.white70),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            widget.farm.location,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color:Colors.white70,
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
                                icon: Icon(Icons.settings, color:Colors.white70),
                                onPressed: () {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (_) =>  SettingsPage(
                                      onNavigate: (page) {
       
        Navigator.pop(context);
      },
      onLogout: () {
        // Logout logic if needed
        Navigator.pop(context);
      },
                                     ),
                                   ),
                                 );
                                },
                              ),
                            ],
                          ),
                        ),

                        // Status Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: _buildGlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.dashboard,
                                  color: overallStatus == 'optimal'
                                    ? kPrimaryGreen
                                    : overallStatus == 'warning'
                                      ? Colors.orange
                                      : Colors.red,
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
                                            ? kPrimaryGreen
                                            : overallStatus == 'warning'
                                              ? Colors.orange[800]
                                              : Colors.red[600],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Last updated: ${_formatTime(_lastUpdateTime)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.white70,
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
      ),
    );
  }

  Widget _buildNoDataState() {
    // ... (no changes needed here)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off, size: 64, color: kDarkText.withOpacity(0.4)),
            SizedBox(height: 16),
            Text(
              'No Sensor Data',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kDarkText,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Waiting for data from ${widget.farm.deviceId ?? "ESP32 device"}...',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: kDarkText.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MODIFIED _buildSensorData METHOD ---
  Widget _buildSensorData(Map<String, dynamic> sensors) {
    final ph = _toDouble(sensors['ph']);
    final temp = _toDouble(sensors['temperature']);
    final water = _toDouble(sensors['waterLevel']);
    final nutrients = _toDouble(
      sensors['TDS'] ?? sensors['TDS'] ?? sensors['nutrientLevel']
    );
      final humidity = _toDouble(sensors['DHT_humidity'] ?? sensors['humidity']);
    final lastUpdatedStr = _formatTime(_lastUpdateTime);

    // Prepare the asset path for the crop image
    String cropAssetPath = '';
    if (widget.farm.cropType != null) {
      // Normalise crop type name (e.g., "Lettuce Profile" -> "lettuce")
      final cropName = widget.farm.cropType!.toLowerCase().split(' ').first;
      // **NOTE**: This assumes your images are named 'lettuce.png', 'tomato.png', etc.
      // and are located in the assets/crops folder.
      cropAssetPath = 'assets/crops/$cropName.png';
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farm Image/Crop Info (MODIFIED TO FILL CARD)
            if (widget.farm.cropType != null)
              _buildGlassCard(
                padding: EdgeInsets.zero, // Remove padding from the card itself
                child: Container(
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Image widget modified to use AspectRatio and BoxFit.cover
                      AspectRatio(
                        aspectRatio: 16 / 9, // Define the desired image shape (e.g., 4/3 or 16/9)
                        child: Image.asset(
                          cropAssetPath,
                          fit: BoxFit.cover, // Ensures the image fills the entire AspectRatio box
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback if the specific image is not found
                            return Container(
                              color: kPrimaryGreen.withOpacity(0.1),
                              child: Center(child: Icon(Icons.grass, size: 48, color: kPrimaryGreen)),
                            );
                          },
                        ),
                      ),
                      
                      // Text is placed below the image and is padded
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                        child: Text(
                          widget.farm.cropType!,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
                color: Colors.white70,
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
                  lastUpdated: lastUpdatedStr,
                ),
                _buildStatusCard(
                  title: 'Temperature',
                  value: temp != null ? '${temp.toStringAsFixed(1)}°C' : '-',
                  icon: Icons.thermostat,
                  status: _getTempStatus(temp),
                  lastUpdated: lastUpdatedStr,
                ),
                _buildStatusCard(
                  title: 'Water Level',
                  value: water != null ? '${water.toStringAsFixed(1)}cm' : '-',
                  icon: Icons.water_drop,
                  status: _getWaterStatus(water),
                  lastUpdated: lastUpdatedStr,
                ),
                _buildStatusCard(
                  title: 'Nutrients',
                  value: nutrients != null ? '${nutrients.toStringAsFixed(0)} ppm' : '-',
                  icon: Icons.eco,
                  status: _getNutrientStatus(nutrients),
                  lastUpdated: lastUpdatedStr,
                ),
        
                _buildStatusCard(
                  title: 'Humidity',
                  value: humidity != null ? '${humidity.toStringAsFixed(0)}%' : '-',
                  icon: Icons.water,
                  status: _getHumidityStatus(humidity),
                  lastUpdated: lastUpdatedStr,
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
                color: Colors.white,
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
    
    if (status == 'optimal') {
      statusColor = kPrimaryGreen;
    } else if (status == 'warning') {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return _buildGlassCard(
      padding: EdgeInsets.all(16),
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
                    color: Colors.white
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
            'Last Update: $lastUpdated',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white,
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
    return _buildGlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: kPrimaryGreen),
              SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return _buildGlassCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          // Inner decoration to fine-tune the glass look of the bar
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
                _buildNavItem(Icons.home, 'Home', true, () {
                  Navigator.of(context).push( MaterialPageRoute(
        builder: (_) => FarmDetailsPage(repository: _repo, farm: widget.farm),
      ),
    );
                }),
                _buildNavItem(Icons.notifications, 'Alerts', false, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlertsPage(deviceId: widget.farm.deviceId!),
                    ),
                  );
                }),
                _buildNavItem(Icons.flash_on, 'Control', false, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ControlPanelPage(
                        farm: widget.farm,
                        repository: widget.repository,
                      ),
                    ),
                  );
                }),
                _buildNavItem(Icons.bar_chart, 'Analytics', false, () {

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DashboardPage( deviceId: widget.farm.deviceId!,),
                    ),
                  );
                }),
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
    if (water > 1) return 'optimal';//shallow farm
    if (water > 5) return 'warning';
    return 'critical';
  }

String _getNutrientStatus(double? value) {
  if (value == null) return 'unknown';
  if (value < 500) return 'critical';        // too low
  if (value >= 500 && value <= 1000) return 'optimal';  // healthy range
  if (value > 1000 && value <= 1800) return 'warning';  // moderate-high
  if (value > 1800) return 'critical';      // too high
  return 'unknown';
}


  String _getHumidityStatus(double? humidity) {
    if (humidity == null) return 'unknown';
    if (humidity < 30) return 'warning'; // Too dry
    if (humidity >= 40 && humidity <= 80) return 'optimal';
    if (humidity > 85) return 'warning'; // Too humid
    return 'warning';
  }
}
