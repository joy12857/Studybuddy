import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_fallback_engine.dart';

class OpenAIService {
  // ⚠️ Do NOT put raw secrets here before pushing to GitHub.
  // Use the in-app 🔑 Key Manager or SharedPreferences to set your key.
  static const String _defaultApiKey = 'YOUR_GROQ_API_KEY_HERE';

  // Active Groq models
  static const String _model = 'qwen/qwen3.8-27b';
  static const String _fallbackModel = 'llama-3.3-70b-versatile';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static const String _prefKey = 'groq_api_key';

  static const String _systemPrompt = '''
You are a compassionate, knowledgeable, and supportive AI tutor & wellness companion inside "StudyBuddy" — a student mental health and academic app.
Your role is to:
- Provide empathetic, warm, and supportive responses about mental health, stress, anxiety, mood, study burnout, loneliness, sleep issues, and general emotional wellbeing.
- Give practical, evidence-based coping strategies (breathing exercises, grounding techniques, Pomodoro study tips, sleep hygiene etc.).
- When a student requests study suggestions, focus on their selected Subject, Topic, and academic Challenges/Issues:
  * For Procrastination/Time Management: suggest techniques like Pomodoro, micro-goals, or timeboxed active recall.
  * For Concentration/Focus: suggest sensory adjustments, structured study sprints, and cognitive resets.
  * For Exam Anxiety: integrate calming exercises, mindset shifts, and mock-test preparation.
  * For Feeling Burnt Out: recommend paced scheduling, restorative activities, and stress reduction.
  * For Hard to Understand: encourage the Feynman technique, analogies, and breaking concepts down into core components.
- When generating quizzes or study notes, adhere strictly to the requested schema or output format.
- Encourage students to seek professional help when needed (mention counselors available in the app).
- Keep responses concise but action-oriented (usually 3 to 5 sentences or short bullet points for study plans).
- Use occasional appropriate emojis to feel warm and approachable.
- NEVER provide medical diagnoses or replace professional therapy.
- NEVER give harmful advice.
- If someone mentions self-harm or suicidal thoughts, gently urge them to contact a crisis helpline or a trusted adult immediately.
- Always respond in the same language the user writes in.
''';

  final List<Map<String, String>> _conversationHistory = [];

  // ===========================================================================
  // KEY MANAGEMENT
  // ===========================================================================

  /// Retrieves the currently active Groq API key (SharedPreferences takes priority over static default).
  static Future<String> getActiveApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedKey = prefs.getString(_prefKey);
      if (storedKey != null && storedKey.trim().isNotEmpty) {
        return storedKey.trim();
      }
    } catch (_) {}
    return _defaultApiKey.trim();
  }

  /// Saves a Groq API key into SharedPreferences.
  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, key.trim());
  }

  /// Clears any custom key stored in SharedPreferences.
  static Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  /// Returns true if a non-placeholder API key is available.
  static Future<bool> isKeyConfigured() async {
    final key = await getActiveApiKey();
    return key.isNotEmpty && key != 'YOUR_GROQ_API_KEY_HERE';
  }

  /// Tests whether a given Groq API key is valid by sending a minimal test completion.
  static Future<Map<String, dynamic>> testApiKey(String candidateKey) async {
    final trimmed = candidateKey.trim();
    if (trimmed.isEmpty || trimmed == 'YOUR_GROQ_API_KEY_HERE') {
      return {'success': false, 'message': 'API key cannot be empty or default placeholder.'};
    }

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $trimmed',
              'User-Agent': 'StudyBuddy-App/1.0',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'user', 'content': 'hi'},
              ],
              'max_tokens': 5,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'API key verified successfully with Groq!'};
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'Authentication failed (401). Please verify your Groq key.'};
      } else {
        return {'success': false, 'message': 'Groq returned status code ${response.statusCode}.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ===========================================================================
  // SEND MESSAGE
  // ===========================================================================

  Future<String> sendMessage(String userMessage) async {
    final activeKey = await getActiveApiKey();
    final bool hasValidKey = activeKey.isNotEmpty && activeKey != 'YOUR_GROQ_API_KEY_HERE';

    // If key is not configured, gracefully fallback to the smart built-in engine
    if (!hasValidKey) {
      final fallbackReply = AiFallbackEngine.generateFallbackResponse(userMessage);
      final isStructured = userMessage.contains('JSON schema:') || userMessage.contains('Summarize');
      if (isStructured) {
        return fallbackReply;
      }
      return '$fallbackReply\n\n*(💡 AI Tutor Note: Running with built-in assistant. To connect live Groq Cloud AI, tap the 🔑 key icon in the top right to paste your free Groq API key.)*';
    }

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
      final response = await _executeRequest(activeKey, _model, messages);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botReply = (data['choices'][0]['message']['content'] as String).trim();

        _conversationHistory.add({
          'role': 'assistant',
          'content': botReply,
        });

        return botReply;
      } else if (response.statusCode == 401) {
        if (_conversationHistory.isNotEmpty) _conversationHistory.removeLast();
        final fallback = AiFallbackEngine.generateFallbackResponse(userMessage);
        return '⚠️ **AI authentication failed (401 Unauthorized)**\nYour Groq API key was rejected by Groq. Please check if your key is active at https://console.groq.com/keys, or tap the 🔑 key icon above to enter a new key.\n\n---\n**Local AI Response:**\n$fallback';
      } else if (response.statusCode == 404 || response.statusCode == 400) {
        // Try fallback model if the primary model is unavailable
        final retry = await _executeRequest(activeKey, _fallbackModel, messages);
        if (retry.statusCode == 200) {
          final data = jsonDecode(retry.body);
          final botReply = (data['choices'][0]['message']['content'] as String).trim();
          _conversationHistory.add({'role': 'assistant', 'content': botReply});
          return botReply;
        }
        if (_conversationHistory.isNotEmpty) _conversationHistory.removeLast();
        return AiFallbackEngine.generateFallbackResponse(userMessage);
      } else if (response.statusCode == 429) {
        if (_conversationHistory.isNotEmpty) _conversationHistory.removeLast();
        final fallback = AiFallbackEngine.generateFallbackResponse(userMessage);
        return '⏳ **Groq rate limit reached.** Showing offline study assistant response:\n\n$fallback';
      } else {
        if (_conversationHistory.isNotEmpty) _conversationHistory.removeLast();
        return AiFallbackEngine.generateFallbackResponse(userMessage);
      }
    } catch (_) {
      if (_conversationHistory.isNotEmpty) _conversationHistory.removeLast();
      // On connection error or timeout, provide offline response seamlessly
      final fallback = AiFallbackEngine.generateFallbackResponse(userMessage);
      final isStructured = userMessage.contains('JSON schema:') || userMessage.contains('Summarize');
      if (isStructured) return fallback;
      return '$fallback\n\n*(🌐 Offline mode: Unable to reach Groq Cloud. Displaying local study guidance.)*';
    }
  }

  Future<http.Response> _executeRequest(
    String key,
    String modelName,
    List<Map<String, String>> messages,
  ) {
    return http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
        'User-Agent': 'StudyBuddy-App/1.0',
      },
      body: jsonEncode({
        'model': modelName,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1500,
      }),
    ).timeout(const Duration(seconds: 30));
  }

  void clearHistory() {
    _conversationHistory.clear();
  }
}
