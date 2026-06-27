// ============================================================
//  GEMS — Green Campus Guide Screen
//  Interactive vegetation assessment + 3 reference tabs
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/gems_theme.dart';

class GreenGuideScreen extends StatefulWidget {
  const GreenGuideScreen({super.key});

  @override
  State<GreenGuideScreen> createState() => _GreenGuideScreenState();
}

class _GreenGuideScreenState extends State<GreenGuideScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [GEMSTheme.primaryGreen, GEMSTheme.emerald],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Green Campus Guide', style: GEMSTheme.displayMedium),
                  Text(
                    'Maintenance standards & vegetation management',
                    style: GEMSTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15),

          const SizedBox(height: 32),

          // Assessment tool (always visible)
          const _AssessmentTool()
              .animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

          const SizedBox(height: 32),

          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [GEMSTheme.softShadow],
            ),
            child: TabBar(
              controller: _tabs,
              labelColor: GEMSTheme.primaryGreen,
              unselectedLabelColor: GEMSTheme.textLight,
              indicatorColor: GEMSTheme.primaryGreen,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: '✂️  Cutting Guide'),
                Tab(text: '🔥  Burning Rules'),
                Tab(text: '🧪  Chemical Control'),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 4),

          AnimatedBuilder(
            animation: _tabs,
            builder: (_, __) => IndexedStack(
              index: _tabs.index,
              children: const [
                _CuttingGuide(),
                _BurningGuide(),
                _ChemicalGuide(),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 32),

          const _QuickReference().animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ASSESSMENT TOOL
// ══════════════════════════════════════════════════════════════

class _AssessmentTool extends StatefulWidget {
  const _AssessmentTool();

  @override
  State<_AssessmentTool> createState() => _AssessmentToolState();
}

class _AssessmentToolState extends State<_AssessmentTool> {
  double _heightCm     = 10;
  String _grassType    = 'Carpet Grass';
  String _condition    = 'Green & Growing';
  String _faculty      = 'Natural & Applied Sciences';
  bool   _nearBuilding = false;
  bool   _drySeason    = false;
  _Recommendation? _result;

  static const _grassTypes = [
    'Carpet Grass', 'Bermuda Grass', 'Buffalo Grass',
    'Bush / Wild Grass', 'Mixed Vegetation',
  ];
  static const _conditions = [
    'Green & Growing', 'Dry & Brown', 'Mixed (partly dry)', 'Dead / Dormant',
  ];
  static const _faculties = [
    'Natural & Applied Sciences', 'Environmental Science',
    'Engineering', 'Medical Science', 'General Campus',
  ];

  void _assess() => setState(() => _result = _compute());

  _Recommendation _compute() {
    final h     = _heightCm;
    final isDry = _condition == 'Dry & Brown' || _condition == 'Dead / Dormant';
    final isBush = _grassType == 'Bush / Wild Grass' ||
        _grassType == 'Mixed Vegetation';

    if (h >= 60 && isDry && _nearBuilding) {
      return _Recommendation(
        action: 'URGENT — Chemical + Manual Clearance',
        emoji: '🚨', color: const Color(0xFFB71C1C), urgency: 'Critical',
        reason: 'Grass is ${h.toInt()} cm tall, dry, and within range of buildings. '
            'Burning is PROHIBITED here. Use herbicide first, then manually clear within 48 hours.',
        steps: [
          'Apply glyphosate herbicide at 3–5 L/ha concentration immediately',
          'Allow 5–7 days for vegetation to die fully',
          'Manually remove dead matter using cutlasses and wheelbarrows',
          'Install firebreak — clear 3 m strip around all buildings',
          'Report completion to Faculty Officer and update GEMS task status',
        ],
        doNot: [
          'Do NOT burn near buildings under any circumstances',
          'Do NOT delay — every day increases fire risk',
          'Do NOT use riding mowers in grass above 40 cm',
        ],
      );
    }

    if (h >= 60 && isDry && !_nearBuilding && _drySeason) {
      return _Recommendation(
        action: 'Controlled Burning Permitted',
        emoji: '🔥', color: const Color(0xFFE65100), urgency: 'High',
        reason: 'Grass is ${h.toInt()} cm tall and dry. Controlled burning is the most '
            'efficient option for open areas away from structures. A permit is required.',
        steps: [
          'Obtain a burning permit from the University Environmental Officer',
          'Establish a 5 m firebreak by clearing a strip around the perimeter first',
          'Burn early morning (6–9 AM) when wind is calm and predictable',
          'Have water tanker or fire extinguishers on standby',
          'Post fire wardens at all four sides of the burn area',
          'After burning, allow ash to settle for 48 hours before entering',
          'Overseed with carpet grass within 2 weeks to prevent erosion',
        ],
        doNot: [
          'Do NOT burn after 10 AM — wind speeds increase fire spread risk',
          'Do NOT burn within 50 m of buildings, trees, or roads',
          'Do NOT burn without a university-issued permit',
        ],
      );
    }

    if (h >= 40 && isBush) {
      return _Recommendation(
        action: 'Heavy Bush Clearance Required',
        emoji: '🌿', color: const Color(0xFF6A1B9A), urgency: 'High',
        reason: 'At ${h.toInt()} cm with bush/wild vegetation, mechanical cutting is required first. '
            'Bush this dense can harbour snakes and pests.',
        steps: [
          'Assign at least 4 groundskeepers with protective gear (boots, gloves, long sleeves)',
          'Use brush-cutters or motorised slashers to cut to approximately 15 cm',
          'Remove all cut material from site immediately',
          'Inspect for snake holes, ant colonies, or erosion underneath',
          'Apply pre-emergent herbicide to prevent rapid regrowth',
          'Schedule follow-up mowing in 3 weeks',
        ],
        doNot: [
          'Do NOT enter dense bush without snake-proof boots',
          'Do NOT leave cut material piled on site for more than 48 hours',
          'Do NOT use fire at this stage — material is too dense for safe burn',
        ],
      );
    }

    if (h >= 25 && h < 60) {
      return _Recommendation(
        action: 'Mechanical Cutting Required',
        emoji: '✂️', color: GEMSTheme.warning, urgency: 'Medium',
        reason: 'At ${h.toInt()} cm, this grass is overgrown but manageable '
            'with mechanical cutting. Cut in two passes to avoid scalping the soil.',
        steps: [
          'First pass: cut to 12–15 cm using a brush-cutter or ride-on mower',
          'Wait 3–5 days then second pass: cut to the target height of 5–7 cm',
          'Rake and remove all clippings to prevent thatch buildup',
          'Water lightly after cutting if in dry conditions',
          'Apply a light fertiliser (NPK 15-15-15) to encourage healthy regrowth',
          'Schedule next maintenance cut in 3–4 weeks',
        ],
        doNot: [
          'Do NOT cut more than 1/3 of grass height in a single pass',
          'Do NOT cut when grass is wet — causes uneven cut and disease spread',
        ],
      );
    }

    if (h >= 8 && h < 25) {
      return _Recommendation(
        action: 'Routine Maintenance Cut',
        emoji: '✅', color: GEMSTheme.success, urgency: 'Low',
        reason: 'At ${h.toInt()} cm, a standard maintenance cut will bring it to the ideal height of 5–7 cm.',
        steps: [
          'Set mower blade to 5–7 cm cutting height',
          'Cut in straight overlapping rows for even coverage',
          'Collect clippings if grass is thick; leave in place if sparse (acts as mulch)',
          'Edge along pathways and building foundations with a line trimmer',
          'Water within 24 hours if no rain expected',
        ],
        doNot: [
          'Do NOT cut below 4 cm — exposes roots and causes browning',
          'Do NOT mow in midday heat — stress on both grass and workers',
        ],
      );
    }

    if (h >= 4 && h < 8) {
      return _Recommendation(
        action: 'Grass is at Ideal Height — Monitor Only',
        emoji: '🌱', color: GEMSTheme.accentGreen, urgency: 'None',
        reason: 'At ${h.toInt()} cm, this grass is within the ideal range of 5–7 cm. '
            'No cutting needed — just regular monitoring.',
        steps: [
          'Monitor weekly for growth above 10 cm',
          'Inspect for bare patches, pests, or disease signs',
          'Water every 2–3 days in dry season (early morning preferred)',
          'Apply slow-release fertiliser once per month during growing season',
        ],
        doNot: [
          'Do NOT cut yet — cutting too short weakens root system',
          'Do NOT over-water — promotes fungal disease',
        ],
      );
    }

    return _Recommendation(
      action: 'Grass Too Short — Recovery Mode',
      emoji: '⚠️', color: GEMSTheme.danger, urgency: 'Medium',
      reason: 'At ${h.toInt()} cm, the grass has been cut too short. '
          'This stresses roots and causes browning. Focus on recovery.',
      steps: [
        'Do NOT cut again until grass reaches at least 8 cm',
        'Apply a nitrogen-rich fertiliser to encourage rapid leaf growth',
        'Water daily for 2 weeks — early morning only',
        'Keep foot traffic off the area to allow recovery',
        'Overseed any bare/dead patches with matching grass seed',
      ],
      doNot: [
        'Do NOT apply herbicide on recovering grass',
        'Do NOT mow again until fully recovered to 8 cm+',
        'Do NOT allow heavy equipment on the area',
      ],
    );
  }

  Color get _sliderColor {
    if (_heightCm < 4)   return GEMSTheme.danger;
    if (_heightCm <= 7)  return GEMSTheme.success;
    if (_heightCm <= 24) return GEMSTheme.accentGreen;
    if (_heightCm <= 59) return GEMSTheme.warning;
    return const Color(0xFFE65100);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [GEMSTheme.primaryGreen.withOpacity(0.04), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GEMSTheme.primaryGreen.withOpacity(0.15)),
        boxShadow: [GEMSTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tool header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [GEMSTheme.primaryGreen, GEMSTheme.forestGreen]),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.biotech_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vegetation Assessment Tool',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    Text(
                        'Enter your grass details — get an instant action plan',
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Height slider
                _Label('Current Grass / Bush Height'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor:   _sliderColor,
                          inactiveTrackColor: Colors.grey.shade200,
                          thumbColor:         _sliderColor,
                          overlayColor:
                              _sliderColor.withOpacity(0.2),
                          trackHeight: 8,
                        ),
                        child: Slider(
                          value:    _heightCm,
                          min:      1, max: 150, divisions: 149,
                          onChanged: (v) =>
                              setState(() => _heightCm = v),
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _sliderColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _sliderColor.withOpacity(0.3)),
                      ),
                      child: Text('${_heightCm.toInt()} cm',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              color: _sliderColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ],
                ),

                // Scale marks
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _ScaleMark('1',   'Too short', GEMSTheme.danger),
                      _ScaleMark('5–7', 'Ideal',     GEMSTheme.success),
                      _ScaleMark('25',  'Cut now',   GEMSTheme.warning),
                      _ScaleMark('60+', 'Burn/chem', Color(0xFFE65100)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Dropdowns
                Row(
                  children: [
                    Expanded(child: _DropField(
                      label: 'Grass / Vegetation Type',
                      value: _grassType, items: _grassTypes,
                      icon: Icons.grass,
                      onChanged: (v) =>
                          setState(() => _grassType = v!),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _DropField(
                      label: 'Current Condition',
                      value: _condition, items: _conditions,
                      icon: Icons.wb_sunny_outlined,
                      onChanged: (v) =>
                          setState(() => _condition = v!),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _DropField(
                      label: 'Faculty Location',
                      value: _faculty, items: _faculties,
                      icon: Icons.location_on_outlined,
                      onChanged: (v) =>
                          setState(() => _faculty = v!),
                    )),
                  ],
                ),

                const SizedBox(height: 16),

                // Checkboxes
                Row(
                  children: [
                    _CheckTile(
                      label: 'Near a building (< 50 m)',
                      icon: Icons.home_work_outlined,
                      value: _nearBuilding,
                      onChanged: (v) =>
                          setState(() => _nearBuilding = v!),
                    ),
                    const SizedBox(width: 24),
                    _CheckTile(
                      label: 'Currently dry season',
                      icon: Icons.thermostat_outlined,
                      value: _drySeason,
                      onChanged: (v) =>
                          setState(() => _drySeason = v!),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Assess button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _assess,
                    icon: const Icon(Icons.search, size: 20),
                    label: const Text(
                        'Get Maintenance Recommendation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GEMSTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      textStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                // Result
                if (_result != null) ...[
                  const SizedBox(height: 24),
                  _ResultCard(rec: _result!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Result card ───────────────────────────────────────────────

class _Recommendation {
  final String action, emoji, urgency, reason;
  final Color  color;
  final List<String> steps, doNot;
  const _Recommendation({
    required this.action, required this.emoji,
    required this.color,  required this.urgency,
    required this.reason, required this.steps,
    required this.doNot,
  });
}

class _ResultCard extends StatelessWidget {
  final _Recommendation rec;
  const _ResultCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: rec.color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rec.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: rec.color.withOpacity(0.12),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(rec.emoji,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rec.action,
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: rec.color)),
                      Text('Urgency: ${rec.urgency}',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: rec.color.withOpacity(0.7))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.reason,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: GEMSTheme.textMid,
                        height: 1.6)),
                const SizedBox(height: 20),
                Text('Action Steps',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: GEMSTheme.textDark)),
                const SizedBox(height: 10),
                ...rec.steps.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22, height: 22,
                            margin: const EdgeInsets.only(
                                right: 10, top: 1),
                            decoration: BoxDecoration(
                                color: rec.color,
                                shape: BoxShape.circle),
                            child: Center(
                              child: Text('${e.key + 1}',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                          Expanded(
                            child: Text(e.value,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: GEMSTheme.textMid,
                                    height: 1.5)),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: GEMSTheme.danger.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: GEMSTheme.danger.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⛔ Do NOT',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: GEMSTheme.danger)),
                      const SizedBox(height: 8),
                      ...rec.doNot.map((d) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 5),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(
                                        color: GEMSTheme.danger)),
                                Expanded(
                                  child: Text(d,
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: GEMSTheme.danger
                                              .withOpacity(0.8),
                                          height: 1.4)),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }
}

// ══════════════════════════════════════════════════════════════
//  CUTTING GUIDE TAB
// ══════════════════════════════════════════════════════════════

class _CuttingGuide extends StatelessWidget {
  const _CuttingGuide();

  @override
  Widget build(BuildContext context) {
    return _TabCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
            icon: Icons.content_cut_rounded,
            title: 'Grass Cutting Standards',
            color: GEMSTheme.success),
        const SizedBox(height: 20),
        const _HeightTable(rows: [
          _HR('Below 4 cm', '⛔ Too short',
              'Grass is scalped. Roots are exposed. Do NOT cut again until recovery.',
              GEMSTheme.danger),
          _HR('4 – 7 cm',  '✅ Ideal height',
              'Optimal for tropical campus grasses. Maintain here.',
              GEMSTheme.success),
          _HR('8 – 15 cm', '✂️ Light trim needed',
              'A single standard mowing pass to 5–7 cm.',
              GEMSTheme.accentGreen),
          _HR('16 – 25 cm','✂️ Cut required',
              'Cut in one pass using a ride-on mower or brush-cutter.',
              GEMSTheme.warning),
          _HR('26 – 39 cm','⚠️ Two-pass cut',
              'First pass to 15 cm, wait 3 days, second pass to 5–7 cm.',
              GEMSTheme.warning),
          _HR('40 cm +',   '🌿 Bush clearance',
              'Mechanical slasher or cutlass required. Multiple passes.',
              Color(0xFF6A1B9A)),
        ]),
        const SizedBox(height: 28),
        const _SectionTitle(
            icon: Icons.schedule_rounded,
            title: 'When to Cut',
            color: GEMSTheme.primaryGreen),
        const SizedBox(height: 16),
        const _TipGrid(tips: [
          _Tip('🌅 Best Time',   'Early morning (6–9 AM)\nor late afternoon (4–6 PM).'),
          _Tip('☔ Avoid Rain',  'Never cut wet grass.\nWait 24 hrs after rainfall.'),
          _Tip('📅 Frequency',  'Every 3–4 weeks rainy season.\nEvery 5–6 weeks dry season.'),
          _Tip('🌾 Dry Season', 'Raise cutting height to 7–9 cm\nto protect roots.'),
          _Tip('🧹 Clippings',  'Remove clippings when thick.\nLeave sparse as natural mulch.'),
          _Tip('⚙️ Blade',      'Set mower blade minimum 5 cm.\nNever lower for campus grass.'),
        ]),
      ],
    ));
  }
}

// ══════════════════════════════════════════════════════════════
//  BURNING GUIDE TAB
// ══════════════════════════════════════════════════════════════

class _BurningGuide extends StatelessWidget {
  const _BurningGuide();

  @override
  Widget build(BuildContext context) {
    return _TabCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
            icon: Icons.local_fire_department_rounded,
            title: 'Controlled Burning Rules',
            color: Color(0xFFE65100)),
        const SizedBox(height: 8),
        Text(
          'Burning is a last resort, not a first response. '
          'It requires a university permit and specific conditions.',
          style: GoogleFonts.poppins(
              fontSize: 13, color: GEMSTheme.textMid, height: 1.6),
        ),
        const SizedBox(height: 24),
        const _InfoBox(
          title: '✅ Burning IS Permitted When:',
          color: Color(0xFFE65100),
          items: [
            'Grass height is 60 cm or above',
            'Vegetation is fully dry and brown (not green)',
            'Location is 50+ metres away from any building, road, or tree',
            'It is dry season (November – March in Oyo State)',
            'Wind speed is low and predictable (early morning only)',
            'A burning permit has been issued by the University Environmental Officer',
            'A fire response team and water supply are on standby',
          ],
        ),
        const SizedBox(height: 16),
        const _InfoBox(
          title: '⛔ Burning is STRICTLY FORBIDDEN When:',
          color: GEMSTheme.danger,
          items: [
            'Grass is green or still growing — produces toxic smoke',
            'Within 50 m of any building, classroom, lab, or hostel',
            'During rainy season — incomplete combustion, heavy smoke',
            'Wind is blowing toward buildings or roads',
            'After 10 AM — wind patterns become unpredictable',
            'No permit has been obtained',
            'Fire response resources are not available on-site',
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle(
            icon: Icons.checklist_rounded,
            title: 'Pre-Burn Checklist',
            color: GEMSTheme.primaryGreen),
        const SizedBox(height: 16),
        const _StepList(steps: [
          '📋  Obtain written permit from University Environmental Officer',
          '🗺️  Map the burn area and mark all exclusion zones',
          '🔥  Clear a 5 m firebreak strip around the entire perimeter',
          '💧  Position water tanker at all four corners',
          '👷  Deploy minimum 4 fire wardens with beaters',
          '📢  Notify university security and neighbouring faculties',
          '⏰  Ignite only between 6–9 AM when wind is calm',
          '🌱  Overseed with carpet grass within 14 days after burning',
        ]),
      ],
    ));
  }
}

// ══════════════════════════════════════════════════════════════
//  CHEMICAL GUIDE TAB
// ══════════════════════════════════════════════════════════════

class _ChemicalGuide extends StatelessWidget {
  const _ChemicalGuide();

  @override
  Widget build(BuildContext context) {
    return _TabCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
            icon: Icons.science_rounded,
            title: 'Chemical Vegetation Control',
            color: Color(0xFF1565C0)),
        const SizedBox(height: 8),
        Text(
          'Herbicides should only be used when mechanical cutting is impractical. '
          'Always use PPE.',
          style: GoogleFonts.poppins(
              fontSize: 13, color: GEMSTheme.textMid, height: 1.6),
        ),
        const SizedBox(height: 24),
        ...[
          _ChemCard(
            name: 'Glyphosate (Roundup)',
            type: 'Broad-spectrum herbicide',
            use: 'Kills all vegetation — use on dense bush near buildings where burning is prohibited.',
            rate: '3–5 L/ha in 200 L water',
            wait: '5–7 days before clearance',
            caution: 'Non-selective — kills all plants. Do NOT spray near flower beds or trees.',
            color: const Color(0xFFE65100),
          ),
          _ChemCard(
            name: 'Atrazine',
            type: 'Pre-emergent herbicide',
            use: 'Prevents weed/grass regrowth after clearance. Apply to bare soil after cutting.',
            rate: '1.5–2 kg/ha in 200 L water',
            wait: 'Active for 4–8 weeks',
            caution: 'Do NOT use near water bodies or drainage channels.',
            color: const Color(0xFF1565C0),
          ),
          _ChemCard(
            name: 'Paraquat (Gramoxone)',
            type: 'Contact herbicide',
            use: 'Fast-acting — kills green vegetation on contact within 24–48 hours.',
            rate: '2–3 L/ha in 200 L water',
            wait: '24–48 hours visible effect',
            caution: '⚠️ HIGHLY TOXIC. Full PPE mandatory — gloves, goggles, respirator. No skin contact.',
            color: GEMSTheme.danger,
          ),
          _ChemCard(
            name: '2,4-D Amine',
            type: 'Selective broadleaf herbicide',
            use: 'Kills weeds and broadleaf plants while leaving grass intact.',
            rate: '1–2 L/ha in 200 L water',
            wait: '7–10 days',
            caution: 'Safe for most grasses. Avoid spray drift near crops and ornamentals.',
            color: GEMSTheme.success,
          ),
        ],
        const SizedBox(height: 24),
        const _SectionTitle(
            icon: Icons.security_rounded,
            title: 'Required PPE for Chemical Use',
            color: GEMSTheme.warning),
        const SizedBox(height: 16),
        const _TipGrid(tips: [
          _Tip('🥽 Goggles',   'Chemical-splash rated\ngoggles at all times'),
          _Tip('🧤 Gloves',    'Nitrile or rubber gloves.\nNever bare hands.'),
          _Tip('😷 Respirator','N95 minimum for\nparaquat and glyphosate'),
          _Tip('👟 Boots',     'Rubber boots. No open\nfootwear around chemicals.'),
          _Tip('🥼 Coverall',  'Full-body coverall or\nlong-sleeved clothing'),
          _Tip('🚿 Wash after','Wash all exposed skin\nimmediately after use'),
        ]),
      ],
    ));
  }
}

