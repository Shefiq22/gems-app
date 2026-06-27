// ============================================================
//  GEMS — Working Module Screens
//  Issues, Tree Registry, Alerts, Settings/Profile
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/gems_theme.dart';
import '../services/supabase_service.dart';

// ═══════════════════════════════════════════════════════════════
//  ISSUES SCREEN
// ═══════════════════════════════════════════════════════════════

class IssuesScreen extends StatefulWidget {
  const IssuesScreen({super.key});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _issues = [];
  bool _showForm = false;

  // Form fields
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  String _category  = 'general';
  String _facultyId = 'nas';
  bool   _submitting = false;

  static const _categories = [
    ('fire',     '🔥 Fire / Smoke'),
    ('litter',   '🗑️  Illegal Dumping / Litter'),
    ('erosion',  '🌊 Erosion / Flooding'),
    ('bush',     '🌿 Overgrown Bush'),
    ('flooding', '💧 Drainage / Flooding'),
    ('other',    '📋 Other'),
  ];

  static const _faculties = [
    ('nas', 'Natural & Applied Sciences'),
    ('es',  'Environmental Science'),
    ('eng', 'Engineering'),
    ('med', 'Medical Science'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final role = SupabaseService.currentRole;
      final data = await SupabaseService.getIssueReports(
          facultyId: role == 'faculty_officer'
              ? SupabaseService.currentFacultyId
              : null);
      if (mounted) setState(() => _issues = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitIssue() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await SupabaseService.submitIssueReport(
        facultyId:   _facultyId,
        title:       _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category:    _category,
        reportedBy:  SupabaseService.currentFullName,
      );
      _titleCtrl.clear();
      _descCtrl.clear();
      if (mounted) setState(() => _showForm = false);
      _load();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Issues & Reports', style: GEMSTheme.displayMedium),
                  Text('Track and manage campus environmental issues',
                      style: GEMSTheme.bodySmall),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    setState(() => _showForm = !_showForm),
                icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
                label: Text(_showForm ? 'Cancel' : 'Report Issue'),
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

          const SizedBox(height: 24),

          // Report form
          if (_showForm)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: GEMSTheme.primaryGreen.withOpacity(0.2)),
                boxShadow: [GEMSTheme.softShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Report an Environmental Issue',
                      style: GEMSTheme.headingMedium),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: _dropdownField(
                              'Faculty', _facultyId, _faculties,
                              (v) => setState(() => _facultyId = v!))),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _dropdownField(
                              'Issue Category', _category, _categories,
                              (v) => setState(() => _category = v!))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _inputField('Issue Title', _titleCtrl,
                      'Brief title of the issue'),
                  const SizedBox(height: 16),
                  _inputField('Description', _descCtrl,
                      'Describe what you observed...', maxLines: 3),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _submitIssue,
                      icon: _submitting
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(_submitting
                          ? 'Submitting...' : 'Submit Issue Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GEMSTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),

          // Issues list
          if (_loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                        color: GEMSTheme.primaryGreen)))
          else if (_issues.isEmpty)
            _emptyState('No issues reported yet.', Icons.check_circle_outline)
          else
            ..._issues.asMap().entries.map((e) =>
                _IssueCard(issue: e.value, onStatusChange: _load)
                    .animate()
                    .fadeIn(delay: (e.key * 80).ms)),
        ],
      ),
    );
  }

  Widget _dropdownField(String label, String value,
      List<(String, String)> items, ValueChanged<String?> onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: GEMSTheme.textDark)),
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

  Widget _inputField(String label, TextEditingController ctrl,
      String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: GEMSTheme.textDark)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: GEMSTheme.offWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: GoogleFonts.poppins(
                fontSize: 13, color: GEMSTheme.textDark),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400, fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _IssueCard extends StatelessWidget {
  final Map<String, dynamic> issue;
  final VoidCallback onStatusChange;
  const _IssueCard({required this.issue, required this.onStatusChange});

  static const _categoryEmoji = {
    'fire': '🔥', 'litter': '🗑️', 'erosion': '🌊',
    'bush': '🌿', 'flooding': '💧', 'other': '📋',
  };

  Color get _statusColor {
    switch (issue['status']) {
      case 'investigating': return GEMSTheme.warning;
      case 'resolved': return GEMSTheme.success;
      default: return GEMSTheme.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _categoryEmoji[issue['category']] ?? '📋';
    final faculty =
        (issue['faculties'] as Map<String, dynamic>?)?['name'] ??
            issue['faculty_id'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withOpacity(0.2)),
        boxShadow: [GEMSTheme.softShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue['title'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: GEMSTheme.textDark)),
                const SizedBox(height: 4),
                Text(issue['description'] ?? '',
                    style: GEMSTheme.bodySmall,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Chip(label: faculty, color: GEMSTheme.primaryGreen),
                    const SizedBox(width: 6),
                    _Chip(
                        label: 'By: ${issue['reported_by'] ?? 'Unknown'}',
                        color: GEMSTheme.textMid),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                    (issue['status'] as String? ?? '').toUpperCase(),
                    style: GoogleFonts.poppins(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: _statusColor)),
              ),
              const SizedBox(height: 8),
              if (issue['status'] == 'open')
                _SmallBtn(
                    label: 'Investigate',
                    color: GEMSTheme.warning,
                    onTap: () async {
                      await SupabaseService.updateIssueStatus(
                          issue['id'], 'investigating');
                      onStatusChange();
                    }),
              if (issue['status'] == 'investigating')
                _SmallBtn(
                    label: 'Resolved',
                    color: GEMSTheme.success,
                    onTap: () async {
                      await SupabaseService.updateIssueStatus(
                          issue['id'], 'resolved');
                      onStatusChange();
                    }),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TREE REGISTRY SCREEN
// ═══════════════════════════════════════════════════════════════

class TreeRegistryScreen extends StatefulWidget {
  const TreeRegistryScreen({super.key});

  @override
  State<TreeRegistryScreen> createState() => _TreeRegistryScreenState();
}

class _TreeRegistryScreenState extends State<TreeRegistryScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _trees = [];
  bool _showForm = false;

  final _speciesCtrl  = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl    = TextEditingController();
  final _qtyCtrl      = TextEditingController(text: '1');
  String _facultyId = 'nas';
  String _status    = 'planned';
  bool   _submitting = false;

  static const _faculties = [
    ('nas', 'Natural & Applied Sciences'),
    ('es',  'Environmental Science'),
    ('eng', 'Engineering'),
    ('med', 'Medical Science'),
  ];

  static const _statuses = [
    ('planned', '📋 Planned'),
    ('growing', '🌱 Growing'),
    ('mature',  '🌳 Mature'),
    ('removed', '❌ Removed'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getTreeRegistry();
      if (mounted) setState(() => _trees = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addTree() async {
    if (_speciesCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await SupabaseService.addTree({
        'species':       _speciesCtrl.text.trim(),
        'faculty_id':    _facultyId,
        'quantity':      int.tryParse(_qtyCtrl.text) ?? 1,
        'date_planted':  DateTime.now().toIso8601String().split('T')[0],
        'status':        _status,
        'location_desc': _locationCtrl.text.trim(),
        'notes':         _notesCtrl.text.trim(),
        'planted_by':    SupabaseService.currentFullName,
      });
      _speciesCtrl.clear();
      _locationCtrl.clear();
      _notesCtrl.clear();
      _qtyCtrl.text = '1';
      if (mounted) setState(() => _showForm = false);
      _load();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _speciesCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  // Stats
  int get _totalTrees => _trees.fold<int>(
      0, (sum, t) => sum + ((t['quantity'] as num?)?.toInt() ?? 0));
  int get _matureTrees => _trees
      .where((t) => t['status'] == 'mature')
      .fold<int>(0, (sum, t) => sum + ((t['quantity'] as num?)?.toInt() ?? 0));

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tree Registry', style: GEMSTheme.displayMedium),
                  Text('Campus tree inventory and planting records',
                      style: GEMSTheme.bodySmall),
                ],
              ),
              if (SupabaseService.currentRole != 'student')
                ElevatedButton.icon(
                  onPressed: () =>
                      setState(() => _showForm = !_showForm),
                  icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
                  label: Text(_showForm ? 'Cancel' : 'Add Tree'),
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

          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              _StatBox(
                  label: 'Total Trees',
                  value: '$_totalTrees',
                  icon: Icons.park_rounded,
                  color: GEMSTheme.primaryGreen),
              const SizedBox(width: 16),
              _StatBox(
                  label: 'Mature Trees',
                  value: '$_matureTrees',
                  icon: Icons.nature,
                  color: GEMSTheme.emerald),
              const SizedBox(width: 16),
              _StatBox(
                  label: 'Species',
                  value: '${_trees.map((t) => t['species']).toSet().length}',
                  icon: Icons.eco,
                  color: GEMSTheme.accentGreen),
              const SizedBox(width: 16),
              _StatBox(
                  label: 'Faculties',
                  value: '4',
                  icon: Icons.account_balance,
                  color: GEMSTheme.forestGreen),
            ],
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 24),

          // Add form
          if (_showForm)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: GEMSTheme.primaryGreen.withOpacity(0.2)),
                boxShadow: [GEMSTheme.softShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Tree Record',
                      style: GEMSTheme.headingMedium),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: _Field('Species', _speciesCtrl,
                              'e.g. Mahogany, Neem, Mango')),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _Field(
                              'Quantity', _qtyCtrl, '1',
                              keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                          child: _DropField(
                              'Faculty', _facultyId, _faculties,
                              (v) => setState(
                                  () => _facultyId = v!))),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _DropField('Status', _status,
                              _statuses,
                              (v) =>
                                  setState(() => _status = v!))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Field('Location Description', _locationCtrl,
                      'e.g. North boundary, Lab Block A entrance'),
                  const SizedBox(height: 14),
                  _Field('Notes', _notesCtrl,
                      'Any additional notes...', maxLines: 2),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _addTree,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                          _submitting ? 'Saving...' : 'Save Tree Record'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GEMSTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),

          // Trees list
          if (_loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                        color: GEMSTheme.primaryGreen)))
          else if (_trees.isEmpty)
            _emptyState(
                'No trees registered yet.', Icons.park_outlined)
          else
            ..._trees.asMap().entries.map((e) =>
                _TreeCard(tree: e.value, onStatusChange: _load)
                    .animate()
                    .fadeIn(delay: (e.key * 80).ms)),
        ],
      ),
    );
  }
}

