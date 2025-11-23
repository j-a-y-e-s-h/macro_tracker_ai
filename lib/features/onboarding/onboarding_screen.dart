import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/user_service.dart';
import '../main_navigation.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  String _gender = 'male';
  String _activityLevel = 'sedentary';
  String _goal = 'lose';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Let\'s calculate your macros.',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Gender
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (v) => setState(() => _gender = v!),
              ),
              const SizedBox(height: 16),

              // Age
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Weight
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Height
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(labelText: 'Height (cm)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Activity Level
              DropdownButtonFormField<String>(
                value: _activityLevel,
                decoration: const InputDecoration(labelText: 'Activity Level'),
                items: const [
                  DropdownMenuItem(value: 'sedentary', child: Text('Sedentary (Office job)')),
                  DropdownMenuItem(value: 'light', child: Text('Lightly Active (1-2 days/week)')),
                  DropdownMenuItem(value: 'moderate', child: Text('Moderately Active (3-5 days/week)')),
                  DropdownMenuItem(value: 'active', child: Text('Active (6-7 days/week)')),
                  DropdownMenuItem(value: 'very_active', child: Text('Very Active (Physical job)')),
                ],
                onChanged: (v) => setState(() => _activityLevel = v!),
              ),
              const SizedBox(height: 16),

              // Goal
              DropdownButtonFormField<String>(
                value: _goal,
                decoration: const InputDecoration(labelText: 'Goal'),
                items: const [
                  DropdownMenuItem(value: 'lose', child: Text('Lose Weight')),
                  DropdownMenuItem(value: 'maintain', child: Text('Maintain Weight')),
                  DropdownMenuItem(value: 'gain', child: Text('Gain Muscle')),
                ],
                onChanged: (v) => setState(() => _goal = v!),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _submit,
                child: const Text('Calculate & Start', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(userServiceProvider.notifier).updateUserStats(
        age: int.parse(_ageController.text),
        gender: _gender,
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        activityLevel: _activityLevel,
        goal: _goal,
      );
      
      // Navigate to Dashboard
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    }
  }
}
