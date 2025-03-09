import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/models.dart';
import 'services.dart';

class FinancialService {
  static final FinancialService instance = FinancialService._internal();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseService _firebaseService = FirebaseService();

  FinancialService._internal();

  // Add a transaction and associate it with a goal
  Future<void> addGoalTransaction(
      Transaction transaction, String goalId) async {
    final currentUser = _firebaseService.currentUser;
    if (currentUser == null) throw Exception('No user logged in');

    // Get the goal
    final goals = await _databaseService.getSavingsGoals(currentUser.id);
    final goal = goals.firstWhere(
      (g) => g.id == goalId,
      orElse: () => throw Exception('Goal not found'),
    );

    if (goal.isCompleted) {
      throw Exception('Cannot add transaction to completed goal');
    }

    // Add the transaction with goal reference
    final transactionWithGoal = transaction.copyWith(
      goalId: goalId,
      notes: '${transaction.notes ?? ''}\nGoal: ${goal.name}',
    );
    await _databaseService.insertTransaction(transactionWithGoal);

    // Update goal progress
    if (transaction.type == TransactionType.expense) {
      final updatedGoal = goal.copyWith(
        currentAmount: goal.currentAmount + transaction.amount,
      );
      await _databaseService.updateSavingsGoal(updatedGoal);
    }
  }

  // Get transactions for a specific goal
  Future<List<Transaction>> getGoalTransactions(String goalId) async {
    final currentUser = _firebaseService.currentUser;
    if (currentUser == null) throw Exception('No user logged in');

    final transactions = await _databaseService.getTransactions(currentUser.id);
    return transactions.where((t) => t.goalId == goalId).toList();
  }

  // Get goal summary including transactions
  Future<Map<String, dynamic>> getGoalSummary(String goalId) async {
    final currentUser = _firebaseService.currentUser;
    if (currentUser == null) throw Exception('No user logged in');

    final goals = await _databaseService.getSavingsGoals(currentUser.id);
    final goal = goals.firstWhere(
      (g) => g.id == goalId,
      orElse: () => throw Exception('Goal not found'),
    );

    final goalTransactions = await getGoalTransactions(goalId);

    final totalSpent = goalTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalContributed = goalTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    return {
      'goal': {
        'id': goal.id,
        'name': goal.name,
        'targetAmount': goal.targetAmount,
        'currentAmount': goal.currentAmount,
        'progress': (goal.currentAmount / goal.targetAmount * 100),
        'isCompleted': goal.isCompleted,
      },
      'transactions': {
        'all': goalTransactions,
        'totalSpent': totalSpent,
        'totalContributed': totalContributed,
        'netContribution': totalContributed - totalSpent,
      },
      'remaining': goal.targetAmount - goal.currentAmount,
      'recentTransactions': goalTransactions
          .take(5)
          .map((t) => {
                'id': t.id,
                'amount': t.amount,
                'type': t.type.toString(),
                'description': t.description,
                'date': t.date.toIso8601String(),
              })
          .toList(),
    };
  }

  // Get monthly summary of all financial data
  Future<Map<String, dynamic>> getMonthlyFinancialSummary() async {
    final currentUser = _firebaseService.currentUser;
    if (currentUser == null) throw Exception('No user logged in');

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);

    final transactions = await _databaseService.getTransactions(currentUser.id);
    final budgets = await _databaseService.getBudgets(currentUser.id);
    final goals = await _databaseService.getSavingsGoals(currentUser.id);

    // Filter transactions for current month
    final monthlyTransactions = transactions
        .where((t) =>
            t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            t.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    // Calculate income and expenses
    final totalIncome = monthlyTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpenses = monthlyTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Calculate budget progress
    final budgetProgress = <String, Map<String, dynamic>>{};
    for (var budget in budgets) {
      final spent = monthlyTransactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.category.toString() == budget.category.toString())
          .fold(0.0, (sum, t) => sum + t.amount);

      budgetProgress[budget.category.toString().split('.').last] = {
        'budget': budget.amount,
        'spent': spent,
        'remaining': budget.amount - spent,
        'percentage': spent / budget.amount * 100,
      };
    }

    // Calculate savings and goal progress
    final monthlySavings = totalIncome - totalExpenses;
    final goalProgress = <String, Map<String, dynamic>>{};
    for (var goal in goals) {
      final goalTransactions =
          monthlyTransactions.where((t) => t.goalId == goal.id);
      final goalSpent = goalTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
      final goalContributed = goalTransactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);

