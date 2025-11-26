import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

final aiServiceProvider = Provider<AIService>((ref) => AIService());

class AIService {
  static const String _geminiKeyKey = 'gemini_api_key';
  static const String _chatgptKeyKey = 'chatgpt_api_key';
  static const String _chatgptModelKey = 'chatgpt_model';
  static const String _geminiModelKey = 'gemini_model';
  static const String _aiProviderKey = 'ai_provider';
  
  // Model Lists
  static const List<String> geminiModels = [
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-pro',
    'gemini-1.0-pro',
    'gemini-2.0-flash-exp', // Experimental
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
    await prefs.setString(_geminiKeyKey, key);
    await prefs.remove(_geminiModelKey);
  }

  Future<void> saveChatGPTKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatgptKeyKey, key);
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
    return prefs.getString(_geminiModelKey) ?? 'gemini-1.5-flash';
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
    debugPrint('Starting Gemini Model Discovery (HTTP)...');
    
    final prefs = await SharedPreferences.getInstance();
    final savedModel = prefs.getString(_geminiModelKey);
    if (savedModel != null) {
       if (await _testGeminiModelHttp(savedModel, key)) {
         debugPrint('Saved Gemini model $savedModel is working.');
         return savedModel;
       }
    }

    for (final modelName in geminiModels) {
      if (modelName == savedModel) continue;
      
      debugPrint('Testing Gemini model: $modelName');
      if (await _testGeminiModelHttp(modelName, key)) {
        debugPrint('Found working Gemini model: $modelName');
        await setGeminiModel(modelName);
        return modelName;
      }
    }
    throw Exception('No working Gemini models found. Check your API Key and internet connection.');
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
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Gemini HTTP Test failed for $modelName: $e');
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
      );
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
      
      await _discoverWorkingGeminiModel(key); 
      return await _analyzeWithGeminiHttp(key, await getGeminiModel(), textInput, imageBytes != null ? Uint8List.fromList(imageBytes) : null);
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

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini HTTP Error: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
    
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch != null) {
      return jsonDecode(jsonMatch.group(0)!);
    }
    throw Exception('Could not parse AI response (HTTP)');
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
      );

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
        await _discoverWorkingGeminiModel(key);
        return await _chatWithGeminiHttp(prompt, key, await getGeminiModel());
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> _chatWithGeminiHttp(String prompt, String apiKey, String modelName) async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{
          'parts': [{'text': prompt}]
        }]
      }),
    );

    if (response.statusCode != 200) {
      return "Error connecting to Gemini (HTTP): ${response.statusCode}";
    }

    final data = jsonDecode(response.body);
    return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? "I'm not sure how to respond to that.";
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
      );

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
