import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseHelper {
    Future<int> addMedication(String name, String dosage, String notes) async {
      final dbClient = await db;
      return await dbClient.insert('medications', {
        'name': name,
        'dosage': dosage,
        'notes': notes,
      });
    }

    Future<int> addReminderForMedication(int medicationId, String time, bool enabled) async {
      final dbClient = await db;
      return await dbClient.insert('reminders', {
        'medication_id': medicationId,
        'time': time,
        'enabled': enabled ? 1 : 0,
      });
    }
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add dose_history table if upgrading from version 1
      await db.execute('''
        CREATE TABLE IF NOT EXISTS dose_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          medication_id INTEGER NOT NULL,
          taken INTEGER NOT NULL,
          timestamp TEXT NOT NULL,
          FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
        await db.execute('''
          CREATE TABLE dose_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medication_id INTEGER NOT NULL,
            taken INTEGER NOT NULL,
            timestamp TEXT NOT NULL,
            FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
          )
        ''');
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT,
        notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        time TEXT NOT NULL,
        enabled INTEGER NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getReminders() async {
    final dbClient = await db;
    return await dbClient.query('reminders', orderBy: 'id DESC');
  }

  Future<int> addReminder(String medication, String time, bool enabled) async {
    final dbClient = await db;
    return await dbClient.insert('reminders', {
      'medication': medication,
      'time': time,
      'enabled': enabled ? 1 : 0,
    });
  }

  Future<int> updateReminder(int id, String medication, String time, bool enabled) async {
    final dbClient = await db;
    return await dbClient.update(
      'reminders',
      {
        'medication': medication,
        'time': time,
        'enabled': enabled ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteReminder(int id) async {
    final dbClient = await db;
    return await dbClient.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleReminder(int id, bool enabled) async {
    final dbClient = await db;
    return await dbClient.update(
      'reminders',
      {'enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> registerUser(String username, String email, String password) async {
    final dbClient = await db;
    return await dbClient.insert('users', {
      'username': username,
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>?> getUser(String email) async {
    final dbClient = await db;
    final res = await dbClient.query('users', where: 'email = ?', whereArgs: [email]);
    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }
}
