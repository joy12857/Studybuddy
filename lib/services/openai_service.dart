import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  // ⚠️ Replace with your actual Groq API key. Do NOT commit real keys to GitHub.
  static const String _apiKey = 'YOUR_GROQ_API_KEY_HERE';
  static const String _model = 'qwen/qwen3.8-27b';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static const String _systemPrompt = '''
You are a compassionate and supportive AI wellness companion inside "StudyBuddy" — a mental health app for students.
Your role is to:
- Provide empathetic, warm, and supportive responses about mental health, stress, anxiety, mood, study burnout, loneliness, sleep issues, and general emotional wellbeing.
- Give practical, evidence-based coping strategies (breathing exercises, grounding techniques, Pomodoro study tips, sleep hygiene etc.).
- When a student requests study suggestions, focus on their selected Subject, Topic, and academic Challenges/Issues:
  * For Procrastination/Time Management: suggest techniques like Pomodoro, micro-goals, or timeboxed active recall.
  * For Concentration/Focus: suggest sensory adjustments, structured study sprints, and cognitive resets.
  * For Exam Anxiety: integrate calming exercises, mindset shifts, and mock-test preparation.
  * For Feeling Burnt Out: recommend paced scheduling, restorative activities, and stress reduction.
  * For Hard to Understand: encourage the Feynman technique, analogies, and breaking concepts down into core components.
- Encourage students to seek professional help when needed (mention counselors available in the app).
- Keep responses concise but action-oriented (usually 3 to 5 sentences or short bullet points for study plans).
- Use occasional appropriate emojis to feel warm and approachable, but don't overdo it.
- NEVER provide medical diagnoses or replace professional therapy.
- NEVER give harmful advice.
- If someone mentions self-harm or suicidal thoughts, gently urge them to contact a crisis helpline or a trusted adult immediately.
- Always respond in the same language the user writes in.
''';

  final List<Map<String, String>> _conversationHistory = [];

  Future<String> sendMessage(String userMessage) async {
    // Add user message to history
    _conversationHistory.add({
      'role': 'user',
      'content': userMessage,
    });

    final messages = [
      {
        'role': 'system',
        'content': _systemPrompt,
      },
      ..._conversationHistory,
    ];

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'User-Agent': 'StudyBuddy-App/1.0',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.8,
          'max_tokens': 512,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botReply = data['choices'][0]['message']['content'] as String;

        // Add assistant reply to conversation history
        _conversationHistory.add({
          'role': 'assistant',
          'content': botReply,
        });

        return botReply.trim();
      } else if (response.statusCode == 401) {
        if (_conversationHistory.isNotEmpty) _conversationHistory.removeLast();
        return '⚠️ AI authentication failed. Please check if the Groq API key is correct and active in openai_service.dart.';
      } else if (response.statusCode == 429) {
        if (_conversationHistory.isNotEmpty) _conversationHistory.removeLast();
        try {
          final errData = jsonDecode(response.body);
          final errCode = errData['error']?['code'] ?? '';
          if (errCode == 'insufficient_quota') {
            return '⚠️ OpenAI API quota exceeded. Please check your billing plan/credits at platform.openai.com.';
          }
        } catch (_) {}
        return '⏳ I\'m receiving too many requests or the API limit has been reached. Please try again in a moment.';
      } else {
        if (_conversationHistory.isNotEmpty) _conversationHistory.removeLast();
        return '⚠️ Something went wrong. Please try again.';
      }
    } catch (e) {
      if (_conversationHistory.isNotEmpty) _conversationHistory.removeLast();
      return '🌐 Unable to connect to AI. Please check your internet connection and try again.';
    }
  }

  void clearHistory() {
    _conversationHistory.clear();
  }
}
