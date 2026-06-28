// ============================================================
//  GEMS — Dashboard Screen
//
//  Admin        → full university overview, all faculties,
//                 stat cards, trend chart, benchmark banner
//  Faculty Off. → their faculty only, pending veg reports
//  Groundskeeper → task list (their faculty) + submit btn
//  Student      → READ-ONLY: GHI scores per faculty +
//                 campus news + report issue button only
//
//  Zero hardcoded data. All values from Supabase.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../theme/gems_theme.dart';
import '../models/app_data.dart';
import '../widgets/sidebar.dart';
import '../widgets/faculty_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/animated_score_ring.dart';
import '../services/supabase_service.dart';
import 'faculty_detail_screen.dart';
import 'green_guide_screen.dart';
import 'vegetation_report_screen.dart';
import 'notifications_screen.dart';
import 'module_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _selectedNav = 0;
  late AnimationController _heroAnim;

  bool   _loading = true;
  String? _error;

  List<Faculty>         _faculties = [];
  List<MaintenanceTask> _tasks     = [];
  List<MonthlyReport>   _reports   = [];

  // University-wide settings (no hardcoding)
  int    _totalAreaHa  = 0;
  int    _foundedYear  = 0;
  String _uniName      = '';

  final String _role      = SupabaseService.currentRole;
  final String _facultyId = SupabaseService.currentFacultyId;

  String _userName    = '';
  String _userInitial = 'U';

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);

    if (!SupabaseService.isConfigured ||
        SupabaseService.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (r) => false);
      });
      return;
    }

    _userName    = SupabaseService.currentFullName;
    _userInitial = _userName.isNotEmpty
        ? _userName[0].toUpperCase()
        : 'U';

    _loadData();
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final facultyFilter =
          (_role == 'faculty_officer' || _role == 'groundskeeper') &&
                  _facultyId.isNotEmpty
              ? _facultyId
              : null;

      final results = await Future.wait([
        SupabaseService.getFaculties(),
        SupabaseService.getTasks(facultyId: facultyFilter),
        SupabaseService.getMonthlyReports(),
        SupabaseService.getUniversitySettings(),
      ]);

      final rawFaculties = results[0] as List<Map<String, dynamic>>;
      final rawTasks     = results[1] as List<Map<String, dynamic>>;
      final rawReports   = results[2] as List<Map<String, dynamic>>;
      final uniSettings  = results[3] as Map<String, dynamic>;

      final tasks = rawTasks.map(MaintenanceTask.fromJson).toList();

      final faculties = rawFaculties.map((json) {
        final f  = Faculty.fromJson(json);
        final ft = tasks.where((t) => t.facultyId == f.id).toList();
        return f.copyWith(tasks: ft);
      }).toList();

      final visibleFaculties = facultyFilter != null
          ? faculties
              .where((f) => f.id == facultyFilter)
              .toList()
          : faculties;

      if (!mounted) return;
      setState(() {
        _faculties    = visibleFaculties;
        _tasks        = tasks;
        _reports      = rawReports.map(MonthlyReport.fromJson).toList();
        _totalAreaHa  =
            (uniSettings['total_area_ha'] as num?)?.toInt() ?? 0;
        _foundedYear  =
            (uniSettings['founded_year'] as num?)?.toInt() ??
                DateTime.now().year;
        _uniName      = uniSettings['name'] as String? ??
            'Abiola Ajimobi University';
        _loading      = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _signOut() async {
    await SupabaseService.signOut();
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (r) => false);
    }
  }

  // ── Computed stats ────────────────────────────────────────
  double get _overallScore {
    if (_faculties.isEmpty) return 0;
    return _faculties
            .map((f) => f.greenHealthScore)
            .reduce((a, b) => a + b) /
        _faculties.length;
  }

  int get _criticalTasks =>
      _tasks.where((t) =>
          t.status == 'overdue' || t.priority == 'critical').length;

  int get _completedTasks =>
      _tasks.where((t) => t.status == 'completed').length;

  int get _campusAge =>
      DateTime.now().year - _foundedYear;

  // ── Body router ───────────────────────────────────────────
  Widget _buildBody() {
    switch (_selectedNav) {
      case 0:  return _buildDashboardTab();
      case 1:  return _buildFacultiesTab();
      case 2:  return _buildTasksTab();
      case 3:  return _buildReportsTab();
      case 4:  return const GreenGuideScreen();
      case 5:  return const IssuesScreen();
      case 6:  return const VegetationReportScreen();
      case 7:  return const TreeRegistryScreen();
      case 8:  return const NotificationsScreen();
      case 9:  return const SettingsScreen();
      default: return _buildDashboardTab();
    }
  }

  // ── SCAFFOLD ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: GEMSTheme.offWhite,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                  color: GEMSTheme.primaryGreen),
              const SizedBox(height: 20),
              Text('Loading GEMS...', style: GEMSTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    if (_error != null && _faculties.isEmpty) {
      return Scaffold(
        backgroundColor: GEMSTheme.offWhite,
        body: Center(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [GEMSTheme.softShadow],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off,
                  color: GEMSTheme.danger, size: 48),
              const SizedBox(height: 16),
              Text('Could not load data',
                  style: GEMSTheme.headingMedium),
              const SizedBox(height: 8),
              Text(_error!,
                  style: GEMSTheme.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GEMSTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                ),
              ),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: GEMSTheme.offWhite,
      body: Row(
        children: [
          GEMSSidebar(
            selectedIndex: _selectedNav,
            onSelect:      (i) => setState(() => _selectedNav = i),
            userName:      _userName,
            userInitial:   _userInitial,
            onSignOut:     _signOut,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  DASHBOARD TAB — routes by role
  // ══════════════════════════════════════════════════════════

  Widget _buildDashboardTab() {
    switch (_role) {
      case 'student':
        return _buildStudentDashboard();
      case 'groundskeeper':
        return _buildGroundskeeperDashboard();
      default:
        return _buildAdminOfficerDashboard();
    }
  }

  // ── STUDENT DASHBOARD ────────────────────────────────────
  // Read-only. Shows GHI per faculty, no admin controls.
  Widget _buildStudentDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_uniName, style: GEMSTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text('Campus Green Overview',
                      style: GEMSTheme.displayMedium),
                ],
              ),
              _IconBtn(
                  icon: Icons.refresh,
                  tooltip: 'Refresh',
                  onTap: _loadData),
            ],
          ).animate().fadeIn(),

          const SizedBox(height: 16),

          // Student notice
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: GEMSTheme.textMid.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: GEMSTheme.textMid.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.school_rounded,
                  color: GEMSTheme.textMid, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Student view — read-only. '
                  'Use "Report Issue" to flag environmental problems.',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: GEMSTheme.textMid),
                ),
              ),
            ]),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 24),

          // Overall score hero
          _StudentScoreHero(
            score:      _overallScore,
            controller: _heroAnim,
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 24),

          // Faculty score cards (read-only, no tap to detail)
          Text('Faculty Green Health Scores',
              style: GEMSTheme.headingLarge),
          const SizedBox(height: 4),
          Text('Live scores — updated by faculty officers',
              style: GEMSTheme.bodySmall),
          const SizedBox(height: 16),

          if (_faculties.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                  child: Text('No data yet.',
                      style: GEMSTheme.bodySmall)),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _faculties.length,
              itemBuilder: (_, i) {
                final f = _faculties[i];
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: f.color.withOpacity(0.2)),
                    boxShadow: [GEMSTheme.softShadow],
                  ),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: f.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(f.shortName,
                            style: GoogleFonts.poppins(
                                color: f.color,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Text(f.name,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: GEMSTheme.textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: f.greenHealthScore / 100,
                              backgroundColor:
                                  Colors.grey.shade100,
                              valueColor:
                                  AlwaysStoppedAnimation(
                                      f.color),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                              '${f.greenHealthScore.toInt()}/100',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: f.color)),
                        ],
                      ),
                    ),
                  ]),
                ).animate().fadeIn(delay: (200 + i * 80).ms);
              },
            ),

          const SizedBox(height: 28),

          // Report issue CTA
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                GEMSTheme.primaryGreen.withOpacity(0.9),
                GEMSTheme.emerald,
              ]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [GEMSTheme.strongShadow],
            ),
            child: Row(children: [
              const Icon(Icons.report_problem_rounded,
                  color: Colors.amber, size: 36),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spotted an Environmental Issue?',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                        'Help keep campus green — report overgrown bushes, fires, or litter.',
                        style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () =>
                    setState(() => _selectedNav = 5),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: GEMSTheme.primaryGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
                child: Text('Report Now',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ]),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  // ── GROUNDSKEEPER DASHBOARD ───────────────────────────────
  Widget _buildGroundskeeperDashboard() {
    final myTasks = _tasks
        .where((t) =>
            t.facultyId == _facultyId ||
            _facultyId.isEmpty)
        .toList();
    final pending =
        myTasks.where((t) => t.status != 'completed').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, $_userName',
                      style: GEMSTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text('My Work Queue',
                      style: GEMSTheme.displayMedium),
                ],
              ),
              Row(children: [
                ElevatedButton.icon(
                  onPressed: () =>
                      setState(() => _selectedNav = 6),
                  icon: const Icon(Icons.grass, size: 16),
                  label: const Text('Submit Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GEMSTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 10),
                _IconBtn(
                    icon: Icons.refresh,
                    tooltip: 'Refresh',
                    onTap: _loadData),
              ]),
            ],
          ).animate().fadeIn(),

          const SizedBox(height: 20),

          // Quick stats
          Row(children: [
            Expanded(
              child: GEMSStatCard(
                title:    'Pending Tasks',
                value:    '$pending',
                subtitle: 'In your faculty zone',
                icon:     Icons.pending_actions_rounded,
                color:    GEMSTheme.warning,
                trend:    pending > 0
                    ? 'Action needed'
                    : 'All clear!',
                positive: pending == 0,
              ).animate().fadeIn(delay: 100.ms),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GEMSStatCard(
                title:    'Completed Tasks',
                value:    '${myTasks.where((t) => t.status == "completed").length}',
                subtitle: 'This period',
                icon:     Icons.check_circle_outline,
                color:    GEMSTheme.success,
                trend:    'Great work!',
                positive: true,
              ).animate().fadeIn(delay: 200.ms),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GEMSStatCard(
                title:    'Overdue',
                value:    '${myTasks.where((t) => t.status == "overdue").length}',
                subtitle: 'Needs immediate attention',
                icon:     Icons.warning_amber_rounded,
                color:    GEMSTheme.danger,
                trend:    'Urgent',
                positive: false,
              ).animate().fadeIn(delay: 300.ms),
            ),
          ]),

          const SizedBox(height: 28),

          Text('My Task List', style: GEMSTheme.headingLarge),
          const SizedBox(height: 4),
          Text('Tasks assigned to your zone — tap ⋮ to update status',
              style: GEMSTheme.bodySmall),
          const SizedBox(height: 16),

          if (myTasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(children: [
                  const Icon(Icons.check_circle_outline,
                      size: 48,
                      color: GEMSTheme.success),
                  const SizedBox(height: 12),
                  Text('No tasks assigned to your zone.',
                      style: GEMSTheme.bodySmall),
                ]),
              ),
            )
          else
            ..._buildTaskRows(myTasks),
        ],
      ),
    );
  }

  // ── ADMIN / OFFICER DASHBOARD ─────────────────────────────
  Widget _buildAdminOfficerDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_uniName, style: GEMSTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text('Campus Overview',
                      style: GEMSTheme.displayMedium),
                ],
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
              Row(children: [
                if (_error != null)
                  Tooltip(
                    message: 'Data error: $_error',
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.cloud_off,
                          color: GEMSTheme.warning, size: 20),
                    ),
                  ),
                _IconBtn(
                    icon: Icons.refresh,
                    tooltip: 'Refresh',
                    onTap: _loadData),
                const SizedBox(width: 12),
                _IconBtn(
                    icon: Icons.notifications_outlined,
                    tooltip: 'Notifications',
                    onTap: () =>
                        setState(() => _selectedNav = 8)),
              ]).animate().fadeIn(delay: 200.ms),
            ],
          ),

          const SizedBox(height: 20),

          _RoleBanner(role: _role, facultyId: _facultyId)
              .animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 16),

          // Hero card
          _HeroBanner(
            score:      _overallScore,
            controller: _heroAnim,
            faculties:  _faculties,
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

          const SizedBox(height: 24),

          // Stat cards — all values from live data
          Row(children: [
            Expanded(
              child: GEMSStatCard(
                title:    'Overall GHI',
                value:    '${_overallScore.toStringAsFixed(1)}%',
                subtitle: 'Avg. across ${_faculties.length} faculties',
                icon:     Icons.eco,
                color:    GEMSTheme.accentGreen,
                trend:    _overallScore >= 60
                    ? 'Campus in good standing'
                    : 'Below target — action needed',
                positive: _overallScore >= 60,
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GEMSStatCard(
                title:    'Critical Alerts',
                value:    '$_criticalTasks',
                subtitle: 'Overdue or critical tasks',
                icon:     Icons.warning_amber_rounded,
                color:    GEMSTheme.danger,
                trend:    _criticalTasks > 0
                    ? 'Immediate action needed'
                    : 'No critical issues',
                positive: _criticalTasks == 0,
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GEMSStatCard(
                title:    'Tasks Completed',
                value:    '$_completedTasks/${_tasks.length}',
                subtitle: 'This period',
                icon:     Icons.check_circle_outline,
                color:    GEMSTheme.success,
                trend:    _tasks.isNotEmpty
                    ? '${(_completedTasks / _tasks.length * 100).toInt()}% completion rate'
                    : 'No tasks yet',
                positive: _tasks.isEmpty || _completedTasks > 0,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GEMSStatCard(
                title:    'Total Campus Area',
                value:    _totalAreaHa > 0 ? '$_totalAreaHa ha' : '—',
                subtitle: _campusAge > 0
                    ? '$_campusAge year old campus'
                    : '',
                icon:     Icons.map_outlined,
                color:    GEMSTheme.emerald,
                trend:    '${_faculties.length} active faculty zones',
                positive: true,
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
            ),
          ]),

          const SizedBox(height: 28),

          // Faculty grid + side panels
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Faculty Zones',
                        style: GEMSTheme.headingLarge),
                    const SizedBox(height: 4),
                    Text('Tap a faculty to view details',
                        style: GEMSTheme.bodySmall),
                    const SizedBox(height: 20),
                    if (_faculties.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'No faculties found.\nRun SUPABASE_SETUP.sql first.',
                            textAlign: TextAlign.center,
                            style: GEMSTheme.bodySmall,
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.15,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _faculties.length,
                        itemBuilder: (_, i) => FacultyCard(
                          faculty: _faculties[i],
                          onTap: () =>
                              Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  FacultyDetailScreen(
                                      faculty: _faculties[i]),
                              transitionDuration:
                                  const Duration(
                                      milliseconds: 500),
                              transitionsBuilder:
                                  (_, anim, __, child) =>
                                      FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.08, 0),
                                    end: Offset.zero,
                                  ).animate(anim),
                                  child: child,
                                ),
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: (300 + i * 100).ms)
                            .scale(
                                begin:
                                    const Offset(0.92, 0.92)),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    if (_reports.isNotEmpty)
                      _TrendChart(reports: _reports)
                          .animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 20),
                    _RecentAlerts(tasks: _tasks)
                        .animate().fadeIn(delay: 500.ms),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          if (_faculties.isNotEmpty)
            _BenchmarkBanner(faculties: _faculties)
                .animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  List<Widget> _buildTaskRows(List<MaintenanceTask> tasks) {
    return tasks.asMap().entries.map((e) {
      final task    = e.value;
      final faculty = _faculties.firstWhere(
        (f) => f.id == task.facultyId,
        orElse: () => Faculty(
          id: task.facultyId, name: task.facultyId,
          shortName: task.facultyId.toUpperCase(),
          description: '', color: GEMSTheme.primaryGreen,
          greenHealthScore: 0, zones: const [], tasks: const [],
          imageUrl: '', hazardLevel: 'low',
          totalArea: 0, dean: '',
        ),
      );
      return _TaskRow(
        faculty: faculty,
        task: task,
        onStatusChange: _loadData,
      ).animate().fadeIn(delay: (e.key * 60).ms);
    }).toList();
  }

  // ══════════════════════════════════════════════════════════
  //  FACULTIES TAB
  // ══════════════════════════════════════════════════════════

  Widget _buildFacultiesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_role == 'faculty_officer'
                  ? 'My Faculty'
                  : 'All Faculties',
              style: GEMSTheme.displayMedium).animate().fadeIn(),
          const SizedBox(height: 8),
          Text('Vegetation profiles and maintenance status',
              style: GEMSTheme.bodySmall)
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 28),
          if (_faculties.isEmpty)
            Center(
              child: Text('No faculty data.',
                  style: GEMSTheme.bodySmall),
            )
          else
            ..._faculties.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _FacultyListCard(faculty: e.value)
                      .animate()
                      .fadeIn(delay: (e.key * 120).ms)
                      .slideX(begin: 0.1),
                )),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  TASKS TAB
  // ══════════════════════════════════════════════════════════

  Widget _buildTasksTab() {
    final canCreate =
        _role == 'admin' || _role == 'faculty_officer';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Maintenance Tasks',
                      style: GEMSTheme.displayMedium),
                  const SizedBox(height: 4),
                  Text('Scheduled and ongoing activities',
                      style: GEMSTheme.bodySmall),
                ],
              ),
              if (canCreate)
                ElevatedButton.icon(
                  onPressed: () => _showCreateTaskDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GEMSTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ).animate().fadeIn(),
          const SizedBox(height: 28),
          if (_tasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: Text('No tasks yet.',
                    style: GEMSTheme.bodySmall),
              ),
            )
          else
            ..._buildTaskRows(_tasks),
        ],
      ),
    );
  }

  void _showCreateTaskDialog() {
    final titleCtrl  = TextEditingController();
    final descCtrl   = TextEditingController();
    final assignCtrl = TextEditingController();
    String status   = 'pending';
    String priority = 'medium';
    String taskType = 'Bush Clearing';
    String fId = _faculties.isNotEmpty
        ? _faculties.first.id : 'nas';
    DateTime dueDate =
        DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Create New Task',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 18)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DlgField('Task Title', titleCtrl,
                      'e.g. Bush Clearing — Block A'),
                  const SizedBox(height: 12),
                  _DlgField('Description', descCtrl,
                      'What needs to be done...', maxLines: 3),
                  const SizedBox(height: 12),
                  _DlgField('Assigned To', assignCtrl,
                      'e.g. Groundskeeping Team A'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _DlgDrop(
                      'Faculty', fId,
                      _faculties.map((f) => (f.id, f.shortName)).toList(),
                      (v) => setDlg(() => fId = v!),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _DlgDrop(
                      'Priority', priority,
                      const [('low','Low'),('medium','Medium'),('high','High'),('critical','Critical')],
                      (v) => setDlg(() => priority = v!),
                    )),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _DlgDrop(
                      'Task Type', taskType,
                      const [
                        ('Bush Clearing','Bush Clearing'),
                        ('Grass Cutting','Grass Cutting'),
                        ('Tree Planting','Tree Planting'),
                        ('Erosion Control','Erosion Control'),
                        ('Irrigation','Irrigation'),
                        ('Waste Collection','Waste Collection'),
                        ('Pest Control','Pest Control'),
                      ],
                      (v) => setDlg(() => taskType = v!),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _DlgDrop(
                      'Status', status,
                      const [('pending','Pending'),('in_progress','In Progress')],
                      (v) => setDlg(() => status = v!),
                    )),
                  ]),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDlg(() => dueDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: GEMSTheme.offWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.grey.shade200),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 18,
                            color: GEMSTheme.textLight),
                        const SizedBox(width: 10),
                        Text(
                          'Due: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: GEMSTheme.textDark),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(
                      color: GEMSTheme.textMid)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await SupabaseService.createTask({
                  'title':
                      titleCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'assigned_to': assignCtrl.text.trim(),
                  'faculty_id':  fId,
                  'priority':    priority,
                  'task_type':   taskType,
                  'status':      status,
                  'due_date':
                      '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
                });
                _loadData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GEMSTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Create Task',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  REPORTS TAB
  // ══════════════════════════════════════════════════════════

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Environmental Reports',
              style: GEMSTheme.displayMedium)
              .animate().fadeIn(),
          const SizedBox(height: 8),
          Text('Green Health Index trends and analytics',
              style: GEMSTheme.bodySmall)
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 28),
          if (_reports.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  'No monthly reports yet.\n'
                  'Add rows to the monthly_reports table in Supabase.',
                  textAlign: TextAlign.center,
                  style: GEMSTheme.bodySmall,
                ),
              ),
            )
          else ...[
            _FullReportChart(reports: _reports)
                .animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: _VegetationBreakdown(
                        faculties: _faculties)
                    .animate().fadeIn(delay: 300.ms),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _TaskCompletionReport(tasks: _tasks)
                    .animate().fadeIn(delay: 400.ms),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STUDENT SCORE HERO
// ══════════════════════════════════════════════════════════════

class _StudentScoreHero extends StatelessWidget {
  final double score;
  final AnimationController controller;
  const _StudentScoreHero(
      {required this.score, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(GEMSTheme.primaryGreen,
                  GEMSTheme.forestGreen, controller.value)!,
              Color.lerp(GEMSTheme.forestGreen,
                  GEMSTheme.emerald, controller.value)!,
            ],
          ),
          boxShadow: [GEMSTheme.strongShadow],
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('University Campus GHI',
                    style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  score >= 70
                      ? '🌿 Campus is well-maintained'
                      : score >= 50
                          ? '⚠️ Some areas need attention'
                          : '🔴 Campus needs significant work',
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Text(
                  'You can help by reporting issues you see on campus.',
                  style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.5),
                ),
              ],
            ),
          ),
          AnimatedScoreRing(score: score, size: 120),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ROLE BANNER
