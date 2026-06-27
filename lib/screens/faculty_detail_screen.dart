import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/gems_theme.dart';
import '../models/app_data.dart';
import '../services/supabase_service.dart';

class FacultyDetailScreen extends StatefulWidget {
  final Faculty faculty;
  const FacultyDetailScreen({super.key, required this.faculty});

  @override
  State<FacultyDetailScreen> createState() =>
      _FacultyDetailScreenState();
}

class _FacultyDetailScreenState extends State<FacultyDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  Offset _mousePos = Offset.zero;

  // Live tasks for this faculty
  List<MaintenanceTask> _tasks = [];
  bool _loadingTasks = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final raw = await SupabaseService.getTasks(
          facultyId: widget.faculty.id);
      if (mounted) {
        setState(() {
          _tasks = raw.map(MaintenanceTask.fromJson).toList();
          _loadingTasks = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTasks = false);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.faculty;
    return Scaffold(
      backgroundColor: GEMSTheme.offWhite,
      body: MouseRegion(
        onHover: (e) => setState(() => _mousePos = e.position),
        child: CustomScrollView(
          slivers: [
            // ── Hero App Bar ──
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              backgroundColor: f.color,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    if (f.imageUrl.isNotEmpty)
                      Image.network(f.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: f.color),
                          loadingBuilder: (_, child, prog) =>
                              prog == null
                                  ? child
                                  : Container(
                                      color: f.color.withOpacity(0.8)))
                    else
                      Container(color: f.color),

                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            f.color.withOpacity(0.8),
                            f.color.withOpacity(0.6),
                            Colors.black.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),

                    // Parallax circles
                    Builder(builder: (_) {
                      final size = MediaQuery.of(context).size;
                      final dx =
                          (_mousePos.dx / (size.width + 1) - 0.5) *
                              60;
                      final dy = (_mousePos.dy / 400 - 0.5) * 30;
                      return Stack(children: [
                        Positioned(
                          right: 40 + dx, top: 20 + dy,
                          child: Container(
                            width: 200, height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 120 - dx * 0.5,
                          bottom: 20 - dy * 0.5,
                          child: Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.04),
                            ),
                          ),
                        ),
                      ]);
                    }),

                    // Content
                    Positioned(
                      bottom: 32, left: 32, right: 32,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(children: [
                            _Pill(f.shortName),
                            const SizedBox(width: 10),
                            if (f.hazardLevel == 'critical')
                              _Pill('🔥 FIRE RISK',
                                  color: GEMSTheme.danger),
                          ]),
                          const SizedBox(height: 12),
                          Text(f.name,
                              style: GoogleFonts.playfairDisplay(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800))
                              .animate()
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: 0.2),
                          const SizedBox(height: 8),
                          Text('Dean: ${f.dean}  ·  ${f.totalArea} ha',
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 16),
                          Row(children: [
                            _ScorePill('GHI Score',
                                '${f.greenHealthScore.toInt()}/100'),
                            const SizedBox(width: 12),
                            _ScorePill('Hazard',
                                f.hazardLevel.toUpperCase()),
                            const SizedBox(width: 12),
                            _ScorePill('Tasks',
                                '${_tasks.length} active'),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: TabBar(
                controller: _tabCtrl,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Vegetation'),
                  Tab(text: 'Tasks'),
                ],
              ),
            ),

            // ── Tab content ──
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _OverviewTab(faculty: widget.faculty),
                  _VegetationTab(faculty: widget.faculty),
                  _TasksTab(
                    faculty: widget.faculty,
                    tasks: _tasks,
                    loading: _loadingTasks,
                    onRefresh: _loadTasks,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color? color;
  const _Pill(this.text, {this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: (color ?? Colors.white).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: color != null
              ? Border.all(color: color!.withOpacity(0.5))
              : null,
        ),
        child: Text(text,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      );
}

class _ScorePill extends StatelessWidget {
  final String label, value;
  const _ScorePill(this.label, this.value);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Text(value,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white60, fontSize: 10)),
        ]),
      );
}

