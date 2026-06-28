// ============================================================
//  GEMS — Sidebar (role-aware + live notification badge)
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/gems_theme.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _NavDef {
  final IconData icon;
  final String   label;
  final int      index;
  const _NavDef(this.icon, this.label, this.index);
}

class GEMSSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String userName;
  final String userInitial;
  final VoidCallback onSignOut;

  const GEMSSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.userName,
    required this.userInitial,
    required this.onSignOut,
  });

  @override
  State<GEMSSidebar> createState() => _GEMSSidebarState();
}

class _GEMSSidebarState extends State<GEMSSidebar> {
  bool _collapsed = false;
  int  _unreadCount = 0;
  RealtimeChannel? _channel;

  // ── Nav definitions ───────────────────────────────────────
  static const _adminNav = [
    _NavDef(Icons.dashboard_rounded,       'Dashboard',     0),
    _NavDef(Icons.account_balance_rounded, 'Faculties',     1),
    _NavDef(Icons.task_alt_rounded,        'Tasks',         2),
    _NavDef(Icons.bar_chart_rounded,       'Reports',       3),
    _NavDef(Icons.menu_book_rounded,       'Green Guide',   4),
    _NavDef(Icons.report_problem_rounded,  'Issues',        5),
    _NavDef(Icons.grass_rounded,           'Veg. Reports',  6),
    _NavDef(Icons.park_rounded,            'Tree Registry', 7),
    _NavDef(Icons.notifications_rounded,   'Notifications', 8),
    _NavDef(Icons.settings_rounded,        'Settings',      9),
  ];

  static const _officerNav = [
    _NavDef(Icons.dashboard_rounded,       'Dashboard',     0),
    _NavDef(Icons.account_balance_rounded, 'My Faculty',    1),
    _NavDef(Icons.task_alt_rounded,        'Tasks',         2),
    _NavDef(Icons.bar_chart_rounded,       'Reports',       3),
    _NavDef(Icons.menu_book_rounded,       'Green Guide',   4),
    _NavDef(Icons.report_problem_rounded,  'Issues',        5),
    _NavDef(Icons.grass_rounded,           'Veg. Reports',  6),
    _NavDef(Icons.park_rounded,            'Tree Registry', 7),
    _NavDef(Icons.notifications_rounded,   'Notifications', 8),
    _NavDef(Icons.settings_rounded,        'Settings',      9),
  ];

  static const _groundskeeperNav = [
    _NavDef(Icons.dashboard_rounded,     'Dashboard',     0),
    _NavDef(Icons.task_alt_rounded,      'My Tasks',      2),
    _NavDef(Icons.grass_rounded,         'Submit Report', 6),
    _NavDef(Icons.notifications_rounded, 'Notifications', 8),
    _NavDef(Icons.menu_book_rounded,     'Green Guide',   4),
    _NavDef(Icons.settings_rounded,      'Settings',      9),
  ];

  static const _studentNav = [
    _NavDef(Icons.dashboard_rounded,     'Campus Overview', 0),
    _NavDef(Icons.report_problem_rounded,'Report Issue',    5),
    _NavDef(Icons.menu_book_rounded,     'Green Guide',     4),
    _NavDef(Icons.notifications_rounded, 'Notifications',   8),
    _NavDef(Icons.settings_rounded,      'Settings',        9),
  ];

  List<_NavDef> get _navItems {
    switch (SupabaseService.currentRole) {
      case 'admin':           return _adminNav;
      case 'faculty_officer': return _officerNav;
      case 'groundskeeper':   return _groundskeeperNav;
      default:                return _studentNav;
    }
  }

