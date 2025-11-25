import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../services/meal_planner_service.dart';
import '../../services/user_service.dart';
import '../../models/meal_plan_model.dart';
import 'shopping_list_screen.dart';

class MealPlannerScreen extends ConsumerStatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  ConsumerState<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends ConsumerState<MealPlannerScreen> {
  String _selectedDay = 'Monday';
  final List<String> _daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  void _addMeal(String type) {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Meal Name'),
              autofocus: true,
            ),
            TextField(
              controller: caloriesController,
              decoration: const InputDecoration(labelText: 'Calories (approx)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                _saveMeal(
                  nameController.text, 
                  double.tryParse(caloriesController.text) ?? 0, 
                  type
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMeal(String name, double calories, String type) async {
    final user = ref.read(userServiceProvider);
    if (user == null) return;

    final meal = MealItem(
      id: const Uuid().v4(),
      name: name,
      calories: calories,
      protein: 0, // Simplified for now
      carbs: 0,
      fat: 0,
      type: type,
    );

    final plannerService = ref.read(mealPlannerServiceProvider.notifier);
    var currentPlan = plannerService.getCurrentPlan();

    if (currentPlan == null) {
      // Create new plan if none exists
      final now = DateTime.now();
      // Find Monday of this week
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      
      currentPlan = MealPlan(
        id: const Uuid().v4(),
        userId: user.id,
        startDate: monday,
        endDate: sunday,
        days: {},
      );
    }

    // Update the plan
    final Map<String, List<MealItem>> updatedDays = Map.from(currentPlan.days);
    final dayMeals = List<MealItem>.from(updatedDays[_selectedDay] ?? []);
    dayMeals.add(meal);
    updatedDays[_selectedDay] = dayMeals;

    final updatedPlan = currentPlan.copyWith(days: updatedDays);
    await plannerService.savePlan(updatedPlan);
  }

  @override
  Widget build(BuildContext context) {
    final plannerService = ref.watch(mealPlannerServiceProvider.notifier);
    final currentPlan = plannerService.getCurrentPlan();
    final mealsForDay = currentPlan?.days[_selectedDay] ?? [];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShoppingListScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Day Selector
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _daysOfWeek.length,
              itemBuilder: (context, index) {
                final day = _daysOfWeek[index];
                final isSelected = day == _selectedDay;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.primaryColor : theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      day,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Meal List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMealSection('Breakfast', mealsForDay),
                _buildMealSection('Lunch', mealsForDay),
                _buildMealSection('Dinner', mealsForDay),
                _buildMealSection('Snack', mealsForDay),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(String type, List<MealItem> allMeals) {
    final meals = allMeals.where((m) => m.type == type).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(type, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
              onPressed: () => _addMeal(type),
            ),
          ],
        ),
        if (meals.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text('No meals planned', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
          )
        else
          ...meals.map((meal) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(meal.name),
              subtitle: Text('${meal.calories.toInt()} kcal'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () {
                  // Delete logic would go here
                },
              ),
            ),
          )),
        const Divider(),
      ],
    );
  }
}
