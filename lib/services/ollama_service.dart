import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class OllamaService {
  // static const String _baseUrl = 'http://localhost:11434/api'; // Now dynamic

  Future<Map<String, dynamic>> analyzeFood(String? textInput, Uint8List? imageBytes, String baseUrl) async {
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

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': imageBytes != null ? 'llava' : 'llama3',
          'prompt': prompt,
          'stream': false,
          'format': 'json', // Force JSON mode if supported
          if (imageBytes != null) 'images': [base64Encode(imageBytes)],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['response'] as String;
        
        // Extract JSON
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch != null) {
          return jsonDecode(jsonMatch.group(0)!);
        }
      }
      
      throw Exception('Ollama API error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Ollama analysis failed: $e. Ensure Ollama is running and models (llama3, llava) are installed.');
    }
  }

  Future<String> chat(String prompt, String baseUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'llama3',
          'prompt': prompt,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] as String;
      }
      
      return "Ollama API error: ${response.statusCode}";
    } catch (e) {
      return "Error connecting to Ollama: $e";
    }
  }
}
