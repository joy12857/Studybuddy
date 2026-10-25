import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/academic_models.dart';
import '../services/openai_service.dart';
import '../widgets/interactive_animations.dart';

class FocusFlashcardsScreen extends StatefulWidget {
  const FocusFlashcardsScreen({super.key});

  @override
  State<FocusFlashcardsScreen> createState() => _FocusFlashcardsScreenState();
}

class _FocusFlashcardsScreenState extends State<FocusFlashcardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 1. Pomodoro Timer State
  int _secondsRemaining = 25 * 60;
  bool _isTimerRunning = false;
  Timer? _timer;
  int _completedSessions = 0;

  // 2. Flashcards State
  final List<Flashcard> _flashcards = [
    Flashcard(
      id: '1',
      courseCode: 'CSE-101',
      question: 'What is the time complexity of Binary Search?',
      answer: 'O(log N) in a sorted array.',
    ),
    Flashcard(
      id: '2',
      courseCode: 'MAT-201',
      question: 'State the Fundamental Theorem of Calculus.',
      answer:
          'It connects differentiation and integration, showing they are inverse processes.',
    ),
    Flashcard(
      id: '3',
      courseCode: 'PHY-102',
      question: 'What is Gauss\'s Law for Electricity?',
      answer: 'The net electric flux through any closed surface is proportional to the enclosed electric charge.',
    ),
  ];

  int _currentCardIndex = 0;
  bool _showAnswer = false;

  // 3. Exam Countdown State — starts empty, loaded from SharedPreferences
  List<Map<String, dynamic>> _exams = [];

  // 4. AI Notes State
  final OpenAIService _aiService = OpenAIService();
  final TextEditingController _notesInputController = TextEditingController();
  String _aiGeneratedSummary = "";
  bool _isSummarizing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadExams();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    _notesInputController.dispose();
    super.dispose();
  }

  // ============================================================
  // EXAM PERSISTENCE
  // ============================================================

  Future<void> _loadExams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString('saved_exam_courses');
      if (dataStr != null) {
        final List decoded = jsonDecode(dataStr);
        setState(() {
          _exams = decoded.map((e) => Map<String, dynamic>.from(e)).map((e) {
            // Parse the date string back to DateTime
            e['date'] = DateTime.parse(e['date']);
            return e;
          }).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveExams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodable = _exams.map((e) {
        final copy = Map<String, dynamic>.from(e);
        copy['date'] = (copy['date'] as DateTime).toIso8601String();
        return copy;
      }).toList();
      await prefs.setString('saved_exam_courses', jsonEncode(encodable));
    } catch (_) {}
  }

  // Sync exams to course manager (SharedPreferences key: saved_student_courses)
  Future<void> _syncExamToCourseManager(Map<String, dynamic> examData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> courses = [];

      final dataStr = prefs.getString('saved_student_courses');
      if (dataStr != null) {
        final List decoded = jsonDecode(dataStr);
        courses = decoded.map((c) => Map<String, dynamic>.from(c)).toList();
      }

      // Check if this course already exists by courseId
      final existingIdx = courses.indexWhere((c) =>
          c['code'] == examData['courseId'] ||
          c['id'] == examData['syncId']);

      final courseEntry = {
        'id': examData['syncId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'code': examData['courseId'] ?? '',
        'title': examData['course'] ?? '',
        'credits': 3.0,
        'grade': _targetGpaToGrade(examData['targetGpa'] ?? 4.0),
        'gradePoint': (examData['targetGpa'] as num?)?.toDouble() ?? 4.0,
        'semester': 'Fall 2026',
        'weakTopics': <String>[],
      };

      if (existingIdx != -1) {
        courses[existingIdx] = courseEntry;
      } else {
        courses.add(courseEntry);
      }

      await prefs.setString('saved_student_courses', jsonEncode(courses));
    } catch (_) {}
  }

  // Remove from course manager when exam is deleted
  Future<void> _removeFromCourseManager(String syncId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString('saved_student_courses');
      if (dataStr != null) {
        final List decoded = jsonDecode(dataStr);
        final courses = decoded.map((c) => Map<String, dynamic>.from(c)).toList();
        courses.removeWhere((c) => c['id'] == syncId);
        await prefs.setString('saved_student_courses', jsonEncode(courses));
      }
    } catch (_) {}
  }

  String _targetGpaToGrade(double gpa) {
    if (gpa >= 4.0) return 'A+';
    if (gpa >= 3.75) return 'A';
    if (gpa >= 3.50) return 'A-';
    if (gpa >= 3.25) return 'B+';
    if (gpa >= 3.00) return 'B';
    if (gpa >= 2.75) return 'B-';
    if (gpa >= 2.50) return 'C+';
    if (gpa >= 2.25) return 'C';
    if (gpa >= 2.00) return 'C-';
    if (gpa >= 1.75) return 'D+';
    if (gpa >= 1.50) return 'D';
    return 'F';
  }

  // ============================================================
  // ADD / EDIT EXAM COURSE MODAL
  // ============================================================

  void _showAddExamModal({int? editIndex}) {
    final courseIdCtrl = TextEditingController();
    final courseNameCtrl = TextEditingController();
    final targetGpaCtrl = TextEditingController(text: "3.50");
    DateTime selectedDate = DateTime.now().add(const Duration(days: 14));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);

    if (editIndex != null) {
      final exam = _exams[editIndex];
      courseIdCtrl.text = exam['courseId'] ?? '';
      courseNameCtrl.text = exam['course'] ?? '';
      targetGpaCtrl.text = (exam['targetGpa'] ?? 3.5).toString();
      selectedDate = exam['date'] as DateTime;
      selectedTime = TimeOfDay(hour: selectedDate.hour, minute: selectedDate.minute);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        editIndex != null ? "Edit Exam Course" : "Add Exam Course",
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: courseIdCtrl,
                    style: GoogleFonts.outfit(),
                    decoration: const InputDecoration(
                      labelText: "Course ID (e.g. CSE-101)",
                      prefixIcon: Icon(Icons.tag_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: courseNameCtrl,
                    style: GoogleFonts.outfit(),
                    decoration: const InputDecoration(
                      labelText: "Course Name (e.g. Data Structures Final)",
                      prefixIcon: Icon(Icons.book_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: targetGpaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.outfit(),
                    decoration: const InputDecoration(
                      labelText: "Targeted GPA (e.g. 3.50)",
                      prefixIcon: Icon(Icons.grade_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Date picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            ));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Color(0xFF0F766E)),
                          const SizedBox(width: 12),
                          Text(
                            "Exam Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                            style: GoogleFonts.outfit(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Time picker
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedTime = picked;
                          selectedDate = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            picked.hour,
                            picked.minute,
                          );
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: Color(0xFF0F766E)),
                          const SizedBox(width: 12),
                          Text(
                            "Exam Time: ${selectedTime.format(context)}",
                            style: GoogleFonts.outfit(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        if (courseIdCtrl.text.isEmpty || courseNameCtrl.text.isEmpty) return;

                        final syncId = editIndex != null
                            ? (_exams[editIndex]['syncId'] ?? DateTime.now().millisecondsSinceEpoch.toString())
                            : DateTime.now().millisecondsSinceEpoch.toString();

                        final examData = {
                          "syncId": syncId,
                          "courseId": courseIdCtrl.text.trim(),
                          "course": courseNameCtrl.text.trim(),
                          "targetGpa": double.tryParse(targetGpaCtrl.text) ?? 3.5,
                          "date": selectedDate,
                          "prepPercent": editIndex != null ? (_exams[editIndex]['prepPercent'] ?? 0.0) : 0.0,
                        };

                        setState(() {
                          if (editIndex != null) {
                            _exams[editIndex] = examData;
                          } else {
                            _exams.add(examData);
                          }
                        });

                        _saveExams();
                        _syncExamToCourseManager(examData);
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                editIndex != null ? "Exam course updated!" : "Exam course added & synced to Grade Manager!",
                                style: GoogleFonts.outfit()),
                            backgroundColor: const Color(0xFF0F766E),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      child: Text(
                        editIndex != null ? "Save Changes" : "Add Course",
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // ============================================================
  // POMODORO TIMER
  // ============================================================

  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() {
        _isTimerRunning = false;
      });
    } else {
      setState(() {
        _isTimerRunning = true;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer?.cancel();
            _isTimerRunning = false;
            _completedSessions++;
            _secondsRemaining = 25 * 60;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("🎉 Pomodoro Session Complete! Take a 5-min break.",
                    style: GoogleFonts.outfit()),
                backgroundColor: const Color(0xFF0F766E),
              ),
            );
          }
        });
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _secondsRemaining = 25 * 60;
    });
  }

  String _formatTimer(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$mins:$secs";
  }

  Future<void> _generateSummary() async {
    final text = _notesInputController.text.trim();
    if (text.isEmpty || _isSummarizing) return;

    setState(() {
      _isSummarizing = true;
      _aiGeneratedSummary = "";
    });

    final prompt =
        "Summarize the following study material into concise bullet points, key concepts, and exam cheat-sheet notes:\n\n$text";

    try {
      final reply = await _aiService.sendMessage(prompt);
      if (!mounted) return;
      setState(() {
        _aiGeneratedSummary = reply;
        _isSummarizing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _aiGeneratedSummary =
            "• Key Concept: Active recall boosts long-term memory retention.\n• Strategy: Break study sessions into 25-minute Pomodoro sprints.\n• Formula: Focus = (Intention - Distractions).";
        _isSummarizing = false;
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
          "Focus, Flashcards & Exams",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0F766E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF0F766E),
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.timer_rounded), text: "Pomodoro"),
            Tab(icon: Icon(Icons.style_rounded), text: "Flashcards"),
            Tab(icon: Icon(Icons.event_note_rounded), text: "Exams"),
            Tab(icon: Icon(Icons.summarize_rounded), text: "AI Notes"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Pomodoro Focus Timer
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                PulsingGlow(
                  glowColor: const Color(0xFF0F766E),
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _formatTimer(_secondsRemaining),
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _toggleTimer,
                      icon: Icon(
                        _isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        _isTimerRunning ? "Pause" : "Start Focus",
                        style: GoogleFonts.outfit(
                            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _resetTimer,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text("Reset", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text("Completed Today",
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 4),
                          Text("$_completedSessions Sessions",
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: const Color(0xFF0F766E))),
                        ],
                      ),
                      Column(
                        children: [
                          Text("Total Focus Time",
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 4),
                          Text("${_completedSessions * 25} mins",
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: const Color(0xFF0F766E))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Smart Flashcards Spaced Repetition
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Card ${_currentCardIndex + 1} of ${_flashcards.length}",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Chip(
                      label: Text(_flashcards[_currentCardIndex].courseCode,
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.white)),
                      backgroundColor: const Color(0xFF0F766E),
                    )
                  ],
                ),
                const SizedBox(height: 16),

                // Flashcard Flip Container
                GestureDetector(
                  onTap: () => setState(() => _showAnswer = !_showAnswer),
                  child: Container(
                    height: 240,
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _showAnswer
                          ? (isDark ? const Color(0xFF0F2728) : Colors.teal.shade50)
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF0F766E),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showAnswer ? "ANSWER" : "QUESTION",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showAnswer
                              ? _flashcards[_currentCardIndex].answer
                              : _flashcards[_currentCardIndex].question,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Tap to Flip Card 🔄",
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Rating Spaced Repetition Buttons
                if (_showAnswer) ...[
                  Text("Rate Mastery for Spaced Repetition:",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
                        onPressed: () {
                          setState(() {
                            _showAnswer = false;
                            _currentCardIndex = (_currentCardIndex + 1) % _flashcards.length;
                          });
                        },
                        child: Text("Hard", style: GoogleFonts.outfit(color: Colors.white)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
                        onPressed: () {
                          setState(() {
                            _showAnswer = false;
                            _currentCardIndex = (_currentCardIndex + 1) % _flashcards.length;
                          });
                        },
                        child: Text("Good", style: GoogleFonts.outfit(color: Colors.white)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                        onPressed: () {
                          setState(() {
                            _showAnswer = false;
                            _currentCardIndex = (_currentCardIndex + 1) % _flashcards.length;
                          });
                        },
                        child: Text("Easy", style: GoogleFonts.outfit(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // 3. Exam Countdown & Readiness — MANUAL ADD, EDITABLE
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Upcoming Exams & Revision Countdown",
                        style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_rounded,
                          color: Color(0xFF0F766E), size: 30),
                      onPressed: () => _showAddExamModal(),
                      tooltip: "Add Exam Course",
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Add your courses manually. They auto-sync with Course & Grade Manager.",
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),

                if (_exams.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.event_note_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          "No exam courses added yet.\nTap + to add your first course.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => _showAddExamModal(),
                          icon: const Icon(Icons.add_rounded, color: Colors.white),
                          label: Text("Add Course",
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _exams.length,
                    itemBuilder: (context, index) {
                      final exam = _exams[index];
                      final DateTime dt = exam["date"];
                      final int daysLeft = dt.difference(DateTime.now()).inDays;
                      final double prep = exam["prepPercent"] ?? 0.0;
                      final double targetGpa = (exam["targetGpa"] as num?)?.toDouble() ?? 0.0;
                      final String courseId = exam["courseId"] ?? '';
                      final String timeStr =
                          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        courseId.isNotEmpty ? "$courseId · ${exam["course"]}" : exam["course"],
                                        style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold, fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Target GPA: ${targetGpa.toStringAsFixed(2)} · $timeStr",
                                        style: GoogleFonts.outfit(
                                            fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: daysLeft <= 3
                                            ? Colors.red.shade100
                                            : Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                          daysLeft >= 0
                                              ? "$daysLeft Days Left ⏳"
                                              : "Exam Passed",
                                          style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: daysLeft <= 3
                                                  ? Colors.red.shade900
                                                  : Colors.amber.shade900)),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 18, color: Colors.grey),
                                      onPressed: () =>
                                          _showAddExamModal(editIndex: index),
                                      tooltip: "Edit",
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded,
                                          size: 18, color: Colors.redAccent),
                                      onPressed: () {
                                        final syncId = exam['syncId'];
                                        setState(() {
                                          _exams.removeAt(index);
                                        });
                                        _saveExams();
                                        if (syncId != null) _removeFromCourseManager(syncId);
                                      },
                                      tooltip: "Delete",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Preparation Readiness:",
                                    style: GoogleFonts.outfit(fontSize: 13)),
                                Text("${(prep * 100).toInt()}% Ready",
                                    style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F766E))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Editable prep slider
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: const Color(0xFF0F766E),
                                inactiveTrackColor:
                                    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                thumbColor: const Color(0xFF0F766E),
                                overlayColor: const Color(0xFF0F766E).withValues(alpha: 0.2),
                                trackHeight: 8,
                              ),
                              child: Slider(
                                value: prep,
                                min: 0.0,
                                max: 1.0,
                                divisions: 20,
                                label: "${(prep * 100).toInt()}%",
                                onChanged: (val) {
                                  setState(() {
                                    _exams[index]["prepPercent"] = val;
                                  });
                                  _saveExams();
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          // 4. AI Notes & Summaries
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("AI Notes & Cheat-Sheet Generator",
                    style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Paste lecture slides or notes below to generate instant key takeaways.",
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 14),

                TextField(
                  controller: _notesInputController,
                  maxLines: 4,
                  style: GoogleFonts.outfit(),
                  decoration: const InputDecoration(
                    hintText: "Paste course notes or topic outline here...",
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isSummarizing ? null : _generateSummary,
                    icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                    label: Text(
                      _isSummarizing ? "Summarizing..." : "Generate AI Summary",
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                if (_aiGeneratedSummary.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0F766E)),
                    ),
                    child: Text(
                      _aiGeneratedSummary,
                      style: GoogleFonts.outfit(fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
