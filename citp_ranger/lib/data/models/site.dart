enum SiteStatus { draft, pending, open, rejected }

SiteStatus statusFromName(String? value) {
  return switch (value) {
    'draft' => SiteStatus.draft,
    'pending' => SiteStatus.pending,
    'rejected' => SiteStatus.rejected,
    _ => SiteStatus.open,
  };
}

class Site {
  const Site({
    required this.id,
    required this.rangerName,
    required this.speciesKey,
    required this.notes,
    required this.status,
    this.source = 'ranger',
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.photoPath,
    this.photoUrl,
    this.syncedAt,
  });

  final String id;
  final String rangerName;
  final String speciesKey;
  final double? latitude;
  final double? longitude;
  final String notes;
  final String? photoPath;
  final String? photoUrl;
  final SiteStatus status;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;

  bool get hasLocation => latitude != null && longitude != null;

  Site copyWith({
    String? rangerName,
    String? speciesKey,
    Object? latitude = _keep,
    Object? longitude = _keep,
    String? notes,
    Object? photoPath = _keep,
    Object? photoUrl = _keep,
    SiteStatus? status,
    String? source,
    DateTime? updatedAt,
    Object? syncedAt = _keep,
  }) {
    return Site(
      id: id,
      rangerName: rangerName ?? this.rangerName,
      speciesKey: speciesKey ?? this.speciesKey,
      latitude: latitude == _keep ? this.latitude : latitude as double?,
      longitude: longitude == _keep ? this.longitude : longitude as double?,
      notes: notes ?? this.notes,
      photoPath: photoPath == _keep ? this.photoPath : photoPath as String?,
      photoUrl: photoUrl == _keep ? this.photoUrl : photoUrl as String?,
      status: status ?? this.status,
      source: source ?? this.source,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt == _keep ? this.syncedAt : syncedAt as DateTime?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'ranger_name': rangerName,
      'species': speciesKey,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'photo_path': photoPath,
      'photo_url': photoUrl,
      'status': status.name,
      'source': source,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'synced_at': syncedAt?.toUtc().toIso8601String(),
    };
  }

  factory Site.fromMap(Map<dynamic, dynamic> map) {
    return Site(
      id: map['id']! as String,
      rangerName: map['ranger_name']! as String,
      speciesKey: map['species']! as String,
      latitude: _asDouble(map['latitude']),
      longitude: _asDouble(map['longitude']),
      notes: (map['notes'] as String?) ?? '',
      photoPath: map['photo_path'] as String?,
      photoUrl: map['photo_url'] as String?,
      status: statusFromName(map['status'] as String?),
      source: (map['source'] as String?) ?? 'ranger',
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
      syncedAt: map['synced_at'] == null
          ? null
          : DateTime.parse(map['synced_at']! as String),
    );
  }

  Map<String, Object?> toRemote() {
    return {
      'id': id,
      'ranger_name': rangerName,
      'species': speciesKey,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'photo_url': photoUrl,
      'status': status.name,
      'source': source,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory Site.fromRemote(Map<String, dynamic> map, {String? photoPath}) {
    return Site(
      id: map['id'].toString(),
      rangerName: map['ranger_name'] as String,
      speciesKey: map['species'] as String,
      latitude: _asDouble(map['latitude']),
      longitude: _asDouble(map['longitude']),
      notes: (map['notes'] as String?) ?? '',
      photoPath: photoPath,
      photoUrl: map['photo_url'] as String?,
      status: statusFromName(map['status']?.toString()),
      source: (map['source'] as String?) ?? 'ranger',
      createdAt: DateTime.parse(map['created_at'].toString()),
      updatedAt: DateTime.parse(map['updated_at'].toString()),
      syncedAt: DateTime.now().toUtc(),
    );
  }
}

const _keep = Object();

double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
