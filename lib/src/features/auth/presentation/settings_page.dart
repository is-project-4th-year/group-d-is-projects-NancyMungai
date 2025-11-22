import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:naihydro/src/features/auth/presentation/data/auth_service.dart';

// --- SHARED THEME COLORS ---
const Color kPrimaryGreen = Color(0xFF558B2F);
const Color kAccentGreen = Color(0xFF8BC34A);
const Color kBackgroundColor = Color(0xFFC7CEC8);
const Color kCardColor = Colors.white10;
const Color kDarkText = Colors.white70;
const Color kLightText = Colors.white;

class SettingsPage extends StatefulWidget {
  final AuthService authService;
  final Function(String page) onNavigate;
  final VoidCallback onLogout;

  const SettingsPage({
    super.key,
    required this.authService,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _database = FirebaseDatabase.instance;
  
  // User data
  String _userName = 'Loading...';
  String _userEmail = '';
  
  Map<String, dynamic> settings = {
    "notifications": true,
    "lowWaterAlerts": true,
    "temperatureAlerts": true,
    "phAlerts": true,
    "autoRefresh": true,
    "refreshInterval": 30.0,
    "darkMode": false
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = widget.authService.currentUser?.uid;
    final email = widget.authService.currentUser?.email;
    
    if (uid != null) {
      try {
        final snapshot = await _database.ref('users/$uid/profile/name').get();
        if (snapshot.exists && mounted) {
          setState(() {
            _userName = snapshot.value.toString();
            _userEmail = email ?? 'No email';
          });
        } else {
          setState(() {
            _userName = 'User';
            _userEmail = email ?? 'No email';
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
        setState(() {
          _userName = 'User';
          _userEmail = email ?? 'No email';
        });
      }
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: kDarkText,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: GoogleFonts.poppins(color: kDarkText),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: GoogleFonts.poppins(color: kDarkText.withOpacity(0.7)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: _userEmail),
              enabled: false,
              style: GoogleFonts.poppins(color: kDarkText.withOpacity(0.5)),
              decoration: InputDecoration(
                labelText: 'Email (cannot be changed)',
                labelStyle: GoogleFonts.poppins(color: kDarkText.withOpacity(0.7)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: kDarkText)),
          ),
          ElevatedButton(
            onPressed: () async {
              final uid = widget.authService.currentUser?.uid;
              if (uid != null && nameController.text.trim().isNotEmpty) {
                try {
                  await _database.ref('users/$uid/profile/name').set(nameController.text.trim());
                  setState(() {
                    _userName = nameController.text.trim();
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Profile updated successfully'),
                      backgroundColor: kPrimaryGreen,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating profile: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen),
            child: Text('Save', style: GoogleFonts.poppins(color: kLightText)),
          ),
        ],
      ),
    );
  }

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
                    onPressed: () => Navigator.pop(context),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_userName,
                                  style: GoogleFonts.poppins(
                                      fontSize: 16, color: kDarkText)),
                              Text(_userEmail,
                                  style: GoogleFonts.poppins(
                                      fontSize: 14, color: Colors.white70)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _showEditProfileDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccentGreen.withOpacity(0.8),
                          ),
                          child: const Text("Edit"),
                        )
                      ],
                    ),
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Syncing data...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentGreen.withOpacity(0.9),
                      ),
                      child: const Text("Sync Now"),
                    ),
                  ],
                ),
              ),

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
}