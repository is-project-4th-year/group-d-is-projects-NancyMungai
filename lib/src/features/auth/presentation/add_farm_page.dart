// lib/src/features/home/presentation/add_farm_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../presentation/data/farm_repository.dart';
import '../presentation/models/farm_model.dart';
import '../presentation/data/auth_service.dart';

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
  final _deviceCtrl = TextEditingController(text: 'esp32-001'); // Default ESP32 ID
  
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF22c55e), Color(0xFF16a34a)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.eco, color: Colors.white, size: 32),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Add New Farm',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Fill in the farm details',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
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
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Icon(Icons.eco, color: Color(0xFF22c55e)),
                            SizedBox(width: 8),
                            Text(
                              'Farm Information',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
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
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _nameCtrl,
                          onChanged: (_) => _clearError('name'),
                          decoration: InputDecoration(
                            hintText: 'e.g., Main Greenhouse',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _nameError != null ? Colors.red : Colors.grey[300]!,
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
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _locationCtrl,
                          onChanged: (_) => _clearError('location'),
                          decoration: InputDecoration(
                            hintText: 'e.g., Building A, Section 1',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _locationError != null ? Colors.red : Colors.grey[300]!,
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
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _cropTypeCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g., Lettuce, Tomatoes, Herbs',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
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
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _deviceCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g., esp32-001',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            helperText: 'Link your ESP32 sensor device',
                          ),
                        ),
                        SizedBox(height: 16),

                        // Description
                        Text(
                          'Description (Optional)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _descriptionCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Additional details about this farm...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text('Cancel'),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Color(0xFF22c55e),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
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
                                          Icon(Icons.save, size: 18),
                                          SizedBox(width: 8),
                                          Text('Save Farm'),
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
          ),
        ],
      ),
    );
  }
}