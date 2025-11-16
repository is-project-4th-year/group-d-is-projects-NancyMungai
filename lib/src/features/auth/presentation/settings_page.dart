import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- SHARED THEME COLORS ---
const Color kPrimaryGreen = Color(0xFF558B2F);
const Color kAccentGreen = Color(0xFF8BC34A);
const Color kBackgroundColor = Color(0xFFC7CEC8);
const Color kCardColor = Colors.white10;
const Color kDarkText = Colors.white70;

class SettingsPage extends StatefulWidget {
  final Function(String page) onNavigate;
  final VoidCallback onLogout;

  const SettingsPage({
    super.key,
     required this.onNavigate,
     required this.onLogout,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic> settings = {
    "notifications": true,
    "lowWaterAlerts": true,
    "temperatureAlerts": true,
    "phAlerts": true,
    "soundAlerts": true,
    "autoRefresh": true,
    "refreshInterval": 30.0,
    "darkMode": false
  };

  void update(String key, dynamic value) {
    setState(() => settings[key] = value);
  }

  Widget glassCard({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              )
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
          image: DecorationImage(
            image: AssetImage("assets/images/detailspg.jpeg"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // HEADER
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => widget.onNavigate("home"),
                  ),
                  Text(
                    "Settings",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kDarkText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // PROFILE CARD
              glassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Profile",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: kDarkText,
                        )),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("John Farmer",
                                style: GoogleFonts.poppins(
                                    fontSize: 16, color: kDarkText)),
                            Text("farmer@example.com",
                                style: GoogleFonts.poppins(
                                    fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccentGreen.withOpacity(0.8),
                          ),
                          child: const Text("Edit"),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text("Farm Name", style: GoogleFonts.poppins(color: kDarkText)),
                    Text("My Hydroponic Farm",
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.white70)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // NOTIFICATIONS
              glassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Notifications",
                        style: GoogleFonts.poppins(
                            fontSize: 18, color: kDarkText)),

                    const SizedBox(height: 16),
                    _switchTile("Push Notifications", "notifications"),

                    _switchTile("Low Water Alerts", "lowWaterAlerts",
                        disabled: !settings["notifications"]),

                    _switchTile("Temperature Alerts", "temperatureAlerts",
                        disabled: !settings["notifications"]),

                    _switchTile("pH Alerts", "phAlerts",
                        disabled: !settings["notifications"]),

                    _switchTile("Sound Alerts", "soundAlerts",
                        disabled: !settings["notifications"]),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // DATA & SYNC
              glassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Data & Sync",
                        style: GoogleFonts.poppins(
                            fontSize: 18, color: kDarkText)),

                    const SizedBox(height: 16),
                    _switchTile("Auto Refresh", "autoRefresh"),

                    const SizedBox(height: 10),
                    Text(
                      "Refresh Interval: ${settings["refreshInterval"].round()} seconds",
                      style: GoogleFonts.poppins(color: kDarkText),
                    ),
                    Slider(
                      value: settings["refreshInterval"],
                      onChanged: settings["autoRefresh"]
                          ? (v) => update("refreshInterval", v)
                          : null,
                      min: 10,
                      max: 120,
                      divisions: 22,
                      activeColor: kAccentGreen,
                    ),

                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentGreen.withOpacity(0.9),
                      ),
                      child: const Text("Sync Now"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

   

              const SizedBox(height: 20),

      
              // ABOUT
              glassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("About",
                        style: GoogleFonts.poppins(
                            fontSize: 18, color: kDarkText)),
                    const SizedBox(height: 16),

                    _infoRow("Version", "1.2.0"),

                    _buttonTile("Privacy Policy"),
                    _buttonTile("Terms of Service"),
                    _buttonTile("Contact Support"),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // LOGOUT
              glassCard(
                padding: const EdgeInsets.all(14),
                child: ElevatedButton(
                  onPressed: widget.onLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Sign Out"),
                ),
              ),

              const SizedBox(height: 70),
            ],
          ),
        ),
      ),

      // BOTTOM NAV 
    );
  }

  // ---- COMPONENT HELPERS ----

  Widget _switchTile(String label, String key, {bool disabled = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(fontSize: 15, color: kDarkText)),
        Switch(
          value: settings[key],
          onChanged: disabled ? null : (v) => update(key, v),
          activeColor: kAccentGreen,
        ),
      ],
    );
  }

  Widget _buttonTile(String label) {
    return TextButton(
      onPressed: () {},
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label,
            style: GoogleFonts.poppins(fontSize: 15, color: kDarkText)),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(color: kDarkText)),
        Text(value,
            style: GoogleFonts.poppins(color: Colors.white70)),
      ],
    );
  }

  Widget _navButton(IconData icon, String page) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: () => widget.onNavigate(page),
    );
  }
}
