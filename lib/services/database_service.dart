import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/document.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'digisign_database.db');
    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE documents(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        path TEXT,
        dateCreated INTEGER,
        lastUpdated INTEGER,
        isSigned INTEGER
      )
    ''');
  }

  Future<int> insertDocument(Document document) async {
    final db = await database;
    return await db.insert('documents', document.toMap());
  }

  Future<int> updateDocument(Document document) async {
    final db = await database;
    return await db.update('documents', document.toMap(), where: 'id = ?', whereArgs: [document.id]);
  }

  Future<int> deleteDocument(int id) async {
    final db = await database;
    return await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  Future<Document?> getDocument(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('documents', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Document.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Document>> getAllDocuments({String sortBy = 'lastUpdated', bool descending = true}) async {
    final db = await database;
    final order = descending ? 'DESC' : 'ASC';
    final List<Map<String, dynamic>> maps = await db.query('documents', orderBy: '$sortBy $order');

    return List.generate(maps.length, (i) => Document.fromMap(maps[i]));
  }
}