// ══════════════════════════════════════════════════════════════

class _RoleBanner extends StatelessWidget {
  final String role, facultyId;
  const _RoleBanner({required this.role, required this.facultyId});

  @override
  Widget build(BuildContext context) {
    String   msg;
    Color    color;
    IconData icon;

    switch (role) {
      case 'admin':
        msg   = 'Admin View — monitoring all faculties';
        color = GEMSTheme.primaryGreen;
        icon  = Icons.admin_panel_settings_rounded;
        break;
      case 'faculty_officer':
        msg   = 'Faculty Officer — ${facultyId.toUpperCase()} zone';
        color = GEMSTheme.emerald;
        icon  = Icons.account_balance_rounded;
        break;
      case 'groundskeeper':
        msg   = 'Groundskeeper — submit reports, view your tasks';
        color = GEMSTheme.warning;
        icon  = Icons.agriculture_rounded;
        break;
      default:
        msg   = 'Student View — read-only';
        color = GEMSTheme.textMid;
        icon  = Icons.school_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(msg,
            style: GoogleFonts.poppins(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  HERO BANNER (Admin/Officer)
// ══════════════════════════════════════════════════════════════

class _HeroBanner extends StatelessWidget {
  final double score;
  final AnimationController controller;
  final List<Faculty> faculties;
  const _HeroBanner(
      {required this.score,
      required this.controller,
      required this.faculties});

  @override
  Widget build(BuildContext context) {
    final sorted = [...faculties]
      ..sort((a, b) =>
          b.greenHealthScore.compareTo(a.greenHealthScore));
    final best     = sorted.isNotEmpty ? sorted.first : null;
    final worst    = sorted.length > 1 ? sorted.last : null;
    final critical = faculties.where((f) => f.hazardLevel == 'critical').length;
    final medium   = faculties.where((f) => f.hazardLevel == 'medium').length;
    final good     = faculties.where((f) => f.hazardLevel == 'low').length;

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(GEMSTheme.primaryGreen,
                  GEMSTheme.forestGreen, controller.value)!,
              Color.lerp(GEMSTheme.forestGreen,
                  GEMSTheme.emerald, controller.value)!,
              Color.lerp(GEMSTheme.emerald,
                  const Color(0xFF004D40), controller.value)!,
            ],
          ),
          boxShadow: [GEMSTheme.strongShadow],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(children: [
          Positioned(
              right: -30, top: -30,
              child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05)))),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 32, vertical: 20),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('🌿 Live Campus Status',
                          style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12)),
                    ),
                    const SizedBox(height: 8),
                    Text('Campus Green Health Index',
                        style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      best != null && worst != null
                          ? '${best.shortName} leads at '
                            '${best.greenHealthScore.toInt()}/100. '
                            '${worst.shortName} needs attention.'
                          : 'Loading...',
                      style: GoogleFonts.poppins(
                          color: Colors.white60, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      if (critical > 0) ...[
                        _HBadge(
                            label: '🔴 $critical Critical',
                            color: GEMSTheme.danger),
                        const SizedBox(width: 8),
                      ],
                      if (medium > 0) ...[
                        _HBadge(
                            label: '🟡 $medium Moderate',
                            color: GEMSTheme.warning),
                        const SizedBox(width: 8),
                      ],
                      if (good > 0)
                        _HBadge(
                            label: '🟢 $good Good',
                            color: GEMSTheme.success),
                    ]),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8),
                child: AnimatedScoreRing(
                    score: score, size: 120),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _HBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _HBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 12)),
      );
}

