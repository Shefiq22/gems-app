// ============================================================
//  GEMS — Notifications Screen
//  Real-time inbox. Each role sees only their own notifications.
//  Groundskeeper sees task updates + their report feedback.
//  Faculty Officer sees veg reports + task changes + issues.
//  Admin sees everything.
//  Student sees issue status updates.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/gems_theme.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool   _loading = true;
  String _filter  = 'all'; // 'all' | 'unread'
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data =
          await SupabaseService.getNotifications(limit: 100);
      if (mounted) setState(() => _notifications = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribeRealtime() {
    _channel = SupabaseService.subscribeToNotifications(
      onNew: (row) {
        if (!mounted) return;
        setState(() {
          // Prepend new notification at top
          _notifications = [row, ..._notifications];
        });
        // Show a snackbar toast
        _showToast(
          row['title'] as String? ?? 'New notification',
          row['body']  as String? ?? '',
          row['type']  as String? ?? '',
        );
      },
    );
  }

  void _showToast(String title, String body, String type) {
    final icon = _typeIcon(type);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(body,
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
        backgroundColor: GEMSTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _markRead(String id) async {
    await SupabaseService.markNotificationRead(id);
    if (mounted) {
      setState(() {
        final idx =
            _notifications.indexWhere((n) => n['id'] == id);
        if (idx != -1) {
          _notifications[idx] = {
            ..._notifications[idx],
            'is_read': true,
          };
        }
      });
    }
  }

  Future<void> _markAllRead() async {
    await SupabaseService.markAllNotificationsRead();
    if (mounted) {
      setState(() {
        _notifications = _notifications.map((n) {
          return {...n, 'is_read': true};
        }).toList();
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'unread') {
      return _notifications
          .where((n) => n['is_read'] != true)
          .toList();
    }
    return _notifications;
  }

  int get _unreadCount =>
      _notifications.where((n) => n['is_read'] != true).length;

  IconData _typeIcon(String type) {
    switch (type) {
      case 'task_created': return Icons.task_alt_rounded;
      case 'task_updated': return Icons.autorenew_rounded;
      case 'veg_report':   return Icons.grass_rounded;
      case 'issue':        return Icons.report_problem_rounded;
      case 'tree':         return Icons.park_rounded;
      default:             return Icons.notifications_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'task_created': return GEMSTheme.primaryGreen;
      case 'task_updated': return GEMSTheme.warning;
      case 'veg_report':   return GEMSTheme.emerald;
      case 'issue':        return GEMSTheme.danger;
      case 'tree':         return GEMSTheme.forestGreen;
      default:             return GEMSTheme.textMid;
    }
  }

  String _timeAgo(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt  = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inSeconds < 60)  return 'Just now';
      if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)    return '${diff.inHours}h ago';
      if (diff.inDays < 7)      return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        GEMSTheme.primaryGreen,
                        GEMSTheme.emerald,
                      ]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                              Icons.notifications_rounded,
                              color: Colors.white, size: 26),
                        ),
                        if (_unreadCount > 0)
                          Positioned(
                            right: 6, top: 6,
                            child: Container(
                              width: 18, height: 18,
                              decoration: const BoxDecoration(
                                color: GEMSTheme.danger,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _unreadCount > 9
                                      ? '9+'
                                      : '$_unreadCount',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight:
                                          FontWeight.w800),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notifications',
                          style: GEMSTheme.displayMedium),
                      Text(
                        _unreadCount > 0
                            ? '$_unreadCount unread notification(s)'
                            : 'All caught up!',
                        style: GEMSTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  if (_unreadCount > 0)
                    TextButton.icon(
                      onPressed: _markAllRead,
                      icon: const Icon(Icons.done_all,
                          size: 16,
                          color: GEMSTheme.primaryGreen),
                      label: Text('Mark all read',
                          style: GoogleFonts.poppins(
                              color: GEMSTheme.primaryGreen,
                              fontSize: 13)),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        color: GEMSTheme.textMid),
                    tooltip: 'Refresh',
                    onPressed: _load,
                  ),
                ],
              ),
            ],
          ).animate().fadeIn(),

          const SizedBox(height: 20),

          // ── Filter tabs ──
          Row(
            children: [
              _FilterChip(
                label: 'All',
                count: _notifications.length,
                selected: _filter == 'all',
                onTap: () => setState(() => _filter = 'all'),
              ),
              const SizedBox(width: 10),
              _FilterChip(
                label: 'Unread',
                count: _unreadCount,
                selected: _filter == 'unread',
                onTap: () => setState(() => _filter = 'unread'),
                badgeColor: GEMSTheme.danger,
              ),
            ],
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 20),

          // ── Content ──
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: CircularProgressIndicator(
                    color: GEMSTheme.primaryGreen),
              ),
            )
          else if (items.isEmpty)
            _emptyState()
          else
            ...items.asMap().entries.map((e) {
              final n        = e.value;
              final type     = n['type'] as String? ?? '';
              final isRead   = n['is_read'] == true;
              final color    = _typeColor(type);
              final icon     = _typeIcon(type);
              final timeAgo  = _timeAgo(n['created_at'] as String?);

              return GestureDetector(
                onTap: isRead ? null : () => _markRead(n['id'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isRead
                        ? Colors.white
                        : color.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead
                          ? Colors.grey.shade100
                          : color.withOpacity(0.25),
                      width: isRead ? 1 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(
                            isRead ? 0.03 : 0.08),
                        blurRadius: isRead ? 8 : 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Icon(icon,
                            color: color, size: 22),
                      ),
                      const SizedBox(width: 14),

                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(
                                  n['title'] as String? ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    color: GEMSTheme.textDark,
                                  ),
                                ),
                              ),
                              Text(timeAgo,
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color:
                                          GEMSTheme.textLight)),
                            ]),
                            const SizedBox(height: 4),
                            Text(
                              n['body'] as String? ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: isRead
                                    ? GEMSTheme.textLight
                                    : GEMSTheme.textMid,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!isRead) ...[
                              const SizedBox(height: 8),
                              Row(children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('Tap to mark as read',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: color)),
                              ]),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (e.key * 50).ms);
            }),
        ],
      ),
    );
  }

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.notifications_none_rounded,
                  size: 72,
                  color: GEMSTheme.textLight.withOpacity(0.3)),
              const SizedBox(height: 20),
              Text(
                _filter == 'unread'
                    ? 'No unread notifications'
                    : 'No notifications yet',
                style: GEMSTheme.headingMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'When tasks are created, reports submitted,\nor issues raised, they will appear here.',
                textAlign: TextAlign.center,
                style: GEMSTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
}

// ── FILTER CHIP ───────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String   label;
  final int      count;
  final bool     selected;
  final VoidCallback onTap;
  final Color    badgeColor;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.badgeColor = GEMSTheme.primaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? GEMSTheme.primaryGreen
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? GEMSTheme.primaryGreen
                : Colors.grey.shade200,
          ),
          boxShadow: selected
              ? [BoxShadow(
                  color: GEMSTheme.primaryGreen.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : GEMSTheme.textMid)),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withOpacity(0.25)
                    : badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : badgeColor)),
            ),
          ],
        ]),
      ),
    );
  }
}