import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/weight_log_model.dart';

final weightServiceProvider = StateNotifierProvider<WeightService, List<WeightLog>>((ref) {
  return WeightService();
});

class WeightService extends StateNotifier<List<WeightLog>> {
  WeightService() : super([]) {
    _loadLogs();
  }

  static const _storageKey = 'weight_logs';

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      state = jsonList.map((e) => WeightLog.fromJson(e)).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
    }
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<void> addLog(WeightLog log) async {
    state = [log, ...state]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await _saveLogs();
  }

  Future<void> deleteLog(String id) async {
    state = state.where((log) => log.id != id).toList();
    await _saveLogs();
  }
  
  // Get latest weight
  double? get currentWeight => state.isNotEmpty ? state.first.weight : null;
}