// ══════════════════════════════════════════════════════════════
//  Shared sub-widgets (trend chart, alerts, benchmark, etc.)
//  These are unchanged from previous version — omitting for
//  brevity but they must remain in the file.
// ══════════════════════════════════════════════════════════════

class _TrendChart extends StatelessWidget {
  final List<MonthlyReport> reports;
  const _TrendChart({required this.reports});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [GEMSTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('6-Month Trend', style: GEMSTheme.headingMedium),
          const SizedBox(height: 4),
          Text('GHI by Faculty', style: GEMSTheme.bodySmall),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.shade100, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles:
                        SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles:
                        SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles:
                        SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i >= 0 && i < reports.length) {
                        return Text(
                          reports[i].month.isNotEmpty
                              ? reports[i].month[0]
                              : '',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: GEMSTheme.textLight),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                _line(reports.map((r) => r.nasScore).toList(),
                    GEMSTheme.nasFacultyColor),
                _line(reports.map((r) => r.esScore).toList(),
                    GEMSTheme.esFacultyColor),
                _line(reports.map((r) => r.engScore).toList(),
                    GEMSTheme.engFacultyColor),
                _line(reports.map((r) => r.medScore).toList(),
                    GEMSTheme.medFacultyColor),
              ],
            )),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _LegendDot(color: GEMSTheme.nasFacultyColor, label: 'NAS'),
              _LegendDot(color: GEMSTheme.esFacultyColor,  label: 'ENV'),
              _LegendDot(color: GEMSTheme.engFacultyColor, label: 'ENG'),
              _LegendDot(color: GEMSTheme.medFacultyColor, label: 'MED'),
            ],
          ),
        ],
      ),
    );
  }

  LineChartBarData _line(List<double> vals, Color color) =>
      LineChartBarData(
        spots: vals.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList(),
        isCurved: true,
        color: color,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
            show: true, color: color.withOpacity(0.06)),
      );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
                color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, color: GEMSTheme.textLight)),
      ]);
}

