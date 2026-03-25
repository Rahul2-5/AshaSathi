import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabaseOffline {
  static final AppDatabaseOffline _instance =
      AppDatabaseOffline._internal();

  factory AppDatabaseOffline() => _instance;
  AppDatabaseOffline._internal();

  static Database? _database;

  static const String _dbName = 'asha_sathi_offline.db';

  static const String patientTable = 'patients';
  static const String taskTable = 'tasks';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ================= CREATE =================

  Future<void> _onCreate(Database db, int version) async {
    // Patients
    await db.execute('''
      CREATE TABLE $patientTable (
        localId INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        serverId INTEGER,
        name TEXT NOT NULL,
        gender TEXT NOT NULL,
        age INTEGER NOT NULL,
        dateOfBirth TEXT NOT NULL,
        address TEXT NOT NULL,
        description TEXT,
        phoneNumber TEXT NOT NULL,
        photoPath TEXT,
        syncStatus INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        retryCount INTEGER NOT NULL DEFAULT 0,
        lastError TEXT,
        baseHash TEXT,
        conflictServerPayload TEXT
      )
    ''');

    // Tasks
    await db.execute('''
      CREATE TABLE $taskTable (
        localId INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        serverId INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        createdDate TEXT NOT NULL,
        syncStatus INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
  }

  // ================= MIGRATION =================

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $taskTable (
          localId INTEGER PRIMARY KEY AUTOINCREMENT,
          uuid TEXT NOT NULL UNIQUE,
          serverId INTEGER,
          title TEXT NOT NULL,
          description TEXT,
          status TEXT NOT NULL,
          createdDate TEXT NOT NULL,
          syncStatus INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE $patientTable ADD COLUMN description TEXT');
    }

    if (oldVersion < 5) {
      await _addColumnIfMissing(
        db,
        table: patientTable,
        column: 'retryCount',
        definition: 'INTEGER NOT NULL DEFAULT 0',
      );
      await _addColumnIfMissing(
        db,
        table: patientTable,
        column: 'lastError',
        definition: 'TEXT',
      );
      await _addColumnIfMissing(
        db,
        table: patientTable,
        column: 'baseHash',
        definition: 'TEXT',
      );
      await _addColumnIfMissing(
        db,
        table: patientTable,
        column: 'conflictServerPayload',
        definition: 'TEXT',
      );
    }
  }

  Future<void> _addColumnIfMissing(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final cols = await db.rawQuery('PRAGMA table_info($table)');
    final exists = cols.any((c) => c['name'] == column);
    if (exists) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }
}
