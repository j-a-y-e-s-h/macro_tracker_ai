import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Added for TimeoutException
import 'dart:io';    // Added for SocketException

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

final aiServiceProvider = Provider<AIService>((ref) => AIService());

class AIService {
  static const String _geminiKeyKey = 'gemini_api_key';
  static const String _chatgptKeyKey = 'chatgpt_api_key';
  static const String _chatgptModelKey = 'chatgpt_model';
  static const String _geminiModelKey = 'gemini_model';
  static const String _aiProviderKey = 'ai_provider';
  
  // Model Lists - Current stable models from official Gemini API
  static const List<String> geminiModels = [
    'gemini-2.5-flash',      // Recommended: Fast & Efficient (stable)
    'gemini-2.5-pro',        // High Intelligence (stable)
    'gemini-2.0-flash',      // Previous generation workhorse
    'gemini-1.5-flash',      // Legacy fallback
    'gemini-1.5-pro',        // Legacy fallback
  ];

  static const List<String> chatgptModels = [
    'gpt-4o-mini',
    'gpt-4o',
    'gpt-3.5-turbo',
    'gpt-4-turbo',
  ];

  // --- Getters & Setters ---

  Future<String?> getGeminiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiKeyKey);
  }

  Future<String?> getChatGPTKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chatgptKeyKey);
  }

  Future<String> getAIProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_aiProviderKey) ?? 'gemini';
  }

  Future<void> setAIProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiProviderKey, provider);
  }

  Future<void> saveGeminiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmedKey = key.trim(); // Sanitize input
    if (trimmedKey.isEmpty) throw Exception('API key cannot be empty');
    
    debugPrint('Saving Gemini API key (length: ${trimmedKey.length})');
    await prefs.setString(_geminiKeyKey, trimmedKey);
    await prefs.remove(_geminiModelKey); // Force re-discovery
  }

  Future<void> saveChatGPTKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmedKey = key.trim();
    if (trimmedKey.isEmpty) throw Exception('API key cannot be empty');

    await prefs.setString(_chatgptKeyKey, trimmedKey);
    await prefs.remove(_chatgptModelKey);
  }

  Future<String> getChatGPTModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chatgptModelKey) ?? 'gpt-4o-mini';
  }

  Future<void> setChatGPTModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatgptModelKey, model);
  }

  Future<String> getGeminiModel() async {
    final prefs = await SharedPreferences.getInstance();
    final savedModel = prefs.getString(_geminiModelKey);
    
    // Validate saved model exists in current list, otherwise use default
    if (savedModel != null && geminiModels.contains(savedModel)) {
      return savedModel;
    }
    
    // Return default and clear invalid cached model
    if (savedModel != null && !geminiModels.contains(savedModel)) {
      await prefs.remove(_geminiModelKey);
      debugPrint('Cleared invalid cached model: $savedModel');
    }
    
    return 'gemini-2.5-flash';
  }

  Future<void> setGeminiModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiModelKey, model);
  }

  // --- Smart Auto-Discovery & Validation ---

  Future<String> validateApiKey(String provider, String key) async {
    if (provider == 'gemini') {
      return await _discoverWorkingGeminiModel(key);
    } else if (provider == 'chatgpt') {
      return await _discoverWorkingChatGPTModel(key);
    }
    throw Exception('Unknown provider');
  }

  Future<String> _discoverWorkingGeminiModel(String key) async {
    debugPrint('🔍 Starting Gemini Model Discovery...');
    debugPrint('API Key check: ${key.length} chars, starts with "${key.substring(0, key.length > 10 ? 10 : key.length)}..."');
    
    final prefs = await SharedPreferences.getInstance();
    final savedModel = prefs.getString(_geminiModelKey);
    
    // 1. Try saved model first
    if (savedModel != null) {
       debugPrint('Testing saved model: $savedModel');
       if (await _testGeminiModelHttp(savedModel, key)) {
         debugPrint('✓ Saved model $savedModel is working.');
         return savedModel;
       } else {
         debugPrint('✗ Saved model $savedModel failed.');
       }
    }

    // 2. Try all available models
    debugPrint('Testing ${geminiModels.length} available models...');
    for (final modelName in geminiModels) {
      if (modelName == savedModel) continue;
      
      debugPrint('Testing model: $modelName');
      if (await _testGeminiModelHttp(modelName, key)) {
        debugPrint('✓ Found working Gemini model: $modelName');
        await setGeminiModel(modelName);
        return modelName;
      }
    }
    
    debugPrint('❌ All Gemini models failed.');
    throw Exception(
      'Could not find a working Gemini model. Please check:\n'
      '1. Your API key is valid\n'
      '2. You have internet connection\n'
      '3. Gemini API quota is not exceeded'
    );
  }

  Future<bool> _testGeminiModelHttp(String modelName, String key) async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$key';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': 'Hi'}]
          }]
        }),
      ).timeout(
        const Duration(seconds: 20), // Increased timeout to 20s
        onTimeout: () {
          debugPrint('  ⏱ Timeout testing $modelName');
          throw TimeoutException('Request timeout');
        },
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('  ✗ $modelName failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('  ✗ Exception testing $modelName: $e');
      return false;
    }
  }

  Future<String> _discoverWorkingChatGPTModel(String key) async {
    debugPrint('Starting ChatGPT Model Discovery...');
    
    final prefs = await SharedPreferences.getInstance();
    final savedModel = prefs.getString(_chatgptModelKey);
     if (savedModel != null) {
       if (await _testChatGPTModel(savedModel, key)) {
         return savedModel;
       }
    }

    for (final modelName in chatgptModels) {
      if (modelName == savedModel) continue;
      if (await _testChatGPTModel(modelName, key)) {
        await setChatGPTModel(modelName);
        return modelName;
      }
    }
    throw Exception('No working ChatGPT models found. Check your API Key.');
  }

  Future<bool> _testChatGPTModel(String modelName, String key) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: jsonEncode({
          'model': modelName,
          'messages': [{'role': 'user', 'content': 'Hi'}],
          'max_tokens': 5,
        }),
      ).timeout(const Duration(seconds: 20));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- Core Analysis Methods ---

  Future<Map<String, dynamic>> analyzeFood(String? textInput, List<int>? imageBytes) async {
    final provider = await getAIProvider();
    
    if (provider == 'gemini') {
      final key = await getGeminiKey();
      if (key == null) throw Exception('Gemini API Key not set');
      
      // Use cached model, fallback to discovery if needed
      String model;
      try {
        model = await getGeminiModel();
      } catch (e) {
        model = await _discoverWorkingGeminiModel(key);
      }
      
      try {
        return await _analyzeWithGeminiHttp(key, model, textInput, imageBytes != null ? Uint8List.fromList(imageBytes) : null);
      } catch (e) {
        debugPrint('Analysis failed with cached model $model, retrying discovery...');
        final newModel = await _discoverWorkingGeminiModel(key);
        return await _analyzeWithGeminiHttp(key, newModel, textInput, imageBytes != null ? Uint8List.fromList(imageBytes) : null);
      }
    } else {
      final key = await getChatGPTKey();
      if (key == null) throw Exception('ChatGPT API Key not set');
      
      await _discoverWorkingChatGPTModel(key);
      return await _analyzeWithChatGPT(textInput, imageBytes != null ? Uint8List.fromList(imageBytes) : null);
    }
  }

  Future<Map<String, dynamic>> _analyzeWithGeminiHttp(String apiKey, String modelName, String? textInput, Uint8List? imageBytes) async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey';
    
    final prompt = '''
Analyze this food and provide nutritional information in JSON format.
${textInput != null ? 'Food description: $textInput' : 'Analyze the food in the image.'}

Return ONLY valid JSON in this exact format:
{
  "name": "Food name",
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fat": 0,
  "servingSize": "e.g. 100g, 1 cup"
}
''';

    final Map<String, dynamic> body;
    if (imageBytes != null) {
      body = {
        'contents': [{
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Encode(imageBytes)
              }
            }
          ]
        }]
      };
    } else {
      body = {
        'contents': [{
          'parts': [{'text': prompt}]
        }]
      };
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 45), // Generous timeout for image analysis
        onTimeout: () {
          throw TimeoutException('Analysis timed out. Please check your internet connection.');
        },
      );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        if (response.statusCode == 403 || response.statusCode == 401) {
           throw Exception('Invalid API Key. Please check settings.');
        } else if (response.statusCode == 429) {
           throw Exception('Quota exceeded. Please try again later.');
        }
        throw Exception('Gemini Error (${response.statusCode}): $errorBody');
      }

      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
      
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!);
      }
      throw Exception('Could not parse AI response (Invalid JSON)');
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        throw Exception('Network error: Please check your internet connection.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _analyzeWithChatGPT(String? textInput, Uint8List? imageBytes) async {
    final apiKey = await getChatGPTKey();
    final modelName = await getChatGPTModel();

    final prompt = '''
Analyze this food and provide nutritional information in JSON format.
${textInput != null ? 'Food description: $textInput' : 'Analyze the food in the image.'}

Return ONLY valid JSON in this exact format:
{
  "name": "Food name",
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fat": 0,
  "servingSize": "e.g. 100g, 1 cup"
}
''';

    final messages = <Map<String, dynamic>>[];
    if (imageBytes != null) {
      final base64Image = base64Encode(imageBytes);
      messages.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
          }
        ]
      });
    } else {
      messages.add({'role': 'user', 'content': prompt});
    }

    return await _callChatGPT(apiKey!, modelName, messages);
  }

  Future<Map<String, dynamic>> _callChatGPT(String apiKey, String model, List<Map<String, dynamic>> messages) async {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'max_tokens': 500,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'];
        
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch != null) {
          return jsonDecode(jsonMatch.group(0)!);
        }
      }
      
      if (response.statusCode == 429) {
        throw Exception('Quota Exceeded');
      }
      
      throw Exception('API error: ${response.statusCode}');
  }

  // --- Chat / Coach Methods ---

  Future<String> chat(String prompt) async {
    final provider = await getAIProvider();
    
    try {
      if (provider == 'chatgpt') {
        final key = await getChatGPTKey();
        if (key == null) return "Please set your ChatGPT API Key in Settings.";
        await _discoverWorkingChatGPTModel(key);
        return await _chatWithChatGPT(prompt, key);
      } else {
        final key = await getGeminiKey();
        if (key == null) return "Please set your Gemini API Key in Settings.";
        
        // Use cached model if possible
        String model;
        try {
          model = await getGeminiModel();
        } catch (e) {
          model = await _discoverWorkingGeminiModel(key);
        }

        try {
          return await _chatWithGeminiHttp(prompt, key, model);
        } catch (e) {
          final newModel = await _discoverWorkingGeminiModel(key);
          return await _chatWithGeminiHttp(prompt, key, newModel);
        }
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> _chatWithGeminiHttp(String prompt, String apiKey, String modelName) async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': prompt}]
          }]
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        return "Error connecting to Gemini (HTTP): ${response.statusCode}";
      }

      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? "I'm not sure how to respond to that.";
    } catch (e) {
      return "Connection error: $e";
    }
  }

  Future<String> _chatWithChatGPT(String prompt, String apiKey) async {
    final modelName = await getChatGPTModel();
    try {
      return await _callChatGPTChat(apiKey, modelName, prompt);
    } catch (e) {
      return "Error connecting to ChatGPT: $e";
    }
  }

  Future<String> _callChatGPTChat(String apiKey, String model, String prompt) async {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      }
      
      throw Exception('API error: ${response.statusCode}');
  }

  Future<String> getSupplementAdvice(String dietSummary, String goal) async {
    final prompt = """
    Based on this diet summary: "$dietSummary" and the goal "$goal", 
    identify 1-2 potential nutrient gaps and suggest a specific supplement if needed.
    If the diet looks good, say "No supplements needed".
    Keep it very short (max 2 sentences).
    """;
    return await chat(prompt);
  }
}
