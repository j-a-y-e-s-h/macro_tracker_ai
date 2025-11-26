import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/user_service.dart';
import '../weight/weight_screen.dart';

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  int _selectedRange = 30; // 7, 30, 90 days

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
        title: const Text('Trends'),
        actions: [
          PopupMenuButton<int>(
            initialValue: _selectedRange,
            onSelected: (range) => setState(() => _selectedRange = range),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 Days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 Days')),
              const PopupMenuItem(value: 90, child: Text('Last 90 Days')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildWeightTrendCard(user),
            _buildExpenditureTrendCard(user),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightTrendCard(user) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weight Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WeightScreen()),
                  );
                },
                child: const Text(
                  'Log Weight',
                  style: TextStyle(color: Color(0xFF14B8A6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Weight chart
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
                        if (value.toInt() % 7 == 0) {
                          final date = DateTime.now().subtract(Duration(days: _selectedRange - value.toInt()));
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
                    spots: _getWeightSpots(),
                    isCurved: true,
                    color: const Color(0xFF8B5CF6),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Current weight
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Weight',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
              Text(
                '${user.weight.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  color: Colors.white,
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

  Widget _buildExpenditureTrendCard(user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expenditure Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adaptive TDEE tracking coming soon',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          
          // TDEE chart
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
                        if (value.toInt() % 7 == 0) {
                          final date = DateTime.now().subtract(Duration(days: _selectedRange - value.toInt()));
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
                    spots: _getTDEESpots(user),
                    isCurved: true,
                    color: const Color(0xFF14B8A6),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF14B8A6).withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Current TDEE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current TDEE',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
              Text(
                '${user.tdee.toInt()} kcal',
                style: const TextStyle(
                  color: Colors.white,
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

  List<FlSpot> _getWeightSpots() {
    // Sample data - will be replaced with actual weight logs
    final user = ref.watch(userServiceProvider);
    final baseWeight = user?.weight ?? 70.0;
    
    final spots = <FlSpot>[];
    for (var i = 0; i < _selectedRange; i++) {
      // Simulate slight variations
      final weight = baseWeight + (i % 3 - 1) * 0.2;
      spots.add(FlSpot(i.toDouble(), weight));
    }
    return spots;
  }

  List<FlSpot> _getTDEESpots(user) {
    final baseTDEE = user.tdee;
    
    final spots = <FlSpot>[];
    for (var i = 0; i < _selectedRange; i++) {
      // Flat line for now - will be adaptive
      spots.add(FlSpot(i.toDouble(), baseTDEE));
    }
    return spots;
  }
}
