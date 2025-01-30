import 'package:uuid/uuid.dart';

enum SavingsGoalStatus { active, completed, cancelled }

class SavingsGoal {
  final String id;
  final String userId;
  final String name;
  final String description;
  final double targetAmount;
  double currentAmount;
  final DateTime targetDate;
  final DateTime createdAt;
  DateTime? updatedAt;
  SavingsGoalStatus status;

  SavingsGoal({
    String? id,
    required this.userId,
    required this.name,
    required this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    DateTime? createdAt,
    this.updatedAt,
    this.status = SavingsGoalStatus.active,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get progressPercentage => (currentAmount / targetAmount) * 100;

  bool get isCompleted => currentAmount >= targetAmount;

  Duration get remainingTime => targetDate.difference(DateTime.now());

  double get requiredMonthlyContribution {
    if (remainingTime.inDays <= 0) return 0;
    final remainingAmount = targetAmount - currentAmount;
    final remainingMonths = remainingTime.inDays / 30;
    return remainingAmount / remainingMonths;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status.toString(),
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      description: map['description'],
      targetAmount: map['targetAmount'],
      currentAmount: map['currentAmount'],
      targetDate: DateTime.parse(map['targetDate']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      status: SavingsGoalStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
      ),
    );
  }

  SavingsGoal copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    SavingsGoalStatus? status,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}
