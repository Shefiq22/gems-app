// ============================================================
//  GEMS — App Data Models  (NO mock data — models only)
//  All data comes from Supabase via SupabaseService.
// ============================================================

import 'package:flutter/material.dart';
import '../theme/gems_theme.dart';

// ── FACULTY ──────────────────────────────────────────────────

class Faculty {
  final String id;
  final String name;
  final String shortName;
  final String description;
  final Color color;
  final double greenHealthScore;
  final List<VegetationZone> zones;
  final List<MaintenanceTask> tasks;
  final String imageUrl;
  final String hazardLevel;
  final int totalArea;
  final String dean;

  const Faculty({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.color,
    required this.greenHealthScore,
    required this.zones,
    required this.tasks,
    required this.imageUrl,
    required this.hazardLevel,
    required this.totalArea,
    required this.dean,
  });

  factory Faculty.fromJson(Map<String, dynamic> json) {
    final id       = json['id'] as String? ?? '';
    final rawZones = json['vegetation_zones'] as List<dynamic>?;
    return Faculty(
      id:               id,
      name:             json['name']              as String? ?? '',
      shortName:        json['short_name']        as String? ?? '',
      description:      json['description']       as String? ?? '',
      color:            _colorForId(id),
      greenHealthScore: (json['green_health_score'] as num?)?.toDouble() ?? 0,
      zones:            rawZones != null
          ? rawZones
              .map((z) => VegetationZone.fromJson(z as Map<String, dynamic>))
              .toList()
          : [],
      tasks:            const [],
      imageUrl:         json['image_url']   as String? ?? '',
      hazardLevel:      json['hazard_level'] as String? ?? 'low',
      totalArea:        (json['total_area'] as num?)?.toInt() ?? 0,
      dean:             json['dean']         as String? ?? '',
    );
  }

  Faculty copyWith({List<MaintenanceTask>? tasks}) => Faculty(
        id: id, name: name, shortName: shortName,
        description: description, color: color,
        greenHealthScore: greenHealthScore, zones: zones,
        tasks: tasks ?? this.tasks,
        imageUrl: imageUrl, hazardLevel: hazardLevel,
        totalArea: totalArea, dean: dean,
      );

  static Color _colorForId(String id) {
    switch (id) {
      case 'nas':  return GEMSTheme.nasFacultyColor;
      case 'es':   return GEMSTheme.esFacultyColor;
      case 'eng':  return GEMSTheme.engFacultyColor;
      case 'med':  return GEMSTheme.medFacultyColor;
      default:     return GEMSTheme.primaryGreen;
    }
  }
}

// ── VEGETATION ZONE ───────────────────────────────────────────

class VegetationZone {
  final String   id;
  final String   name;
  final String   type;
  final double   percentage;
  final Color    color;
  final IconData icon;

  const VegetationZone({
    required this.id,
    required this.name,
    required this.type,
    required this.percentage,
    required this.color,
    required this.icon,
  });

  factory VegetationZone.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'grass';
    return VegetationZone(
      id:         json['id']         as String? ?? '',
      name:       json['name']       as String? ?? '',
      type:       type,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      color:      _hexToColor(json['color_hex'] as String? ?? '#66BB6A'),
      icon:       _iconForType(type),
    );
  }

  static Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'bush':    return Icons.forest;
      case 'trees':   return Icons.nature;
      case 'flowers': return Icons.local_florist;
      case 'bare':    return Icons.landscape;
      default:        return Icons.grass;
    }
  }
}

// ── MAINTENANCE TASK ──────────────────────────────────────────

class MaintenanceTask {
  final String   id;
  final String   title;
  final String   description;
  final String   status;
  final String   priority;
  final DateTime dueDate;
  final String   assignedTo;
  final String   taskType;
  final String   facultyId;

  const MaintenanceTask({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.assignedTo,
    required this.taskType,
    required this.facultyId,
  });

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    return MaintenanceTask(
      id:          json['id']          as String? ?? '',
      title:       json['title']       as String? ?? '',
      description: json['description'] as String? ?? '',
      status:      json['status']      as String? ?? 'pending',
      priority:    json['priority']    as String? ?? 'medium',
      dueDate:     json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      assignedTo:  json['assigned_to'] as String? ?? '',
      taskType:    json['task_type']   as String? ?? '',
      facultyId:   json['faculty_id']  as String? ?? '',
    );
  }
}

// ── MONTHLY REPORT ────────────────────────────────────────────

class MonthlyReport {
  final String month;
  final double nasScore;
  final double esScore;
  final double engScore;
  final double medScore;

  const MonthlyReport({
    required this.month,
    required this.nasScore,
    required this.esScore,
    required this.engScore,
    required this.medScore,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    return MonthlyReport(
      month:    json['month']     as String? ?? '',
      nasScore: (json['nas_score'] as num?)?.toDouble() ?? 0,
      esScore:  (json['es_score']  as num?)?.toDouble() ?? 0,
      engScore: (json['eng_score'] as num?)?.toDouble() ?? 0,
      medScore: (json['med_score'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ── USER PROFILE ──────────────────────────────────────────────

class UserProfile {
  final String  id;
  final String  fullName;
  final String  role;
  final String? facultyId;
  final String? email;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.facultyId,
    this.email,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id:        json['id']        as String? ?? '',
      fullName:  json['full_name'] as String? ?? '',
      role:      json['role']      as String? ?? 'groundskeeper',
      facultyId: json['faculty_id'] as String?,
      email:     json['email']     as String?,
    );
  }

  String get roleLabel {
    switch (role) {
      case 'admin':           return 'University Admin';
      case 'faculty_officer': return 'Faculty Officer';
      case 'groundskeeper':   return 'Groundskeeper';
      case 'student':         return 'Student / Public';
      default:                return 'User';
    }
  }
}

// ── UNIVERSITY CONSTANTS ──────────────────────────────────────

class University {
  static const String name      = 'Abiola Ajimobi Technical University';
  static const String shortName = 'AATU';
  static const int    ageYears  = 15;
  static const int    totalHa   = 47;
  static const int    numFaculties = 4;
}