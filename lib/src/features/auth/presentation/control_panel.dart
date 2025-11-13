// lib/src/features/home/presentation/pages/control_panel.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../presentation/data/farm_repository.dart';
import '../presentation/models/farm_model.dart';

class ControlPanelPage extends StatefulWidget {
  final FarmModel farm;
  final FarmRepository repository;

  const ControlPanelPage({
    required this.farm,
    required this.repository,
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
        widget.farm.deviceId, // ✅ Pass the device ID
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
    friendlyMessage = 'You don’t have permission to control this device. Please check your account or device link.';
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
}
finally {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Control Panel',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF22c55e),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farm Info Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF22c55e).withOpacity(0.1),
                    const Color(0xFF16a34a).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF22c55e), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.farm.name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF22c55e),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        widget.farm.location,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Warning if no device ID
            if (widget.farm.deviceId == null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No device linked to this farm. Controls disabled.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.orange[800],
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
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            // Water Pump Control
            _buildControlCard(
              title: 'Water Pump',
              icon: Icons.water_drop,
              isOn: pumpOn,
              onToggle: (value) =>
                  _toggleControl('pump_state', value),
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
              onToggle: (value) =>
                  _toggleControl('lights', value),
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
              onToggle: (value) =>
                  _toggleControl('fan', value),
              isLoading: _isLoading,
              description: 'Control the ventilation fan',
              isEnabled: widget.farm.deviceId != null,
            ),
            const SizedBox(height: 24),

            // Info Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Device ID: ${widget.farm.deviceId ?? "Not configured"}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: !isEnabled
                ? Colors.grey[300]!
                : isOn
                    ? const Color(0xFF22c55e)
                    : Colors.grey[200]!,
            width: 2,
          ),
          color: !isEnabled
              ? Colors.grey[100]
              : isOn
                  ? const Color(0xFF22c55e).withOpacity(0.05)
                  : Colors.white,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: !isEnabled
                  ? Colors.grey[200]
                  : isOn
                      ? const Color(0xFF22c55e).withOpacity(0.2)
                      : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: !isEnabled
                  ? Colors.grey[400]
                  : isOn
                      ? const Color(0xFF22c55e)
                      : Colors.grey[600],
              size: 28,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: !isEnabled ? Colors.grey[400] : Colors.grey[800],
            ),
          ),
          subtitle: Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          trailing: _isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      const Color(0xFF22c55e),
                    ),
                  ),
                )
              : Switch(
                  value: isOn,
                  activeColor: const Color(0xFF22c55e),
                  inactiveThumbColor: Colors.grey[400],
                  onChanged: isEnabled ? onToggle : null,
                ),
        ),
      ),
    );
  }
}

