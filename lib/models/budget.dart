import 'package:uuid/uuid.dart';
import 'transaction.dart';

enum BudgetFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}

class Budget {
  final String id;
  final String userId;
  final TransactionCategory category;
  final String? customCategory; // For "other" category
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final BudgetFrequency frequency;
  final bool isRecurring;
  final String? recurringId;
  final DateTime createdAt;
  DateTime? updatedAt;
  final bool isActive;

  Budget({
    String? id,
    required this.userId,
    required this.category,
    this.customCategory,
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.frequency,
    this.isRecurring = false,
    this.recurringId,
    DateTime? createdAt,
    this.updatedAt,
    this.isActive = true,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'category': category.toString(),
      'customCategory': customCategory,
      'amount': amount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'frequency': frequency.toString(),
      'isRecurring': isRecurring ? 1 : 0,
      'recurringId': recurringId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      userId: map['userId'],
      category: TransactionCategory.values.firstWhere(
        (e) => e.toString() == map['category'],
      ),
      customCategory: map['customCategory'],
      amount: map['amount'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      frequency: BudgetFrequency.values.firstWhere(
        (e) => e.toString() == map['frequency'],
      ),
      isRecurring: map['isRecurring'] == 1,
      recurringId: map['recurringId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      isActive: map['isActive'] == 1,
    );
  }

  Budget copyWith({
    String? id,
    String? userId,
    TransactionCategory? category,
    String? customCategory,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
    BudgetFrequency? frequency,
    bool? isRecurring,
    String? recurringId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      customCategory: customCategory ?? this.customCategory,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      frequency: frequency ?? this.frequency,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
