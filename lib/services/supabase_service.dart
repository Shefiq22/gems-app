// ============================================================
//  GEMS — Supabase Service  (LIVE ONLY — zero mock data)
//  Replace the two constants below with your real values:
//    Supabase Dashboard → Settings → API
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── YOUR CREDENTIALS ────────────────────────────────────────
const String _supabaseUrl     = 'https://hrblmwvwrzhgzdsxwiat.supabase.co';
const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhyYmxtd3Z3cnpoZ3pkc3h3aWF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI0MTUzNjcsImV4cCI6MjA5Nzk5MTM2N30.xgM7GQ6W-qInDkG-F3P-FliUwWoPG4e_agDREetc6dA';

// ── REDIRECT URL ─────────────────────────────────────────────
// Also add this in: Supabase → Authentication → URL Configuration
const String _webRedirectUrl = 'http://localhost:8080/#/reset-password';

class SupabaseService {
  // ── CONFIG ───────────────────────────────────────────────
  static bool get isConfigured =>
      !_supabaseUrl.contains('YOUR_PROJECT_ID') &&
      !_supabaseAnonKey.startsWith('YOUR_');

  static SupabaseClient get _db {
    if (!isConfigured) throw Exception('Supabase not configured.');
    return Supabase.instance.client;
  }

  // ── INIT ─────────────────────────────────────────────────
  static Future<void> initialize() async {
    if (!isConfigured) {
      debugPrint('⚠️  GEMS: Paste your Supabase URL and anon key in supabase_service.dart');
      return;
    }
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
    debugPrint('✅ GEMS: Supabase connected → $_supabaseUrl');
  }

  // ── AUTH ─────────────────────────────────────────────────

  static Future<User?> signIn(String email, String password) async {
    final res = await _db.auth.signInWithPassword(email: email, password: password);
    return res.user;
  }