// ══════════════════════════════════════════════════════════════
//  QUICK REFERENCE
// ══════════════════════════════════════════════════════════════

class _QuickReference extends StatelessWidget {
  const _QuickReference();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [GEMSTheme.strongShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.bookmark_rounded,
                color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            Text('Quick Reference — AATU Green Standards',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _QCol('Grass Heights', [
                '≤ 4 cm → Recovery mode',
                '5–7 cm → Ideal, monitor only',
                '8–15 cm → Standard mow',
                '16–25 cm → Immediate cut',
                '26–59 cm → Two-pass cut',
                '60+ cm (dry) → Burn or chemical',
              ])),
              const SizedBox(width: 24),
              Expanded(child: _QCol('Burning Rules', [
                '✅ 60+ cm, dry, open area',
                '✅ Dry season only (Nov–Mar)',
                '✅ 6–9 AM window only',
                '⛔ Never within 50 m of buildings',
                '⛔ Never green/wet grass',
                '⛔ Permit required always',
              ])),
              const SizedBox(width: 24),
              Expanded(child: _QCol('Chemical Use', [
                'Glyphosate → kill all vegetation',
                'Atrazine → prevent regrowth',
                'Paraquat → fast contact kill',
                '2,4-D → weeds in lawn',
                'Always use full PPE',
                'Never near water bodies',
              ])),
            ],
          ),
        ],
      ),
    );
  }
}

