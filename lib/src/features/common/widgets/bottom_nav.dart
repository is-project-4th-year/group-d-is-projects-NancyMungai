import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naihydro/src/features/auth/presentation/dashboard_page.dart';
import 'package:naihydro/src/features/auth/presentation/alerts_page.dart';
import '../../auth/presentation/control_panel.dart';
import '../../auth/presentation/models/farm_model.dart';
import '../../auth/presentation/data/farm_repository.dart';



/// Reusable bottom navigation widget
/// Usage: Add to the bottom of any Scaffold that needs navigation
class BottomNavBar extends StatelessWidget {
  final int activeIndex; // 0=Home, 1=Alerts, 2=Control, 3=Analytics
  final FarmModel? farm; // Optional, needed for Control page
  final FarmRepository? repository; // Optional, needed for Control page
   final String deviceId;

  const BottomNavBar({
    required this.deviceId,
    required this.activeIndex,
    this.farm,
    this.repository,
    Key? key,
  }) : super(key: key);

  void _navigate(BuildContext context, int index) {
    // Don't navigate if already on that page
    if (activeIndex == index) return;

    late Widget page;
    late bool isReplacement; // Use replacement for some transitions

    switch (index) {
      case 0: // Home
        isReplacement = false;
        // Pop back to home
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;

      case 1: // Alerts
        page = AlertsPage(deviceId: deviceId);
        isReplacement = false;
        break;

      case 2: // Control
        if (farm == null || repository == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Farm data not available')),
          );
          return;
        }
        page = ControlPanelPage(
          farm: farm!,
          repository: repository!,
        );
        isReplacement = false;
        break;

      case 3: // Analytics
        page = DashboardPage(deviceId: deviceId);
        isReplacement = false;
        break;

      default:
        return;
    }

    if (isReplacement) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => page),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const List<IconData> icons = [
      Icons.home,
      Icons.notifications,
      Icons.flash_on,
      Icons.bar_chart,
    ];

    const List<String> labels = [
      'Home',
      'Alerts',
      'Control',
      'Analytics',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        border: Border(top: BorderSide(color: Colors.white10.withOpacity(0.3))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              4,
              (index) => InkWell(
                onTap: () => _navigate(context, index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[index],
                      color: activeIndex == index
                          ? const Color(0xFF22c55e)
                          : Colors.grey[600],
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[index],
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: activeIndex == index
                            ? const Color(0xFF22c55e)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}