class _RecentAlerts extends StatelessWidget {
  final List<MaintenanceTask> tasks;
  const _RecentAlerts({required this.tasks});
  @override
  Widget build(BuildContext context) {
    final alerts = tasks
        .where((t) =>
            t.status == 'overdue' || t.priority == 'critical')
        .take(3)
        .toList();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [GEMSTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Active Alerts', style: GEMSTheme.headingMedium),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            Text('No critical alerts 🎉', style: GEMSTheme.bodySmall)
          else
            ...alerts.map((t) {
              final color = t.status == 'overdue'
                  ? GEMSTheme.danger : GEMSTheme.warning;
              final emoji = t.status == 'overdue' ? '🔴' : '🟡';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(children: [
                  Text(emoji,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(t.title,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: GEMSTheme.textDark,
                            fontWeight: FontWeight.w500)),
                  ),
                ]),
              );
            }),
        ],
      ),
    );
  }
}

class _BenchmarkBanner extends StatelessWidget {
  final List<Faculty> faculties;
  const _BenchmarkBanner({required this.faculties});
  @override
  Widget build(BuildContext context) {
    final sorted = [...faculties]
      ..sort((a, b) =>
          b.greenHealthScore.compareTo(a.greenHealthScore));
    final best = sorted.isNotEmpty ? sorted.first : null;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [GEMSTheme.strongShadow],
      ),
      child: Row(children: [
        const Icon(Icons.emoji_events,
            color: Color(0xFFFFD700), size: 48),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                best != null
                    ? 'Benchmark: ${best.name} — '
                      '${best.greenHealthScore.toInt()}/100'
                    : 'Benchmark Faculty',
                style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'All faculties should target this score. '
                'Well-maintained lawns, active tree canopy, thriving flower beds.',
                style: GoogleFonts.poppins(
                    color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _FacultyListCard extends StatefulWidget {
  final Faculty faculty;
  const _FacultyListCard({required this.faculty});
  @override
  State<_FacultyListCard> createState() =>
      _FacultyListCardState();
}

class _FacultyListCardState extends State<_FacultyListCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final f = widget.faculty;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) =>
                    FacultyDetailScreen(faculty: f))),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..translate(0.0, _hovered ? -4.0 : 0.0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: f.color
                    .withOpacity(_hovered ? 0.14 : 0.06),
                blurRadius: _hovered ? 28 : 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: f.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(f.shortName,
                    style: GoogleFonts.poppins(
                        color: f.color,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.name, style: GEMSTheme.headingMedium),
                  const SizedBox(height: 4),
                  Text(f.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GEMSTheme.bodySmall),
                  const SizedBox(height: 10),
                  Row(children: [
                    _Chip(f.dean, GEMSTheme.textMid),
                    const SizedBox(width: 8),
                    _Chip('${f.totalArea} ha', GEMSTheme.emerald),
                    const SizedBox(width: 8),
                    _Chip(
                      f.hazardLevel.toUpperCase(),
                      f.hazardLevel == 'critical'
                          ? GEMSTheme.danger
                          : f.hazardLevel == 'medium'
                              ? GEMSTheme.warning
                              : GEMSTheme.success,
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Column(children: [
              Text('GHI', style: GEMSTheme.label),
              Text('${f.greenHealthScore.toInt()}',
                  style: GoogleFonts.poppins(
                      color: f.color,
                      fontSize: 36,
                      fontWeight: FontWeight.w800)),
              Text('/ 100', style: GEMSTheme.bodySmall),
            ]),
            const SizedBox(width: 16),
            Icon(Icons.chevron_right,
                color: _hovered
                    ? f.color
                    : GEMSTheme.textLight),
          ]),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color  color;
  const _Chip(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: GoogleFonts.poppins(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      );
}

class _TaskRow extends StatefulWidget {
  final Faculty         faculty;
  final MaintenanceTask task;
  final VoidCallback    onStatusChange;
  const _TaskRow(
      {required this.faculty,
      required this.task,
      required this.onStatusChange});
  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> {
  bool _hovered = false;
  Color get _sc {
    switch (widget.task.status) {
      case 'completed':   return GEMSTheme.success;
      case 'overdue':     return GEMSTheme.danger;
      case 'in_progress': return GEMSTheme.warning;
      default:            return GEMSTheme.textLight;
    }
  }
  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final f = widget.faculty;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _hovered
              ? Colors.white
              : const Color(0xFFF9FAF8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _hovered
                  ? f.color.withOpacity(0.3)
                  : Colors.transparent),
          boxShadow: _hovered
              ? [BoxShadow(
                  color: f.color.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(children: [
          Container(
            width: 6, height: 48,
            decoration: BoxDecoration(
                color: _sc,
                borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: GEMSTheme.textDark)),
                const SizedBox(height: 2),
                Text(t.description,
                    style: GEMSTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _TBadge(f.shortName, f.color),
          const SizedBox(width: 6),
          _TBadge(t.taskType, GEMSTheme.emerald),
          const SizedBox(width: 6),
          _TBadge(t.status.replaceAll('_', ' ').toUpperCase(), _sc),
          const SizedBox(width: 10),
          if (t.status != 'completed')
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: GEMSTheme.textLight, size: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (s) async {
                await SupabaseService.updateTaskStatus(t.id, s);
                widget.onStatusChange();
              },
              itemBuilder: (_) => [
                if (t.status != 'in_progress')
                  _mi('in_progress', 'Mark In Progress',
                      Icons.autorenew, GEMSTheme.warning),
                _mi('completed', 'Mark Completed',
                    Icons.check_circle, GEMSTheme.success),
                _mi('overdue', 'Mark Overdue',
                    Icons.error, GEMSTheme.danger),
              ],
            ),
          Text('${t.dueDate.day}/${t.dueDate.month}',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: GEMSTheme.textLight)),
        ]),
      ),
    );
  }
  PopupMenuItem<String> _mi(
          String v, String l, IconData i, Color c) =>
      PopupMenuItem(
        value: v,
        child: Row(children: [
          Icon(i, color: c, size: 16),
          const SizedBox(width: 8),
          Text(l, style: GoogleFonts.poppins(fontSize: 13)),
        ]),
      );
}

class _TBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _TBadge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color)),
      );
}

