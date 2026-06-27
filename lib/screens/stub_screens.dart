import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/gems_theme.dart';

class StubScreen extends StatelessWidget {
  final int index;
  final String title;
  final IconData icon;
  final String description;

  const StubScreen({
    super.key,
    required this.index,
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: GEMSTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: GEMSTheme.primaryGreen, size: 26),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GEMSTheme.displayMedium),
                  const SizedBox(height: 4),
                  Text(description, style: GEMSTheme.bodySmall),
                ],
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15),
          const SizedBox(height: 60),
          Center(
            child: Column(
              children: [
                Icon(icon, size: 80, color: GEMSTheme.textLight.withOpacity(0.3)),
                const SizedBox(height: 24),
                Text('Coming Soon', style: GoogleFonts.playfairDisplay(
                  fontSize: 28, fontWeight: FontWeight.w700, color: GEMSTheme.textLight,
                )),
                const SizedBox(height: 12),
                Text(
                  'This module is under development.\nCheck back in the next release.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14, color: GEMSTheme.textLight, height: 1.6,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }
}

Widget buildStubPage(int index) {
  final pages = {
    5: ('Issues & Reports', Icons.report_problem_rounded,
        'Report and track campus environmental issues'),
    6: ('Tree Registry', Icons.park_rounded,
        'Campus tree inventory and planting records'),
    7: ('Alerts & Notifications', Icons.notifications_rounded,
        'System alerts and environmental warnings'),
    8: ('Settings', Icons.settings_rounded,
        'System configuration and user preferences'),
  };
  final page = pages[index];
  if (page == null) return const SizedBox();
  return StubScreen(index: index, title: page.$1, icon: page.$2, description: page.$3);
}
