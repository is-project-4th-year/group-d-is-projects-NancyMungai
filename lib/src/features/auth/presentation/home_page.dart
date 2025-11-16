// lib/src/features/home/presentation/home_page.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:naihydro/src/features/auth/presentation/data/auth_service.dart';
import 'package:naihydro/src/features/auth/presentation/dashboard_page.dart';
import 'package:naihydro/src/features/auth/presentation/alerts_page.dart';
import 'package:naihydro/src/features/auth/presentation/control_panel.dart';
import 'package:naihydro/src/features/auth/presentation/settings_page.dart';
import '../presentation/data/farm_repository.dart';
import '../presentation/models/farm_model.dart';
import 'add_farm_page.dart';
import 'farm_details_page.dart';

const Color kPrimaryGreen = Color(0xFF558B2F);
const Color kAccentGreen = Color(0xFF8BC34A);
const Color kBackgroundColor = Color(0xFFC7CEC8);
const Color kCardColor = Colors.white10;
const Color kDarkText = Color(0xFF37474F);
const Color kLightText = Colors.white;

class HomePage extends StatefulWidget {
  final AuthService authService;
  final Future<void> Function()? onSignOut;

  const HomePage({required this.authService, this.onSignOut, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final FarmRepository _repo;
  late final Stream<List<FarmModel>> _farmsStream;
  String _userName = 'User';
  final _database = FirebaseDatabase.instance;

  @override
  void initState() {
    super.initState();
    _repo = FarmRepository();
    _farmsStream = _repo.getFarmsStream();
    _loadUserName();
  }

  // Load user name from Firebase
  Future<void> _loadUserName() async {
    final uid = widget.authService.currentUser?.uid;
    if (uid != null) {
      try {
        final snapshot = await _database.ref('users/$uid/profile/name').get();
        if (snapshot.exists && mounted) {
          setState(() {
            _userName = snapshot.value.toString();
          });
        }
      } catch (e) {
        print('Error loading user name: $e');
      }
    }
  }

  Future<void> _openAddFarm() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddFarmPage(repository: _repo, authService: widget.authService),
      ),
    );
  }

  void _openFarmDetails(FarmModel farm) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FarmDetailsPage(repository: _repo, farm: farm),
      ),
    );
  }

  // Edit farm dialog
  void _openEditFarm(FarmModel farm) {
    final nameCtrl = TextEditingController(text: farm.name);
    final locationCtrl = TextEditingController(text: farm.location);
    String selectedCrop = farm.cropType ?? 'Lettuce';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Farm',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: kDarkText,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.poppins(color: kDarkText),
              decoration: InputDecoration(
                labelText: 'Farm Name',
                labelStyle: GoogleFonts.poppins(color: kDarkText.withOpacity(0.7)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationCtrl,
              style: GoogleFonts.poppins(color: kDarkText),
              decoration: InputDecoration(
                labelText: 'Location',
                labelStyle: GoogleFonts.poppins(color: kDarkText.withOpacity(0.7)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCrop,
              style: GoogleFonts.poppins(color: kDarkText),
              decoration: InputDecoration(
                labelText: 'Crop Type',
                labelStyle: GoogleFonts.poppins(color: kDarkText.withOpacity(0.7)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ['Lettuce', 'Tomatoes', 'Herbs', 'Spinach', 'Kale']
                  .map((crop) => DropdownMenuItem(value: crop, child: Text(crop)))
                  .toList(),
              onChanged: (value) {
                if (value != null) selectedCrop = value;
              },
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
              try {
                final uid = widget.authService.currentUser?.uid;
                if (uid != null) {
                  await _database.ref('users/$uid/farms/${farm.id}').update({
                    'name': nameCtrl.text.trim(),
                    'location': locationCtrl.text.trim(),
                    'cropType': selectedCrop,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Farm updated successfully'),
                      backgroundColor: kPrimaryGreen,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating farm: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen),
            child: Text('Save', style: GoogleFonts.poppins(color: kLightText)),
          ),
        ],
      ),
    );
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

  Widget _buildFarmCard(FarmModel farm) {
    String bgAssetPath = 'assets/images/details.jpeg';

    return GestureDetector(
      onTap: () => _openFarmDetails(farm),
      child: _buildGlassCard(
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18.5),
              child: Stack(
                children: [
                  Image.asset(
                    bgAssetPath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: kPrimaryGreen.withOpacity(0.1),
                        alignment: Alignment.center,
                        child: Icon(Icons.grass, color: kPrimaryGreen, size: 48),
                      );
                    },
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(
                      color: Colors.black.withOpacity(0.1),
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(Icons.edit, color: kLightText.withOpacity(0.8), size: 20),
                        onPressed: () => _openEditFarm(farm),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farm.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: kLightText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          farm.location,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: kLightText.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickActionIcon(
                          Icons.bar_chart,
                          'Analytics',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DashboardPage(deviceId: farm.deviceId ?? 'esp32-001'),
                            ),
                          ),
                        ),
                        _buildQuickActionIcon(
                          Icons.flash_on,
                          'Control',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ControlPanelPage(farm: farm, repository: _repo),
                            ),
                          ),
                        ),
                        _buildQuickActionIcon(
                          Icons.notifications,
                          'Alerts',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlertsPage(
                                deviceId: farm.deviceId ?? 'esp32-001',
                                farm: farm,
                                repository: _repo,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: kAccentGreen, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: kLightText.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFarmCard() {
    return GestureDetector(
      onTap: _openAddFarm,
      child: _buildGlassCard(
        padding: const EdgeInsets.all(16),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kPrimaryGreen.withOpacity(0.05),
                kCardColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: kPrimaryGreen, size: 48),
              const SizedBox(height: 8),
              Text(
                'Add New Farm',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kLightText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String userInitials = _userName.length >= 2 
        ? _userName.substring(0, 2).toUpperCase() 
        : _userName.toUpperCase();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kAccentGreen,
                shape: BoxShape.circle,
                border: Border.all(color: kLightText, width: 2),
              ),
              child: Center(
                child: Text(
                  userInitials,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: kDarkText,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Greenhouses',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kDarkText,
                    ),
                  ),
                  Text(
                    'Welcome back, $_userName',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: kDarkText.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.notifications_none, color: kDarkText),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AlertsPage(deviceId: 'esp32-001'),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.settings, color: kDarkText),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsPage(
                      onNavigate: (page) => Navigator.pop(context),
                      onLogout: () async {
                        if (widget.onSignOut != null) await widget.onSignOut!();
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<FarmModel>>(
              stream: _farmsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading farms: ${snapshot.error}',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final farms = snapshot.data ?? [];

                if (farms.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No farms yet',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kDarkText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first farm and link your ESP32 device.',
                            style: GoogleFonts.poppins(
                              color: kDarkText.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 150,
                            width: 150,
                            child: _buildAddFarmCard(),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: farms.length + 1,
                  itemBuilder: (context, index) {
                    if (index == farms.length) {
                      return _buildAddFarmCard();
                    }
                    final farm = farms[index];
                    return _buildFarmCard(farm);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}