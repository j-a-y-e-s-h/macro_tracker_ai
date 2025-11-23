import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  
  String _gender = 'Male';
  String _activityLevel = 'Sedentary';
  String _goal = 'Maintain';

  @override
  void initState() {
    super.initState();
    final user = ref.read(userServiceProvider)!;
    _ageController = TextEditingController(text: user.age.toString());
    _weightController = TextEditingController(text: user.weight.toString());
    _heightController = TextEditingController(text: user.height.toString());
    _gender = user.gender;
    _activityLevel = user.activityLevel;
    _goal = user.goal;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(userServiceProvider)!;
      
      final updatedUser = user.copyWith(
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        gender: _gender,
        activityLevel: _activityLevel,
        goal: _goal,
      );

      await ref.read(userServiceProvider.notifier).saveUser(updatedUser);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Personal Stats', theme),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _gender.toLowerCase(),
                    decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: (v) => setState(() => _gender = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Activity & Goals', theme),
            DropdownButtonFormField<String>(
              value: _activityLevel.toLowerCase() == 'sedentary' ? 'sedentary' : 
                     _activityLevel.toLowerCase() == 'light' ? 'light' :
                     _activityLevel.toLowerCase() == 'moderate' ? 'moderate' :
                     _activityLevel.toLowerCase() == 'active' ? 'active' : 'very_active',
              decoration: const InputDecoration(labelText: 'Activity Level', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'sedentary', child: Text('Sedentary')),
                DropdownMenuItem(value: 'light', child: Text('Lightly Active')),
                DropdownMenuItem(value: 'moderate', child: Text('Moderately Active')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'very_active', child: Text('Very Active')),
              ],
              onChanged: (v) => setState(() => _activityLevel = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _goal.toLowerCase(),
              decoration: const InputDecoration(labelText: 'Goal', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'lose', child: Text('Lose Weight')),
                DropdownMenuItem(value: 'maintain', child: Text('Maintain Weight')),
                DropdownMenuItem(value: 'gain', child: Text('Gain Muscle')),
              ],
              onChanged: (v) => setState(() => _goal = v!),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
