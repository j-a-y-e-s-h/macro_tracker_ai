import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/user_service.dart';
import '../main_navigation.dart';
import '../../services/auth_service.dart';

class UltimateOnboardingScreen extends ConsumerStatefulWidget {
  const UltimateOnboardingScreen({super.key});

  @override
  ConsumerState<UltimateOnboardingScreen> createState() => _UltimateOnboardingScreenState();
}

class _UltimateOnboardingScreenState extends ConsumerState<UltimateOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCalculating = false;

  // Form Data
  String _gender = 'Male';
  int _age = 25;
  double _height = 175; // cm
  double _weight = 70; // kg
  String _activityLevel = 'Moderate';
  String _goal = 'Lose Weight';
  
  // Auth Data
  // No longer needed as user is already logged in
  // We might still want a name field if it wasn't captured during signup (e.g. email signup)
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authServiceProvider).currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();

    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finishOnboarding() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _isCalculating = true);
    
    // Simulate "AI Calculation"
    await Future.delayed(const Duration(seconds: 2));

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Save User Plan to Firestore
      final planData = {
        'name': _nameController.text,
        'email': user.email,
        'age': _age,
        'gender': _gender,
        'height': _height,
        'weight': _weight,
        'activityLevel': _activityLevel,
        'goal': _goal,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await ref.read(authServiceProvider).saveUserPlan(user.uid, planData);

      // Update Local State (Riverpod)
      await ref.read(userServiceProvider.notifier).updateUserStats(
        age: _age,
        gender: _gender,
        weight: _weight,
        height: _height,
        activityLevel: _activityLevel,
        goal: _goal,
      );
      
      final localUser = ref.read(userServiceProvider);
      if (localUser != null) {
        final updatedUser = localUser.copyWith(
          name: _nameController.text,
          email: user.email ?? '',
        );
        await ref.read(userServiceProvider.notifier).saveUser(updatedUser);
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.black,
                    AppTheme.black,
                    AppTheme.primary.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Progress Bar
                if (_currentPage < 5)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / 6,
                      backgroundColor: AppTheme.surface,
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) => setState(() => _currentPage = page),
                    children: [
                      _buildWelcomePage(),
                      _buildGenderAgePage(),
                      _buildHeightWeightPage(),
                      _buildActivityPage(),
                      _buildGoalPage(),
                      _buildNamePage(), // Replaces AuthPage
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_isCalculating)
            Container(
              color: AppTheme.black.withValues(alpha: 0.9),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 24),
                    Text(
                      'Designing your ultimate plan...',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 80, color: AppTheme.primary),
          const SizedBox(height: 32),
          Text(
            'Welcome to MacroMate',
            style: Theme.of(context).textTheme.displayLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'The ultimate AI-powered nutrition coach. Let\'s build your perfect body.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          _buildPrimaryButton('Get Started', _nextPage),
        ],
      ),
    );
  }

  Widget _buildGenderAgePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tell us about yourself', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 32),
          
          const Text('Gender', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSelectableCard('Male', _gender == 'Male', () => setState(() => _gender = 'Male'))),
              const SizedBox(width: 16),
              Expanded(child: _buildSelectableCard('Female', _gender == 'Female', () => setState(() => _gender = 'Female'))),
            ],
          ),
          
          const SizedBox(height: 32),
          const Text('Age', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => _age = (_age > 10) ? _age - 1 : _age),
                  icon: const Icon(Icons.remove, color: AppTheme.primary),
                ),
                Text('$_age years', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                IconButton(
                  onPressed: () => setState(() => _age = (_age < 100) ? _age + 1 : _age),
                  icon: const Icon(Icons.add, color: AppTheme.primary),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          _buildPrimaryButton('Next', _nextPage),
        ],
      ),
    );
  }

  Widget _buildHeightWeightPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Measurements', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 32),
          
          const Text('Height (cm)', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          Slider(
            value: _height,
            min: 100,
            max: 250,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.surface,
            onChanged: (val) => setState(() => _height = val),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => _height = (_height > 100) ? _height - 1 : _height),
                  icon: const Icon(Icons.remove, color: AppTheme.primary),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: TextEditingController(text: _height.toInt().toString())
                      ..selection = TextSelection.fromPosition(
                          TextPosition(offset: _height.toInt().toString().length)),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      suffixText: ' cm',
                      suffixStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed >= 100 && parsed <= 250) {
                        setState(() => _height = parsed);
                      }
                    },
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _height = (_height < 250) ? _height + 1 : _height),
                  icon: const Icon(Icons.add, color: AppTheme.primary),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          const Text('Weight (kg)', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          Slider(
            value: _weight,
            min: 30,
            max: 200,
            activeColor: AppTheme.secondary,
            inactiveColor: AppTheme.surface,
            onChanged: (val) => setState(() => _weight = val),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => _weight = (_weight > 30) ? _weight - 0.5 : _weight),
                  icon: const Icon(Icons.remove, color: AppTheme.secondary),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: TextEditingController(text: _weight.toStringAsFixed(1))
                      ..selection = TextSelection.fromPosition(
                          TextPosition(offset: _weight.toStringAsFixed(1).length)),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      suffixText: ' kg',
                      suffixStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed >= 30 && parsed <= 200) {
                        setState(() => _weight = parsed);
                      }
                    },
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _weight = (_weight < 200) ? _weight + 0.5 : _weight),
                  icon: const Icon(Icons.add, color: AppTheme.secondary),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          _buildPrimaryButton('Next', _nextPage),
        ],
      ),
    );
  }

  Widget _buildActivityPage() {
    final levels = ['Sedentary', 'Light', 'Moderate', 'Active', 'Very Active'];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity Level', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: levels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final level = levels[index];
                String description = '';
                switch (level) {
                  case 'Sedentary': description = 'Little to no exercise'; break;
                  case 'Light': description = 'Light exercise 1-3 days/week'; break;
                  case 'Moderate': description = 'Moderate exercise 3-5 days/week'; break;
                  case 'Active': description = 'Hard exercise 6-7 days/week'; break;
                  case 'Very Active': description = 'Very hard exercise & physical job'; break;
                }
                
                return _buildSelectableCard(
                  level,
                  _activityLevel == level,
                  () => setState(() => _activityLevel = level),
                  subtitle: description,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildPrimaryButton('Next', _nextPage),
        ],
      ),
    );
  }

  Widget _buildGoalPage() {
    final goals = ['Lose Weight', 'Maintain', 'Gain Muscle'];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Goal', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final goal = goals[index];
                return _buildSelectableCard(
                  goal,
                  _goal == goal,
                  () => setState(() => _goal = goal),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildPrimaryButton('Next', _nextPage),
        ],
      ),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('One last thing...', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('What should we call you?', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),
            
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            
            const SizedBox(height: 32),
            _buildPrimaryButton('Complete Setup', _finishOnboarding),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableCard(String title, bool isSelected, VoidCallback onTap, {String? subtitle}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.primary : Colors.white,
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? AppTheme.primary.withValues(alpha: 0.8) : AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
