import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ai_provider.dart';
import '../../services/user_service.dart';

class AICoachScreen extends ConsumerStatefulWidget {
  const AICoachScreen({super.key});

  @override
  ConsumerState<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends ConsumerState<AICoachScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = []; // {role: 'user'/'ai', content: '...'}
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initial greeting
    _messages.add({
      'role': 'ai',
      'content': 'Hello! I\'m your MacroMate Coach. Ask me anything about your diet, workouts, or nutrition goals! 💪'
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
      _controller.clear();
    });

    try {
      final user = ref.read(userServiceProvider);
      final userContext = user != null 
          ? "User Context: Age ${user.age}, Weight ${user.weight}kg, Goal ${user.goal}, TDEE ${user.tdee}." 
          : "";
      
      final prompt = "Act as a professional nutrition and fitness coach. $userContext\nUser: $text";
      
      // We reuse the food analysis service for now, but ideally we'd have a dedicated chat method.
      // Since analyzeFood returns JSON, we'll use a direct call or modify the service.
      // For this implementation, I'll assume we can use the existing service or I'll add a chat method.
      // Let's use the existing analyzeFood but wrap the prompt to ask for JSON? 
      // actually, let's just add a chat method to GeminiService in the next step. 
      // For now, I will simulate it or use a temporary workaround.
      
      // WAIT: I should update GeminiService to support chat. 
      // I'll write this file assuming GeminiService has a `chat` method.
      
      final response = await ref.read(aiServiceProvider).chat(prompt);
      
      setState(() {
        _messages.add({'role': 'ai', 'content': response});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'content': 'Sorry, I encountered an error. Please check your API key.'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? theme.primaryColor : theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(12).copyWith(
                        bottomRight: isUser ? Radius.zero : null,
                        bottomLeft: !isUser ? Radius.zero : null,
                      ),
                    ),
                    child: Text(
                      msg['content']!,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask your coach...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: theme.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
