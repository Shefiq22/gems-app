// ============================================================
//  GEMS — Vegetation Report Screen
//  Who uses it:
//    Groundskeepers → submit a field vegetation report
//    Faculty Officers → view all pending reports for their faculty, mark reviewed/actioned
//    Admins → view ALL reports across all faculties
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/gems_theme.dart';
import '../services/supabase_service.dart';

class VegetationReportScreen extends StatefulWidget {
  const VegetationReportScreen({super.key});

  @override
  State<VegetationReportScreen> createState() =>
      _VegetationReportScreenState();
}

class _VegetationReportScreenState
    extends State<VegetationReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final String _role = SupabaseService.currentRole;

  @override
  void initState() {
    super.initState();
    // Groundskeepers get one tab (Submit); officers/admins get two
    _tabs = TabController(
      length: _role == 'groundskeeper' ? 1 : 2,
      vsync: this,
    );
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [GEMSTheme.primaryGreen, GEMSTheme.emerald],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.grass, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vegetation Reports', style: GEMSTheme.displayMedium),
                  Text(
                    _role == 'groundskeeper'
                        ? 'Submit your field observations'
                        : 'Review field reports from groundskeepers',
                    style: GEMSTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15),

          const SizedBox(height: 28),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
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
              tabs: [
                const Tab(text: '📋  Submit Report'),
                if (_role != 'groundskeeper')
                  const Tab(text: '📂  All Reports'),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 4),

          AnimatedBuilder(
            animation: _tabs,
            builder: (_, __) => IndexedStack(
              index: _tabs.index,
              children: [
                const _SubmitReportForm(),
                if (_role != 'groundskeeper')
                  const _ReportsList(),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

// ── SUBMIT FORM ───────────────────────────────────────────────

class _SubmitReportForm extends StatefulWidget {
  const _SubmitReportForm();

  @override
  State<_SubmitReportForm> createState() => _SubmitReportFormState();
}

class _SubmitReportFormState extends State<_SubmitReportForm> {
  final _zoneCtrl  = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _facultyId      = SupabaseService.currentFacultyId.isNotEmpty
      ? SupabaseService.currentFacultyId : 'nas';
  String _vegType        = 'bush';
  String _condition      = 'dry';
  double _heightCm       = 20;
  double _coveragePct    = 50;
  bool   _nearBuilding   = false;
  bool   _isDrySeason    = false;
  bool   _loading        = false;
  bool   _submitted      = false;

  static const _faculties = [
    ('nas', 'Natural & Applied Sciences'),
    ('es',  'Environmental Science'),
    ('eng', 'Engineering'),
    ('med', 'Medical Science'),
  ];

  static const _vegTypes = [
    ('bush',  'Dense Bush / Wild Grass'),
    ('grass', 'Maintained Grass'),
    ('mixed', 'Mixed Vegetation'),
    ('bare',  'Bare / Eroded Land'),
  ];

  static const _conditions = [
    ('green', 'Green & Growing'),
    ('dry',   'Dry & Brown'),
    ('mixed', 'Mixed (partly dry)'),
    ('dead',  'Dead / Dormant'),
  ];

  Color get _sliderColor {
    if (_heightCm < 4)  return GEMSTheme.danger;
    if (_heightCm <= 7) return GEMSTheme.success;
    if (_heightCm <= 24) return GEMSTheme.accentGreen;
    if (_heightCm <= 59) return GEMSTheme.warning;
    return const Color(0xFFE65100);
  }

  String get _urgencyLabel {
    if (_heightCm >= 60 && _condition == 'dry' && _nearBuilding) return 'CRITICAL — Immediate action required';
    if (_heightCm >= 60) return 'High — Burn or chemical control';
    if (_heightCm >= 25) return 'Medium — Mechanical cutting required';
    if (_heightCm >= 8)  return 'Low — Routine maintenance';
    return 'Monitor — Ideal height range';
  }

  Color get _urgencyColor {
    if (_heightCm >= 60 && _nearBuilding) return GEMSTheme.danger;
    if (_heightCm >= 60) return const Color(0xFFE65100);
    if (_heightCm >= 25) return GEMSTheme.warning;
    return GEMSTheme.success;
  }

  Future<void> _submit() async {
    if (_zoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter the zone/location name.'),
        backgroundColor: GEMSTheme.danger,
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      await SupabaseService.submitVegetationReport(
        facultyId:      _facultyId,
        zoneName:       _zoneCtrl.text.trim(),
        grassHeightCm:  _heightCm,
        vegetationType: _vegType,
        condition:      _condition,
        nearBuilding:   _nearBuilding,
        isDrySeason:    _isDrySeason,
        coveragePct:    _coveragePct,
        notes:          _notesCtrl.text.trim(),
      );
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: GEMSTheme.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _zoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccess();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [GEMSTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Faculty + Zone ──
          Row(
            children: [
              Expanded(child: _buildDropdown('Faculty', _facultyId, _faculties,
                  (v) => setState(() => _facultyId = v!))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Zone / Location Name'),
                    const SizedBox(height: 8),
                    _inputBox(TextField(
                      controller: _zoneCtrl,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: GEMSTheme.textDark),
                      decoration: InputDecoration(
                        hintText: 'e.g. Block A Perimeter, Lab Walkway',
                        hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade400, fontSize: 12),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Vegetation type + condition ──
          Row(
            children: [
              Expanded(child: _buildDropdown('Vegetation Type', _vegType, _vegTypes,
                  (v) => setState(() => _vegType = v!))),
              const SizedBox(width: 16),
              Expanded(child: _buildDropdown('Current Condition', _condition, _conditions,
                  (v) => setState(() => _condition = v!))),
            ],
          ),

          const SizedBox(height: 24),

          // ── Height slider ──
          _label('Grass / Bush Height'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: _sliderColor,
                    inactiveTrackColor: Colors.grey.shade200,
                    thumbColor: _sliderColor,
                    overlayColor: _sliderColor.withOpacity(0.2),
                    trackHeight: 8,
                  ),
                  child: Slider(
                    value: _heightCm,
                    min: 1,
                    max: 150,
                    divisions: 149,
                    onChanged: (v) => setState(() => _heightCm = v),
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

          const SizedBox(height: 16),

          // ── Coverage slider ──
          _label('Vegetation Coverage of Zone (%)'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: GEMSTheme.primaryGreen,
                    inactiveTrackColor: Colors.grey.shade200,
                    thumbColor: GEMSTheme.primaryGreen,
                    overlayColor:
                        GEMSTheme.primaryGreen.withOpacity(0.2),
                    trackHeight: 8,
                  ),
                  child: Slider(
                    value: _coveragePct,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: (v) => setState(() => _coveragePct = v),
                  ),
                ),
              ),
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: GEMSTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_coveragePct.toInt()}%',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: GEMSTheme.primaryGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Checkboxes ──
          Row(
            children: [
              _CheckTile(
                label: 'Within 50 m of a building',
                icon: Icons.home_work_outlined,
                value: _nearBuilding,
                onChanged: (v) => setState(() => _nearBuilding = v!),
              ),
              const SizedBox(width: 32),
              _CheckTile(
                label: 'Currently dry season',
                icon: Icons.thermostat_outlined,
                value: _isDrySeason,
                onChanged: (v) => setState(() => _isDrySeason = v!),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Notes ──
          _label('Additional Notes (optional)'),
          const SizedBox(height: 8),
          _inputBox(TextField(
            controller: _notesCtrl,
            maxLines: 3,
            style: GoogleFonts.poppins(
                fontSize: 13, color: GEMSTheme.textDark),
            decoration: InputDecoration(
              hintText:
                  'Any hazards, pest sightings, erosion, or other observations...',
              hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400, fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          )),

          const SizedBox(height: 24),

          // ── Urgency preview ──
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _urgencyColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _urgencyColor.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt, color: _urgencyColor, size: 20),
                const SizedBox(width: 10),
                Text(_urgencyLabel,
                    style: GoogleFonts.poppins(
                        color: _urgencyColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(
                  _loading ? 'Submitting...' : 'Submit Field Report',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: GEMSTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [GEMSTheme.softShadow],
        ),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: GEMSTheme.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: GEMSTheme.success, size: 48),
              ),
              const SizedBox(height: 24),
              Text('Report Submitted!',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: GEMSTheme.textDark)),
              const SizedBox(height: 12),
              Text(
                'Your field vegetation report has been received.\nA Faculty Officer will review and take action.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: GEMSTheme.textLight,
                    height: 1.6),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => setState(() {
                  _submitted = false;
                  _zoneCtrl.clear();
                  _notesCtrl.clear();
                  _heightCm = 20;
                  _coveragePct = 50;
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GEMSTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Submit Another Report',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));

  Widget _buildDropdown(
      String label, String value, List<(String, String)> items,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
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
                      value: i.$1, child: Text(i.$2)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: GEMSTheme.textDark));

  Widget _inputBox(Widget child) => Container(
        decoration: BoxDecoration(
          color: GEMSTheme.offWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: child,
      );
}

// ── REPORTS LIST (Officer / Admin view) ───────────────────────

class _ReportsList extends StatefulWidget {
  const _ReportsList();

  @override
  State<_ReportsList> createState() => _ReportsListState();
}

class _ReportsListState extends State<_ReportsList> {
  bool _loading = true;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final role = SupabaseService.currentRole;
      final facultyId = role == 'faculty_officer'
          ? SupabaseService.currentFacultyId
          : null;
      final data = await SupabaseService.getVegetationReports(
          facultyId: facultyId);
      if (mounted) setState(() => _reports = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
            child: CircularProgressIndicator(
                color: GEMSTheme.primaryGreen)),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: _reports.asMap().entries.map((e) {
          final r = e.value;
          final height = (r['grass_height_cm'] as num?)?.toDouble() ?? 0;
          final status = r['status'] as String? ?? 'pending';
          final faculty = r['faculties'] as Map<String, dynamic>?;

          Color statusColor;
          IconData statusIcon;
          switch (status) {
            case 'reviewed':
              statusColor = GEMSTheme.warning;
              statusIcon  = Icons.visibility;
              break;
            case 'actioned':
              statusColor = GEMSTheme.success;
              statusIcon  = Icons.check_circle;
              break;
            default:
              statusColor = GEMSTheme.danger;
              statusIcon  = Icons.pending_actions;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: statusColor.withOpacity(0.2)),
              boxShadow: [GEMSTheme.softShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['zone_name'] ?? '',
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: GEMSTheme.textDark)),
                          const SizedBox(height: 3),
                          Text(
                            faculty?['name'] ?? r['faculty_id'] ?? '',
                            style: GEMSTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon,
                              color: statusColor, size: 14),
                          const SizedBox(width: 5),
                          Text(status.toUpperCase(),
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Stats row
                Row(
                  children: [
                    _Stat(
                        label: 'Height',
                        value: '${height.toInt()} cm',
                        color: height >= 60
                            ? GEMSTheme.danger
                            : height >= 25
                                ? GEMSTheme.warning
                                : GEMSTheme.success),
                    _Stat(
                        label: 'Type',
                        value: r['vegetation_type'] ?? '',
                        color: GEMSTheme.primaryGreen),
                    _Stat(
                        label: 'Condition',
                        value: r['condition'] ?? '',
                        color: r['condition'] == 'dry'
                            ? GEMSTheme.danger
                            : GEMSTheme.success),
                    _Stat(
                        label: 'Coverage',
                        value: '${(r['coverage_pct'] as num?)?.toInt() ?? 0}%',
                        color: GEMSTheme.emerald),
                    if (r['near_building'] == true)
                      _Stat(
                          label: 'Near Building',
                          value: '⚠️ Yes',
                          color: GEMSTheme.danger),
                  ],
                ),

                if ((r['notes'] as String? ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(r['notes'] as String,
                      style: GEMSTheme.bodySmall),
                ],

                const SizedBox(height: 14),

                Row(
                  children: [
                    Text(
                      'By: ${r['submitter_name'] ?? 'Unknown'}',
                      style: GEMSTheme.bodySmall,
                    ),
                    const Spacer(),
                    // Action buttons (officer/admin only)
                    if (status == 'pending')
                      _ActionBtn(
                        label: 'Mark Reviewed',
                        color: GEMSTheme.warning,
                        onTap: () async {
                          await SupabaseService
                              .updateVegetationReportStatus(
                                  r['id'], 'reviewed');
                          _load();
                        },
                      ),
                    if (status == 'reviewed') ...[
                      const SizedBox(width: 8),
                      _ActionBtn(
                        label: 'Mark Actioned',
                        color: GEMSTheme.success,
                        onTap: () async {
                          await SupabaseService
                              .updateVegetationReportStatus(
                                  r['id'], 'actioned');
                          _load();
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: (e.key * 80).ms);
        }).toList(),
      ),
    );
  }
}

// ── SMALL WIDGETS ─────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: GEMSTheme.textLight)),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ),
      );
}

class _CheckTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool?> onChanged;
  const _CheckTile(
      {required this.label,
      required this.icon,
      required this.value,
      required this.onChanged});

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