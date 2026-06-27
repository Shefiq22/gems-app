import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/gems_theme.dart';

class GEMSStatCard extends StatefulWidget {
  final String  title;
  final String  value;
  final String  subtitle;
  final IconData icon;
  final Color   color;
  final String  trend;
  final bool    positive;

  const GEMSStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.trend,
    required this.positive,
  });

  @override
  State<GEMSStatCard> createState() => _GEMSStatCardState();
}

class _GEMSStatCardState extends State<GEMSStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? widget.color.withOpacity(0.3)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color
                  .withOpacity(_hovered ? 0.14 : 0.05),
              blurRadius: _hovered ? 24 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon,
                      color: widget.color, size: 20),
                ),
                Icon(
                  widget.positive
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: widget.positive
                      ? GEMSTheme.success
                      : GEMSTheme.danger,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(widget.value,
                style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: GEMSTheme.textDark)),
            const SizedBox(height: 2),
            Text(widget.title,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: GEMSTheme.textMid)),
            const SizedBox(height: 2),
            Text(widget.subtitle,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: GEMSTheme.textLight)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (widget.positive
                        ? GEMSTheme.success
                        : GEMSTheme.danger)
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(widget.trend,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: widget.positive
                          ? GEMSTheme.success
                          : GEMSTheme.danger,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}