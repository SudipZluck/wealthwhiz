import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart' as models;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class DatabaseService {
  static Database? _database;
  static const String dbName = 'wealthwhiz.db';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    await _upgradeDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), dbName);
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE transactions ADD COLUMN notes TEXT');
        }
        if (oldVersion < 3) {
          await db
              .execute('ALTER TABLE transactions ADD COLUMN receiptPath TEXT');
        }
      },
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
        notes TEXT,
        receiptPath TEXT,
        isRecurring INTEGER NOT NULL DEFAULT 0,
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
        isRecurring INTEGER NOT NULL DEFAULT 0,
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

  Future<void> _upgradeDatabase() async {
    final db = await database;

    var tableInfo = await db.rawQuery('PRAGMA table_info(transactions)');

    // Check for notes column
    bool hasNotesColumn = tableInfo.any((column) => column['name'] == 'notes');
    if (!hasNotesColumn) {
      await db.execute('ALTER TABLE transactions ADD COLUMN notes TEXT');
    }

    // Check for receiptPath column
    bool hasReceiptPathColumn =
        tableInfo.any((column) => column['name'] == 'receiptPath');
    if (!hasReceiptPathColumn) {
      await db.execute('ALTER TABLE transactions ADD COLUMN receiptPath TEXT');
    }
  }

  // Transaction Methods
  Future<List<models.Transaction>> getTransactions(String userId) async {
    print('getTransactions called with userId: $userId');
    try {
      print('Starting to fetch transactions for user: $userId'); // Debug log

      // Get transactions from Firestore
      final firestoreSnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      print(
          'Found ${firestoreSnapshot.docs.length} transactions in Firestore for user: $userId'); // Debug log
      firestoreSnapshot.docs.forEach((doc) {
        print(
            'Firestore transaction: ${doc.id} - ${doc.data()}'); // Debug each transaction
      });

      final firestoreTransactions = firestoreSnapshot.docs.map((doc) {
        final data = doc.data();

        // Convert Timestamp to DateTime if needed
        if (data['date'] is Timestamp) {
          data['date'] = (data['date'] as Timestamp).toDate().toIso8601String();
        }
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data['updatedAt'] is Timestamp) {
          data['updatedAt'] =
              (data['updatedAt'] as Timestamp).toDate().toIso8601String();
        }

        final transaction = models.Transaction.fromMap({
          'id': doc.id,
          ...data,
        });
        print(
            'Processed transaction: ${transaction.description} - ${transaction.amount} - ${transaction.userId}'); // Debug processed transaction
        return transaction;
      }).toList();

      // Get local transactions
      final db = await database;
      final List<Map<String, dynamic>> localTransactions = await db.query(
        'transactions',
        where: 'userId = ? AND isSynced = ?',
        whereArgs: [userId, 0],
      );

      print(
          'Found ${localTransactions.length} local transactions for user: $userId'); // Debug log

      // Combine both lists
      final allTransactions = [
        ...firestoreTransactions,
        ...localTransactions.map((t) => models.Transaction.fromMap(t)),
      ]..sort(
          (a, b) => b.date.compareTo(a.date)); // Sort by date (newest first)

      print(
          'Total transactions for user $userId: ${allTransactions.length}'); // Debug final count
      allTransactions.forEach((t) => print(
          'Final transaction: ${t.description} - ${t.amount} - ${t.userId}')); // Debug each transaction

      return allTransactions;
    } catch (e, stackTrace) {
      print('Error fetching transactions: $e'); // Debug log error
      print('Stack trace: $stackTrace'); // Debug log stack trace
      rethrow;
    }
  }

  Future<(models.Transaction, bool)> insertTransaction(
      models.Transaction transaction) async {
    try {
      // Get current user ID
      final currentUser = FirebaseService().currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      print(
          'Starting to save transaction for user: ${currentUser.id}'); // Debug log

      // Create transaction data with user ID and timestamps
      final transactionData = {
        'userId': currentUser.id,
        'amount': transaction.amount,
        'date': transaction.date.toIso8601String(),
        'type': transaction.type.toString().split('.').last.toLowerCase(),
        'category':
            transaction.category.toString().split('.').last.toLowerCase(),
        'description': transaction.description,
        'notes': transaction.notes ?? '',
        'receiptPath': transaction.receiptPath ?? '',
        'isRecurring': transaction.isRecurring ? 1 : 0,
        'recurringId': transaction.recurringId ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      print('Prepared transaction data: $transactionData'); // Debug log

      // Save to Firestore
      final docRef =
          await _firestore.collection('transactions').add(transactionData);
      print('Saved to Firestore with ID: ${docRef.id}'); // Debug log

      // Add Firestore document ID to transaction data
      final completeTransactionData = {
        ...transactionData,
        'id': docRef.id,
        'isSynced': 1,
      };

      // Save to local SQLite database
      final db = await database;
      try {
        await db.insert(
          'transactions',
          completeTransactionData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('Saved to local database successfully'); // Debug log
      } catch (dbError) {
        print('Error inserting into local database: $dbError');
        // Print the table schema for debugging
        final tableInfo = await db.rawQuery('PRAGMA table_info(transactions)');
        print('Table schema: $tableInfo');
        rethrow;
      }

      return (models.Transaction.fromMap(completeTransactionData), true);
    } catch (e, stackTrace) {
      print('Error saving transaction: $e'); // Debug log
      print('Stack trace: $stackTrace'); // Debug log

      // If Firestore fails, save to local database only
      try {
        final currentUser = FirebaseService().currentUser;
        if (currentUser == null) {
          throw Exception('No user logged in');
        }

        // Create local-only transaction data
        final localTransactionData = {
          'userId': currentUser.id,
          'amount': transaction.amount,
          'date': transaction.date.toIso8601String(),
          'type': transaction.type.toString().split('.').last.toLowerCase(),
          'category':
              transaction.category.toString().split('.').last.toLowerCase(),
          'description': transaction.description,
          'notes': transaction.notes ?? '',
          'receiptPath': transaction.receiptPath ?? '',
          'isRecurring': transaction.isRecurring ? 1 : 0,
          'recurringId': transaction.recurringId ?? '',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'isSynced': 0,
        };

        final db = await database;
        await db.insert(
          'transactions',
          localTransactionData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        return (models.Transaction.fromMap(localTransactionData), false);
      } catch (localError) {
        print('Error saving to local database: $localError');
        rethrow;
      }
    }
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
