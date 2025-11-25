import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../services/user_service.dart';
import '../../services/food_log_service.dart';
import '../../models/food_log_model.dart';
import '../../core/theme/app_theme.dart';

class QuickAddMacrosScreen extends ConsumerStatefulWidget {
  const QuickAddMacrosScreen({super.key});

  @override
  ConsumerState<QuickAddMacrosScreen> createState() => _QuickAddMacrosScreenState();
}

class _QuickAddMacrosScreenState extends ConsumerState<QuickAddMacrosScreen> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _addToLog() {
    final user = ref.read(userServiceProvider);
    if (user == null) return;

    final timestamp = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final log = FoodLog(
      id: const Uuid().v4(),
      userId: user.id,
      name: _nameController.text.isEmpty ? 'Quick Add' : _nameController.text,
      calories: double.tryParse(_caloriesController.text) ?? 0,
      protein: double.tryParse(_proteinController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      fat: double.tryParse(_fatController.text) ?? 0,
      timestamp: timestamp,
      isAiGenerated: false,
    );

    ref.read(foodLogServiceProvider.notifier).addLog(log);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        title: const Text('Quick Add Macros'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Food Name (Optional)',
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _caloriesController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Calories',
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _proteinController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Protein (g)',
                      labelStyle: const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _carbsController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Carbs (g)',
                      labelStyle: const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _fatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Fat (g)',
                      labelStyle: const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date & Time Selection
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d').format(_selectedDate),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _addToLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Add to Diary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
