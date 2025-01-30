import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class BudgetService {
  static final BudgetService _instance = BudgetService._();
  static Database? _database;
  static const String tableName = 'budgets';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSyncing = false;

  factory BudgetService() => _instance;

  BudgetService._();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'budgets.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $tableName(
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            category TEXT NOT NULL,
            customCategory TEXT,
            amount REAL NOT NULL,
            startDate TEXT NOT NULL,
            endDate TEXT NOT NULL,
            frequency TEXT NOT NULL,
            isRecurring INTEGER NOT NULL DEFAULT 0,
            recurringId TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT,
            isActive INTEGER NOT NULL DEFAULT 1,
            isSynced INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<List<Budget>> getBudgets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  Future<Budget> saveBudget(Budget budget) async {
    final db = await database;
    await db.insert(
      tableName,
      {
        ...budget.toMap(),
        'isSynced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _syncBudgets(); // Trigger sync
    return budget;
  }

  Future<void> updateBudget(Budget budget) async {
    final db = await database;
    await db.update(
      tableName,
      {
        ...budget.toMap(),
        'isSynced': 0,
      },
      where: 'id = ?',
      whereArgs: [budget.id],
    );
    _syncBudgets(); // Trigger sync
  }

  Future<void> deleteBudget(String id) async {
    final db = await database;
    await db.update(
      tableName,
      {
        'isActive': 0,
        'isSynced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _syncBudgets(); // Trigger sync
  }

  Future<void> _syncBudgets() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final db = await database;
      final List<Map<String, dynamic>> unsyncedBudgets = await db.query(
        tableName,
        where: 'isSynced = ?',
        whereArgs: [0],
      );

      for (final budgetMap in unsyncedBudgets) {
        try {
          final budget = Budget.fromMap(budgetMap);
          await _firestore
              .collection('budgets')
              .doc(budget.id)
              .set(budget.toMap());

          await db.update(
            tableName,
            {'isSynced': 1},
            where: 'id = ?',
            whereArgs: [budget.id],
          );
        } catch (e) {
          print('Failed to sync budget ${budgetMap['id']}: $e');
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> dispose() async {
    await _database?.close();
    _database = null;
  }
}
