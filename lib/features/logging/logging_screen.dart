import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../services/ai_service.dart';
import '../../providers/ai_provider.dart';
import '../../services/food_log_service.dart';
import '../../services/user_service.dart';
import '../../models/food_log_model.dart';
import '../food_search/food_search_screen.dart';
import '../settings/settings_screen.dart';

class LoggingScreen extends ConsumerStatefulWidget {
  const LoggingScreen({super.key});

  @override
  ConsumerState<LoggingScreen> createState() => _LoggingScreenState();
}

class _LoggingScreenState extends ConsumerState<LoggingScreen> {
  final _inputController = TextEditingController();
  final _picker = ImagePicker();
  
  bool _isLoading = false;
  Map<String, dynamic>? _aiResult;
  String? _error;
  XFile? _selectedImage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  Future<void> _analyzeFood() async {
    final input = _inputController.text.trim();
    if (input.isEmpty && _selectedImage == null) {
      setState(() => _error = 'Please enter text or pick an image');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _aiResult = null;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final imageBytes = _selectedImage != null ? await _selectedImage!.readAsBytes() : null;
      
      final result = await aiService.analyzeFood(
        input.isEmpty ? null : input,
        imageBytes,
      );
      
      setState(() => _aiResult = result);
    } catch (e) {
      setState(() => _error = 'AI Analysis Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLog() async {
    if (_aiResult == null) return;

    final user = ref.read(userServiceProvider);
    if (user == null) return;

    final log = FoodLog(
      id: const Uuid().v4(),
      userId: user.id,
      name: _aiResult!['name'] ?? 'Unknown Food',
      calories: (_aiResult!['calories'] as num?)?.toDouble() ?? 0,
      protein: (_aiResult!['protein'] as num?)?.toDouble() ?? 0,
      carbs: (_aiResult!['carbs'] as num?)?.toDouble() ?? 0,
      fat: (_aiResult!['fat'] as num?)?.toDouble() ?? 0,
      timestamp: DateTime.now(),
      isAiGenerated: true,
      imageUrl: _selectedImage?.path,
    );

    await ref.read(foodLogServiceProvider.notifier).addLog(log);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food logged successfully!'),  backgroundColor: Color(0xFF00D9C0)),
      );
      Navigator.pop(context); // Return to Dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Food')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Selection Area
            if (_selectedImage != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_selectedImage!.path),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _buildActionButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
            
            const SizedBox(height: 24),

            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                labelText: 'What did you eat?',
                hintText: 'e.g., 2 eggs and toast',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _analyzeFood,
                ),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[800])),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider(color: Colors.grey[800])),
              ],
            ),
            const SizedBox(height: 24),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FoodSearchScreen()),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('Search Food Database'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                    if (_error!.contains('API Key'))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            );
                          },
                          child: const Text('Go to Settings'),
                        ),
                      ),
                  ],
                ),
              )
            else if (_aiResult != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: _buildResultCard(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              _aiResult!['name'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroItem('Calories', _aiResult!['calories']),
                _buildMacroItem('Protein', _aiResult!['protein']),
                _buildMacroItem('Carbs', _aiResult!['carbs']),
                _buildMacroItem('Fat', _aiResult!['fat']),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveLog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Add to Log', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(String label, dynamic value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
