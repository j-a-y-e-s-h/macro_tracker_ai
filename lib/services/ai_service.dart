import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const String _geminiKeyKey = 'gemini_api_key';
  static const String _chatgptKeyKey = 'chatgpt_api_key';
  static const String _chatgptModelKey = 'chatgpt_model';
  static const String _geminiModelKey = 'gemini_model';
  static const String _aiProviderKey = 'ai_provider';
  
  // Model Lists
  static const List<String> geminiModels = [
    'gemini-2.5-flash-preview',
    'gemini-2.5-pro',
    'gemini-1.5-pro',
    'gemini-1.5-flash',
  ];

  static const List<String> chatgptModels = [
    'gpt-5',
    'gpt-5-mini',
    'gpt-5-nano',
    'gpt-4.1-mini',
    'o3',
    'o4-mini',
    'gpt-4o',
  ];

  // Getters & Setters
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
  }

  Future<void> saveChatGPTKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatgptKeyKey, key);
  }

  Future<String> getChatGPTModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chatgptModelKey) ?? 'gpt-4o';
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

  // Smart Model Validation
  Future<String> validateApiKey(String provider, String key) async {
    if (provider == 'gemini') {
      return await _findWorkingGeminiModel(key);
    } else if (provider == 'chatgpt') {
      return await _findWorkingChatGPTModel(key);
    }
    throw Exception('Unknown provider');
  }

  Future<String> _findWorkingGeminiModel(String key) async {
    // Try the user's selected model first (if any), then iterate through the list
    final selectedModel = await getGeminiModel();
    final modelsToTry = [selectedModel, ...geminiModels.where((m) => m != selectedModel)];

    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: key);
        await model.generateContent([Content.text('Test')]);
        return modelName; // Found a working model
      } catch (e) {
        print('Model $modelName failed: $e');
        continue;
      }
    }
    throw Exception('No working Gemini models found. Check your API Key.');
  }

  Future<String> _findWorkingChatGPTModel(String key) async {
    final selectedModel = await getChatGPTModel();
    final modelsToTry = [selectedModel, ...chatgptModels.where((m) => m != selectedModel)];

    for (final modelName in modelsToTry) {
      try {
        final response = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $key',
          },
          body: jsonEncode({
            'model': modelName,
            'messages': [{'role': 'user', 'content': 'Test'}],
            'max_tokens': 5,
          }),
        );

        if (response.statusCode == 200) {
          return modelName;
        }
      } catch (e) {
        print('Model $modelName failed: $e');
        continue;
      }
    }
    throw Exception('No working ChatGPT models found. Check your API Key.');
  }

  // Analyze food with AI (text or image)
  Future<Map<String, dynamic>> analyzeFood(String? textInput, List<int>? imageBytes) async {
    final provider = await getAIProvider();
    
    try {
      if (provider == 'chatgpt') {
        return await _analyzeWithChatGPT(textInput, imageBytes != null ? Uint8List.fromList(imageBytes) : null);
      } else {
        return await _analyzeWithGemini(textInput, imageBytes != null ? Uint8List.fromList(imageBytes) : null);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _analyzeWithGemini(String? textInput, Uint8List? imageBytes) async {
    final apiKey = await getGeminiKey();
    if (apiKey == null) throw Exception('Gemini API Key not set');

    // Smart Selection: Try selected model, fallback to others if it fails
    String modelName = await getGeminiModel();
    
    // If image is present, ensure we use a vision-capable model if the selected one isn't (simplified check)
    // For now, we assume all models in our list might support vision or we let the smart fallback handle it.
    // Actually, 1.0-pro doesn't support vision, but 1.5-flash/pro do. 
    // Let's rely on the try-catch block to switch models.

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

    // Try selected model first
    try {
      final model = GenerativeModel(model: modelName, apiKey: apiKey);
      return await _generateContent(model, prompt, imageBytes);
    } catch (e) {
      print('Selected Gemini model $modelName failed: $e. Attempting smart fallback...');
      
      // Fallback loop
      for (final fallbackModel in geminiModels) {
        if (fallbackModel == modelName) continue;
        try {
           final model = GenerativeModel(model: fallbackModel, apiKey: apiKey);
           final result = await _generateContent(model, prompt, imageBytes);
           // If successful, update the preference so we use this working model next time?
           // Maybe not, user might want to stick to their choice. But for "Smart" behavior, we could.
           // For now, just return the result.
           return result;
        } catch (e2) {
          continue;
        }
      }
      throw Exception('All Gemini models failed. Please check your API key or internet connection.');
    }
  }

  Future<Map<String, dynamic>> _generateContent(GenerativeModel model, String prompt, Uint8List? imageBytes) async {
    final Content content;
    if (imageBytes != null) {
      content = Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]);
    } else {
      content = Content.text(prompt);
    }

    final response = await model.generateContent([content]);
    final text = response.text ?? '';
    
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch != null) {
      return jsonDecode(jsonMatch.group(0)!);
    }
    
    throw Exception('Could not parse AI response');
  }

  Future<Map<String, dynamic>> _analyzeWithChatGPT(String? textInput, Uint8List? imageBytes) async {
    final apiKey = await getChatGPTKey();
    if (apiKey == null) throw Exception('ChatGPT API Key not set');

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

    String modelName = await getChatGPTModel();
    // Force vision capable model if image is present and selected model is known not to support it?
    // For now, we'll try the selected model and fallback.

    try {
      return await _callChatGPT(apiKey, modelName, messages);
    } catch (e) {
      print('Selected ChatGPT model $modelName failed: $e. Attempting smart fallback...');
       for (final fallbackModel in chatgptModels) {
        if (fallbackModel == modelName) continue;
        try {
           return await _callChatGPT(apiKey, fallbackModel, messages);
        } catch (e2) {
          continue;
        }
      }
      throw Exception('All ChatGPT models failed. Please check your API key or quota.');
    }
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

  // Chat function for AI Coach
  Future<String> chat(String prompt) async {
    final provider = await getAIProvider();
    
    try {
      if (provider == 'chatgpt') {
        return await _chatWithChatGPT(prompt);
      } else {
        return await _chatWithGemini(prompt);
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> _chatWithGemini(String prompt) async {
    final apiKey = await getGeminiKey();
    if (apiKey == null) return "Please set your Gemini API Key in Settings.";

    String modelName = await getGeminiModel();

    try {
      final model = GenerativeModel(model: modelName, apiKey: apiKey);
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? "I'm not sure how to respond to that.";
    } catch (e) {
       // Fallback
       for (final fallbackModel in geminiModels) {
        if (fallbackModel == modelName) continue;
        try {
           final model = GenerativeModel(model: fallbackModel, apiKey: apiKey);
           final response = await model.generateContent([Content.text(prompt)]);
           return response.text ?? "I'm not sure how to respond to that.";
        } catch (e2) {
          continue;
        }
      }
      return "Error connecting to Gemini: $e";
    }
  }

  Future<String> _chatWithChatGPT(String prompt) async {
    final apiKey = await getChatGPTKey();
    if (apiKey == null) return "Please set your ChatGPT API Key in Settings.";

    String modelName = await getChatGPTModel();

    try {
      return await _callChatGPTChat(apiKey, modelName, prompt);
    } catch (e) {
      // Fallback
       for (final fallbackModel in chatgptModels) {
        if (fallbackModel == modelName) continue;
        try {
           return await _callChatGPTChat(apiKey, fallbackModel, prompt);
        } catch (e2) {
          continue;
        }
      }
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
}
