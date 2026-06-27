import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/gems_theme.dart';
import '../models/app_data.dart';

class FacultyCard extends StatefulWidget {
  final Faculty      faculty;
  final VoidCallback onTap;
  const FacultyCard({super.key, required this.faculty, required this.onTap});

  @override
  State<FacultyCard> createState() => _FacultyCardState();
}

class _FacultyCardState extends State<FacultyCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.faculty;
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _scaleCtrl.reverse();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _scaleCtrl.forward();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleCtrl,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hovered
                    ? f.color.withOpacity(0.4)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: f.color
                      .withOpacity(_hovered ? 0.2 : 0.07),
                  blurRadius: _hovered ? 28 : 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image ──
                  Expanded(
                    flex: 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        f.imageUrl.isNotEmpty
                            ? Image.network(
                                f.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _placeholder(f),
                                loadingBuilder: (_, child, prog) =>
                                    prog == null
                                        ? child
                                        : _placeholder(f),
                              )
                            : _placeholder(f),

                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.55),
                              ],
                            ),
                          ),
                        ),

                        // Score badge
                        Positioned(
                          top: 10, right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: f.color,
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${f.greenHealthScore.toInt()}',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),

                        // Critical badge
                        if (f.hazardLevel == 'critical')
                          Positioned(
                            top: 10, left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: GEMSTheme.danger,
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Text('🔥 CRITICAL',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),

                        // Faculty name over image
                        Positioned(
                          bottom: 10, left: 12, right: 12,
                          child: Text(f.name,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  Shadow(
                                    color:
                                        Colors.black.withOpacity(0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),

                  // ── Bottom info ──
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          14, 8, 14, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          // GHI progress bar
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Green Health Index',
                                      style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: GEMSTheme.textLight)),
                                  Text(
                                    '${f.greenHealthScore.toInt()}/100',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: f.color),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Stack(children: [
                                Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius:
                                        BorderRadius.circular(3),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor:
                                      f.greenHealthScore / 100,
                                  child: Container(
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: f.color,
                                      borderRadius:
                                          BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ]),
                            ],
                          ),

                          // Zone mini pills (from live data)
                          if (f.zones.isNotEmpty)
                            Wrap(
                              spacing: 5, runSpacing: 4,
                              children: f.zones.take(3).map((z) =>
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: z.color.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    '${z.percentage.toInt()}% ${z.name.split(' ').first}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: z.color),
                                  ),
                                )).toList(),
                            )
                          else
                            Text(f.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: GEMSTheme.textLight)),

                          // View details hint on hover
                          if (_hovered)
                            Row(children: [
                              Text('View Details',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: f.color,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward,
                                  size: 12, color: f.color),
                            ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(Faculty f) => Container(
        color: f.color.withOpacity(0.15),
        child: Icon(Icons.eco, color: f.color, size: 40),
      );
}