import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:naihydro/src/features/auth/presentation/data/auth_service.dart';
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
        builder: (_) => FarmDetailsPage(authService: widget.authService,repository: _repo, farm: farm),
      ),
    );
  }

void _openEditFarm(FarmModel farm) {
  final nameCtrl = TextEditingController(text: farm.name);
  final locationCtrl = TextEditingController(text: farm.location);
  String selectedCrop = farm.cropType ?? 'Lettuce';

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: _buildGlassCard(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'Edit Farm Details',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: kLightText,
                  ),
                ),
                const SizedBox(height: 20),

                // Farm Name Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: nameCtrl,
                    style: GoogleFonts.poppins(
                      color: kLightText,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Farm Name',
                      labelStyle: GoogleFonts.poppins(
                        color: kLightText.withOpacity(0.6),
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Location Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: locationCtrl,
                    style: GoogleFonts.poppins(
                      color: kLightText,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Location',
                      labelStyle: GoogleFonts.poppins(
                        color: kLightText.withOpacity(0.6),
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Crop Type Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedCrop,
                    style: GoogleFonts.poppins(
                      color: kLightText,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Crop Type',
                      labelStyle: GoogleFonts.poppins(
                        color: kLightText.withOpacity(0.6),
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    dropdownColor: kBackgroundColor,
                    items: ['Lettuce', 'Tomatoes', 'Herbs', 'Spinach', 'Kale']
                        .map((crop) => DropdownMenuItem(
                          value: crop,
                          child: Text(crop),
                        ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) selectedCrop = value;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: kLightText,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
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
                                  content: const Text('Farm updated successfully'),
                                  backgroundColor: kPrimaryGreen,
                                  duration: const Duration(seconds: 2),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.poppins(
                            color: kLightText,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
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
      ),
    ),
  );
}

void _deleteFarm(FarmModel farm) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: _buildGlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning icon at top
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: Colors.red[600],
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Delete Farm',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 12),
            
            // Message
            Text(
              'Are you sure you want to delete "${farm.name}"?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: kLightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red[300],
              ),
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: kLightText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final uid = widget.authService.currentUser?.uid;
                        if (uid != null) {
                          await _database.ref('users/$uid/farms/${farm.id}').remove();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Farm deleted successfully'),
                              backgroundColor: Colors.red[600],
                            ),
                          );
                        }
                      } catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting farm: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: kLightText.withOpacity(0.8), size: 20),
                            onPressed: () => _openEditFarm(farm),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red[300], size: 20),
                            onPressed: () => _deleteFarm(farm),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
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
                          () => _openFarmDetails(farm),
                        ),
                        _buildQuickActionIcon(
                          Icons.flash_on,
                          'Control',
                          () => _openFarmDetails(farm),
                        ),
                        _buildQuickActionIcon(
                          Icons.notifications,
                          'Alerts',
                          () => _openFarmDetails(farm),
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
                      color: kLightText,
                    ),
                  ),
                  Text(
                    'Welcome back, $_userName',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: kLightText.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.settings, color: kLightText),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsPage(
                      authService: widget.authService,
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
                    return const Center(
                      child: CircularProgressIndicator(color: kPrimaryGreen),
                    );
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
                                color: kLightText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first farm and link your ESP32 device.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: kLightText.withOpacity(0.7),
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
      ),
    );
  }
}