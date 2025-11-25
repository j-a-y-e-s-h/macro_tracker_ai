
class TdeeCalculator {
  /// Calculates BMR using Mifflin-St Jeor Equation
  static double calculateBMR({
    required double weight, // kg
    required double height, // cm
    required int age,
    required String gender,
  }) {
    double s = gender == 'male' ? 5 : -161;
    return (10 * weight) + (6.25 * height) - (5 * age) + s;
  }

  /// Calculates TDEE based on Activity Level
  static double calculateTDEE(double bmr, String activityLevel) {
    switch (activityLevel) {
      case 'sedentary':
        return bmr * 1.2;
      case 'light':
        return bmr * 1.375;
      case 'moderate':
        return bmr * 1.55;
      case 'active':
        return bmr * 1.725;
      case 'very_active':
        return bmr * 1.9;
      default:
        return bmr * 1.2;
    }
  }

  /// Adjusts TDEE based on Goal (Lose/Gain/Maintain)
  static double calculateTargetCalories(double tdee, String goal) {
    switch (goal) {
      case 'lose':
        return tdee - 500; // Deficit
      case 'gain':
        return tdee + 300; // Surplus
      case 'maintain':
      default:
        return tdee;
    }
  }

  /// Calculates Macros (Protein/Fat/Carbs)
  /// Strategy: High Protein (2g/kg), Moderate Fat (0.8g/kg), Rest Carbs
  static Map<String, double> calculateMacros(double targetCalories, double weight) {
    double protein = weight * 2.0; // 2g per kg
    double fat = weight * 0.8; // 0.8g per kg
    
    double proteinCals = protein * 4;
    double fatCals = fat * 9;
    
    double remainingCals = targetCalories - (proteinCals + fatCals);
    double carbs = remainingCals / 4;

    // Ensure carbs aren't negative (edge case for very low cal)
    if (carbs < 0) carbs = 0;

    return {
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
    };
  }
}
