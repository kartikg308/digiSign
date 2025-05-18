import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/document.dart';
import '../models/signature.dart';

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
    // Create documents table
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

    // Create signatures table
    await db.execute('''
      CREATE TABLE signatures(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        bytes BLOB,
        dateCreated INTEGER
      )
    ''');
  }

  // Document operations
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

  // Signature operations
  Future<int> insertSignature(Signature signature) async {
    final db = await database;
    return await db.insert('signatures', signature.toMap());
  }

  Future<int> updateSignature(Signature signature) async {
    final db = await database;
    return await db.update('signatures', signature.toMap(), where: 'id = ?', whereArgs: [signature.id]);
  }

  Future<int> deleteSignature(int id) async {
    final db = await database;
    return await db.delete('signatures', where: 'id = ?', whereArgs: [id]);
  }

  Future<Signature?> getSignature(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('signatures', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Signature.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Signature>> getAllSignatures({String sortBy = 'dateCreated', bool descending = true}) async {
    final db = await database;
    final order = descending ? 'DESC' : 'ASC';
    final List<Map<String, dynamic>> maps = await db.query('signatures', orderBy: '$sortBy $order');

    return List.generate(maps.length, (i) => Signature.fromMap(maps[i]));
  }
}
