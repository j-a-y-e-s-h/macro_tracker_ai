import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/user_service.dart';
import '../onboarding/onboarding_screen.dart';
import '../main_navigation.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // For now, simulate login - will integrate Firebase later
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      // Navigate to onboarding for new users
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  Future<void> _loginAsGuest() async {
    // Check if user data exists
    final user = ref.read(userServiceProvider);
    
    if (user != null) {
      // Existing user - go to main app
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      // New user - go to onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Track your macros with precision',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 48),

                // Email Field
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.email, color: Color(0xFF14B8A6)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Password Field
                TextField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF14B8A6)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14B8A6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Log In',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Guest Mode Button
                TextButton(
                  onPressed: _loginAsGuest,
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(
                      color: Color(0xFF14B8A6),
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to signup - simplified for now
                        _loginAsGuest();
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Color(0xFF14B8A6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