class _FullReportChart extends StatelessWidget {
  final List<MonthlyReport> reports;
  const _FullReportChart({required this.reports});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [GEMSTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GHI Monthly Progress',
              style: GEMSTheme.headingLarge),
          const SizedBox(height: 4),
          Text('All faculties tracked monthly',
              style: GEMSTheme.bodySmall),
          const SizedBox(height: 24),
          SizedBox(
            height: 280,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.shade100, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true, reservedSize: 36,
                    getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: GEMSTheme.textLight)),
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true, reservedSize: 28,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i >= 0 && i < reports.length) {
                        return Text(reports[i].month,
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: GEMSTheme.textLight));
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: reports.asMap().entries.map((e) {
                final r = e.value;
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(toY: r.nasScore, color: GEMSTheme.nasFacultyColor, width: 10, borderRadius: BorderRadius.circular(4)),
                  BarChartRodData(toY: r.esScore,  color: GEMSTheme.esFacultyColor,  width: 10, borderRadius: BorderRadius.circular(4)),
                  BarChartRodData(toY: r.engScore, color: GEMSTheme.engFacultyColor, width: 10, borderRadius: BorderRadius.circular(4)),
                  BarChartRodData(toY: r.medScore, color: GEMSTheme.medFacultyColor, width: 10, borderRadius: BorderRadius.circular(4)),
                ]);
              }).toList(),
            )),
          ),
        ],
      ),
    );
  }
}

