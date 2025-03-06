import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/goal.dart';
import 'firebase_service.dart';

class GoalService {
  static const String _goalsKey = 'goals';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  Future<List<Goal>> getGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getStringList(_goalsKey) ?? [];
    return goalsJson.map((json) => Goal.fromMap(jsonDecode(json))).toList();
  }

  Future<void> addGoal(Goal goal) async {
    final prefs = await SharedPreferences.getInstance();
    final goals = await getGoals();
    goals.add(goal);
    await _saveGoals(goals, prefs);
    await _syncWithFirestore();
  }

  Future<void> updateGoal(Goal goal) async {
    final prefs = await SharedPreferences.getInstance();
    final goals = await getGoals();
    final index = goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      goals[index] = goal;
      await _saveGoals(goals, prefs);
      await _syncWithFirestore();
    }
  }

  Future<void> deleteGoal(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    final goals = await getGoals();
    goals.removeWhere((goal) => goal.id == goalId);
    await _saveGoals(goals, prefs);
    await _syncWithFirestore();
  }

  Future<void> _saveGoals(List<Goal> goals, SharedPreferences prefs) async {
    final goalsJson = goals.map((goal) => jsonEncode(goal.toMap())).toList();
    await prefs.setStringList(_goalsKey, goalsJson);
  }

  Future<void> _syncWithFirestore() async {
    try {
      final currentUser = await _firebaseService.getCurrentUser();
      if (currentUser == null) return;

      final goals = await getGoals();
      final batch = _firestore.batch();
      final goalsCollection = _firestore.collection('goals');

      // Upload unsynced goals
      for (var goal in goals.where((g) => !g.isSynced)) {
        final docRef = goalsCollection.doc(goal.id);
        batch.set(docRef, goal.toFirestore());
      }

      await batch.commit();

      // Mark goals as synced
      final syncedGoals =
          goals.map((goal) => goal.copyWith(isSynced: true)).toList();
      final prefs = await SharedPreferences.getInstance();
      await _saveGoals(syncedGoals, prefs);

      // Fetch and merge remote goals
      final snapshot = await goalsCollection
          .where('userId', isEqualTo: currentUser.id)
          .get();

      final remoteGoals =
          snapshot.docs.map((doc) => Goal.fromFirestore(doc)).toList();
      await _mergeRemoteGoals(remoteGoals);
    } catch (e) {
      print('Error syncing with Firestore: $e');
    }
  }

  Future<void> _mergeRemoteGoals(List<Goal> remoteGoals) async {
    final localGoals = await getGoals();
    final mergedGoals = <Goal>[];
    final seenIds = <String>{};

    // Add all local goals
    for (var local in localGoals) {
      seenIds.add(local.id);
      mergedGoals.add(local);
    }

    // Add remote goals that don't exist locally
    for (var remote in remoteGoals) {
      if (!seenIds.contains(remote.id)) {
        mergedGoals.add(remote.copyWith(isSynced: true));
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await _saveGoals(mergedGoals, prefs);
  }

  Future<void> updateGoalProgress(String goalId, double amount) async {
    final goals = await getGoals();
    final index = goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      final goal = goals[index];
      final newAmount = goal.currentAmount + amount;
      final isCompleted = newAmount >= goal.targetAmount;

      final updatedGoal = goal.copyWith(
        currentAmount: newAmount,
        isCompleted: isCompleted,
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      goals[index] = updatedGoal;
      final prefs = await SharedPreferences.getInstance();
      await _saveGoals(goals, prefs);
      await _syncWithFirestore();
    }
  }
}