  static Future<void> signUp(
    String email,
    String password,
    String fullName,
    String role, {
    String? facultyId,
  }) async {
    await _db.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
        if (facultyId != null && facultyId.isNotEmpty) 'faculty_id': facultyId,
      },
      emailRedirectTo: kIsWeb ? _webRedirectUrl : null,
    );
  }

  static Future<void> resetPassword(String email) async {
    await _db.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? _webRedirectUrl : null,
    );
  }

  static Future<void> updatePassword(String newPassword) async {
    await _db.auth.updateUser(UserAttributes(password: newPassword));
  }

  static Future<void> signOut() async {
    await _db.auth.signOut();
  }

  static User? get currentUser => isConfigured ? _db.auth.currentUser : null;

  static String get currentRole =>
      currentUser?.userMetadata?['role'] as String? ?? 'groundskeeper';

  static String get currentFacultyId =>
      currentUser?.userMetadata?['faculty_id'] as String? ?? '';

  static String get currentFullName {
    final meta = currentUser?.userMetadata;
    return meta?['full_name'] as String? ??
        currentUser?.email?.split('@').first ?? 'User';
  }

  // ── PROFILE ──────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getMyProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final res = await _db.from('profiles').select().eq('id', uid).maybeSingle();
    return res as Map<String, dynamic>?;
  }

  static Future<void> updateProfile({required String fullName}) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await _db.from('profiles').update({
      'full_name': fullName,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', uid);
    await _db.auth.updateUser(UserAttributes(data: {'full_name': fullName}));
  }

  static Future<List<Map<String, dynamic>>> getAllProfiles() async {
    final res = await _db.from('profiles').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  // ── FACULTIES ────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getFaculties() async {
    final res = await _db
        .from('faculties')
        .select('*, vegetation_zones(*)')
        .order('name');
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<void> updateFacultyScore(String facultyId, double score) async {
    await _db.from('faculties').update({
      'green_health_score': score,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', facultyId);
  }

  // ── TASKS ────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTasks({String? facultyId}) async {
    var query = _db
        .from('maintenance_tasks')
        .select('*, faculties(name, short_name)');
    if (facultyId != null && facultyId.isNotEmpty) {
      query = query.eq('faculty_id', facultyId) as dynamic;
    }
    final res = await query.order('due_date');
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<void> createTask(Map<String, dynamic> task) async {
    await _db.from('maintenance_tasks').insert({
      ...task,
      'created_by': currentUser?.id,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> updateTaskStatus(String taskId, String status) async {
    await _db.from('maintenance_tasks').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', taskId);
  }

  static Future<void> deleteTask(String taskId) async {
    await _db.from('maintenance_tasks').delete().eq('id', taskId);
  }

  // ── VEGETATION REPORTS ────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getVegetationReports({
    String? facultyId,
    String? status,
  }) async {
    var query = _db.from('vegetation_reports').select('*, faculties(name, short_name)');
    if (facultyId != null && facultyId.isNotEmpty) {
      query = query.eq('faculty_id', facultyId) as dynamic;
    }
    if (status != null) {
      query = query.eq('status', status) as dynamic;
    }
    final res = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<void> submitVegetationReport({
    required String facultyId,
    required String zoneName,
    required double grassHeightCm,
    required String vegetationType,
    required String condition,
    required bool nearBuilding,
    required bool isDrySeason,
    required double coveragePct,
    String notes = '',
    String? photoUrl,
  }) async {
    await _db.from('vegetation_reports').insert({
      'faculty_id':      facultyId,
      'zone_name':       zoneName,
      'grass_height_cm': grassHeightCm,
      'vegetation_type': vegetationType,
      'condition':       condition,
      'near_building':   nearBuilding,
      'is_dry_season':   isDrySeason,
      'coverage_pct':    coveragePct,
      'notes':           notes,
      if (photoUrl != null) 'photo_url': photoUrl,
      'submitted_by':    currentUser?.id,
      'submitter_name':  currentFullName,
      'status':          'pending',
      'created_at':      DateTime.now().toIso8601String(),
    });
  }

  static Future<void> updateVegetationReportStatus(String id, String status) async {
    await _db.from('vegetation_reports').update({'status': status}).eq('id', id);
  }

  // ── ISSUE REPORTS ─────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getIssueReports({String? facultyId}) async {
    var query = _db.from('issue_reports').select('*, faculties(name)');
    if (facultyId != null && facultyId.isNotEmpty) {
      query = query.eq('faculty_id', facultyId) as dynamic;
    }
    final res = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<void> submitIssueReport({
    required String facultyId,
    required String title,
    required String description,
    required String category,
    required String reportedBy,
    String? photoUrl,
  }) async {
    await _db.from('issue_reports').insert({
      'faculty_id':   facultyId,
      'title':        title,
      'description':  description,
      'category':     category,
      'reported_by':  reportedBy,
      if (photoUrl != null) 'photo_url': photoUrl,
      'status':       'open',
      'priority':     'medium',
      'created_at':   DateTime.now().toIso8601String(),
    });
  }

  static Future<void> updateIssueStatus(String id, String status) async {
    await _db.from('issue_reports').update({'status': status}).eq('id', id);
  }

  // ── TREE REGISTRY ─────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTreeRegistry({String? facultyId}) async {
    var query = _db.from('tree_registry').select('*, faculties(name)');
    if (facultyId != null && facultyId.isNotEmpty) {
      query = query.eq('faculty_id', facultyId) as dynamic;
    }
    final res = await query.order('date_planted', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<void> addTree(Map<String, dynamic> tree) async {
    await _db.from('tree_registry').insert({
      ...tree,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> updateTreeStatus(String id, String status) async {
    await _db.from('tree_registry').update({'status': status}).eq('id', id);
  }

  // ── MONTHLY REPORTS ───────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getMonthlyReports() async {
    final res = await _db
        .from('monthly_reports')
        .select()
        .order('year')
        .order('month_num');
    return List<Map<String, dynamic>>.from(res as List);
  }

  // ── ALERTS (combined overdue tasks + open issues) ─────────

  static Future<List<Map<String, dynamic>>> getAlerts({String? facultyId}) async {
    final tasks  = await getTasks(facultyId: facultyId);
    final issues = await getIssueReports(facultyId: facultyId);
    final alerts = <Map<String, dynamic>>[];
    for (final t in tasks) {
      if (t['status'] == 'overdue' || t['priority'] == 'critical') {
        alerts.add({...t, '_alert_type': 'task'});
      }
    }
    for (final i in issues) {
      if (i['status'] == 'open' || i['status'] == 'investigating') {
        alerts.add({...i, '_alert_type': 'issue'});
      }
    }
    return alerts;
  }

  // ── REALTIME STREAM ───────────────────────────────────────

  static Stream<AuthState> get authStateChanges =>
      _db.auth.onAuthStateChange;
}