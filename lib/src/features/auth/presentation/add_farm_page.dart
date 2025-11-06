import 'package:flutter/material.dart';
import '../presentation/data/farm_repository.dart';
import '../presentation/models/farm_model.dart';
import '../presentation/data/auth_service.dart';

class AddFarmPage extends StatefulWidget {
  final FarmRepository repository;
  final AuthService authService;

  const AddFarmPage({required this.repository, required this.authService, Key? key}) : super(key: key);

  @override
  State<AddFarmPage> createState() => _AddFarmPageState();
}

class _AddFarmPageState extends State<AddFarmPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _deviceCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _deviceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _error = null;
      _saving = true;
    });

    final uid = widget.authService.currentUser?.uid ?? 'unknown';
    final farm = FarmModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      ownerId: uid,
      deviceId: _deviceCtrl.text.trim().isEmpty ? null : _deviceCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await widget.repository.addFarm(farm);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = 'Failed to save farm: $e';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Farm')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          if (_error != null)
            Container(
              width: double.infinity,
              color: Colors.red[50],
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Farm Name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Farm name required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationCtrl,
                    decoration: const InputDecoration(labelText: 'Location'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Location required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _deviceCtrl,
                    decoration: const InputDecoration(labelText: 'ESP32 Device ID (optional)'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: _saving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(onPressed: _save, child: const Text('Save Farm')),
          ),
        ]),
      ),
    );
  }
}
