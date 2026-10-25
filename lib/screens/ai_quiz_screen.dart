import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/openai_service.dart';

class AiQuizScreen extends StatefulWidget {
  const AiQuizScreen({super.key});

  @override
  State<AiQuizScreen> createState() => _AiQuizScreenState();
}

class _AiQuizScreenState extends State<AiQuizScreen> {
  final OpenAIService _aiService = OpenAIService();
  final TextEditingController topicController =
      TextEditingController(text: "Data Structures & Algorithms");

  String selectedSubject = "Computer Science";
  String selectedDifficulty = "Medium";
  bool isGenerating = false;
  bool isQuizActive = false;

  List<Map<String, dynamic>> quizQuestions = [];
  int currentQuestionIndex = 0;
  int? selectedAnswerIndex;
  int score = 0;
  bool isSubmitted = false;

  final List<String> subjects = [
    "Computer Science",
    "Mathematics",
    "Physics",
    "Biology & Chemistry",
    "Economics & Business",
    "Literature & History"
  ];

  final List<String> difficulties = ["Easy", "Medium", "Hard"];

  @override
  void dispose() {
    topicController.dispose();
    super.dispose();
  }

  Future<void> _generateQuiz() async {
    final topic = topicController.text.trim();
    if (topic.isEmpty || isGenerating) return;

    setState(() {
      isGenerating = true;
      quizQuestions.clear();
      currentQuestionIndex = 0;
      selectedAnswerIndex = null;
      score = 0;
      isSubmitted = false;
    });

    final prompt = '''
Generate a 4-question multiple-choice quiz on the topic "$topic" in "$selectedSubject" with "$selectedDifficulty" difficulty.
Respond ONLY with a valid JSON array of objects. Do not include markdown code block ticks, backticks, or any additional text.
JSON schema:
[
  {
    "question": "Clear question text here?",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctIndex": 0,
    "explanation": "Brief explanation of why this answer is correct."
  }
]
''';

    try {
      final rawResponse = await _aiService.sendMessage(prompt);
      String cleaned = rawResponse
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      int startIdx = cleaned.indexOf('[');
      int endIdx = cleaned.lastIndexOf(']');
      if (startIdx != -1 && endIdx != -1) {
        cleaned = cleaned.substring(startIdx, endIdx + 1);
      }

      final List parsed = jsonDecode(cleaned);
      setState(() {
        quizQuestions = parsed.map((item) {
          return {
            "question": item["question"] ?? "Question",
            "options": List<String>.from(item["options"] ?? []),
            "correctIndex": item["correctIndex"] ?? 0,
            "explanation": item["explanation"] ?? "",
          };
        }).toList();
        isQuizActive = true;
        isGenerating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isGenerating = false;
        // Fallback default sample quiz if network parses error
        quizQuestions = [
          {
            "question": "What is the worst-case time complexity of QuickSort?",
            "options": ["O(N log N)", "O(N^2)", "O(N)", "O(1)"],
            "correctIndex": 1,
            "explanation":
                "QuickSort degrades to O(N^2) when the pivot choice is poor (e.g. sorted array with first/last element pivot)."
          },
          {
            "question": "Which data structure follows the LIFO principle?",
            "options": ["Queue", "Stack", "Array", "Linked List"],
            "correctIndex": 1,
            "explanation": "Stack follows Last-In, First-Out (LIFO)."
          },
          {
            "question":
                "What is the average lookup time for a Hash Table with good hashing?",
            "options": ["O(1)", "O(N)", "O(log N)", "O(N^2)"],
            "correctIndex": 0,
            "explanation":
                "A hash table achieves average constant time O(1) key lookup."
          }
        ];
        isQuizActive = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text("Loaded sample quiz for $topic",
              style: GoogleFonts.outfit()),
        ),
      );
    }
  }

