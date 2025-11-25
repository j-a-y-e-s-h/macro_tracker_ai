import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_plan_model.dart';

final mealPlannerServiceProvider = StateNotifierProvider<MealPlannerService, List<MealPlan>>((ref) {
  return MealPlannerService();
});

class MealPlannerService extends StateNotifier<List<MealPlan>> {
  MealPlannerService() : super([]) {
    _loadPlans();
  }

  static const _storageKey = 'meal_plans';

  Future<void> _loadPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      state = jsonList.map((e) => MealPlan.fromJson(e)).toList();
    }
  }

  Future<void> _savePlans() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<void> savePlan(MealPlan plan) async {
    // Remove existing plan with same ID if any
    state = [
      ...state.where((p) => p.id != plan.id),
      plan
    ];
    await _savePlans();
  }

  Future<void> deletePlan(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _savePlans();
  }
  
  MealPlan? getCurrentPlan() {
    if (state.isEmpty) return null;
    // Simple logic: return the last created plan for now
    return state.last;
  }
}
