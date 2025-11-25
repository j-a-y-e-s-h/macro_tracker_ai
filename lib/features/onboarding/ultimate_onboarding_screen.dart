import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../main_navigation.dart';
import '../auth/email_verification_screen.dart';

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
  String _dietPreference = 'Balanced';
  
  // Auth Data
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

    // Email validation
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    
    // Simple email regex validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    setState(() => _isCalculating = true);
    
    // Simulate "AI Calculation"
    await Future.delayed(const Duration(seconds: 2));

    // Create User
    await ref.read(userServiceProvider.notifier).updateUserStats(
      age: _age,
      gender: _gender,
      weight: _weight,
      height: _height,
      activityLevel: _activityLevel,
      goal: _goal,
    );
    
    // Save name and email
    final user = ref.read(userServiceProvider);
    if (user != null) {
      final updatedUser = user.copyWith(
        name: _nameController.text,
        email: email,
      );
      await ref.read(userServiceProvider.notifier).saveUser(updatedUser);
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
      );
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
                    AppTheme.primary.withOpacity(0.1),
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
                      _buildAuthPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_isCalculating)
            Container(
              color: AppTheme.black.withOpacity(0.9),
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
          Slider(
            value: _height,
            min: 100,
            max: 250,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.surface,
            onChanged: (val) => setState(() => _height = val),
          ),
          Center(child: Text('${_height.toInt()} cm', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
          
          const SizedBox(height: 32),
          const Text('Weight (kg)', style: TextStyle(color: AppTheme.textSecondary)),
          Slider(
            value: _weight,
            min: 30,
            max: 200,
            activeColor: AppTheme.secondary,
            inactiveColor: AppTheme.surface,
            onChanged: (val) => setState(() => _weight = val),
          ),
          Center(child: Text('${_weight.toInt()} kg', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
          
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
                return _buildSelectableCard(
                  level,
                  _activityLevel == level,
                  () => setState(() => _activityLevel = level),
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

  Widget _buildAuthPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Save your plan', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Create an account to track your progress forever.', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),
            
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            
            const SizedBox(height: 32),
            _buildPrimaryButton('Create Account', _finishOnboarding),
            
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {
                  // Toggle login mode (UI only for now)
                  setState(() => _isLogin = !_isLogin);
                },
                child: Text(
                  _isLogin ? 'Need an account? Sign Up' : 'Already have an account? Log In',
                  style: const TextStyle(color: AppTheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableCard(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.2) : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppTheme.primary : Colors.white,
            ),
          ),
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
