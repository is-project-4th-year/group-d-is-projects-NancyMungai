// lib/src/features/home/presentation/home_page.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:naihydro/src/features/auth/presentation/data/auth_service.dart';
import 'package:naihydro/src/features/auth/presentation/dashboard_page.dart';
import 'package:naihydro/src/features/auth/presentation/alerts_page.dart';
import '../../common/widgets/alert_item.dart';
import '../../common/widgets/status_card.dart';
import '../../auth/presentation/chat_page.dart';
// lib/src/features/auth/presentation/home_page.dart
import '../presentation/data/farm_repository.dart';
import '../presentation/models/farm_model.dart';
import 'add_farm_page.dart';
import 'farm_details_page.dart';


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

  @override
  void initState() {
    super.initState();
    _repo = FarmRepository();
    _farmsStream = _repo.getFarmsStream();
  }

  Future<void> _openAddFarm() async {
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddFarmPage(repository: _repo, authService: widget.authService),
      ),
    );
    if (res == true) {
      // stream auto-updates; nothing to do
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('naihydro'),
        actions: [
          IconButton(
            onPressed: () async {
              if (widget.onSignOut != null) await widget.onSignOut!();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<List<FarmModel>>(
        stream: _farmsStream,
        builder: (context, snapshot) {
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
                    const Text('No farms yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Add your first farm and link your ESP32 device.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _openAddFarm,
                      child: const Text('Add Farm'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: farms.length,
            itemBuilder: (context, index) {
              final f = farms[index];
              return ListTile(
                title: Text(f.name),
                subtitle: Text(f.location),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => FarmDetailsPage(repository: _repo, farm: f)),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddFarm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
