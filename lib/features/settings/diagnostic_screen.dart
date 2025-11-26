import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';
import '../../services/ai_service.dart';

class DiagnosticScreen extends ConsumerStatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  ConsumerState<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends ConsumerState<DiagnosticScreen> {
  final List<String> _logs = [];
  bool _isRunning = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().split('.').first}: $message');
    });
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _logs.clear();
      _isRunning = true;
    });

    try {
      _addLog('Starting Diagnostics...');
      
      final aiService = ref.read(aiServiceProvider);
      final key = await aiService.getGeminiKey();
      
      if (key == null || key.isEmpty) {
        _addLog('❌ Error: No Gemini API Key found.');
        return;
      }

      _addLog('Key found (length: ${key.length})');
      _addLog('Key starts with: ${key.substring(0, key.length > 5 ? 5 : key.length)}...');

      // Test Internet
      _addLog('Testing Internet Connection...');
      try {
        final google = await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 5));
        _addLog('✓ Internet OK (${google.statusCode})');
      } catch (e) {
        _addLog('❌ Internet Check Failed: $e');
        _addLog('⚠️ If internet fails, API will not work.');
      }

      // 1. List Available Models (Crucial for debugging 404s)
      _addLog('\nListing Available Models...');
      try {
        final listUrl = 'https://generativelanguage.googleapis.com/v1beta/models?key=$key';
        final listResponse = await http.get(Uri.parse(listUrl)).timeout(const Duration(seconds: 10));
        
        if (listResponse.statusCode == 200) {
          final data = jsonDecode(listResponse.body);
          final models = (data['models'] as List?)?.map((m) => m['name'].toString().replaceAll('models/', '')).toList();
          _addLog('✓ Found ${models?.length ?? 0} models');
          if (models != null) {
            // Filter for gemini models to keep log short
            final geminiModels = models.where((m) => m.contains('gemini')).take(5).toList();
            _addLog('Examples: ${geminiModels.join(', ')}');
          }
        } else {
          _addLog('❌ ListModels Failed: ${listResponse.statusCode}');
          _addLog('Body: ${listResponse.body}');
        }
      } catch (e) {
        _addLog('❌ ListModels Exception: $e');
      }

      // 2. Test Gemini Models (Try v1beta first, then v1)
      final models = [
        'gemini-2.5-flash',
        'gemini-2.5-pro',
        'gemini-2.0-flash',
      ];

      for (final model in models) {
        _addLog('\nTesting $model...');
        
        // Try v1beta
        String url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key';
        bool success = await _testUrl(url, 'v1beta');
        
        // If v1beta fails, try v1
        if (!success) {
           _addLog('  Retrying with v1...');
           url = 'https://generativelanguage.googleapis.com/v1/models/$model:generateContent?key=$key';
           await _testUrl(url, 'v1');
        }
      }

    } catch (e) {
      _addLog('Critical Error: $e');
    } finally {
      setState(() => _isRunning = false);
      _addLog('\nDiagnostics Complete.');
    }
  }

  Future<bool> _testUrl(String url, String version) async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': 'Hi'}]
          }]
        }),
      ).timeout(const Duration(seconds: 15));
      stopwatch.stop();

      _addLog('[$version] Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        _addLog('✓ SUCCESS');
        return true;
      } else {
        _addLog('❌ FAILED');
        // Only log body if it's not a standard 404 to avoid clutter, unless it's the last attempt
        if (response.statusCode != 404) {
           _addLog('Body: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      _addLog('❌ EXCEPTION: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        title: const Text('Diagnostics', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isRunning ? null : _runDiagnostics,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.black,
                ),
                child: _isRunning 
                  ? const CircularProgressIndicator(color: AppTheme.black)
                  : const Text('Run Diagnostics', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceHighlight),
                ),
                child: _logs.isEmpty 
                  ? const Center(child: Text('Press Run to start', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        Color color = Colors.white;
                        if (log.contains('❌')) color = Colors.redAccent;
                        if (log.contains('✓')) color = Colors.greenAccent;
                        if (log.contains('⚠️')) color = Colors.orangeAccent;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            log,
                            style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 12),
                          ),
                        );
                      },
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
