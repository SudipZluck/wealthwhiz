import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

enum TransactionType {
  expense,
  income,
}

enum TransactionCategory {
  food,
  shopping,
  entertainment,
  utilities,
  transportation,
  health,
  education,
  salary,
  travel,
  housing,
  investment,
  freelance,
  business,
  gifts,
  other,
}

enum SyncStatus {
  synced,
  pending,
  failed,
}

class Transaction {
  final String id;
  final String userId;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final TransactionCategory category;
  final String description;
  String? receiptUrl;
  final String? note;
  final bool isRecurring;
  final String? recurringId;
  final DateTime createdAt;
  DateTime? updatedAt;
  final String? notes;
  final String? receiptPath;
  final SyncStatus syncStatus;
  final String? goalId;

  Transaction({
    String? id,
    required this.userId,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    required this.description,
    this.receiptUrl,
    this.note,
    this.isRecurring = false,
    this.recurringId,
    DateTime? createdAt,
    this.updatedAt,
    this.notes,
    this.receiptPath,
    this.syncStatus = SyncStatus.pending,
    this.goalId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.name,
      'category': category.name,
      'description': description,
      'receiptUrl': receiptUrl,
      'note': note,
      'isRecurring': isRecurring,
      'recurringId': recurringId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'notes': notes,
      'receiptPath': receiptPath,
      'syncStatus': syncStatus.name,
      'goalId': goalId,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'category': category.name,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'receiptPath': receiptPath,
      'lastModified': FieldValue.serverTimestamp(),
      'goalId': goalId,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      userId: map['userId'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: map['date'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['date'] as int)
          : DateTime.parse(map['date'].toString()),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TransactionCategory.other,
      ),
      description: map['description'] as String,
      receiptUrl: map['receiptUrl'] as String?,
      note: map['note'] as String?,
      isRecurring: map['isRecurring'] is int
          ? (map['isRecurring'] as int) == 1
          : map['isRecurring'] ?? false,
      recurringId: map['recurringId'] as String?,
      createdAt: map['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.parse(map['createdAt'].toString()),
      updatedAt: map['updatedAt'] == null
          ? null
          : map['updatedAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
              : DateTime.parse(map['updatedAt'].toString()),
      notes: map['notes'] as String?,
      receiptPath: map['receiptPath'] as String?,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == (map['syncStatus'] ?? SyncStatus.pending.name),
        orElse: () => SyncStatus.pending,
      ),
      goalId: map['goalId'] as String?,
    );
  }

  factory Transaction.fromFirestore(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      userId: map['userId'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TransactionCategory.other,
      ),
      description: map['description'] as String,
      receiptUrl: map['receiptUrl'] as String?,
      note: map['notes'] as String?,
      isRecurring: map['isRecurring'] ?? false,
      recurringId: map['recurringId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      notes: map['notes'] as String?,
      receiptPath: map['receiptPath'] as String?,
      syncStatus: SyncStatus.synced,
      goalId: map['goalId'] as String?,
    );
  }

  Transaction copyWith({
    String? id,
    String? userId,
    double? amount,
    DateTime? date,
    TransactionType? type,
    TransactionCategory? category,
    String? description,
    String? receiptUrl,
    String? note,
    bool? isRecurring,
    String? recurringId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    String? receiptPath,
    SyncStatus? syncStatus,
    String? goalId,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      note: note ?? this.note,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      receiptPath: receiptPath ?? this.receiptPath,
      syncStatus: syncStatus ?? this.syncStatus,
      goalId: goalId ?? this.goalId,
    );
  }
}