// ── OVERVIEW TAB ─────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Faculty faculty;
  const _OverviewTab({required this.faculty});

  @override
  Widget build(BuildContext context) {
    final f = faculty;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          _Card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.info_outline, color: f.color, size: 20),
                const SizedBox(width: 8),
                Text('Faculty Overview', style: GEMSTheme.headingMedium),
              ]),
              const SizedBox(height: 12),
              Text(f.description, style: GEMSTheme.bodyLarge),
            ],
          )).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 20),

          Row(children: [
            Expanded(child: _InfoCard(
              icon: Icons.person_outline, label: 'Dean',
              value: f.dean, color: f.color,
            ).animate().fadeIn(delay: 200.ms)),
            const SizedBox(width: 16),
            Expanded(child: _InfoCard(
              icon: Icons.map_outlined, label: 'Total Area',
              value: '${f.totalArea} Hectares', color: GEMSTheme.emerald,
            ).animate().fadeIn(delay: 300.ms)),
            const SizedBox(width: 16),
            Expanded(child: _InfoCard(
              icon: Icons.warning_amber_rounded, label: 'Hazard Level',
              value: f.hazardLevel.toUpperCase(),
              color: f.hazardLevel == 'critical'
                  ? GEMSTheme.danger
                  : f.hazardLevel == 'medium'
                      ? GEMSTheme.warning
                      : GEMSTheme.success,
            ).animate().fadeIn(delay: 400.ms)),
          ]),

          const SizedBox(height: 20),

          // Benchmark comparison
          _Card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Benchmark Comparison', style: GEMSTheme.headingMedium),
              const SizedBox(height: 4),
              Text('vs. Environmental Science (target: 78)',
                  style: GEMSTheme.bodySmall),
              const SizedBox(height: 20),
              _BenchBar(label: f.shortName,
                  score: f.greenHealthScore, color: f.color),
              const SizedBox(height: 12),
              const _BenchBar(label: 'ENV Target',
                  score: 78, color: GEMSTheme.esFacultyColor),
              const SizedBox(height: 16),
              Text(
                f.greenHealthScore < 78
                    ? '${(78 - f.greenHealthScore).toStringAsFixed(0)} points needed to reach the benchmark'
                    : 'This faculty meets the benchmark! ✅',
                style: GoogleFonts.poppins(
                    color: f.greenHealthScore < 78
                        ? GEMSTheme.warning
                        : GEMSTheme.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          )).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [GEMSTheme.softShadow],
        ),
        child: child,
      );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  final Color    color;
  const _InfoCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [GEMSTheme.softShadow],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: GEMSTheme.textDark)),
          Text(label, style: GEMSTheme.bodySmall),
        ]),
      );
}

class _BenchBar extends StatelessWidget {
  final String label;
  final double score;
  final Color  color;
  const _BenchBar(
      {required this.label, required this.score, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(
            width: 70,
            child: Text(label, style: GEMSTheme.bodySmall)),
        Expanded(
          child: Stack(children: [
            Container(
                height: 10,
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(5))),
            FractionallySizedBox(
              widthFactor: score / 100,
              child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5))),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        Text('${score.toInt()}',
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color)),
      ]);
}

// ── VEGETATION TAB ───────────────────────────────────────────

class _VegetationTab extends StatelessWidget {
  final Faculty faculty;
  const _VegetationTab({required this.faculty});

