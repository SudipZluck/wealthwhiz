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
      version: 2,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $tableName(
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            type TEXT NOT NULL,
            category TEXT NOT NULL,
            amount REAL NOT NULL,
            date INTEGER NOT NULL,
            description TEXT NOT NULL,
            receiptUrl TEXT,
            note TEXT,
            isRecurring INTEGER NOT NULL,
            recurringId TEXT,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER,
            notes TEXT,
            receiptPath TEXT,
            syncStatus TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          // Drop the old table and create new one
          await db.execute('DROP TABLE IF EXISTS $tableName');
          await db.execute('''
            CREATE TABLE $tableName(
              id TEXT PRIMARY KEY,
              userId TEXT NOT NULL,
              type TEXT NOT NULL,
              category TEXT NOT NULL,
              amount REAL NOT NULL,
              date INTEGER NOT NULL,
              description TEXT NOT NULL,
              receiptUrl TEXT,
              note TEXT,
              isRecurring INTEGER NOT NULL,
              recurringId TEXT,
              createdAt INTEGER NOT NULL,
              updatedAt INTEGER,
              notes TEXT,
              receiptPath TEXT,
              syncStatus TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<void> saveTransaction(Transaction transaction) async {
    final db = await database;
    final Map<String, dynamic> data = {
      'id': transaction.id,
      'userId': transaction.userId,
      'type': transaction.type.name,
      'category': transaction.category.name,
      'amount': transaction.amount,
      'date': transaction.date.millisecondsSinceEpoch,
      'description': transaction.description,
      'receiptUrl': transaction.receiptUrl,
      'note': transaction.note,
      'isRecurring': transaction.isRecurring ? 1 : 0,
      'recurringId': transaction.recurringId,
      'createdAt': transaction.createdAt.millisecondsSinceEpoch,
      'updatedAt': transaction.updatedAt?.millisecondsSinceEpoch,
      'notes': transaction.notes,
      'receiptPath': transaction.receiptPath,
      'syncStatus': transaction.syncStatus.name,
    };
    print('saveTransaction: Saving data - $data');
    await db.insert(
      tableName,
      data,
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
    return List.generate(maps.length, (i) {
      final map = maps[i];
      return Transaction(
        id: map['id'] as String,
        userId: map['userId'] as String,
        type: TransactionType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => TransactionType.expense,
        ),
        category: TransactionCategory.values.firstWhere(
          (e) => e.name == map['category'],
          orElse: () => TransactionCategory.other,
        ),
        amount: map['amount'] as double,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        description: map['description'] as String,
        receiptUrl: map['receiptUrl'] as String?,
        note: map['note'] as String?,
        isRecurring: (map['isRecurring'] as int) == 1,
        recurringId: map['recurringId'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        updatedAt: map['updatedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
            : null,
        notes: map['notes'] as String?,
        receiptPath: map['receiptPath'] as String?,
        syncStatus: SyncStatus.values.firstWhere(
          (e) => e.name == (map['syncStatus'] ?? SyncStatus.pending.name),
          orElse: () => SyncStatus.pending,
        ),
      );
    });
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