  String get _roleLabel {
    switch (SupabaseService.currentRole) {
      case 'admin':           return 'University Admin';
      case 'faculty_officer': return 'Faculty Officer';
      case 'groundskeeper':   return 'Groundskeeper';
      default:                return 'Student / Public';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _subscribeToNotifications();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await SupabaseService.getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  void _subscribeToNotifications() {
    _channel = SupabaseService.subscribeToNotifications(
      onNew: (_) {
        if (mounted) setState(() => _unreadCount++);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = _collapsed ? 72.0 : 230.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      width: w,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A2010), Color(0xFF1B5E20)],
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20),
        ],
      ),
      child: Column(
        children: [
          // ── Logo ─────────────────────────────────────────
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.eco,
                    color: Colors.white, size: 22),
              ),
              if (!_collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text('GEMS',
                          style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      Text('Green Env. System',
                          style: GoogleFonts.poppins(
                              color: Colors.white38,
                              fontSize: 9,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ]),
          ),

          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          const SizedBox(height: 12),

          // ── Nav items ────────────────────────────────────
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10),
              children: _navItems.map((item) {
                final isSelected =
                    widget.selectedIndex == item.index;
                final isNotif = item.index == 8;
                return _NavItem(
                  icon:        item.icon,
                  label:       item.label,
                  selected:    isSelected,
                  collapsed:   _collapsed,
                  badgeCount:  isNotif ? _unreadCount : 0,
                  onTap: () {
                    widget.onSelect(item.index);
                    // Clear badge when user opens notifications
                    if (isNotif && _unreadCount > 0) {
                      setState(() => _unreadCount = 0);
                      SupabaseService
                          .markAllNotificationsRead();
                    }
                  },
                );
              }).toList(),
            ),
          ),

          Divider(color: Colors.white.withOpacity(0.1), height: 1),

          // ── User card / sign out ──────────────────────────
          if (!_collapsed)
            GestureDetector(
              onTap: widget.onSignOut,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        GEMSTheme.accentGreen.withOpacity(0.8),
                    child: Text(widget.userInitial,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(widget.userName,
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(_roleLabel,
                            style: GoogleFonts.poppins(
                                color: Colors.white38,
                                fontSize: 10)),
                      ],
                    ),
                  ),
                  const Icon(Icons.logout_rounded,
                      color: Colors.white38, size: 18),
                ]),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout_rounded,
                  color: Colors.white38, size: 18),
              tooltip: 'Sign Out',
              onPressed: widget.onSignOut,
            ),

          // ── Collapse toggle ───────────────────────────────
          GestureDetector(
            onTap: () =>
                setState(() => _collapsed = !_collapsed),
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _collapsed
                    ? Icons.chevron_right
                    : Icons.chevron_left,
                color: Colors.white54, size: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── NAV ITEM ─────────────────────────────────────────────────

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String   label;
  final bool     selected;
  final bool     collapsed;
  final int      badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.collapsed,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 4),
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 12 : 14,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? Colors.white.withOpacity(0.15)
                : _hovered
                    ? Colors.white.withOpacity(0.07)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: widget.selected
                ? Border.all(
                    color: Colors.white.withOpacity(0.2))
                : null,
          ),
          child: Row(children: [
            // Icon with badge
            Stack(children: [
              Icon(widget.icon,
                  color: active
                      ? Colors.white
                      : Colors.white38,
                  size: 20),
              if (widget.badgeCount > 0)
                Positioned(
                  right: -2, top: -2,
                  child: Container(
                    width: 14, height: 14,
                    decoration: const BoxDecoration(
                      color: GEMSTheme.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.badgeCount > 9
                            ? '9+'
                            : '${widget.badgeCount}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
            ]),

            if (!widget.collapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.label,
                    style: GoogleFonts.poppins(
                        color: active
                            ? Colors.white
                            : Colors.white54,
                        fontSize: 13,
                        fontWeight: widget.selected
                            ? FontWeight.w600
                            : FontWeight.w400)),
              ),
              // Badge count label when not collapsed
              if (widget.badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: GEMSTheme.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.badgeCount > 99
                        ? '99+'
                        : '${widget.badgeCount}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ]),
        ),
      ),
    );
  }
}