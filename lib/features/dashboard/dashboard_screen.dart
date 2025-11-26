import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/food_log_service.dart';
import '../../services/ai_service.dart';
import '../logging/quick_add_macros_screen.dart';
import '../logging/logging_screen.dart';
import '../food_search/food_search_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late PageController _pageController;
  DateTime _currentDate = DateTime.now();
  final int _initialPage = 500;
  
  int _waterGlasses = 0;
  final Map<String, bool> _habits = {
    'Walk 5k Steps': false,
    'Eat Veggies': false,
    'No Sugar': false,
  };
  
  String? _aiTip;
  bool _loadingTip = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    _loadDailyData();
    _generateDailyTip();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    final daysDiff = page - _initialPage;
    setState(() {
      _currentDate = DateTime.now().add(Duration(days: daysDiff));
    });
    _loadDailyData();
  }

  Future<void> _loadDailyData() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(_currentDate);
    
    setState(() {
      _waterGlasses = prefs.getInt('water_$dateKey') ?? 0;
      _habits['Walk 5k Steps'] = prefs.getBool('habit_walk_$dateKey') ?? false;
      _habits['Eat Veggies'] = prefs.getBool('habit_veggies_$dateKey') ?? false;
      _habits['No Sugar'] = prefs.getBool('habit_sugar_$dateKey') ?? false;
    });
  }

  Future<void> _saveWater(int glasses) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(_currentDate);
    await prefs.setInt('water_$dateKey', glasses);
    setState(() => _waterGlasses = glasses);
  }

  Future<void> _saveHabit(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(_currentDate);
    String habitKey = '';
    if (key.contains('Walk')) {
      habitKey = 'habit_walk';
    } else if (key.contains('Veggies')) {
      habitKey = 'habit_veggies';
    } else if (key.contains('Sugar')) {
      habitKey = 'habit_sugar';
    }
    
    await prefs.setBool('${habitKey}_$dateKey', value);
    setState(() => _habits[key] = value);
  }

  Future<void> _generateDailyTip() async {
    if (_aiTip != null) return; 
    
    setState(() => _loadingTip = true);
    final user = ref.read(userServiceProvider);
    final aiService = ref.read(aiServiceProvider);
    
    if (user == null) {
      setState(() => _loadingTip = false);
      return;
    }

    final hour = DateTime.now().hour;
    String timeContext = "morning";
    if (hour >= 12 && hour < 17) timeContext = "afternoon";
    if (hour >= 17) timeContext = "evening";

    final prompt = "I am a ${user.gender}, ${user.age} years old, goal is ${user.goal}. It is $timeContext. Give me one short, motivating sentence (max 15 words) about nutrition or hydration.";

    try {
      final tip = await aiService.chat(prompt);
      if (mounted) {
        setState(() {
          _aiTip = tip.replaceAll('"', '');
          _loadingTip = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e.toString().contains('429')) {
             _aiTip = "Stay consistent! (AI quota limit reached)";
          } else {
             _aiTip = "Stay consistent and hit your goals!";
          }
          _loadingTip = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userServiceProvider);
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(),
            ],
            body: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final daysDiff = index - _initialPage;
                final date = DateTime.now().add(Duration(days: daysDiff));
                return _buildDayView(date, user);
              },
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildFloatingBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBottomBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: AppTheme.surfaceHighlight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBarItem(Icons.qr_code_scanner, 'Scan', () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodSearchScreen()));
          }),
          _buildBarItem(Icons.search, 'Search', () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodSearchScreen()));
          }),
          _buildBarItem(Icons.camera_alt, 'AI Snap', () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const LoggingScreen()));
          }, isCenter: true),
          _buildBarItem(Icons.edit, 'Quick', () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickAddMacrosScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildBarItem(IconData icon, String label, VoidCallback onTap, {bool isCenter = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isCenter ? 12 : 8),
            decoration: BoxDecoration(
              color: isCenter ? AppTheme.primary : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon, 
              color: isCenter ? AppTheme.black : AppTheme.textSecondary,
              size: isCenter ? 28 : 24,
            ),
          ),
          if (!isCenter)
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    final isToday = _currentDate.day == DateTime.now().day &&
        _currentDate.month == DateTime.now().month &&
        _currentDate.year == DateTime.now().year;

    return SliverAppBar(
      backgroundColor: AppTheme.black,
      floating: true,
      pinned: true,
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App Logo (Icon for now, can be image)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isToday ? 'Today' : DateFormat('EEE, MMM d').format(_currentDate),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, color: AppTheme.textSecondary),
        onPressed: () => _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: AppTheme.textSecondary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          onPressed: () => _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: AppTheme.black,
              surface: AppTheme.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final daysDiff = picked.difference(DateTime.now()).inDays;
      _pageController.jumpToPage(_initialPage + daysDiff);
    }
  }

  Widget _buildDayView(DateTime date, user) {
    ref.watch(foodLogServiceProvider); 
    final dailyTotals = ref.read(foodLogServiceProvider.notifier).getDailyTotals(date);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 140), // Increased bottom padding for floating bar + safe area
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSmartHeader(user, dailyTotals),
          const SizedBox(height: 24),
          _buildAISuggestion(),
          const SizedBox(height: 24),
          _buildNutritionSummary(user, dailyTotals),
          const SizedBox(height: 24),
          _buildWaterTracker(),
          const SizedBox(height: 24),
          _buildHabits(),
          const SizedBox(height: 24),
          _buildMealSection('Breakfast', date, '08:00 - 10:00'),
          _buildMealSection('Lunch', date, '12:00 - 14:00'),
          _buildMealSection('Dinner', date, '18:00 - 20:00'),
          _buildMealSection('Snacks', date, 'Anytime'),
        ],
      ),
    );
  }

  Widget _buildSmartHeader(user, Map<String, double> totals) {
    final remaining = (user.tdee - totals['calories']!).toInt();
    String message;
    
    if (remaining > 500) {
      message = "You have plenty of energy left for a great dinner!";
    } else if (remaining > 0) {
      message = "You're on track! Maybe a light snack?";
    } else {
      message = "You've hit your target! Great fueling today.";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello,',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  user.name.split(' ').first,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
            // Profile Pic or Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.black),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildAISuggestion() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.15),
            AppTheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'AI Coach Tip',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'BETA',
                        style: TextStyle(color: AppTheme.primary, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _loadingTip 
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    )
                  : Text(
                      _aiTip ?? "Stay consistent and hit your protein goals!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary(user, Map<String, double> totals) {
    final caloriesRemaining = (user.tdee - totals['calories']!).toInt();
    final caloriesConsumed = totals['calories']!.toInt();
    final progress = (totals['calories']! / user.tdee).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Eaten', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '$caloriesConsumed',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Left', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '$caloriesRemaining',
                    style: TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold, 
                      color: caloriesRemaining >= 0 ? AppTheme.primary : AppTheme.secondary
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.surfaceHighlight,
              color: AppTheme.primary,
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroItem('Protein', totals['protein']!, user.proteinTarget, AppTheme.proteinColor),
              _buildMacroItem('Fats', totals['fat']!, user.fatTarget, AppTheme.fatColor),
              _buildMacroItem('Carbs', totals['carbs']!, user.carbTarget, AppTheme.carbsColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, double current, double target, Color color) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.surfaceHighlight,
                  color: color,
                  strokeWidth: 6,
                ),
              ),
              Text(
                '${(current).toInt()}g',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'of ${target.toInt()}g',
            style: const TextStyle(color: AppTheme.textDim, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTracker() {
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
              const Text('Water', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('$_waterGlasses / 8 glasses', style: const TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 8,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final isFilled = index < _waterGlasses;
                return GestureDetector(
                  onTap: () => _saveWater(index + 1),
                  child: Container(
                    width: 40,
                    decoration: BoxDecoration(
                      color: isFilled ? Colors.blue[400] : AppTheme.surfaceHighlight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.water_drop,
                      color: isFilled ? Colors.white : AppTheme.textDim,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabits() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Habits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          ..._habits.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _saveHabit(entry.key, !entry.value),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                      color: entry.value ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: entry.value ? AppTheme.primary : AppTheme.textSecondary,
                          width: 2,
                        ),
                      ),
                      child: entry.value
                          ? const Icon(Icons.check, size: 16, color: AppTheme.black)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: entry.value ? Colors.white : AppTheme.textSecondary,
                        fontSize: 16,
                        decoration: entry.value ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMealSection(String title, DateTime date, String timeRange) {
    final logs = ref.read(foodLogServiceProvider.notifier).getLogsForDate(date);
    final mealLogs = logs.where((log) {
      final hour = log.timestamp.hour;
      if (title == 'Breakfast' && hour >= 5 && hour < 11) return true;
      if (title == 'Lunch' && hour >= 11 && hour < 16) return true;
      if (title == 'Dinner' && hour >= 16 && hour < 22) return true;
      if (title == 'Snacks' && (hour < 5 || hour >= 22)) return true;
      return false;
    }).toList();

    final totalCals = mealLogs.fold<double>(0, (sum, item) => sum + item.calories);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(timeRange, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHighlight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${totalCals.toInt()} kcal',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          if (mealLogs.isNotEmpty) ...[
            const Divider(height: 1, color: AppTheme.surfaceHighlight),
            ...mealLogs.map((log) => _buildFoodItem(log)),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodItem(log) {
    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.withValues(alpha: 0.2),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) {
        ref.read(foodLogServiceProvider.notifier).deleteLog(log.id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Food image or emoji
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.surfaceHighlight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(_getEmojiForFood(log.name), style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.name,
                    style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      Text(
                        '${log.calories.toInt()} kcal',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const Text(' • ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      Text(
                        DateFormat('HH:mm').format(log.timestamp),
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _buildMiniMacro('P', log.protein, AppTheme.proteinColor),
                const SizedBox(width: 8),
                _buildMiniMacro('C', log.carbs, AppTheme.carbsColor),
                const SizedBox(width: 8),
                _buildMiniMacro('F', log.fat, AppTheme.fatColor),
                const SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: AppTheme.textSecondary),
                    onPressed: () => _showEditLogDialog(log),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getEmojiForFood(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('apple')) return '🍎';
    if (lowerName.contains('banana')) return '🍌';
    if (lowerName.contains('orange')) return '🍊';
    if (lowerName.contains('berry') || lowerName.contains('straw')) return '🍓';
    if (lowerName.contains('grape')) return '🍇';
    if (lowerName.contains('melon')) return '🍈';
    if (lowerName.contains('avocado')) return '🥑';
    if (lowerName.contains('tomato')) return '🍅';
    if (lowerName.contains('potato')) return '🥔';
    if (lowerName.contains('carrot')) return '🥕';
    if (lowerName.contains('corn')) return '🌽';
    if (lowerName.contains('broccoli')) return '🥦';
    if (lowerName.contains('salad') || lowerName.contains('lettuce')) return '🥗';
    if (lowerName.contains('bread') || lowerName.contains('toast')) return '🍞';
    if (lowerName.contains('egg')) return '🥚';
    if (lowerName.contains('meat') || lowerName.contains('steak') || lowerName.contains('beef')) return '🥩';
    if (lowerName.contains('chicken')) return '🍗';
    if (lowerName.contains('fish') || lowerName.contains('salmon') || lowerName.contains('tuna')) return '🐟';
    if (lowerName.contains('rice')) return '🍚';
    if (lowerName.contains('pasta') || lowerName.contains('noodle')) return '🍝';
    if (lowerName.contains('pizza')) return '🍕';
    if (lowerName.contains('burger')) return '🍔';
    if (lowerName.contains('sandwich')) return '🥪';
    if (lowerName.contains('soup')) return '🥣';
    if (lowerName.contains('coffee')) return '☕';
    if (lowerName.contains('tea')) return '🍵';
    if (lowerName.contains('milk')) return '🥛';
    if (lowerName.contains('juice')) return '🧃';
    if (lowerName.contains('water')) return '💧';
    if (lowerName.contains('cake') || lowerName.contains('dessert')) return '🍰';
    if (lowerName.contains('chocolate')) return '🍫';
    if (lowerName.contains('cookie')) return '🍪';
    if (lowerName.contains('ice cream')) return '🍦';
    return '🍽️';
  }

  void _showEditLogDialog(log) {
    final nameController = TextEditingController(text: log.name);
    final caloriesController = TextEditingController(text: log.calories.toStringAsFixed(1));
    final proteinController = TextEditingController(text: log.protein.toStringAsFixed(1));
    final carbsController = TextEditingController(text: log.carbs.toStringAsFixed(1));
    final fatController = TextEditingController(text: log.fat.toStringAsFixed(1));
    final weightController = TextEditingController(text: '100'); // Default to 100g for scaling

    // Store base values for scaling
    final baseCals = log.calories;
    final baseProt = log.protein;
    final baseCarbs = log.carbs;
    final baseFat = log.fat;

    // Add listener for smart scaling
    weightController.addListener(() {
      final weight = double.tryParse(weightController.text);
      if (weight != null) {
        final factor = weight / 100;
        caloriesController.text = (baseCals * factor).toStringAsFixed(1);
        proteinController.text = (baseProt * factor).toStringAsFixed(1);
        carbsController.text = (baseCarbs * factor).toStringAsFixed(1);
        fatController.text = (baseFat * factor).toStringAsFixed(1);
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Edit Food', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Food Name', labelStyle: TextStyle(color: AppTheme.textSecondary)),
              ),
              const SizedBox(height: 16),
              // Weight Field
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Weight (g) - Scales Macros', 
                  labelStyle: TextStyle(color: AppTheme.primary),
                  suffixText: 'g',
                  suffixStyle: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: caloriesController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Calories', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: proteinController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Protein (g)', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: carbsController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Carbs (g)', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: fatController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Fat (g)', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedLog = log.copyWith(
                name: nameController.text,
                calories: double.tryParse(caloriesController.text) ?? log.calories,
                protein: double.tryParse(proteinController.text) ?? log.protein,
                carbs: double.tryParse(carbsController.text) ?? log.carbs,
                fat: double.tryParse(fatController.text) ?? log.fat,
              );
              
              ref.read(foodLogServiceProvider.notifier).deleteLog(log.id);
              ref.read(foodLogServiceProvider.notifier).addLog(updatedLog);
              
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Save', style: TextStyle(color: AppTheme.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMacro(String label, double val, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('${val.toInt()}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}
