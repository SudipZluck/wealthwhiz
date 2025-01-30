import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart' as models;

class DatabaseService {
  static Database? _database;
  static const String dbName = 'wealthwhiz.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        receiptUrl TEXT,
        note TEXT,
        isRecurring INTEGER NOT NULL,
        recurringId TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        isRecurring INTEGER NOT NULL,
        recurringId TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL NOT NULL,
        targetDate TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        status TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // Transaction Methods
  Future<List<models.Transaction>> getTransactions(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return List.generate(
        maps.length, (i) => models.Transaction.fromMap(maps[i]));
  }

  Future<models.Transaction> insertTransaction(
      models.Transaction transaction) async {
    final db = await database;
    await db.insert(
      'transactions',
      transaction.toMap()..['isSynced'] = 0,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return transaction;
  }

  Future<void> updateTransaction(models.Transaction transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      transaction.toMap()..['isSynced'] = 0,
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Budget Methods
  Future<List<models.Budget>> getBudgets(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'startDate DESC',
    );
    return List.generate(maps.length, (i) => models.Budget.fromMap(maps[i]));
  }

  Future<models.Budget> insertBudget(models.Budget budget) async {
    final db = await database;
    await db.insert(
      'budgets',
      budget.toMap()..['isSynced'] = 0,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return budget;
  }

  Future<void> updateBudget(models.Budget budget) async {
    final db = await database;
    await db.update(
      'budgets',
      budget.toMap()..['isSynced'] = 0,
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<void> deleteBudget(String id) async {
    final db = await database;
    await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Savings Goal Methods
  Future<List<models.SavingsGoal>> getSavingsGoals(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'savings_goals',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'targetDate ASC',
    );
    return List.generate(
        maps.length, (i) => models.SavingsGoal.fromMap(maps[i]));
  }

  Future<models.SavingsGoal> insertSavingsGoal(models.SavingsGoal goal) async {
    final db = await database;
    await db.insert(
      'savings_goals',
      goal.toMap()..['isSynced'] = 0,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return goal;
  }

  Future<void> updateSavingsGoal(models.SavingsGoal goal) async {
    final db = await database;
    await db.update(
      'savings_goals',
      goal.toMap()..['isSynced'] = 0,
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<void> deleteSavingsGoal(String id) async {
    final db = await database;
    await db.delete(
      'savings_goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Sync Methods
  Future<List<Map<String, dynamic>>> getUnsyncedTransactions() async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedBudgets() async {
    final db = await database;
    return await db.query(
      'budgets',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedSavingsGoals() async {
    final db = await database;
    return await db.query(
      'savings_goals',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markAsSynced(String table, String id) async {
    final db = await database;
    await db.update(
      table,
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('budgets');
    await db.delete('savings_goals');
  }
}
