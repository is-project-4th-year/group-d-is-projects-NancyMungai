import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const BottomNav({
    Key? key,
    required this.currentIndex,
    required this.onItemTapped, required void Function(int index) onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0, currentIndex, onItemTapped),
              _buildNavItem(Icons.notifications, 'Alerts', 1, currentIndex, onItemTapped),
              _buildNavItem(Icons.flash_on, 'Control', 2, currentIndex, onItemTapped),
              _buildNavItem(Icons.bar_chart, 'Analytics', 3, currentIndex, onItemTapped),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, int index, int currentIndex, Function(int) onTap) {
    final isActive = index == currentIndex;
    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF22c55e) : Colors.grey[600],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isActive ? const Color(0xFF22c55e) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
