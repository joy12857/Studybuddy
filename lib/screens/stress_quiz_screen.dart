import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StressQuizScreen extends StatefulWidget {
  const StressQuizScreen({super.key});

  @override
  State<StressQuizScreen> createState() => _StressQuizScreenState();
}

class _StressQuizScreenState extends State<StressQuizScreen> {
  int currentStage = 0; // 0: Start, 1: Quiz, 2: Result
  int currentQuestionIndex = 0;
  int totalScore = 0;
  int? selectedAnswerIndex;

  final List<Map<String, dynamic>> questions = [
    {
      "text": "I found it difficult to wind down or relax after a stressful day.",
      "category": "stress"
    },
    {
      "text": "I felt that I was using a lot of nervous energy or feeling jittery.",
      "category": "stress"
    },
    {
      "text": "I felt sad, downhearted, or unmotivated to do my regular tasks.",
      "category": "depression"
    },
    {
      "text": "I found myself getting agitated, irritable, or impatient easily.",
      "category": "stress"
    },
    {
      "text": "I felt that I had nothing positive or exciting to look forward to.",
      "category": "depression"
    },
    {
      "text": "I experienced trouble sleeping, staying asleep, or woke up exhausted.",
      "category": "anxiety"
    },
    {
      "text": "I found it hard to focus, concentrate, or make decisions about my studies.",
      "category": "anxiety"
    }
  ];

  final List<Map<String, dynamic>> options = [
    {"text": "Never / Not at all", "score": 0},
    {"text": "Sometimes / Mildly", "score": 1},
    {"text": "Often / Moderately", "score": 2},
    {"text": "Almost Always / Severely", "score": 3},
  ];

  void startQuiz() {
    setState(() {
      currentStage = 1;
      currentQuestionIndex = 0;
      totalScore = 0;
      selectedAnswerIndex = null;
    });
  }

  void selectAnswer(int index) {
    setState(() {
      selectedAnswerIndex = index;
    });
  }

  void nextQuestion() {
    if (selectedAnswerIndex == null) return;

    totalScore += options[selectedAnswerIndex!]["score"] as int;

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswerIndex = null;
      });
    } else {
      saveQuizResult();
      setState(() {
        currentStage = 2;
      });
    }
  }

  Future<void> saveQuizResult() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('latest_stress_score', totalScore);
    await prefs.setString('latest_stress_date', DateTime.now().toIso8601String());
  }

  Map<String, dynamic> getResultDetails() {
    if (totalScore <= 6) {
      return {
        "level": "Low / Normal Stress",
        "color": const Color(0xFF10B981),
        "desc": "Your stress levels are currently low. Keep maintaining your balance with light walks, good sleep, and healthy habits!",
        "recommendations": [
          "Continue practicing mindfulness 5-10 minutes daily.",
          "Keep a regular sleep schedule of 7-8 hours.",
          "Engage in hobbies or social activities that make you happy."
        ]
      };
    } else if (totalScore <= 13) {
      return {
        "level": "Moderate Stress",
        "color": const Color(0xFFF59E0B),
        "desc": "You are experiencing moderate stress. Try setting healthy boundaries, doing deep breathing exercises, and taking regular study breaks.",
        "recommendations": [
          "Try our Guided Mindful Breathing session.",
          "Break down heavy workloads into small, manageable Pomodoro sessions.",
          "Avoid excessive caffeine and practice winding down before sleep."
        ]
      };
    } else {
      return {
        "level": "High Stress",
        "color": const Color(0xFFEF4444),
        "desc": "You are experiencing high stress levels. It might be helpful to reach out to a professional or counselor for guidance.",
        "recommendations": [
          "Schedule a chat with a counselor via our 'Book Counselor' screen.",
          "Prioritize rest and temporarily reduce optional commitments.",
          "Reach out to close friends or family to share what you are going through."
        ]
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Stress Assessment",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: currentStage == 0
              ? _buildStartWidget(theme)
              : currentStage == 1
                  ? _buildQuizWidget(theme)
                  : _buildResultWidget(theme),
        ),
      ),
    );
  }

  Widget _buildStartWidget(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.quiz_rounded, size: 80, color: Color(0xFF10B981)),
        const SizedBox(height: 24),
        Text(
          "Stress & Anxiety Quiz",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "This 7-question quiz helps you evaluate your stress, anxiety, and depression indicators over the past week. Please answer honestly based on how you have been feeling.",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCFCE7)),
          ),
          child: Row(
            children: [
              const Icon(Icons.security_rounded, color: Color(0xFF16A34A)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Your responses are private and stored locally on your device.",
                  style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF15803D)),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: startQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: Text(
              "Start Assessment",
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizWidget(ThemeData theme) {
    final progress = (currentQuestionIndex + 1) / questions.length;
    final question = questions[currentQuestionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Question ${currentQuestionIndex + 1} of ${questions.length}",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
            Text(
              "${(progress * 100).toInt()}% Done",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 40),
        // Question Text Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Text(
            question["text"],
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
        const SizedBox(height: 30),
        // Answers Options List
        Expanded(
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              final opt = options[index];
              final isSelected = selectedAnswerIndex == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => selectAnswer(index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade400,
                              width: 2,
                            ),
                            color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            opt["text"],
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF1E293B) : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: selectedAnswerIndex == null ? null : nextQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: Text(
              currentQuestionIndex == questions.length - 1 ? "View Results" : "Next Question",
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultWidget(ThemeData theme) {
    final details = getResultDetails();
    final Color scoreColor = details["color"];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Text(
            "Your Stress Score",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),
          // Score Circle
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scoreColor, width: 8),
                color: Colors.white,
              ),
              child: Center(
                child: Text(
                  "$totalScore",
                  style: GoogleFonts.outfit(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            details["level"],
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            details["desc"],
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey.shade700, height: 1.5),
          ),
          const SizedBox(height: 30),
          // Recommendation Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Actionable Steps",
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color),
                ),
                const SizedBox(height: 12),
                ... (details["recommendations"] as List<String>).map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: scoreColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              rec,
                              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                            ),
                          )
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: startQuiz,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: const BorderSide(color: Color(0xFF10B981)),
                  ),
                  child: Text(
                    "Retake Quiz",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    "Wellness Dashboard",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}