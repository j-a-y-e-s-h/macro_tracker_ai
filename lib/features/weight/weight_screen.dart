import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../services/weight_service.dart';
import '../../services/user_service.dart';
import '../../models/weight_log_model.dart';

class WeightScreen extends ConsumerStatefulWidget {
  const WeightScreen({super.key});

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen> {
  final _weightController = TextEditingController();

  void _logWeight() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Weight'),
        content: TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(_weightController.text);
              if (weight != null) {
                _saveWeight(weight);
                Navigator.pop(context);
                _weightController.clear();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWeight(double weight) async {
    final user = ref.read(userServiceProvider);
    if (user == null) return;

    final log = WeightLog(
      id: const Uuid().v4(),
      userId: user.id,
      weight: weight,
      timestamp: DateTime.now(),
    );

    await ref.read(weightServiceProvider.notifier).addLog(log);
    
    // Also update user profile weight
    // In a real app, we might want to ask before updating the profile
    // or have the profile update trigger a TDEE recalculation.
    // For now, let's keep them separate or update manually in settings.
  }

  @override
  Widget build(BuildContext context) {
    final weightLogs = ref.watch(weightServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Weight Trend')),
      floatingActionButton: FloatingActionButton(
        onPressed: _logWeight,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Chart
            SizedBox(
              height: 300,
              child: weightLogs.isEmpty
                  ? const Center(child: Text('No weight data yet'))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: weightLogs.asMap().entries.map((e) {
                              // Reverse index for X axis (oldest to newest)
                              // This is a simple visualization, for a real calendar X-axis we need more logic
                              return FlSpot(
                                (weightLogs.length - 1 - e.key).toDouble(), 
                                e.value.weight
                              );
                            }).toList(),
                            isCurved: true,
                            color: theme.colorScheme.secondary,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            
            // Recent Logs
            Expanded(
              child: ListView.builder(
                itemCount: weightLogs.length,
                itemBuilder: (context, index) {
                  final log = weightLogs[index];
                  return ListTile(
                    title: Text('${log.weight} kg'),
                    subtitle: Text(DateFormat.yMMMd().add_jm().format(log.timestamp)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => ref.read(weightServiceProvider.notifier).deleteLog(log.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
