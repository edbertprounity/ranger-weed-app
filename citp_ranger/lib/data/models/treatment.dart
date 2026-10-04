import 'site.dart';

class Treatment {
  const Treatment({
    required this.id,
    required this.siteId,
    required this.rangerName,
    required this.treatedAt,
    required this.notes,
    required this.nextCheckDue,
    this.photoPath,
    this.syncedAt,
  });

  final String id;
  final String siteId;
  final String rangerName;
  final DateTime treatedAt;
  final String notes;
  final DateTime nextCheckDue;
  final String? photoPath;
  final DateTime? syncedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'site_id': siteId,
      'ranger_name': rangerName,
      'treated_at': treatedAt.toUtc().toIso8601String(),
      'notes': notes,
      'next_check_due': nextCheckDue.toUtc().toIso8601String(),
      'photo_path': photoPath,
      'synced_at': syncedAt?.toUtc().toIso8601String(),
    };
  }

  factory Treatment.fromMap(Map<dynamic, dynamic> map) {
    return Treatment(
      id: map['id']! as String,
      siteId: map['site_id']! as String,
      rangerName: map['ranger_name']! as String,
      treatedAt: DateTime.parse(map['treated_at']! as String),
      notes: (map['notes'] as String?) ?? '',
      nextCheckDue: DateTime.parse(map['next_check_due']! as String),
      photoPath: map['photo_path'] as String?,
      syncedAt: map['synced_at'] == null
          ? null
          : DateTime.parse(map['synced_at']! as String),
    );
  }

  Map<String, Object?> toRemote() {
    return {
      'id': id,
      'site_id': siteId,
      'ranger_name': rangerName,
      'treated_at': treatedAt.toUtc().toIso8601String(),
      'notes': notes,
      'next_check_due': nextCheckDue.toUtc().toIso8601String(),
    };
  }

  factory Treatment.fromRemote(Map<String, dynamic> map, {String? photoPath}) {
    return Treatment(
      id: map['id'].toString(),
      siteId: map['site_id'].toString(),
      rangerName: map['ranger_name'] as String,
      treatedAt: DateTime.parse(map['treated_at'].toString()),
      notes: (map['notes'] as String?) ?? '',
      nextCheckDue: DateTime.parse(map['next_check_due'].toString()),
      photoPath: photoPath,
      syncedAt: DateTime.now().toUtc(),
    );
  }
}

class SiteView {
  const SiteView({required this.site, this.treatment});

  final Site site;
  final Treatment? treatment;
}