class _VegetationBreakdown extends StatelessWidget {
  final List<Faculty> faculties;
  const _VegetationBreakdown({required this.faculties});
  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    int zoneCount = 0;
    for (final f in faculties) {
      for (final z in f.zones) {
        totals[z.type] = (totals[z.type] ?? 0) + z.percentage;
        zoneCount++;
      }
    }
    if (zoneCount == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [GEMSTheme.softShadow]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Campus Vegetation Breakdown',
                style: GEMSTheme.headingMedium),
            const SizedBox(height: 16),
            Text(
                'No zone data — add vegetation_zones records in Supabase.',
                style: GEMSTheme.bodySmall),
          ],
        ),
      );
    }
    final total =
        totals.values.fold(0.0, (a, b) => a + b);
    final items = totals.entries
        .map((e) => (e.key, e.value / total))
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    final colors = <String, Color>{
      'bush':    const Color(0xFF4E342E),
      'grass':   GEMSTheme.accentGreen,
      'trees':   GEMSTheme.forestGreen,
      'bare':    const Color(0xFFBCAAA4),
      'flowers': const Color(0xFFE91E63),
    };
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [GEMSTheme.softShadow]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Campus Vegetation Breakdown',
              style: GEMSTheme.headingMedium),
          const SizedBox(height: 20),
          ...items.map((item) {
            final c =
                colors[item.$1] ?? GEMSTheme.primaryGreen;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        item.$1[0].toUpperCase() +
                            item.$1.substring(1),
                        style: GEMSTheme.bodySmall),
                    Text('${(item.$2 * 100).toInt()}%',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.$2,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(c),
                    minHeight: 8,
                  ),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }
}

