import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('buyers.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE buyers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<int> insertBuyer(Map<String, dynamic> buyer) async {
    final db = await database;
    return await db.insert('buyers', buyer);
  }

  Future<List<Map<String, dynamic>>> getBuyers() async {
    final db = await database;
    return await db.query('buyers');
  }

  Future<Map<String, dynamic>?> getBuyerByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'buyers',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateBuyer(Map<String, dynamic> buyer) async {
    final db = await database;
    return await db.update(
      'buyers',
      buyer,
      where: 'id = ?',
      whereArgs: [buyer['id']],
    );
  }

  Future<int> deleteBuyer(int id) async {
    final db = await database;
    return await db.delete('buyers', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