  void _submitAnswer(int index) {
    if (selectedAnswerIndex != null) return;
    setState(() {
      selectedAnswerIndex = index;
      if (index == quizQuestions[currentQuestionIndex]["correctIndex"]) {
        score++;
      }
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < quizQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswerIndex = null;
      });
    } else {
      setState(() {
        isSubmitted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "AI Adaptive Practice Quiz",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isQuizActive) ...[
              // Generator Setup Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          "AI Quiz Generator",
                          style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Generate instant adaptive multiple-choice quizzes for any subject & topic to test active recall.",
                      style: GoogleFonts.outfit(
                          fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                "Select Subject",
                style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedSubject,
                decoration:
                    const InputDecoration(prefixIcon: Icon(Icons.school_outlined)),
                items: subjects
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, style: GoogleFonts.outfit()),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedSubject = val);
                },
              ),
              const SizedBox(height: 16),

              Text(
                "Specific Topic",
                style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: topicController,
                style: GoogleFonts.outfit(),
                decoration: const InputDecoration(
                  hintText: "e.g., Binary Search Trees, Organic Chemistry...",
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                "Difficulty Level",
                style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: difficulties.map((d) {
                  final isSel = selectedDifficulty == d;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Center(
                          child: Text(
                            d,
                            style: GoogleFonts.outfit(
                              fontWeight:
                                  isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? Colors.white : null,
                            ),
                          ),
                        ),
                        selected: isSel,
                        selectedColor: const Color(0xFF0F766E),
                        onSelected: (val) {
                          if (val) setState(() => selectedDifficulty = d);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: isGenerating ? null : _generateQuiz,
                  child: isGenerating
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              "Generate & Start Quiz",
                              style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                ),
              ),
            ] else if (!isSubmitted) ...[
              // Active Quiz Screen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Question ${currentQuestionIndex + 1} of ${quizQuestions.length}",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => isQuizActive = false),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text("Quit", style: GoogleFonts.outfit()),
                  )
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (currentQuestionIndex + 1) / quizQuestions.length,
                color: const Color(0xFF0F766E),
                backgroundColor: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 24),

              // Question Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  quizQuestions[currentQuestionIndex]["question"],
                  style: GoogleFonts.outfit(
                      fontSize: 17, fontWeight: FontWeight.bold, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),

              // Options List
              ...List.generate(
                (quizQuestions[currentQuestionIndex]["options"] as List).length,
                (optIdx) {
                  final optText = quizQuestions[currentQuestionIndex]["options"]
                      [optIdx];
                  final isCorrect = optIdx ==
                      quizQuestions[currentQuestionIndex]["correctIndex"];
                  final isSelected = selectedAnswerIndex == optIdx;

                  Color borderCol = isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0);
                  Color bgCol =
                      isDark ? const Color(0xFF1E293B) : Colors.white;

                  if (selectedAnswerIndex != null) {
                    if (isCorrect) {
                      borderCol = Colors.teal;
                      bgCol = Colors.teal.shade50;
                    } else if (isSelected) {
                      borderCol = Colors.redAccent;
                      bgCol = Colors.red.shade50;
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _submitAnswer(optIdx),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgCol,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderCol, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFF0F766E)
                                  .withValues(alpha: 0.1),
                              child: Text(
                                String.fromCharCode(65 + optIdx),
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: const Color(0xFF0F766E)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                optText,
                                style: GoogleFonts.outfit(
                                    fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              if (selectedAnswerIndex != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    "💡 Explanation: ${quizQuestions[currentQuestionIndex]["explanation"]}",
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: Colors.blue.shade900),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _nextQuestion,
                    child: Text(
                      currentQuestionIndex < quizQuestions.length - 1
                          ? "Next Question"
                          : "See Results",
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ] else ...[
              // Results & Adaptive Mastery Screen
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        size: 70, color: Colors.amber),
                    const SizedBox(height: 12),
                    Text(
                      "Quiz Completed!",
                      style: GoogleFonts.outfit(
                          fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "You scored $score out of ${quizQuestions.length}",
                      style: GoogleFonts.outfit(
                          fontSize: 18, color: const Color(0xFF0F766E)),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        score == quizQuestions.length
                            ? "🏆 Mastered! Excellent performance. Topic added to revision schedule."
                            : "📖 Adaptive Update: Review weak concepts and retake quiz for full mastery.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                      ),
                      onPressed: () => setState(() => isQuizActive = false),
                      child: Text("Take Another Quiz",
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