class _TaskCompletionReport extends StatelessWidget {
  final List<MaintenanceTask> tasks;
  const _TaskCompletionReport({required this.tasks});
  @override
  Widget build(BuildContext context) {
    final completed  = tasks.where((t) => t.status == 'completed').length.toDouble();
    final inProgress = tasks.where((t) => t.status == 'in_progress').length.toDouble();
    final pending    = tasks.where((t) => t.status == 'pending').length.toDouble();
    final overdue    = tasks.where((t) => t.status == 'overdue').length.toDouble();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [GEMSTheme.softShadow]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Task Status Overview',
              style: GEMSTheme.headingMedium),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(PieChartData(
              sections: [
                if (completed  > 0) PieChartSectionData(value: completed,  color: GEMSTheme.success,  title: 'Done',    titleStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                if (inProgress > 0) PieChartSectionData(value: inProgress, color: GEMSTheme.warning,  title: 'Active',  titleStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                if (pending    > 0) PieChartSectionData(value: pending,    color: GEMSTheme.textLight, title: 'Pending', titleStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                if (overdue    > 0) PieChartSectionData(value: overdue,    color: GEMSTheme.danger,    title: 'Overdue', titleStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
              ],
              sectionsSpace: 3,
              centerSpaceRadius: 40,
            )),
          ),
        ],
      ),
    );
  }
}

