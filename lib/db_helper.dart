import 'dart:io'; 
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final _databaseName = "MyDatabase_v3.db";
  static final _databaseVersion = 3;

  static final table = 'documents';
  static final columnId = '_id';
  static final columnDocType = 'doc_type';      // ドキュメント種別
  static final columnSubject = 'subject';       // 科目名
  static final columnTag = 'tag';               // 詳細タグ
  static final columnPeriod = 'period';         // 時期情報
  static final columnContent = 'content';
  static final columnDate = 'date';
  static final columnImagePath = 'image_path';
  static final columnFileHash = 'file_hash';

  static final tableKeywords = 'keywords';
  static final columnKeyId = '_id';
  static final columnKeyword = 'keyword';
  static final columnRuleSubject = 'rule_subject';

  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future _onCreate(Database db, int version) async {
    // 正規化されたドキュメントテーブル
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnDocType TEXT NOT NULL,
            $columnSubject TEXT NOT NULL,
            $columnTag TEXT NOT NULL,
            $columnPeriod TEXT,
            $columnContent TEXT NOT NULL,
            $columnDate TEXT NOT NULL,
            $columnImagePath TEXT,
            $columnFileHash TEXT UNIQUE
          )
          ''');
    
    // インデックスで検索を高速化
    await db.execute('CREATE INDEX idx_subject ON $table($columnSubject)');
    await db.execute('CREATE INDEX idx_tag ON $table($columnTag)');
    await db.execute('CREATE INDEX idx_date ON $table($columnDate)');
    
    await db.execute('''
          CREATE TABLE $tableKeywords (
            $columnKeyId INTEGER PRIMARY KEY,
            $columnKeyword TEXT NOT NULL UNIQUE,
            $columnRuleSubject TEXT NOT NULL
          )
          ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // v2 → v3 マイグレーション
      try {
        // 古いテーブルを名前変更
        await db.execute('ALTER TABLE $table RENAME TO documents_old');
        
        // 新しいテーブルを作成
        await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnDocType TEXT NOT NULL,
            $columnSubject TEXT NOT NULL,
            $columnTag TEXT NOT NULL,
            $columnPeriod TEXT,
            $columnContent TEXT NOT NULL,
            $columnDate TEXT NOT NULL,
            $columnImagePath TEXT,
            $columnFileHash TEXT UNIQUE
          )
        ''');
        
        // 古いデータを新しい形式に変換してコピー
        await db.execute('''
          INSERT INTO $table 
          ($columnId, $columnDocType, $columnSubject, $columnTag, $columnPeriod, 
           $columnContent, $columnDate, $columnImagePath, $columnFileHash)
          SELECT 
            _id,
            SUBSTR(title, 0, INSTR(title, ' / ')),
            CASE 
              WHEN INSTR(title, ' / ') > 0 
              THEN SUBSTR(title, INSTR(title, ' / ') + 3, 
                         INSTR(SUBSTR(title, INSTR(title, ' / ') + 3), ' / ') - 1)
              ELSE '不明'
            END,
            CASE 
              WHEN INSTR(title, ' / ', INSTR(title, ' / ') + 3) > 0
              THEN SUBSTR(title, INSTR(title, ' / ', INSTR(title, ' / ') + 3) + 3,
                         INSTR(SUBSTR(title, INSTR(title, ' / ', INSTR(title, ' / ') + 3) + 3), ' / ') - 1)
              ELSE '不明'
            END,
            CASE 
              WHEN INSTR(title, ' / ', INSTR(title, ' / ', INSTR(title, ' / ') + 3) + 3) > 0
              THEN SUBSTR(title, INSTR(title, ' / ', INSTR(title, ' / ', INSTR(title, ' / ') + 3) + 3) + 3)
              ELSE '未設定'
            END,
            content, date, image_path, file_hash
          FROM documents_old
        ''');
        
        // インデックスを作成
        await db.execute('CREATE INDEX idx_subject ON $table($columnSubject)');
        await db.execute('CREATE INDEX idx_tag ON $table($columnTag)');
        await db.execute('CREATE INDEX idx_date ON $table($columnDate)');
        
        // 古いテーブルを削除
        await db.execute('DROP TABLE documents_old');
      } catch (e) {
        print('Migration error: $e');
      }
    }
  }

  // --- ドキュメント追加（正規化版） ---
  Future<int> insertDocument({
    required String docType,
    required String subject,
    required String tag,
    required String period,
    required String content,
    required String imagePath,
    required String fileHash,
  }) async {
    Database db = await instance.database;
    Map<String, dynamic> row = {
      columnDocType: docType,
      columnSubject: subject,
      columnTag: tag,
      columnPeriod: period,
      columnContent: content,
      columnDate: DateTime.now().toString(),
      columnImagePath: imagePath,
      columnFileHash: fileHash,
    };
    return await db.insert(table, row);
  }

  // --- 従来のインターフェース（互換性） ---
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table, orderBy: "$columnDate DESC");
  }

  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    Database db = await instance.database;
    final rows = await db.query(table, where: '$columnId = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final path = rows.first[columnImagePath] as String?;
      if (path != null && await File(path).exists()) await File(path).delete();
    }
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<void> deleteFolder(String folderName) async {
    Database db = await instance.database;
    final rows = await db.query(table, where: '$columnSubject = ?', whereArgs: [folderName]);
    for (var row in rows) {
      final path = row[columnImagePath] as String?;
      if (path != null && await File(path).exists()) {
        await File(path).delete();
      }
    }
    await db.delete(table, where: '$columnSubject = ?', whereArgs: [folderName]);
  }

  // フォルダ名（科目名）を一括変更
  Future<int> renameFolder(String oldName, String newName) async {
    Database db = await instance.database;
    return await db.update(
      table,
      {columnSubject: newName},
      where: '$columnSubject = ?',
      whereArgs: [oldName],
    );
  }

  Future<bool> isDuplicate(String hash) async {
    Database db = await instance.database;
    final result = await db.query(table, where: '$columnFileHash = ?', whereArgs: [hash]);
    return result.isNotEmpty;
  }

  // --- キーワードルール管理 ---
  Future<int> addKeywordRule(String keyword, String subject) async {
    Database db = await instance.database;
    return await db.insert(tableKeywords, {
      columnKeyword: keyword,
      columnRuleSubject: subject,
    });
  }

  Future<List<Map<String, dynamic>>> getAllKeywordRules() async {
    Database db = await instance.database;
    return await db.query(tableKeywords);
  }

  Future<int> deleteKeywordRule(int id) async {
    Database db = await instance.database;
    return await db.delete(tableKeywords, where: '$columnKeyId = ?', whereArgs: [id]);
  }
}