class _QCol extends StatelessWidget {
  final String title;
  final List<String> items;
  const _QCol(this.title, this.items);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          const SizedBox(height: 10),
          ...items.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(i,
                    style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 11,
                        height: 1.4)),
              )),
        ],
      );
}

// ══════════════════════════════════════════════════════════════
//  SMALL REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════

class _TabCard extends StatelessWidget {
  final Widget child;
  const _TabCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [GEMSTheme.softShadow],
        ),
        child: child,
      );
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String   title;
  final Color    color;
  const _SectionTitle(
      {required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: GEMSTheme.textDark)),
        ],
      );
}

class _ScaleMark extends StatelessWidget {
  final String label, sub;
  final Color  color;
  const _ScaleMark(this.label, this.sub, this.color);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text(sub,
              style: GoogleFonts.poppins(
                  fontSize: 9, color: GEMSTheme.textLight)),
        ],
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: GEMSTheme.textDark));
}

class _DropField extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String?> onChanged;
  const _DropField(
      {required this.label, required this.value,
      required this.items, required this.icon,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(label),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: GEMSTheme.offWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: GEMSTheme.textLight, size: 18),
                style: GoogleFonts.poppins(
                    fontSize: 12, color: GEMSTheme.textDark),
                items: items
                    .map((i) => DropdownMenuItem(
                        value: i, child: Text(i)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      );
}

class _CheckTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool?> onChanged;
  const _CheckTile(
      {required this.label, required this.icon,
      required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: GEMSTheme.primaryGreen,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4)),
          ),
          Icon(icon, size: 16, color: GEMSTheme.textMid),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: GEMSTheme.textMid)),
        ],
      );
}

