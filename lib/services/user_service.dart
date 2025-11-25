import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'tdee_calculator.dart';

final userServiceProvider = StateNotifierProvider<UserService, UserModel?>((ref) {
  return UserService();
});

class UserService extends StateNotifier<UserModel?> {
  UserService() : super(null) {
    _loadUser();
  }

  static const String _userKey = 'user_data';

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      state = UserModel.fromJson(jsonDecode(userJson));
    }
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    state = user;
  }

  Future<void> updateUserStats({
    required int age,
    required String gender,
    required double weight,
    required double height,
    required String activityLevel,
    required String goal,
  }) async {
    // Calculate new TDEE and Macros
    final bmr = TdeeCalculator.calculateBMR(weight: weight, height: height, age: age, gender: gender);
    final tdee = TdeeCalculator.calculateTDEE(bmr, activityLevel);
    final targetCalories = TdeeCalculator.calculateTargetCalories(tdee, goal);
    final macros = TdeeCalculator.calculateMacros(targetCalories, weight);

    final updatedUser = state?.copyWith(
      age: age,
      gender: gender,
      weight: weight,
      height: height,
      activityLevel: activityLevel,
      goal: goal,
      tdee: targetCalories,
      proteinTarget: macros['protein']!,
      carbTarget: macros['carbs']!,
      fatTarget: macros['fat']!,
    ) ?? UserModel(
      id: 'local_user', // Default ID for local-first
      email: '',
      name: 'User',
      age: age,
      gender: gender,
      weight: weight,
      height: height,
      activityLevel: activityLevel,
      goal: goal,
      tdee: targetCalories,
      proteinTarget: macros['protein']!,
      carbTarget: macros['carbs']!,
      fatTarget: macros['fat']!,
    );

    await saveUser(updatedUser);
  }
  
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    state = null;
  }
}
