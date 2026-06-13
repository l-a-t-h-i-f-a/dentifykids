import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/brushing_record.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._();
  factory DatabaseService() => _instance;
  DatabaseService._();

  Database? _db;

  Future<Database> get _database async => _db ??= await _init();

  Future<Database> _init() async {
    final dbPath = join(await getDatabasesPath(), 'dentifykids.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE brushing_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tanggal TEXT NOT NULL,
          waktu_mulai TEXT NOT NULL,
          waktu_selesai TEXT NOT NULL,
          durasi_detik INTEGER NOT NULL,
          jumlah_gerakan INTEGER NOT NULL,
          sesi TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      '''),
    );
  }

  Future<void> insertRecord(BrushingRecord record) async {
    final db = await _database;
    await db.insert('brushing_history', record.toMap());
  }

  Future<bool> hasSesiToday(String tanggal, String sesi) async {
    final db = await _database;
    final result = await db.query(
      'brushing_history',
      where: 'tanggal = ? AND sesi = ?',
      whereArgs: [tanggal, sesi],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<List<BrushingRecord>> getRecordsByDate(String tanggal) async {
    final db = await _database;
    final maps = await db.query(
      'brushing_history',
      where: 'tanggal = ?',
      whereArgs: [tanggal],
      orderBy: 'waktu_mulai ASC',
    );
    return maps.map(BrushingRecord.fromMap).toList();
  }

  Future<List<BrushingRecord>> getRecordsByDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await _database;
    final maps = await db.query(
      'brushing_history',
      where: 'tanggal >= ? AND tanggal <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'tanggal ASC, waktu_mulai ASC',
    );
    return maps.map(BrushingRecord.fromMap).toList();
  }
}