  @override
  Widget build(BuildContext context) {
    final f = faculty;
    if (f.zones.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            'No vegetation zone data.\nAdd records to vegetation_zones table in Supabase.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pie chart
          Expanded(
            child: _Card(child: Column(children: [
              Text('Vegetation Distribution',
                  style: GEMSTheme.headingMedium),
              const SizedBox(height: 24),
              SizedBox(
                height: 240,
                child: PieChart(PieChartData(
                  sections: f.zones.map((z) =>
                    PieChartSectionData(
                      value: z.percentage,
                      color: z.color,
                      title: '${z.percentage.toInt()}%',
                      titleStyle: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                      radius: 80,
                    )).toList(),
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                )),
              ),
              const SizedBox(height: 20),
              ...f.zones.map((z) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                          color: z.color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Icon(z.icon, color: z.color, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(z.name,
                      style: GEMSTheme.bodySmall)),
                  Text('${z.percentage.toInt()}%',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: z.color)),
                ]),
              )),
            ])).animate().fadeIn(delay: 100.ms),
          ),

          const SizedBox(width: 20),

          // Zone cards
          Expanded(
            child: Column(
              children: f.zones.asMap().entries.map((e) =>
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: e.value.color.withOpacity(0.2)),
                    boxShadow: [GEMSTheme.softShadow],
                  ),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: e.value.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(e.value.icon,
                          color: e.value.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.value.name,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: GEMSTheme.textDark)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: e.value.percentage / 100,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation(
                                e.value.color),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    )),
                    const SizedBox(width: 14),
                    Text('${e.value.percentage.toInt()}%',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: e.value.color)),
                  ]),
                ).animate().fadeIn(delay: (e.key * 100).ms)
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── TASKS TAB ────────────────────────────────────────────────

class _TasksTab extends StatelessWidget {
  final Faculty              faculty;
  final List<MaintenanceTask> tasks;
  final bool                 loading;
  final VoidCallback         onRefresh;
  const _TasksTab(
      {required this.faculty,
      required this.tasks,
      required this.loading,
      required this.onRefresh});

  Color _statusColor(String s) {
    switch (s) {
      case 'completed':   return GEMSTheme.success;
      case 'overdue':     return GEMSTheme.danger;
      case 'in_progress': return GEMSTheme.warning;
      default:            return GEMSTheme.textLight;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'completed':   return Icons.check_circle;
      case 'overdue':     return Icons.error;
      case 'in_progress': return Icons.autorenew;
      default:            return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = faculty;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Maintenance Tasks', style: GEMSTheme.headingLarge),
              if (loading)
                const CircularProgressIndicator(
                    color: GEMSTheme.primaryGreen,
                    strokeWidth: 2)
              else
                IconButton(
                  icon: const Icon(Icons.refresh,
                      color: GEMSTheme.textMid),
                  onPressed: onRefresh,
                ),
            ],
          ),
          const SizedBox(height: 20),

          if (tasks.isEmpty && !loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'No tasks for this faculty yet.\nCreate one from the Tasks tab.',
                  textAlign: TextAlign.center,
                  style: GEMSTheme.bodySmall,
                ),
              ),
            )
          else
            ...tasks.asMap().entries.map((e) {
              final t = e.value;
              final sc = _statusColor(t.status);
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sc.withOpacity(0.2)),
                  boxShadow: [GEMSTheme.softShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(_statusIcon(t.status), color: sc, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t.title,
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: GEMSTheme.textDark))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sc.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                            t.status
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: sc)),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Text(t.description, style: GEMSTheme.bodySmall),
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: GEMSTheme.textLight),
                      const SizedBox(width: 4),
                      Text(t.assignedTo, style: GEMSTheme.bodySmall),
                      const Spacer(),
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: GEMSTheme.textLight),
                      const SizedBox(width: 4),
                      Text(
                          'Due: ${t.dueDate.day}/${t.dueDate.month}/${t.dueDate.year}',
                          style: GEMSTheme.bodySmall),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: f.color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(t.taskType,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: f.color,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    // Status update buttons
                    if (t.status != 'completed') ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        if (t.status != 'in_progress')
                          _StatusBtn('In Progress',
                              GEMSTheme.warning, () async {
                            await SupabaseService.updateTaskStatus(
                                t.id, 'in_progress');
                            onRefresh();
                          }),
                        const SizedBox(width: 8),
                        _StatusBtn('Complete',
                            GEMSTheme.success, () async {
                          await SupabaseService.updateTaskStatus(
                              t.id, 'completed');
                          onRefresh();
                        }),
                      ]),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: (e.key * 100).ms).slideY(begin: 0.1);
            }),
        ],
      ),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final Color  color;
  final VoidCallback onTap;
  const _StatusBtn(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ),
      );
}