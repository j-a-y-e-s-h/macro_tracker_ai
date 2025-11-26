import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<bool> loadFromFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // Ensure all required fields are present or provide defaults
        final user = UserModel(
          id: uid,
          email: data['email'] ?? '',
          name: data['name'] ?? 'User',
          age: data['age'] ?? 25,
          gender: data['gender'] ?? 'Male',
          weight: (data['weight'] ?? 70).toDouble(),
          height: (data['height'] ?? 175).toDouble(),
          activityLevel: data['activityLevel'] ?? 'Moderate',
          goal: data['goal'] ?? 'Maintain',
          tdee: (data['tdee'] ?? 2000).toDouble(),
          proteinTarget: (data['proteinTarget'] ?? 150).toDouble(),
          carbTarget: (data['carbTarget'] ?? 200).toDouble(),
          fatTarget: (data['fatTarget'] ?? 60).toDouble(),
        );
        await saveUser(user); // Save to local prefs for next time
        return true;
      } else {
        // User not found in Firestore, ensure local state is clear
        state = null;
      }
    } catch (e) {
      debugPrint('Error loading user from Firestore: $e');
      state = null;
    }
    return false;
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