class _HR {
  final String height, action, note;
  final Color  color;
  const _HR(this.height, this.action, this.note, this.color);
}

class _HeightTable extends StatelessWidget {
  final List<_HR> rows;
  const _HeightTable({required this.rows});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: rows.asMap().entries.map((e) {
            final r      = e.value;
            final isLast = e.key == rows.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: e.key.isEven
                    ? Colors.white
                    : GEMSTheme.offWhite.withOpacity(0.5),
                borderRadius: isLast
                    ? const BorderRadius.vertical(
                        bottom: Radius.circular(12))
                    : null,
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                            color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(r.height,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: r.color)),
                  ),
                  SizedBox(
                    width: 140,
                    child: Text(r.action,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: GEMSTheme.textDark)),
                  ),
                  Expanded(
                    child: Text(r.note,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: GEMSTheme.textLight,
                            height: 1.4)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
}

class _Tip {
  final String title, body;
  const _Tip(this.title, this.body);
}

class _TipGrid extends StatelessWidget {
  final List<_Tip> tips;
  const _TipGrid({required this.tips});

  @override
  Widget build(BuildContext context) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 2.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: tips.map((t) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GEMSTheme.offWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t.title,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: GEMSTheme.textDark)),
                  const SizedBox(height: 3),
                  Text(t.body,
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: GEMSTheme.textLight,
                          height: 1.3)),
                ],
              ),
            )).toList(),
      );
}

