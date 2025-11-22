// lib/src/features/home/presentation/add_farm_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../presentation/data/farm_repository.dart';
import '../presentation/models/farm_model.dart';
import '../presentation/data/auth_service.dart';

const Color kPrimaryGreen = Color(0xFF558B2F);
const Color kAccentGreen = Color(0xFF8BC34A);
const Color kBackgroundColor = Color(0xFFC7CEC8);
const Color kCardColor = Colors.white10;
const Color kLightText = Colors.white;

class AddFarmPage extends StatefulWidget {
  final FarmRepository repository;
  final AuthService authService;

  const AddFarmPage({
    required this.repository,
    required this.authService,
    Key? key,
  }) : super(key: key);

  @override
  State<AddFarmPage> createState() => _AddFarmPageState();
}

class _AddFarmPageState extends State<AddFarmPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _cropTypeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _deviceCtrl = TextEditingController(text: 'esp32-001');
  
  bool _saving = false;
  String? _nameError;
  String? _locationError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _cropTypeCtrl.dispose();
    _descriptionCtrl.dispose();
    _deviceCtrl.dispose();
    super.dispose();
  }

  void _clearError(String field) {
    setState(() {
      if (field == 'name') _nameError = null;
      if (field == 'location') _locationError = null;
    });
  }

  Future<void> _save() async {
    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty ? 'Farm name is required' : null;
      _locationError = _locationCtrl.text.trim().isEmpty ? 'Location is required' : null;
    });

    if (_nameError != null || _locationError != null) return;

    setState(() => _saving = true);

    final uid = widget.authService.currentUser?.uid ?? 'unknown';
    final farm = FarmModel(
      id: 'farm_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty 
          ? null 
          : _descriptionCtrl.text.trim(),
      cropType: _cropTypeCtrl.text.trim().isEmpty 
          ? null 
          : _cropTypeCtrl.text.trim(),
      ownerId: uid,
      deviceId: _deviceCtrl.text.trim().isEmpty 
          ? null 
          : _deviceCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await widget.repository.addFarm(farm);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save farm: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: kLightText),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Icon(Icons.eco, color: kAccentGreen, size: 32),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Add New Farm',
                              style: GoogleFonts.poppins(
                                color: kLightText,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Fill in the farm details',
                              style: GoogleFonts.poppins(
                                color: kLightText.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildGlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Icon(Icons.eco, color: kAccentGreen),
                            SizedBox(width: 8),
                            Text(
                              'Farm Information',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: kLightText,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),

                        // Farm Name
                        Text(
                          'Farm Name *',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: kLightText,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _nameCtrl,
                          onChanged: (_) => _clearError('name'),
                          style: GoogleFonts.poppins(color: kLightText),
                          decoration: InputDecoration(
                            hintText: 'e.g., Main Greenhouse',
                            hintStyle: GoogleFonts.poppins(color: kLightText.withOpacity(0.5)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _nameError != null ? Colors.red : Colors.white.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: kAccentGreen,
                                width: 2,
                              ),
                            ),
                            errorText: _nameError,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Location
                        Text(
                          'Location *',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: kLightText,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _locationCtrl,
                          onChanged: (_) => _clearError('location'),
                          style: GoogleFonts.poppins(color: kLightText),
                          decoration: InputDecoration(
                            hintText: 'e.g., Building A, Section 1',
                            hintStyle: GoogleFonts.poppins(color: kLightText.withOpacity(0.5)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: kAccentGreen,
                                width: 2,
                              ),
                            ),
                            errorText: _locationError,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Crop Type
                        Text(
                          'Crop Type (Optional)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: kLightText,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _cropTypeCtrl,
                          style: GoogleFonts.poppins(color: kLightText),
                          decoration: InputDecoration(
                            hintText: 'e.g., Lettuce, Tomatoes, Herbs',
                            hintStyle: GoogleFonts.poppins(color: kLightText.withOpacity(0.5)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: kAccentGreen,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // ESP32 Device ID
                        Text(
                          'ESP32 Device ID',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: kLightText,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _deviceCtrl,
                          style: GoogleFonts.poppins(color: kLightText),
                          decoration: InputDecoration(
                            hintText: 'e.g., esp32-001',
                            hintStyle: GoogleFonts.poppins(color: kLightText.withOpacity(0.5)),
                            helperText: 'Link your ESP32 sensor device',
                            helperStyle: GoogleFonts.poppins(color: kLightText.withOpacity(0.6)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: kAccentGreen,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Description
                        Text(
                          'Description (Optional)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: kLightText,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _descriptionCtrl,
                          maxLines: 4,
                          style: GoogleFonts.poppins(color: kLightText),
                          decoration: InputDecoration(
                            hintText: 'Additional details about this farm...',
                            hintStyle: GoogleFonts.poppins(color: kLightText.withOpacity(0.5)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: kAccentGreen,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: kLightText.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(color: kLightText),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: kPrimaryGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _saving
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.save, size: 18, color: kLightText),
                                          SizedBox(width: 8),
                                          Text(
                                            'Save Farm',
                                            style: GoogleFonts.poppins(color: kLightText),
                                          ),
                                        ],
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
          ],
        ),
      ),
    );
  }
}