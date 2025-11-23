import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ai_service.dart';
import '../../providers/ai_provider.dart';

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
      // Save keys first
      if (_geminiKeyController.text.trim().isNotEmpty) {
        await aiService.saveGeminiKey(_geminiKeyController.text.trim());
      }
      if (_chatgptKeyController.text.trim().isNotEmpty) {
        await aiService.saveChatGPTKey(_chatgptKeyController.text.trim());
      }

      // Validate and set provider
      await aiService.setAIProvider(_aiProvider);
      await aiService.setChatGPTModel(_chatgptModel);
      await aiService.setGeminiModel(_geminiModel);

      // Smart Validation: Check if the selected configuration works
      String workingModel = '';
      if (_aiProvider == 'gemini') {
        workingModel = await aiService.validateApiKey('gemini', _geminiKeyController.text.trim());
        if (workingModel != _geminiModel) {
           await aiService.setGeminiModel(workingModel);
           setState(() => _geminiModel = workingModel);
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Selected model failed. Auto-switched to working model: $workingModel')),
             );
           }
        }
      } else {
        workingModel = await aiService.validateApiKey('chatgpt', _chatgptKeyController.text.trim());
        if (workingModel != _chatgptModel) {
           await aiService.setChatGPTModel(workingModel);
           setState(() => _chatgptModel = workingModel);
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Selected model failed. Auto-switched to working model: $workingModel')),
             );
           }
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings Saved & Verified!'),
            backgroundColor: Color(0xFF00D9C0),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Configuration',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure your AI providers. The app will automatically find the best working model if your selection fails.',
              style: TextStyle(color: Color(0xFF888888), fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Primary AI Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Primary AI Provider',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Gemini (Google)', style: TextStyle(color: Colors.white)),
                        value: 'gemini',
                        groupValue: _aiProvider,
                        onChanged: (val) => setState(() => _aiProvider = val!),
                        activeColor: const Color(0xFF00D9C0),
                      ),
                      RadioListTile<String>(
                        title: const Text('ChatGPT (OpenAI)', style: TextStyle(color: Colors.white)),
                        value: 'chatgpt',
                        groupValue: _aiProvider,
                        onChanged: (val) => setState(() => _aiProvider = val!),
                        activeColor: const Color(0xFF00D9C0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Gemini Configuration
            if (_aiProvider == 'gemini') ...[
              const Text(
                'Gemini API Key',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _geminiKeyController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter Gemini API Key',
                  hintStyle: const TextStyle(color: Color(0xFF888888)),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.key, color: Color(0xFF00D9C0)),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Gemini Model',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: AIService.geminiModels.contains(_geminiModel) ? _geminiModel : AIService.geminiModels.last,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A1A1A),
                    style: const TextStyle(color: Colors.white),
                    items: AIService.geminiModels.map((model) {
                      return DropdownMenuItem(value: model, child: Text(model));
                    }).toList(),
                    onChanged: (v) => setState(() => _geminiModel = v!),
                  ),
                ),
              ),
            ],

            // ChatGPT Configuration
            if (_aiProvider == 'chatgpt') ...[
              const Text(
                'ChatGPT API Key',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _chatgptKeyController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter ChatGPT API Key',
                  hintStyle: const TextStyle(color: Color(0xFF888888)),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.key, color: Color(0xFF00D9C0)),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'ChatGPT Model',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: AIService.chatgptModels.contains(_chatgptModel) ? _chatgptModel : AIService.chatgptModels.last,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A1A1A),
                    style: const TextStyle(color: Colors.white),
                    items: AIService.chatgptModels.map((model) {
                      return DropdownMenuItem(value: model, child: Text(model));
                    }).toList(),
                    onChanged: (v) => setState(() => _chatgptModel = v!),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isValidating ? null : _saveKeys,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9C0),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isValidating 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black))
                  : const Text(
                      'Save & Verify Settings',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
              ),
            ),
          ],
        ),
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
