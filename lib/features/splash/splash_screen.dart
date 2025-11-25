import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/user_service.dart';
import '../onboarding/ultimate_onboarding_screen.dart';
import '../main_navigation.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );

    _controller.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final user = ref.read(userServiceProvider);
    
    // Navigate to main app if user exists, otherwise to Ultimate Onboarding
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => user != null ? const MainNavigation() : const UltimateOnboardingScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo with Glow
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 64,
                    color: AppTheme.black,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'MacroMate',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Track. Optimize. Achieve.',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