class _TreeCard extends StatelessWidget {
  final Map<String, dynamic> tree;
  final VoidCallback onStatusChange;
  const _TreeCard({required this.tree, required this.onStatusChange});

  static const _statusEmoji = {
    'planned': '📋', 'growing': '🌱', 'mature': '🌳', 'removed': '❌',
  };
  static const _statusColor = {
    'planned': GEMSTheme.textLight, 'growing': GEMSTheme.accentGreen,
    'mature': GEMSTheme.primaryGreen, 'removed': GEMSTheme.danger,
  };

  @override
  Widget build(BuildContext context) {
    final status   = tree['status'] as String? ?? 'growing';
    final emoji    = _statusEmoji[status] ?? '🌱';
    final color    = _statusColor[status] ?? GEMSTheme.primaryGreen;
    final faculty  = (tree['faculties'] as Map<String, dynamic>?)?['name'] ?? tree['faculty_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [GEMSTheme.softShadow],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tree['species'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: GEMSTheme.textDark)),
                const SizedBox(height: 4),
                Text(
                  '${tree['quantity']} tree(s) · $faculty · '
                  'Planted: ${tree['date_planted'] ?? 'Unknown'}',
                  style: GEMSTheme.bodySmall,
                ),
                if ((tree['location_desc'] as String? ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('📍 ${tree['location_desc']}',
                      style: GEMSTheme.bodySmall),
                ],
                if ((tree['planted_by'] as String? ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('👤 ${tree['planted_by']}', style: GEMSTheme.bodySmall),
                ],
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status.toUpperCase(),
                    style: GoogleFonts.poppins(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: color)),
              ),
              if (status == 'growing') ...[
                const SizedBox(height: 8),
                _SmallBtn(
                    label: 'Mark Mature',
                    color: GEMSTheme.primaryGreen,
                    onTap: () async {
                      await SupabaseService.updateTreeStatus(
                          tree['id'], 'mature');
                      onStatusChange();
                    }),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ALERTS SCREEN
// ═══════════════════════════════════════════════════════════════

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getAlerts();
      if (mounted) setState(() => _alerts = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: GEMSTheme.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.notifications_active_rounded,
                    color: GEMSTheme.danger, size: 26),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alerts & Notifications', style: GEMSTheme.displayMedium),
                  Text('Overdue tasks, critical issues, and warnings',
                      style: GEMSTheme.bodySmall),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: GEMSTheme.textMid),
                tooltip: 'Refresh',
                onPressed: _load,
              ),
            ],
          ).animate().fadeIn(),

          const SizedBox(height: 28),

          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(60),
              child: CircularProgressIndicator(color: GEMSTheme.primaryGreen),
            ))
          else if (_alerts.isEmpty)
            _emptyState('All clear — no active alerts! 🎉',
                Icons.check_circle_outline)
          else ...[
            // Summary
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(0xFFFFF3E0),
                  Color(0xFFFBE9E7),
                ]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: GEMSTheme.danger.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: GEMSTheme.danger, size: 32),
                  const SizedBox(width: 16),
                  Text(
                    '${_alerts.length} active alert(s) require attention',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: GEMSTheme.textDark),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),

            ..._alerts.asMap().entries.map((e) {
              final a = e.value;
              final isTask = a['_alert_type'] == 'task';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: GEMSTheme.danger.withOpacity(0.2)),
                  boxShadow: [GEMSTheme.softShadow],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: (isTask
                                ? GEMSTheme.danger
                                : GEMSTheme.warning)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isTask
                            ? Icons.task_alt_rounded
                            : Icons.report_problem_rounded,
                        color: isTask
                            ? GEMSTheme.danger
                            : GEMSTheme.warning,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['title'] ?? '',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: GEMSTheme.textDark)),
                          const SizedBox(height: 3),
                          Text(
                            isTask
                                ? 'Task · ${a['faculty_id']?.toString().toUpperCase() ?? ''} · ${a['status'] ?? ''}'
                                : 'Issue · ${a['faculty_id']?.toString().toUpperCase() ?? ''} · ${a['category'] ?? ''}',
                            style: GEMSTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: GEMSTheme.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isTask ? (a['priority'] ?? '').toUpperCase()
                               : 'OPEN',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: GEMSTheme.danger),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (e.key * 80).ms);
            }),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SETTINGS / PROFILE SCREEN
