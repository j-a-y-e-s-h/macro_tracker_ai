import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/user_service.dart';
import '../../services/food_log_service.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  int _selectedDays = 7; // 7, 14, or 30 days

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userServiceProvider);
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Nutrition'),
        actions: [
          PopupMenuButton<int>(
            initialValue: _selectedDays,
            onSelected: (days) => setState(() => _selectedDays = days),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 Days')),
              const PopupMenuItem(value: 14, child: Text('Last 14 Days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 Days')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeeklyAveragesCard(user),
            _buildMacroDistributionCard(user),
            _buildDailyMacroChart(user),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyAveragesCard(user) {
    final logs = ref.watch(foodLogServiceProvider);
    final now = DateTime.now();
    
    // Calculate averages for selected period
    var totalCal = 0.0, totalProtein = 0.0, totalCarbs = 0.0, totalFat = 0.0;
    var daysWithData = 0;

    for (var i = 0; i < _selectedDays; i++) {
      final date = now.subtract(Duration(days: i));
      final dailyTotals = ref.read(foodLogServiceProvider.notifier).getDailyTotals(date);
      if (dailyTotals['calories']! > 0) {
        totalCal += dailyTotals['calories']!;
        totalProtein += dailyTotals['protein']!;
        totalCarbs += dailyTotals['carbs']!;
        totalFat += dailyTotals['fat']!;
        daysWithData++;
      }
    }

    final avgCal = daysWithData > 0 ? totalCal / daysWithData : 0;
    final avgProtein = daysWithData > 0 ? totalProtein / daysWithData : 0;
    final avgCarbs = daysWithData > 0 ? totalCarbs / daysWithData : 0;
    final avgFat = daysWithData > 0 ? totalFat / daysWithData : 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_selectedDays-Day Averages',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          
          // Calories
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Calories', style: TextStyle(color: Color(0xFF94A3B8))),
              Text(
                '${avgCal.toInt()} kcal',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Protein
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Protein', style: TextStyle(color: Color(0xFF94A3B8))),
              Text(
                '${avgProtein.toInt()}g',
                style: const TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Carbs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Carbs', style: TextStyle(color: Color(0xFF94A3B8))),
              Text(
                '${avgCarbs.toInt()}g',
                style: const TextStyle(
                  color: Color(0xFF3B82F6),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Fat
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Fat', style: TextStyle(color: Color(0xFF94A3B8))),
              Text(
                '${avgFat.toInt()}g',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroDistributionCard(user) {
    final logs = ref.watch(foodLogServiceProvider);
    final now = DateTime.now();
    
    var totalProtein = 0.0, totalCarbs = 0.0, totalFat = 0.0;

    for (var i = 0; i < _selectedDays; i++) {
      final date = now.subtract(Duration(days: i));
      final dailyTotals = ref.read(foodLogServiceProvider.notifier).getDailyTotals(date);
      totalProtein += dailyTotals['protein']!;
      totalCarbs += dailyTotals['carbs']!;
      totalFat += dailyTotals['fat']!;
    }

    final total = totalProtein + totalCarbs + totalFat;
    final proteinPercent = total > 0 ? (totalProtein / total * 100) : 33.3;
    final carbsPercent = total > 0 ? (totalCarbs / total * 100) : 33.3;
    final fatPercent = total > 0 ? (totalFat / total * 100) : 33.3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Macro Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(
                    value: proteinPercent,
                    color: const Color(0xFF8B5CF6),
                    title: '${proteinPercent.toInt()}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: carbsPercent,
                    color: const Color(0xFF3B82F6),
                    title: '${carbsPercent.toInt()}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: fatPercent,
                    color: const Color(0xFFF59E0B),
                    title: '${fatPercent.toInt()}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Protein', const Color(0xFF8B5CF6)),
              _buildLegendItem('Carbs', const Color(0xFF3B82F6)),
              _buildLegendItem('Fat', const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDailyMacroChart(user) {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    
    for (var i = _selectedDays - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dailyTotals = ref.read(foodLogServiceProvider.notifier).getDailyTotals(date);
      spots.add(FlSpot((_selectedDays - 1 - i).toDouble(), dailyTotals['calories']!));
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Calories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFF334155),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() == 0 || value.toInt() == _selectedDays - 1) {
                          final date = now.subtract(Duration(days: _selectedDays - 1 - value.toInt()));
                          return Text(
                            DateFormat('M/d').format(date),
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF14B8A6),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF14B8A6).withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
