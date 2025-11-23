import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<Map<String, dynamic>> analyzeFood(String? textInput, Uint8List? imageBytes, String apiKey) async {
    if (imageBytes != null) {
      // Groq Llama 3.2 11b Vision Preview support
      return _analyzeWithVision(textInput, imageBytes, apiKey);
    }

    final prompt = '''
Analyze this food and provide nutritional information in JSON format.
Food description: $textInput

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
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.2-11b-vision-preview', // Supports text too
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'response_format': {'type': 'json_object'}, // Groq supports JSON mode
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'];
        return jsonDecode(text);
      }
      
      throw Exception('Groq API error: ${response.statusCode} - ${response.body}');
    } catch (e) {
      throw Exception('Groq analysis failed: $e');
    }
  }

  Future<Map<String, dynamic>> _analyzeWithVision(String? textInput, Uint8List imageBytes, String apiKey) async {
    final prompt = '''
Analyze this food image and provide nutritional information in JSON format.
${textInput != null ? 'Additional info: $textInput' : ''}

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

    final base64Image = base64Encode(imageBytes);

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.2-11b-vision-preview',
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
                }
              ]
            }
          ],
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'];
        return jsonDecode(text);
      }
      
      throw Exception('Groq Vision API error: ${response.statusCode} - ${response.body}');
    } catch (e) {
      throw Exception('Groq Vision analysis failed: $e');
    }
  }

  Future<String> chat(String prompt, String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama3-70b-8192', // Fast and smart
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      }
      
      return "Groq API error: ${response.statusCode}";
    } catch (e) {
      return "Error connecting to Groq: $e";
    }
  }
}
