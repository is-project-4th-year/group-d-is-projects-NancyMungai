import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:ui';
import 'package:naihydro/src/features/auth/presentation/dashboard_page.dart';
import '../../auth/presentation/control_panel.dart';
import '../../auth/presentation/models/farm_model.dart';
import '../../auth/presentation/data/farm_repository.dart';
import 'farm_details_page.dart';

const Color kPrimaryGreen = Color(0xFF558B2F);
const Color kAccentGreen = Color(0xFF8BC34A);
const Color kBackgroundColor = Color(0xFFC7CEC8);
const Color kCardColor = Colors.white10;
const Color kLightText = Colors.white;

class AlertsPage extends StatefulWidget {
  final String deviceId;
  final FarmModel? farm;
  final FarmRepository? repository;

  const AlertsPage({
    Key? key,
    required this.deviceId,
    this.farm,
    this.repository,
  }) : super(key: key);

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  late final FirebaseDatabase _database;
  late final Stream<List<Map<String, dynamic>>> _alertsStream;
  Set<String> _hiddenAlerts = {}; // For UI-only hiding
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _database = FirebaseDatabase.instance;
    _alertsStream = _getAlertsStream();
  }

  Stream<List<Map<String, dynamic>>> _getAlertsStream() {
    return _database.ref('alerts/${widget.deviceId}').onValue.map((event) {
      if (!event.snapshot.exists) return [];

      final data = event.snapshot.value as Map?;
      if (data == null) return [];

      final alerts = <Map<String, dynamic>>[];

      data.forEach((key, value) {
        if (value is Map) {
          final alert = {
            'id': key,
            'type': _getAlertType(value['type'] ?? 'unknown'),
            'message': value['body'] ?? value['title'] ?? 'Alert',
            'title': value['title'] ?? 'Alert',
            'severity': _getSeverityFromType(value['type']),
            'timestamp': _parseTimestamp(value['timestamp']),
            'acknowledged': value['acknowledged'] ?? false,
            'resolved': value['resolved'] ?? false,
            'prediction': value['prediction'] ?? 0,
            'sensorReadings': value['sensorReadings'] ?? {},
          };
          alerts.add(alert);
        }
      });

      alerts.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
      return alerts;
    });
  }

  String _getAlertType(String? type) {
    if (type == null) return 'system';
    if (type.contains('water')) return 'water';
    if (type.contains('temperature') || type.contains('temp')) return 'temperature';
    if (type.contains('nutrient') || type.contains('tds')) return 'nutrient';
    if (type.contains('ph')) return 'ph';
    if (type.contains('ml') || type.contains('prediction')) return 'ml';
    return 'system';
  }

  String _getSeverityFromType(String? type) {
    if (type == null) return 'low';
    
    final criticalTypes = [
      'water_critical',
      'temp_critical_hot',
      'temp_critical_cold',
      'ph_critical_low',
      'ph_critical_high',
      'ml_alert',
    ];

    if (criticalTypes.contains(type)) return 'high';
    if (type.contains('warning')) return 'medium';
    return 'low';
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    try {
      if (timestamp is String) {
        return DateTime.parse(timestamp);
      } else if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      debugPrint('Error parsing timestamp: $e');
    }
    return DateTime.now();
  }

  Future<void> _acknowledgeAlert(String id) async {
    await _database.ref('alerts/${widget.deviceId}/$id').update({
      'acknowledged': true,
      'acknowledgedAt': DateTime.now().toIso8601String(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alert acknowledged'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _resolveAlert(String id) async {
    await _database.ref('alerts/${widget.deviceId}/$id').update({
      'resolved': true,
      'resolvedAt': DateTime.now().toIso8601String(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alert resolved'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _hideAlert(String id) {
    setState(() {
      _hiddenAlerts.add(id);
    });
  }

  Color _getSeverityBadgeColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red.shade500;
      case 'medium':
        return Colors.amber.shade500;
      case 'low':
        return Colors.blue.shade500;
      default:
        return Colors.grey.shade500;
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'water':
        return Icons.water_drop;
      case 'temperature':
        return Icons.thermostat;
      case 'nutrient':
        return Icons.eco;
      case 'ph':
        return Icons.science;
      case 'ml':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info;
    }
  }

  List<Map<String, dynamic>> _getFilteredAlerts(List<Map<String, dynamic>> allAlerts) {
    // Remove hidden alerts (UI-only deletion)
    final visibleAlerts = allAlerts.where((a) => !_hiddenAlerts.contains(a['id'])).toList();
    
    if (_activeFilter == 'all') {
      return visibleAlerts.where((a) => !a['resolved']).toList();
    } else if (_activeFilter == 'history') {
      return visibleAlerts; // Show everything in history
    } else {
      return visibleAlerts.where((a) => a['severity'] == _activeFilter && !a['resolved']).toList();
    }
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding, Color? borderColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.3),
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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          color: kBackgroundColor,
          image: DecorationImage(
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
                      Icon(Icons.notifications, color: kPrimaryGreen, size: 32),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Alerts & Notifications",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: kLightText,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _alertsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: kAccentGreen));
                  }

                  final alerts = snapshot.data ?? [];
                  final activeAlerts = alerts.where((a) => !a['resolved'] && !a['acknowledged']).toList();
                  final filteredAlerts = _getFilteredAlerts(alerts);

                  String title;
                  if (_activeFilter == 'all') {
                    title = "Active Alerts (${activeAlerts.length})";
                  } else if (_activeFilter == 'history') {
                    title = "Alert History (${filteredAlerts.length})";
                  } else {
                    title = "${_activeFilter.toUpperCase()} Alerts (${filteredAlerts.length})";
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                'Critical',
                                alerts.where((a) => a['severity'] == 'high' && !a['resolved']).length.toString(),
                                Colors.red.shade400,
                                'high',
                                _activeFilter,
                                (filter) => setState(() => _activeFilter = filter),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSummaryCard(
                                'Warning',
                                alerts.where((a) => a['severity'] == 'medium' && !a['resolved']).length.toString(),
                                Colors.amber.shade400,
                                'medium',
                                _activeFilter,
                                (filter) => setState(() => _activeFilter = filter),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSummaryCard(
                                'History',
                                alerts.length.toString(),
                                kAccentGreen,
                                'history',
                                _activeFilter,
                                (filter) => setState(() => _activeFilter = filter),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: kLightText,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (filteredAlerts.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 32.0),
                              child: Text(
                                _activeFilter == 'history'
                                    ? 'No alerts in history yet.'
                                    : 'No ${_activeFilter == 'all' ? 'active' : _activeFilter} alerts found.',
                                style: GoogleFonts.poppins(color: kLightText.withOpacity(0.7)),
                              ),
                            ),
                          )
                        else
                          ...filteredAlerts.map((alert) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildAlertCard(alert),
                            );
                          }).toList(),

                        const SizedBox(height: 80),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation (matching farm details page style)
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String count,
    Color color,
    String filterKey,
    String activeFilter,
    Function(String) onTap,
  ) {
    final bool isActive = activeFilter == filterKey;

    return InkWell(
      onTap: () => onTap(filterKey),
      child: _buildGlassCard(
        borderColor: isActive ? color.withOpacity(0.8) : Colors.white.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                count,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? color : kLightText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final bool acknowledged = alert['acknowledged'] as bool;
    final bool resolved = alert['resolved'] as bool;
    final Color badgeColor = resolved
        ? kAccentGreen
        : acknowledged
            ? Colors.blueGrey.shade400
            : _getSeverityBadgeColor(alert['severity']);

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getIcon(alert['type']),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            alert['severity'].toString().toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (acknowledged && !resolved)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade400,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ACKNOWLEDGED',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else if (resolved)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: kPrimaryGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'RESOLVED',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert['title'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: kLightText,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button (X icon) - only hides from UI
              IconButton(
                icon: Icon(Icons.close, color: Colors.red.shade400, size: 20),
                onPressed: () => _hideAlert(alert['id']),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert['message'],
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: kLightText.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMM d, h:mm a').format(alert['timestamp']),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: kLightText.withOpacity(0.5),
            ),
          ),
          if (!resolved) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (!acknowledged)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 16, color: Colors.white),
                      label: Text(
                        'Acknowledge',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => _acknowledgeAlert(alert['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentGreen,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                if (!acknowledged) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.check_circle, size: 16, color: kPrimaryGreen),
                    label: Text(
                      'Resolve',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: kPrimaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => _resolveAlert(alert['id']),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kPrimaryGreen, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
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
                _buildNavItem(Icons.notifications, 'Alerts', true, () {}),
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
                _buildNavItem(Icons.bar_chart, 'Analytics', false, () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DashboardPage(deviceId: widget.deviceId),
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
}