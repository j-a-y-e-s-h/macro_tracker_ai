import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ai_service.dart';
import '../../providers/ai_provider.dart';
import '../../services/user_service.dart';
import '../../features/onboarding/ultimate_onboarding_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _geminiKeyController = TextEditingController();
  final _chatgptKeyController = TextEditingController();
  String _aiProvider = 'gemini';
  String _chatgptModel = 'gpt-4o';
  String _geminiModel = 'gemini-1.5-flash';
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final aiService = ref.read(aiServiceProvider);
    final geminiKey = await aiService.getGeminiKey();
    final chatgptKey = await aiService.getChatGPTKey();
    final provider = await aiService.getAIProvider();
    final chatgptModel = await aiService.getChatGPTModel();
    final geminiModel = await aiService.getGeminiModel();
    
    setState(() {
      _geminiKeyController.text = geminiKey ?? '';
      _chatgptKeyController.text = chatgptKey ?? '';
      _aiProvider = provider;
      _chatgptModel = chatgptModel;
      _geminiModel = geminiModel;
    });
  }

  Future<void> _saveKeys() async {
    setState(() => _isValidating = true);
    final aiService = ref.read(aiServiceProvider);
    
    try {
      if (_geminiKeyController.text.trim().isNotEmpty) {
        await aiService.saveGeminiKey(_geminiKeyController.text.trim());
      }
      if (_chatgptKeyController.text.trim().isNotEmpty) {
        await aiService.saveChatGPTKey(_chatgptKeyController.text.trim());
      }

      await aiService.setAIProvider(_aiProvider);
      await aiService.setChatGPTModel(_chatgptModel);
      await aiService.setGeminiModel(_geminiModel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings Saved!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  void _showEditProfileDialog(user) {
    final nameController = TextEditingController(text: user.name);
    final ageController = TextEditingController(text: user.age.toString());
    final weightController = TextEditingController(text: user.weight.toString());
    final heightController = TextEditingController(text: user.height.toString());
    final tdeeController = TextEditingController(text: user.tdee.toInt().toString());
    final proteinController = TextEditingController(text: user.proteinTarget.toInt().toString());
    final carbsController = TextEditingController(text: user.carbTarget.toInt().toString());
    final fatController = TextEditingController(text: user.fatTarget.toInt().toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField('Name', nameController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDialogTextField('Age', ageController, isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDialogTextField('Weight (kg)', weightController, isNumber: true)),
                ],
              ),
              const SizedBox(height: 12),
              _buildDialogTextField('Height (cm)', heightController, isNumber: true),
              const SizedBox(height: 24),
              const Text('Macro Targets (Manual Override)', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildDialogTextField('Daily Calories (TDEE)', tdeeController, isNumber: true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDialogTextField('Protein (g)', proteinController, isNumber: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDialogTextField('Carbs (g)', carbsController, isNumber: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDialogTextField('Fat (g)', fatController, isNumber: true)),
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
              final updatedUser = user.copyWith(
                name: nameController.text,
                age: int.tryParse(ageController.text) ?? user.age,
                weight: double.tryParse(weightController.text) ?? user.weight,
                height: double.tryParse(heightController.text) ?? user.height,
                tdee: double.tryParse(tdeeController.text) ?? user.tdee,
                proteinTarget: double.tryParse(proteinController.text) ?? user.proteinTarget,
                carbTarget: double.tryParse(carbsController.text) ?? user.carbTarget,
                fatTarget: double.tryParse(fatController.text) ?? user.fatTarget,
              );
              ref.read(userServiceProvider.notifier).saveUser(updatedUser);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile Updated!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Save', style: TextStyle(color: AppTheme.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.surfaceHighlight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
        filled: true,
        fillColor: AppTheme.black.withOpacity(0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userServiceProvider);

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('Profile'),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.primary),
                    onPressed: () => _showEditProfileDialog(user),
                  ),
                ],
              ),
              _buildProfileCard(user),
              const SizedBox(height: 32),
            ],

            _buildSectionHeader('AI Configuration'),
            _buildAIConfigCard(),
            const SizedBox(height: 32),

            _buildSectionHeader('Data'),
            _buildDataCard(),
            const SizedBox(height: 32),
            
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProfileCard(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceHighlight),
      ),
      child: Column(
        children: [
          _buildProfileRow('Name', user.name),
          const Divider(color: AppTheme.surfaceHighlight),
          _buildProfileRow('Goal', user.goal),
          const Divider(color: AppTheme.surfaceHighlight),
          _buildProfileRow('Weight', '${user.weight} kg'),
          const Divider(color: AppTheme.surfaceHighlight),
          _buildProfileRow('TDEE', '${user.tdee.toInt()} kcal'),
          const Divider(color: AppTheme.surfaceHighlight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Macros', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
              Text(
                'P:${user.proteinTarget.toInt()} C:${user.carbTarget.toInt()} F:${user.fatTarget.toInt()}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAIConfigCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Provider', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildProviderRadio('Gemini', 'gemini'),
              const SizedBox(width: 16),
              _buildProviderRadio('ChatGPT', 'chatgpt'),
            ],
          ),
          const SizedBox(height: 20),
          if (_aiProvider == 'gemini') _buildTextField('Gemini API Key', _geminiKeyController),
          if (_aiProvider == 'chatgpt') _buildTextField('ChatGPT API Key', _chatgptKeyController),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isValidating ? null : _saveKeys,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isValidating 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppTheme.black))
                : const Text('Save Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderRadio(String label, String value) {
    final isSelected = _aiProvider == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _aiProvider = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.2) : AppTheme.surfaceHighlight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.black,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      obscureText: true,
    );
  }

  Widget _buildDataCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceHighlight),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Clear All Data', style: TextStyle(color: Colors.white)),
            onTap: () async {
              // TODO: Implement clear data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data cleared! (Simulated)')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () async {
          await ref.read(userServiceProvider.notifier).clearUser();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const UltimateOnboardingScreen()),
              (route) => false,
            );
          }
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          foregroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  void dispose() {
    _geminiKeyController.dispose();
    _chatgptKeyController.dispose();
    super.dispose();
  }
}
