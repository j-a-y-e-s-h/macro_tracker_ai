import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_log_model.dart';

final foodLogServiceProvider = StateNotifierProvider<FoodLogService, List<FoodLog>>((ref) {
  return FoodLogService();
});

class FoodLogService extends StateNotifier<List<FoodLog>> {
  FoodLogService() : super([]) {
    _loadLogs();
  }

  static const String _logsKey = 'food_logs';

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getStringList(_logsKey) ?? [];
    state = logsJson
        .map((e) => FoodLog.fromJson(jsonDecode(e)))
        .toList();
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = state.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_logsKey, logsJson);
  }

  Future<void> addLog(FoodLog log) async {
    state = [...state, log];
    await _saveLogs();
  }

  Future<void> deleteLog(String id) async {
    state = state.where((l) => l.id != id).toList();
    await _saveLogs();
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