// ── Dialog helpers ────────────────────────────────────────────

class _DlgField extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final int maxLines;
  const _DlgField(this.label, this.ctrl, this.hint,
      {this.maxLines = 1});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: GEMSTheme.textDark)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: GoogleFonts.poppins(
                fontSize: 13, color: GEMSTheme.textDark),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400, fontSize: 12),
              filled: true,
              fillColor: GEMSTheme.offWhite,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.grey.shade200)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
        ],
      );
}

class _DlgDrop extends StatelessWidget {
  final String label, value;
  final List<(String, String)> items;
  final ValueChanged<String?> onChange;
  const _DlgDrop(
      this.label, this.value, this.items, this.onChange);
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: GEMSTheme.textDark)),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: GEMSTheme.offWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.any((i) => i.$1 == value)
                    ? value
                    : items.first.$1,
                isExpanded: true,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: GEMSTheme.textDark),
                items: items
                    .map((i) => DropdownMenuItem(
                        value: i.$1, child: Text(i.$2)))
                    .toList(),
                onChanged: onChange,
              ),
            ),
          ),
        ],
      );
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final String   tooltip;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon,
      required this.tooltip,
      required this.onTap});
  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => Tooltip(
        message: widget.tooltip,
        child: MouseRegion(
          onEnter: (_) => setState(() => _h = true),
          onExit:  (_) => setState(() => _h = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _h
                    ? GEMSTheme.primaryGreen.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [GEMSTheme.softShadow],
              ),
              child: Icon(widget.icon,
                  color: _h
                      ? GEMSTheme.primaryGreen
                      : GEMSTheme.textMid,
                  size: 20),
            ),
          ),
        ),
      );
}