      final progress = goal.currentAmount / goal.targetAmount * 100;
      goalProgress[goal.id] = {
        'name': goal.name,
        'targetAmount': goal.targetAmount,
        'currentAmount': goal.currentAmount,
        'progress': progress,
        'remainingAmount': goal.targetAmount - goal.currentAmount,
        'isCompleted': goal.isCompleted,
        'monthlySpent': goalSpent,
        'monthlyContributed': goalContributed,
        'monthlyNet': goalContributed - goalSpent,
      };
    }

    return {
      'summary': {
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'monthlySavings': monthlySavings,
        'savingsRate':
            totalIncome > 0 ? (monthlySavings / totalIncome * 100) : 0,
      },
      'budgets': budgetProgress,
      'goals': goalProgress,
      'transactions': monthlyTransactions,
    };
  }

  // Add a new transaction and update related components
  Future<void> addTransaction(Transaction transaction) async {
    final currentUser = _firebaseService.currentUser;
    if (currentUser == null) throw Exception('No user logged in');

    // Add the transaction
    await _databaseService.insertTransaction(transaction);

    // Handle expense transaction
    if (transaction.type == TransactionType.expense) {
      await _handleExpenseTransaction(transaction);
    }
    // Handle income transaction
    else if (transaction.type == TransactionType.income) {
      await _handleIncomeTransaction(transaction);
    }
  }

  Future<void> _handleExpenseTransaction(Transaction transaction) async {
    final currentUser = _firebaseService.currentUser;
    if (currentUser == null) return;

    final budgets = await _databaseService.getBudgets(currentUser.id);
    final relevantBudget = budgets.firstWhere(
      (b) => b.category == transaction.category.toString().split('.').last,
      orElse: () => throw Exception('No budget found for this category'),
    );

    // Check if over budget and notify
    final summary = await getMonthlyFinancialSummary();
    final budgetData =
        summary['budgets'][relevantBudget.category] as Map<String, dynamic>;
    final spent = budgetData['spent'] as double;

    if (spent > relevantBudget.amount) {
      // TODO: Implement notification system
      print('Warning: Over budget for ${relevantBudget.category}');
    }
  }

  Future<void> _handleIncomeTransaction(Transaction transaction) async {
    final currentUser = _firebaseService.currentUser;
    if (currentUser == null) return;

    final summary = await getMonthlyFinancialSummary();
    final totalIncome = summary['summary']['totalIncome'] as double;
    final totalExpenses = summary['summary']['totalExpenses'] as double;
    final excessIncome = totalIncome - totalExpenses;

    // Only allocate if there's excess income
    if (excessIncome > 0) {
      await _allocateExcessToGoals(excessIncome);
    }
  }

  Future<void> _allocateExcessToGoals(double excessAmount) async {
    final currentUser = _firebaseService.currentUser;
    if (currentUser == null) return;

    final goals = await _databaseService.getSavingsGoals(currentUser.id);
    final activeGoals = goals.where((g) => !g.isCompleted).toList();

    if (activeGoals.isEmpty) return;

    // Calculate priority and allocation for each goal
    final goalAllocations =
        _calculateGoalAllocations(activeGoals, excessAmount);

    // Apply allocations to goals
    for (final allocation in goalAllocations.entries) {
      final goal = allocation.key;
      final amount = allocation.value;

      if (amount <= 0) continue;

      // Create a transaction for the goal contribution
      final goalTransaction = Transaction(
        userId: currentUser.id,
        amount: amount,
        date: DateTime.now(),
        type: TransactionType.expense,
        category: TransactionCategory.investment,
        description: 'Automatic contribution to: ${goal.name}',
        notes: 'Automatic allocation from excess income',
        goalId: goal.id,
      );

      await addGoalTransaction(goalTransaction, goal.id);
    }
  }

  Map<SavingsGoal, double> _calculateGoalAllocations(
      List<SavingsGoal> goals, double totalAmount) {
    final allocations = <SavingsGoal, double>{};

    // Calculate priority scores for each goal
    final priorityScores = goals.map((goal) {
      final remainingAmount = goal.targetAmount - goal.currentAmount;
      final daysToTarget = goal.targetDate.difference(DateTime.now()).inDays;
      // Higher score means higher priority
      final priorityScore =
          daysToTarget > 0 ? remainingAmount / daysToTarget : double.infinity;
      return MapEntry(goal, priorityScore);
    }).toList();

    // Sort goals by priority (highest priority first)
    priorityScores.sort((a, b) => b.value.compareTo(a.value));

    // Calculate base allocation (divide equally among goals)
    var remainingAmount = totalAmount;
    final baseAllocation = totalAmount / goals.length;

    // First pass: Allocate base amount or remaining needed amount, whichever is smaller
    for (final entry in priorityScores) {
      final goal = entry.key;
      final remainingNeeded = goal.targetAmount - goal.currentAmount;
      final allocation =
          remainingNeeded < baseAllocation ? remainingNeeded : baseAllocation;

      if (allocation > 0 && allocation <= remainingAmount) {
        allocations[goal] = allocation;
        remainingAmount -= allocation;
      }
    }

    // Second pass: Distribute remaining amount to goals that still need more
    if (remainingAmount > 0) {
      for (final entry in priorityScores) {
        final goal = entry.key;
        final currentAllocation = allocations[goal] ?? 0;
        final remainingNeeded =
            goal.targetAmount - goal.currentAmount - currentAllocation;

        if (remainingNeeded > 0) {
          final additionalAllocation = remainingNeeded < remainingAmount
              ? remainingNeeded
              : remainingAmount;
          allocations[goal] = (allocations[goal] ?? 0) + additionalAllocation;
          remainingAmount -= additionalAllocation;

          if (remainingAmount <= 0) break;
        }
      }
    }

    return allocations;
  }

  // Get budget recommendations based on income and goals
  Future<Map<String, double>> getBudgetRecommendations() async {
    final currentUser = _firebaseService.currentUser;
    if (currentUser == null) throw Exception('No user logged in');

    final summary = await getMonthlyFinancialSummary();
    final monthlyIncome = summary['summary']['totalIncome'] as double;

    // Basic budget allocation percentages
    const recommendations = {
      'housing': 0.30, // 30% for housing
      'food': 0.15, // 15% for food
      'transportation': 0.10, // 10% for transportation
      'utilities': 0.10, // 10% for utilities
      'savings': 0.20, // 20% for savings
      'entertainment': 0.05, // 5% for entertainment
      'health': 0.05, // 5% for health
      'other': 0.05, // 5% for miscellaneous
    };

    // Calculate recommended amounts based on income
    return Map.fromEntries(
      recommendations.entries.map(
        (e) => MapEntry(e.key, monthlyIncome * e.value),
      ),
    );
  }

  // Check if financial goals are realistic based on income and expenses
  Future<Map<String, dynamic>> analyzeGoalsFeasibility() async {
    final currentUser = _firebaseService.currentUser;
    if (currentUser == null) throw Exception('No user logged in');

    final summary = await getMonthlyFinancialSummary();
    final monthlySavings = summary['summary']['monthlySavings'] as double;
    final goals = await _databaseService.getSavingsGoals(currentUser.id);

    final analysis = <String, dynamic>{};
    for (var goal in goals) {
      if (goal.isCompleted) continue;

      final monthsToGoal =
          goal.targetDate.difference(DateTime.now()).inDays / 30;
      final requiredMonthlySavings =
          (goal.targetAmount - goal.currentAmount) / monthsToGoal;

      analysis[goal.id] = {
        'name': goal.name,
        'isFeasible': monthlySavings >= requiredMonthlySavings,
        'requiredMonthlySavings': requiredMonthlySavings,
        'currentMonthlySavings': monthlySavings,
        'monthsToGoal': monthsToGoal,
        'suggestions': _getSuggestions(
          requiredSavings: requiredMonthlySavings,
          currentSavings: monthlySavings,
        ),
      };
    }

    return analysis;
  }

  List<String> _getSuggestions({
    required double requiredSavings,
    required double currentSavings,
  }) {
    final suggestions = <String>[];
    if (currentSavings < requiredSavings) {
      final deficit = requiredSavings - currentSavings;
      suggestions.add(
          'Need to increase monthly savings by ${deficit.toStringAsFixed(2)}');
      suggestions.add('Consider reducing non-essential expenses');
      suggestions.add('Look for additional income sources');
    } else {
      suggestions.add('Current savings rate is sufficient for this goal');
      suggestions.add('Consider investing excess savings');
    }
    return suggestions;
  }
}
