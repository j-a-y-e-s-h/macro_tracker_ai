import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ai_service.dart';
import '../../services/food_log_service.dart';
import '../../providers/ai_provider.dart';
import '../../models/food_log_model.dart';
import '../../services/user_service.dart';
import 'package:uuid/uuid.dart';

class LoggingScreen extends ConsumerStatefulWidget {
  const LoggingScreen({super.key});

  @override
  ConsumerState<LoggingScreen> createState() => _LoggingScreenState();
}

class _LoggingScreenState extends ConsumerState<LoggingScreen> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _isAnalyzing = false;
  int _selectedTab = 0; // 0: Photo, 1: Text

  Future<void> _pickImage(ImageSource source) async {
    // Windows Fix: Camera not supported on Windows via image_picker
    if (Platform.isWindows && source == ImageSource.camera) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not supported on Windows. Opening Gallery instead.')),
      );
      source = ImageSource.gallery;
    }

    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _analyzeAndLog() async {
    if (_selectedImage == null && _textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a photo or text description')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      Uint8List? imageBytes;
      if (_selectedImage != null) {
        imageBytes = await _selectedImage!.readAsBytes();
      }

      final result = await aiService.analyzeFood(_textController.text, imageBytes);
      
      final user = ref.read(userServiceProvider);
      if (user == null) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found. Please log in.')),
        );
        return;
      }

      // Create Log
      final log = FoodLog(
        id: const Uuid().v4(),
        userId: user.id,
        name: result['name'] ?? 'Unknown Food',
        calories: (result['calories'] as num).toDouble(),
        protein: (result['protein'] as num).toDouble(),
        carbs: (result['carbs'] as num).toDouble(),
        fat: (result['fat'] as num).toDouble(),
        timestamp: DateTime.now(),
      );

      ref.read(foodLogServiceProvider.notifier).addLog(log);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged: ${log.name}')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Log Food', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTab('Photo', 0)),
                  Expanded(child: _buildTab('Text', 1)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_selectedTab == 0) ...[
              // Image Picker Area
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery),
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    image: _selectedImage != null
                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                        : null,
                    border: Border.all(color: AppTheme.surfaceHighlight),
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_outlined, size: 64, color: AppTheme.textSecondary),
                            const SizedBox(height: 16),
                            const Text(
                              'Tap to take photo or upload',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildActionButton(Icons.camera_alt, 'Camera', () => _pickImage(ImageSource.camera)),
                                const SizedBox(width: 16),
                                _buildActionButton(Icons.photo_library, 'Gallery', () => _pickImage(ImageSource.gallery)),
                              ],
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            Positioned(
                              top: 16,
                              right: 16,
                              child: IconButton(
                                onPressed: () => setState(() => _selectedImage = null),
                                icon: const Icon(Icons.close, color: Colors.white),
                                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ] else ...[
              // Text Input Area
              TextField(
                controller: _textController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Describe your meal (e.g., "Grilled chicken breast with rice and broccoli")',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Analyze Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isAnalyzing ? null : _analyzeAndLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: AppTheme.surfaceHighlight,
                ),
                child: _isAnalyzing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Analyze & Log',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.black),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppTheme.black : AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHighlight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
