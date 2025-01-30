import 'package:uuid/uuid.dart';
import 'transaction.dart';

class Budget {
  final String id;
  final String userId;
  final TransactionCategory category;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isRecurring;
  final String? recurringId;
  final DateTime createdAt;
  DateTime? updatedAt;

  Budget({
    String? id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.isRecurring = false,
    this.recurringId,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'category': category.toString(),
      'amount': amount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isRecurring': isRecurring,
      'recurringId': recurringId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      userId: map['userId'],
      category: TransactionCategory.values.firstWhere(
        (e) => e.toString() == map['category'],
      ),
      amount: map['amount'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      isRecurring: map['isRecurring'] ?? false,
      recurringId: map['recurringId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Budget copyWith({
    String? id,
    String? userId,
    TransactionCategory? category,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isRecurring,
    String? recurringId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
