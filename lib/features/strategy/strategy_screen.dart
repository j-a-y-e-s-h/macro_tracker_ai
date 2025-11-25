import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/food_log_service.dart';
import '../../services/weight_service.dart';
import '../../services/ai_service.dart';
import '../../providers/ai_provider.dart';
import '../../models/weight_log_model.dart';
import 'package:uuid/uuid.dart';

class StrategyScreen extends ConsumerStatefulWidget {
  const StrategyScreen({super.key});

  @override
  ConsumerState<StrategyScreen> createState() => _StrategyScreenState();
}

class _StrategyScreenState extends ConsumerState<StrategyScreen> {
  String? _aiAnalysis;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runSmartCheckIn();
    });
  }

  Future<void> _runSmartCheckIn() async {
    final user = ref.read(userServiceProvider);
    final aiService = ref.read(aiServiceProvider);
    
    if (user == null || _aiAnalysis != null) return;

    setState(() => _isAnalyzing = true);

    try {
      final foodLogService = ref.read(foodLogServiceProvider.notifier);
      final now = DateTime.now();
      StringBuffer dataSummary = StringBuffer();
      
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final totals = foodLogService.getDailyTotals(date);
        if (totals['calories']! > 0) {
          dataSummary.writeln("- ${DateFormat('EEE').format(date)}: ${totals['calories']!.toInt()} kcal (P: ${totals['protein']!.toInt()}g)");
        }
      }

      if (dataSummary.isEmpty) {
        setState(() {
          _aiAnalysis = "Log some food to get a smart analysis!";
          _isAnalyzing = false;
        });
        return;
      }

      final prompt = """
      Analyze my last week of eating:
      ${dataSummary.toString()}
      My goal is ${user.goal} (TDEE: ${user.tdee.toInt()}).
      Give me 3 short, specific bullet points of advice. Format as a simple list.
      """;

      final response = await aiService.chat(prompt);
      final supplementAdvice = await aiService.getSupplementAdvice(dataSummary.toString(), user.goal);
      
      if (mounted) {
        setState(() {
          _aiAnalysis = "$response\n\n**Supplement Tip:** $supplementAdvice";
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiAnalysis = "Could not generate analysis. Check connection.";
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userServiceProvider);
    
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        title: const Text('Strategy & Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSmartCheckInCard(),
            const SizedBox(height: 24),
            _buildExpenditureGraph(user),
            const SizedBox(height: 24),
            _buildWeightTrendGraph(),
            const SizedBox(height: 24),
            _buildProgramCard(user),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartCheckInCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withOpacity(0.15), AppTheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.analytics_outlined, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              const Text(
                'Weekly Smart Check-in',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isAnalyzing 
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            : Text(
                _aiAnalysis ?? "Log your meals to unlock AI insights.",
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
          const SizedBox(height: 16),
          if (!_isAnalyzing)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _runSmartCheckIn,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primary),
                  foregroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Refresh Analysis'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpenditureGraph(user) {
    final foodLogService = ref.watch(foodLogServiceProvider.notifier);
    final now = DateTime.now();
    List<FlSpot> spots = [];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final totals = foodLogService.getDailyTotals(date);
      spots.add(FlSpot(i.toDouble(), totals['calories']!));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Caloric Expenditure (Last 7 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: [const FlSpot(0, 0), FlSpot(6, user.tdee)], // Target line approximation
                    isCurved: false,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                    barWidth: 2,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                  ),
                ],
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightTrendGraph() {
    final weightLogs = ref.watch(weightServiceProvider);
    final latestWeight = weightLogs.isNotEmpty ? weightLogs.first.weight : 0.0;
    
    // Prepare spots from logs (take last 7 entries for simplicity)
    List<FlSpot> spots = [];
    if (weightLogs.isNotEmpty) {
      final recentLogs = weightLogs.take(7).toList().reversed.toList();
      for (int i = 0; i < recentLogs.length; i++) {
        spots.add(FlSpot(i.toDouble(), recentLogs[i].weight));
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Weight Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(
                latestWeight > 0 ? '$latestWeight kg' : '-- kg',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (spots.isEmpty)
            const Center(child: Text('No weight data yet', style: TextStyle(color: AppTheme.textSecondary)))
          else
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blueAccent,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Log Weight'),
              onPressed: _showAddWeightDialog,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWeightDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Log Weight', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            labelStyle: TextStyle(color: AppTheme.textSecondary),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.surfaceHighlight)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(controller.text);
              final user = ref.read(userServiceProvider);
              
              if (weight != null && user != null) {
                final log = WeightLog(
                  id: const Uuid().v4(),
                  userId: user.id,
                  weight: weight,
                  timestamp: DateTime.now(),
                );
                ref.read(weightServiceProvider.notifier).addLog(log);
                
                // Also update user profile weight
                ref.read(userServiceProvider.notifier).updateUserStats(
                  age: user.age,
                  gender: user.gender,
                  weight: weight,
                  height: user.height,
                  activityLevel: user.activityLevel,
                  goal: user.goal,
                );
                
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Save', style: TextStyle(color: AppTheme.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Program', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHighlight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fitness_center, color: Colors.white),
            ),
            title: Text(user.goal, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('TDEE: ${user.tdee.toInt()} kcal', style: const TextStyle(color: AppTheme.textSecondary)),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
