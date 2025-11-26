import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/food_log_service.dart';
import '../../services/user_service.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _selectedDate = DateTime.now();

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyLogs = ref.read(foodLogServiceProvider.notifier).getLogsForDate(_selectedDate);
    final dailyTotals = ref.read(foodLogServiceProvider.notifier).getDailyTotals(_selectedDate);
    final user = ref.watch(userServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: theme.cardTheme.color,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeDate(-1),
                ),
                Text(
                  DateFormat.yMMMEd().format(_selectedDate),
                  style: theme.textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _selectedDate.day == DateTime.now().day &&
                          _selectedDate.month == DateTime.now().month &&
                          _selectedDate.year == DateTime.now().year
                      ? null
                      : () => _changeDate(1),
                ),
              ],
            ),
          ),

          // Summary Card
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Daily Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${dailyTotals['calories']!.toInt()} / ${user.tdee.toInt()} kcal',
                          style: TextStyle(
                            color: dailyTotals['calories']! > user.tdee ? Colors.redAccent : theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacroItem('Protein', dailyTotals['protein']!, user.proteinTarget, Colors.purple),
                        _buildMacroItem('Carbs', dailyTotals['carbs']!, user.carbTarget, Colors.orange),
                        _buildMacroItem('Fat', dailyTotals['fat']!, user.fatTarget, Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Logs List
          Expanded(
            child: dailyLogs.isEmpty
                ? Center(
                    child: Text(
                      'No logs for this day',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: dailyLogs.length,
                    itemBuilder: (context, index) {
                      final log = dailyLogs[index];
                      return Dismissible(
                        key: Key(log.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          ref.read(foodLogServiceProvider.notifier).deleteLog(log.id);
                        },
                        child: ListTile(
                          leading: log.imageUrl != null
                              ? const CircleAvatar(child: Icon(Icons.image)) // Placeholder for now
                              : const CircleAvatar(child: Icon(Icons.fastfood)),
                          title: Text(log.name),
                          subtitle: Text('${log.calories.toInt()} kcal • P: ${log.protein.toInt()} C: ${log.carbs.toInt()} F: ${log.fat.toInt()}'),
                          trailing: Text(DateFormat.jm().format(log.timestamp)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, double value, double target, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${value.toInt()}/${target.toInt()}g', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