class _InfoBox extends StatelessWidget {
  final String title, color;
  final List<String> items;
  // Accept Color directly
  final Color? _c;
  const _InfoBox(
      {required this.title,
      required Color color,
      required this.items})
      : _c = color,
        color = '';

  @override
  Widget build(BuildContext context) {
    final c = _c!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: TextStyle(color: c, fontSize: 14)),
                    Expanded(
                      child: Text(item,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: GEMSTheme.textMid,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _StepList extends StatelessWidget {
  final List<String> steps;
  const _StepList({required this.steps});

  @override
  Widget build(BuildContext context) => Column(
        children: steps.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24, height: 24,
                    margin: const EdgeInsets.only(right: 12, top: 1),
                    decoration: const BoxDecoration(
                        color: GEMSTheme.primaryGreen,
                        shape: BoxShape.circle),
                    child: Center(
                      child: Text('${e.key + 1}',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  Expanded(
                    child: Text(e.value,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: GEMSTheme.textMid,
                            height: 1.5)),
                  ),
                ],
              ),
            )).toList(),
      );
}

class _ChemCard extends StatelessWidget {
  final String name, type, use, rate, wait, caution;
  final Color  color;
  const _ChemCard({
    required this.name, required this.type,
    required this.use,  required this.rate,
    required this.wait, required this.caution,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(name,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Text(type,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: GEMSTheme.textLight)),
            ]),
            const SizedBox(height: 10),
            Text(use,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: GEMSTheme.textMid,
                    height: 1.4)),
            const SizedBox(height: 8),
            Row(children: [
              _MiniTag('📊 Rate: $rate', GEMSTheme.emerald),
              const SizedBox(width: 8),
              _MiniTag('⏱ Wait: $wait', GEMSTheme.primaryGreen),
            ]),
            const SizedBox(height: 8),
            Text('⚠️ $caution',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500,
                    height: 1.4)),
          ],
        ),
      );
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color  color;
  const _MiniTag(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600)),
      );
}