// ═══════════════════════════════════════════════════════════════

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  Map<String, dynamic>? _profile;
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await SupabaseService.getMyProfile();
      if (mounted) {
        setState(() {
          _profile = p;
          _nameCtrl.text = p?['full_name'] as String? ?? '';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await SupabaseService.updateProfile(
          fullName: _nameCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: GEMSTheme.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await SupabaseService.signOut();
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (r) => false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(
              color: GEMSTheme.primaryGreen));
    }

    final role      = _profile?['role'] as String? ?? 'user';
    final email     = _profile?['email'] as String? ?? '';
    final facultyId = _profile?['faculty_id'] as String? ?? '';
    final initial   = (_nameCtrl.text.isNotEmpty)
        ? _nameCtrl.text[0].toUpperCase() : 'U';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings & Profile', style: GEMSTheme.displayMedium)
              .animate().fadeIn(),
          Text('Manage your account and preferences',
              style: GEMSTheme.bodySmall).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 32),

          // Profile card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [GEMSTheme.softShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: GEMSTheme.primaryGreen,
                      child: Text(initial,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_nameCtrl.text,
                            style: GEMSTheme.headingMedium),
                        const SizedBox(height: 4),
                        _RoleBadge(role: role),
                        if (facultyId.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Faculty: ${facultyId.toUpperCase()}',
                            style: GEMSTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Divider(color: Colors.grey.shade100),
                const SizedBox(height: 20),

                Text('Edit Profile', style: GEMSTheme.headingMedium),
                const SizedBox(height: 16),

                // Name field
                Text('Full Name',
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: GEMSTheme.textDark)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: GEMSTheme.offWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _nameCtrl,
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: GEMSTheme.textDark),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                          Icons.person_outline, size: 20,
                          color: GEMSTheme.textLight),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email (read-only)
                Text('Email Address',
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: GEMSTheme.textDark)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mail_outline,
                          size: 20, color: GEMSTheme.textLight),
                      const SizedBox(width: 10),
                      Text(email,
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: GEMSTheme.textLight)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                            _saving ? 'Saving...' : 'Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GEMSTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 20),

          // Sign out card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [GEMSTheme.softShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account', style: GEMSTheme.headingMedium),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: Text('Sign Out',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700)),
                        content: Text(
                          'Are you sure you want to sign out of GEMS?',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(),
                            child: Text('Cancel',
                                style: GoogleFonts.poppins(
                                    color: GEMSTheme.textMid)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _signOut();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GEMSTheme.danger,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                            ),
                            child: Text('Sign Out',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded,
                        color: GEMSTheme.danger),
                    label: Text('Sign Out',
                        style: GoogleFonts.poppins(
                            color: GEMSTheme.danger,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: GEMSTheme.danger),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  static const _labels = {
    'admin':           ('University Admin', GEMSTheme.primaryGreen),
    'faculty_officer': ('Faculty Officer', GEMSTheme.emerald),
    'groundskeeper':   ('Groundskeeper', GEMSTheme.warning),
    'student':         ('Student / Public', GEMSTheme.textMid),
  };

  @override
  Widget build(BuildContext context) {
    final info = _labels[role] ?? ('User', GEMSTheme.textLight);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: info.$2.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(info.$1,
          style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: info.$2)),
    );
  }
}

// ── SHARED SMALL HELPERS ──────────────────────────────────────

Widget _emptyState(String msg, IconData icon) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 64,
                color: GEMSTheme.textLight.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(msg, style: GEMSTheme.bodySmall),
          ],
        ),
      ),
    );

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color)),
      );
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SmallBtn(
      {required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ),
      );
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatBox(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [GEMSTheme.softShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 10),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: GEMSTheme.textDark)),
              Text(label, style: GEMSTheme.bodySmall),
            ],
          ),
        ),
      );
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  const _Field(this.label, this.ctrl, this.hint,
      {this.maxLines = 1, this.keyboardType});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: GEMSTheme.textDark)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: GEMSTheme.offWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: ctrl,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: GEMSTheme.textDark),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400, fontSize: 12),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ],
      );
}

class _DropField extends StatelessWidget {
  final String label, value;
  final List<(String, String)> items;
  final ValueChanged<String?> onChange;
  const _DropField(this.label, this.value, this.items, this.onChange);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: GEMSTheme.textDark)),
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