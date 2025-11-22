// lib/src/features/home/presentation/pages/control_panel.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // Needed for BackdropFilter (Glassmorphism)

import '../presentation/data/farm_repository.dart';
import '../presentation/models/farm_model.dart';
import 'package:naihydro/src/features/auth/presentation/dashboard_page.dart';
import 'package:naihydro/src/features/auth/presentation/alerts_page.dart';
import 'farm_details_page.dart';
import 'package:naihydro/src/features/auth/presentation/data/auth_service.dart';

// --- CUSTOM THEME COLORS & CONSTANTS ---
const Color kPrimaryGreen = Color(0xFF558B2F);
const Color kAccentGreen = Color(0xFF8BC34A);
const Color kBackgroundColor = Color(0xFFC7CEC8);
const Color kCardColor = Colors.white10;
const Color kDarkText = Color(0xFF37474F);
const Color kLightText = Colors.white;

class ControlPanelPage extends StatefulWidget {
  final FarmModel farm;
  final FarmRepository repository;
   final AuthService authService;

  const ControlPanelPage({
    required this.farm,
    required this.repository,
    required this.authService,
    Key? key,
  }) : super(key: key);

  @override
  State<ControlPanelPage> createState() => _ControlPanelPageState();
}

class _ControlPanelPageState extends State<ControlPanelPage> {
  bool pumpOn = false;
  bool lightsOn = false;
  bool fanOn = false;
  bool _isLoading = false;

  Future<void> _toggleControl(String controlName, bool newState) async {
    // Check if device ID is available
    if (widget.farm.deviceId == null) {
      _showSnackBar('Device ID not configured for this farm', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Send command to Firebase using deviceId
      await widget.repository.updateControlState(
        widget.farm.id,
        controlName,
        newState,
        widget.farm.deviceId,
      );

      // Update local UI state
      setState(() {
        if (controlName == 'pump_state') pumpOn = newState;
        if (controlName == 'lights') lightsOn = newState;
        if (controlName == 'fan') fanOn = newState;
      });

      // Show success feedback
      _showSnackBar(
        '${_capitalize(controlName)} turned ${newState ? "ON" : "OFF"}',
        isError: false,
      );
    } catch (e) {
      String friendlyMessage = 'Something went wrong. Please try again.';

      if (e.toString().contains('permission-denied')) {
        friendlyMessage = 'You don\'t have permission to control this device. Please check your account or device link.';
      } else if (e.toString().contains('network')) {
        friendlyMessage = 'No internet connection. Please check your network.';
      }

      // revert toggle
      setState(() {
        if (controlName == 'pump_state') pumpOn = !newState;
        if (controlName == 'lights') lightsOn = !newState;
        if (controlName == 'fan') fanOn = !newState;
      });

      _showSnackBar(friendlyMessage, isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
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

  @override
  Widget build(BuildContext context) {
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
                          Icon(Icons.flash_on, color: kPrimaryGreen, size: 32),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Control Panel',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
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
                                          color: Colors.white70,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Farm Info Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.farm.name,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  widget.farm.location,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning if no device ID
                    if (widget.farm.deviceId == null)
                      _buildGlassCard(
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange[400], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No device linked to this farm. Controls disabled.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (widget.farm.deviceId == null) const SizedBox(height: 16),

                    // Controls Header
                    Text(
                      'Device Controls',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Water Pump Control
                    _buildControlCard(
                      title: 'Water Pump',
                      icon: Icons.water_drop,
                      isOn: pumpOn,
                      onToggle: (value) => _toggleControl('pump_state', value),
                      isLoading: _isLoading,
                      description: 'Control the water pump relay',
                      isEnabled: widget.farm.deviceId != null,
                    ),
                    const SizedBox(height: 12),

                    // Grow Lights Control
                    _buildControlCard(
                      title: 'Grow Lights',
                      icon: Icons.light_mode,
                      isOn: lightsOn,
                      onToggle: (value) => _toggleControl('lights', value),
                      isLoading: _isLoading,
                      description: 'Control the lighting system',
                      isEnabled: widget.farm.deviceId != null,
                    ),
                    const SizedBox(height: 12),

                    // Fan Control
                    _buildControlCard(
                      title: 'Fan',
                      icon: Icons.air,
                      isOn: fanOn,
                      onToggle: (value) => _toggleControl('fan', value),
                      isLoading: _isLoading,
                      description: 'Control the ventilation fan',
                      isEnabled: widget.farm.deviceId != null,
                    ),
                    const SizedBox(height: 24),

                    // Info Section
                    _buildGlassCard(
                      child: Row(
                        children: [
                          Icon(Icons.info, color: kAccentGreen, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Device ID: ${widget.farm.deviceId ?? "Not configured"}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
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

  Widget _buildControlCard({
    required String title,
    required IconData icon,
    required bool isOn,
    required Function(bool) onToggle,
    required bool isLoading,
    required String description,
    required bool isEnabled,
  }) {
    return _buildGlassCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: !isEnabled
                ? Colors.grey[800]?.withOpacity(0.3)
                : isOn
                    ? kPrimaryGreen.withOpacity(0.3)
                    : Colors.grey[800]?.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: !isEnabled
                ? Colors.grey[400]
                : isOn
                    ? kPrimaryGreen
                    : Colors.white70,
            size: 28,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: !isEnabled ? Colors.grey[400] : Colors.white,
          ),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        trailing: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(kPrimaryGreen),
                ),
              )
            : Switch(
                value: isOn,
                activeColor: kPrimaryGreen,
                inactiveThumbColor: Colors.grey[400],
                onChanged: isEnabled ? onToggle : null,
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FarmDetailsPage(
                        authService: widget.authService,
                      repository: widget.repository,
                      farm: widget.farm,
                    ),
                  ),
                );
              }),
              _buildNavItem(Icons.notifications, 'Alerts', false, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlertsPage(
                      authService: widget.authService,
                      deviceId: widget.farm.deviceId ?? 'esp32-001',
                      farm: widget.farm,
                      repository: widget.repository,
                    ),
                  ),
                );
              }),
              _buildNavItem(Icons.flash_on, 'Control', true, () {}),
              _buildNavItem(Icons.bar_chart, 'Analytics', false, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DashboardPage(
                      authService: widget.authService,
                      deviceId: widget.farm.deviceId ?? 'esp32-001',
                      farm: widget.farm,
                      repository: widget.repository,
                    ),
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