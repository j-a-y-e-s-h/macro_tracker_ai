import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/food_log_model.dart';
import 'auth_service.dart';

final foodLogServiceProvider = StateNotifierProvider<FoodLogService, List<FoodLog>>((ref) {
  return FoodLogService(ref);
});

class FoodLogService extends StateNotifier<List<FoodLog>> {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  FoodLogService(this._ref) : super([]) {
    _init();
  }

  void _init() {
    // Listen to auth changes
    _ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      next.whenData((user) async {
        if (user != null) {
          await _syncLocalLogsToFirestore(user.uid);
          _subscribeToFirestore(user.uid);
        } else {
          _loadLocalLogs();
        }
      });
    });
    
    // Initial check
    final user = _ref.read(authServiceProvider).currentUser;
    if (user != null) {
      _syncLocalLogsToFirestore(user.uid).then((_) => _subscribeToFirestore(user.uid));
    } else {
      _loadLocalLogs();
    }
  }

  Future<void> _syncLocalLogsToFirestore(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getStringList(_logsKey) ?? [];
    if (logsJson.isEmpty) return;

    final batch = _firestore.batch();
    final logs = logsJson.map((e) => FoodLog.fromJson(jsonDecode(e))).toList();
    
    for (var log in logs) {
      final docRef = _firestore.collection('users').doc(userId).collection('food_logs').doc(log.id);
      batch.set(docRef, {
        ...log.toJson(),
        'timestamp': Timestamp.fromDate(log.timestamp),
      });
    }

    try {
      await batch.commit();
      // Clear local logs after successful sync
      await prefs.remove(_logsKey);
      debugPrint('Synced ${logs.length} local logs to Firestore');
    } catch (e) {
      debugPrint('Error syncing local logs: $e');
    }
  }

  void _subscribeToFirestore(String userId) {
    _firestore
        .collection('users')
        .doc(userId)
        .collection('food_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs.map((doc) {
        final data = doc.data();
        // Handle timestamp conversion from Firestore Timestamp to DateTime
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
        }
        return FoodLog.fromJson({...data, 'id': doc.id});
      }).toList();
    });
  }

  static const String _logsKey = 'food_logs';

  Future<void> _loadLocalLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getStringList(_logsKey) ?? [];
    state = logsJson
        .map((e) => FoodLog.fromJson(jsonDecode(e)))
        .toList();
  }

  Future<void> _saveLocalLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = state.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_logsKey, logsJson);
  }

  Future<void> addLog(FoodLog log) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('food_logs')
          .doc(log.id)
          .set({
            ...log.toJson(),
            'timestamp': Timestamp.fromDate(log.timestamp), // Save as Timestamp
          });
    } else {
      state = [...state, log];
      await _saveLocalLogs();
    }
  }

  Future<void> deleteLog(String id) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('food_logs')
          .doc(id)
          .delete();
    } else {
      state = state.where((l) => l.id != id).toList();
      await _saveLocalLogs();
    }
  }

  Future<void> clearAllData() async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user != null) {
      final batch = _firestore.batch();
      final snapshots = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('food_logs')
          .get();
      
      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } else {
      state = [];
      await _saveLocalLogs();
    }
  }

  List<FoodLog> getLogsForDate(DateTime date) {
    return state.where((log) {
      return log.timestamp.year == date.year &&
             log.timestamp.month == date.month &&
             log.timestamp.day == date.day;
    }).toList();
  }

  Map<String, double> getDailyTotals(DateTime date) {
    final logs = getLogsForDate(date);
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (var log in logs) {
      calories += log.calories;
      protein += log.protein;
      carbs += log.carbs;
      fat += log.fat;
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  List<FoodLog> getRecentLogs() {
    // Return unique food items based on name, sorted by most recent
    final uniqueNames = <String>{};
    final recentLogs = <FoodLog>[];
    
    // Iterate in reverse to get most recent first
    for (var i = state.length - 1; i >= 0; i--) {
      final log = state[i];
      if (!uniqueNames.contains(log.name)) {
        uniqueNames.add(log.name);
        recentLogs.add(log);
      }
      if (recentLogs.length >= 20) break; // Limit to 20 items
    }
    
    return recentLogs;
  }
}
