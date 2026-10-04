import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../demo_data.dart';
import '../models/site.dart';
import '../models/treatment.dart';
import '../../core/local_auth.dart';
import '../../core/role.dart';

class AppDatabase {
  AppDatabase(this.db);

  final Database db;

  static Future<AppDatabase> open({String? path}) async {
    final resolved = path ?? await _databasePath();
    final db = await openDatabase(
      resolved,
      version: 4,
      onConfigure: (db) async {
        await _pragma(db, 'PRAGMA foreign_keys = ON');
        await _pragma(db, 'PRAGMA journal_mode = WAL');
        await _pragma(db, 'PRAGMA synchronous = FULL');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _repair(db);
      },
      onDowngrade: (db, oldVersion, newVersion) async {
        // Keep the file. A newer schema on an older build must not wipe records.
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sites (
            id TEXT PRIMARY KEY,
            ranger_name TEXT NOT NULL,
            species TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            notes TEXT NOT NULL,
            photo_path TEXT,
            photo_url TEXT,
            status TEXT NOT NULL,
            source TEXT NOT NULL DEFAULT 'ranger',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            synced_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE treatments (
            id TEXT PRIMARY KEY,
            site_id TEXT NOT NULL,
            ranger_name TEXT NOT NULL,
            treated_at TEXT NOT NULL,
            notes TEXT NOT NULL,
            next_check_due TEXT NOT NULL,
            photo_path TEXT,
            synced_at TEXT,
            FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await _createAccounts(db);
      },
    );
    await _repair(db);
    return AppDatabase(db);
  }

  /// Adds columns a device may be missing after a partial or repeated upgrade.
  static Future<String> _databasePath() async {
    if (kIsWeb) return 'citp_ranger.db';
    final root = await getApplicationDocumentsDirectory();
    return p.join(root.path, 'citp_ranger.db');
  }

  static Future<void> _pragma(Database db, String sql) async {
    try {
      if (sql.startsWith('PRAGMA journal_mode')) {
        await db.rawQuery(sql);
      } else {
        await db.execute(sql);
      }
    } catch (_) {
      // Web SQLite does not support every desktop pragma. The file still opens.
    }
  }

  static Future<void> _repair(Database db) async {
    await _addColumnIfMissing(
      db,
      'sites',
      'source',
      "ALTER TABLE sites ADD COLUMN source TEXT NOT NULL DEFAULT 'ranger'",
    );
    await _addColumnIfMissing(db, 'sites', 'photo_path', 'ALTER TABLE sites ADD COLUMN photo_path TEXT');
    await _addColumnIfMissing(db, 'sites', 'photo_url', 'ALTER TABLE sites ADD COLUMN photo_url TEXT');
    await _addColumnIfMissing(
      db,
      'treatments',
      'photo_path',
      'ALTER TABLE treatments ADD COLUMN photo_path TEXT',
    );
    try {
      await _createAccounts(db);
    } catch (_) {
      // Accounts already exist. Existing sign-ins stay.
    }
  }

  static Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String sql,
  ) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      final names = info.map((row) => row['name']).whereType<String>().toSet();
      if (names.contains(column)) return;
      await db.execute(sql);
    } catch (_) {
      // The column is already there, or this table is not ready yet.
    }
  }

  static Future<void> _createAccounts(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_accounts (
        email TEXT PRIMARY KEY,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        display_name TEXT NOT NULL
      )
    ''');
    for (final account in demoLocalAccounts) {
      await db.insert('local_accounts', {
        'email': account.email,
        'password_hash': localPasswordHash(account.email, account.password),
        'role': account.role.name,
        'display_name': account.name,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<LocalAccount?> accountByEmail(String email) async {
    final rows = await db.query(
      'local_accounts',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final role = roleFromName(row['role'] as String?);
    if (role == null) return null;
    return LocalAccount(
      email: row['email']! as String,
      passwordHash: row['password_hash']! as String,
      role: role,
      displayName: row['display_name']! as String,
    );
  }

  Future<void> rememberAccount(LocalAccount account) async {
    await db.insert('local_accounts', {
      'email': account.email.trim().toLowerCase(),
      'password_hash': account.passwordHash,
      'role': account.role.name,
      'display_name': account.displayName,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> seedIfEmpty(DemoBundle demo) async {
    final count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM sites')) ??
        0;
    if (count > 0) return;
    await db.transaction((txn) async {
      for (final site in demo.sites) {
        await txn.insert('sites', site.toMap());
      }
      for (final treatment in demo.treatments) {
        await txn.insert('treatments', treatment.toMap());
      }
    });
  }

  Future<String?> getMeta(String key) async {
    final rows = await db.query('meta', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setMeta(String key, String value) async {
    await db.insert('meta', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteMeta(String key) async {
    await db.delete('meta', where: 'key = ?', whereArgs: [key]);
  }

  Future<List<Site>> allSites() async {
    final rows = await db.query('sites', orderBy: 'created_at ASC');
    return rows.map(Site.fromMap).toList();
  }

  Future<List<Treatment>> allTreatments() async {
    final rows = await db.query('treatments', orderBy: 'treated_at ASC');
    return rows.map(Treatment.fromMap).toList();
  }

  Future<void> upsertSite(Site site) async {
    await db.insert(
      'sites',
      site.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSite(String id) async {
    await db.delete('sites', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setPhotoPath(String id, String path) async {
    await db.update(
      'sites',
      {'photo_path': path},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markSiteSynced(String id, String? photoUrl) async {
    await db.update(
      'sites',
      {
        'synced_at': DateTime.now().toUtc().toIso8601String(),
        'photo_url': photoUrl,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> upsertTreatment(Treatment treatment) async {
    await db.insert(
      'treatments',
      treatment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markTreatmentSynced(String id) async {
    await db.update(
      'treatments',
      {'synced_at': DateTime.now().toUtc().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
