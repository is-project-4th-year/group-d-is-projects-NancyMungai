// lib/src/features/home/presentation/farm_list_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../presentation/models/farm_model.dart';

class FarmListPage extends StatelessWidget {
  final List<FarmModel> farms;
  final VoidCallback onAddFarm;
  final Function(String farmId) onSelectFarm;

  const FarmListPage({
    required this.farms,
    required this.onAddFarm,
    required this.onSelectFarm,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with gradient
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
                          'naihydro',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Farm Management',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        // Navigate to settings
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: farms.isEmpty ? _buildEmptyState(context) : _buildFarmList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon circle
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF22c55e).withOpacity(0.2),
                    Color(0xFF16a34a).withOpacity(0.3),
                  ],
                ),
              ),
              child: Icon(
                Icons.eco,
                size: 48,
                color: Color(0xFF22c55e),
              ),
            ),
            SizedBox(height: 24),
            
            Text(
              'No Farms Yet',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            
            Text(
              'Get started by adding your first hydroponic farm to begin monitoring environmental conditions.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: onAddFarm,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                backgroundColor: Color(0xFF22c55e),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Add Your First Farm',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Widget _buildFarmList(BuildContext context) {
    return Column(
      children: [
        // Header with "My Farms" and Add button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'My Farms',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              ElevatedButton.icon(
                onPressed: onAddFarm,
                icon: Icon(Icons.add, size: 18),
                label: Text('Add Farm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF22c55e),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Farm cards list
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: farms.length,
            separatorBuilder: (_, __) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final farm = farms[index];
              return _buildFarmCard(context, farm);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFarmCard(BuildContext context, FarmModel farm) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 2),
      ),
      child: InkWell(
        onTap: () => onSelectFarm(farm.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Farm icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [Color(0xFF22c55e), Color(0xFF16a34a)],
                  ),
                ),
                child: Icon(Icons.eco, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              
              // Farm details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          farm.location,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (farm.cropType != null) ...[
                      SizedBox(height: 4),
                      Text(
                        'Crop: ${farm.cropType}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}