import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class FoodDetailSheet extends StatefulWidget {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final Function(double factor, DateTime timestamp) onAdd;

  const FoodDetailSheet({
    super.key,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.onAdd,
  });

  @override
  State<FoodDetailSheet> createState() => _FoodDetailSheetState();
}

class _FoodDetailSheetState extends State<FoodDetailSheet> {
  double _amount = 100; // Default 100g
  String _unit = 'g'; // g, oz, serving
  final DateTime _selectedDate = DateTime.now();
  final TimeOfDay _selectedTime = TimeOfDay.now();

  double get _factor {
    if (_unit == 'g') return _amount / 100;
    if (_unit == 'oz') return (_amount * 28.35) / 100;
    if (_unit == 'serving') return _amount; // Assuming 1 serving = 100g for simplicity, ideally passed in
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final totalCals = widget.calories * _factor;
    final totalProtein = widget.protein * _factor;
    final totalCarbs = widget.carbs * _factor;
    final totalFat = widget.fat * _factor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceHighlight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildBadge('Health Score: 85', Colors.green),
                      const SizedBox(width: 8),
                      _buildBadge('High Protein', AppTheme.proteinColor),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Main Macros
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMacroCircle('Calories', totalCals, AppTheme.primary),
                      _buildMacroCircle('Protein', totalProtein, AppTheme.proteinColor),
                      _buildMacroCircle('Carbs', totalCarbs, AppTheme.carbsColor),
                      _buildMacroCircle('Fats', totalFat, AppTheme.fatColor),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Quantity Input
                  const Text('Amount', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextField(
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            controller: TextEditingController(text: _amount.toStringAsFixed(0))
                              ..selection = TextSelection.fromPosition(TextPosition(offset: _amount.toStringAsFixed(0).length)),
                            onChanged: (val) {
                              setState(() {
                                _amount = double.tryParse(val) ?? 0;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              _buildUnitToggle('g', 'g'),
                              _buildUnitToggle('oz', 'oz'),
                              _buildUnitToggle('serving', 'srv'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Micronutrients (Deep Analysis)
                  const Text('Micronutrients', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildMicroRow('Vitamin A', '12%'),
                  _buildMicroRow('Vitamin C', '24%'),
                  _buildMicroRow('Calcium', '8%'),
                  _buildMicroRow('Iron', '15%'),
                  
                  const SizedBox(height: 100), // Spacing for FAB
                ],
              ),
            ),
          ),
          
          // Add Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final timestamp = DateTime(
                    _selectedDate.year, _selectedDate.month, _selectedDate.day,
                    _selectedTime.hour, _selectedTime.minute,
                  );
                  widget.onAdd(_factor, timestamp);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Add to Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitToggle(String value, String label) {
    final isSelected = _unit == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _unit = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppTheme.black : AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMacroCircle(String label, double value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Text(
              '${value.toInt()}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildMicroRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white)),
          Text(value, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
