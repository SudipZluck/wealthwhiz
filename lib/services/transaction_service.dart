import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import '../models/models.dart';

class TransactionService {
  static final TransactionService instance = TransactionService._();
  static Database? _database;
  static const String tableName = 'transactions';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  TransactionService._() {
    // Initialize connectivity listener
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncTransactions();
      }
    });
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'transactions.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $tableName(
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            category TEXT NOT NULL,
            amount REAL NOT NULL,
            date INTEGER NOT NULL,
            notes TEXT,
            receiptPath TEXT,
            syncStatus TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> saveTransaction(Transaction transaction) async {
    final db = await database;
    await db.insert(
      tableName,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Transaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  Future<void> syncTransactions() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final db = await database;
      final List<Map<String, dynamic>> pendingTransactions = await db.query(
        tableName,
        where: 'syncStatus != ?',
        whereArgs: [SyncStatus.synced.name],
      );

      for (final transactionMap in pendingTransactions) {
        final transaction = Transaction.fromMap(transactionMap);

        try {
          await _firestore
              .collection('transactions')
              .doc(transaction.id)
              .set(transaction.toFirestore());

          await db.update(
            tableName,
            {'syncStatus': SyncStatus.synced.name},
            where: 'id = ?',
            whereArgs: [transaction.id],
          );
        } catch (e) {
          await db.update(
            tableName,
            {'syncStatus': SyncStatus.failed.name},
            where: 'id = ?',
            whereArgs: [transaction.id],
          );
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _database?.close();
    _database = null;
  }
}
