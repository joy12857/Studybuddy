import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/interactive_animations.dart';

class StudyPlannerScreen extends StatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  State<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends State<StudyPlannerScreen> {
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;

  final List<String> subjectsList = [
    "Mathematics",
    "Computer Science",
    "Science",
    "History",
    "Literature",
    "Other"
  ];

  final Map<String, Color> subjectColors = {
    "Mathematics": const Color(0xFF0F766E),
    "Computer Science": const Color(0xFF0284C7),
    "Science": const Color(0xFF7C3AED),
    "History": const Color(0xFFD97706),
    "Literature": const Color(0xFFDB2777),
    "Other": const Color(0xFF475569),
  };

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('study_tasks');
    if (data != null) {
      setState(() {
        tasks = List<Map<String, dynamic>>.from(json.decode(data));
      });
    } else {
      // Load some mock tasks on first open so it doesn't look empty
      tasks = [
        {
          "id": "1",
          "title": "Practice Calculus Integrations",
          "subject": "Mathematics",
          "durationMinutes": 25,
          "isCompleted": false,
          "date": DateTime.now().toIso8601String()
        },
        {
          "id": "2",
          "title": "Study Binary Search Trees",
          "subject": "Computer Science",
          "durationMinutes": 50,
          "isCompleted": true,
          "date": DateTime.now().toIso8601String()
        }
      ];
      saveTasks();
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('study_tasks', json.encode(tasks));
  }

  void addTask(String title, String subject, int duration) {
    setState(() {
      tasks.add({
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "title": title,
        "subject": subject,
        "durationMinutes": duration,
        "isCompleted": false,
        "date": DateTime.now().toIso8601String(),
      });
    });
    saveTasks();
  }

  void toggleTask(int index) {
    setState(() {
      tasks[index]["isCompleted"] = !tasks[index]["isCompleted"];
    });
    saveTasks();
    SystemSound.play(SystemSoundType.click);
  }

  void deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });
    saveTasks();
  }

  double getCompletionPercentage() {
    if (tasks.isEmpty) return 0.0;
    final completedCount = tasks.where((t) => t["isCompleted"] == true).length;
    return completedCount / tasks.length;
  }

  int getTotalStudyMinutes() {
    return tasks
        .where((t) => t["isCompleted"] == true)
        .fold<int>(0, (sum, item) => sum + (item["durationMinutes"] as int));
  }

  void openAddTaskBottomSheet() {
    final titleCtrl = TextEditingController();
    String selectedSubject = "Mathematics";
    int selectedDuration = 25;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
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
                          "New Study Task",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const Divider(height: 10),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      style: GoogleFonts.outfit(),
                      decoration: InputDecoration(
                        labelText: "What are you studying?",
                        hintText: "e.g., Read chapter 4, Solve quiz...",
                        labelStyle: GoogleFonts.outfit(color: Colors.grey.shade600),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Select Subject",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF334155)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: subjectsList.map((subject) {
                        final isSelected = selectedSubject == subject;
                        final color = subjectColors[subject]!;
                        return ChoiceChip(
                          label: Text(
                            subject,
                            style: GoogleFonts.outfit(
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: color,
                          backgroundColor: const Color(0xFFF1F5F9),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() {
                                selectedSubject = subject;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Target Duration: $selectedDuration Minutes",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF334155)),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Color(0xFF0F766E), size: 20),
                        Expanded(
                          child: Slider(
                            value: selectedDuration.toDouble(),
                            min: 5,
                            max: 120,
                            divisions: 23, // increments of 5 mins
                            activeColor: const Color(0xFF0F766E),
                            inactiveColor: const Color(0xFFE2E8F0),
                            label: "$selectedDuration mins",
                            onChanged: (val) {
                              setModalState(() {
                                selectedDuration = val.toInt();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        final title = titleCtrl.text.trim();
                        if (title.isNotEmpty) {
                          addTask(title, selectedSubject, selectedDuration);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Task added successfully!", style: GoogleFonts.outfit()),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                      child: Text(
                        "Create Task",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void openTimerModal(Map<String, dynamic> task, int taskIndex) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PomodoroTimerDialog(
          task: task,
          onTimerComplete: () {
            setState(() {
              tasks[taskIndex]["isCompleted"] = true;
            });
            saveTasks();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final completionPct = getCompletionPercentage();
    final totalStudyTime = getTotalStudyMinutes();

    final activeTasks = tasks.where((t) => t["isCompleted"] == false).toList();
    final completedTasks = tasks.where((t) => t["isCompleted"] == true).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Study Planner",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dashboard Stats Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        // Progress Circle
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: completionPct,
                                strokeWidth: 8,
                                color: Colors.white,
                                backgroundColor: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            Text(
                              "${(completionPct * 100).toInt()}%",
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Study Progress",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${tasks.length - activeTasks.length} of ${tasks.length} tasks completed",
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Studied: $totalStudyTime Mins",
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Active Focus Tasks (${activeTasks.length})",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (activeTasks.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            "All caught up! Add a new task to begin your focus sprint.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: activeTasks.length,
                      itemBuilder: (context, idx) {
                        final task = activeTasks[idx];
                        final origIndex = tasks.indexOf(task);
                        final color = subjectColors[task["subject"]] ?? const Color(0xFF0F766E);

                        return FadeInSlide(
                          delay: Duration(milliseconds: 50 * idx),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Theme.of(context).dividerColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Checkbox(
                                activeColor: const Color(0xFF0F766E),
                                value: task["isCompleted"],
                                onChanged: (_) => toggleTask(origIndex),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              title: Text(
                                task["title"],
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF1E293B),
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      task["subject"],
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "⏳ ${task["durationMinutes"]} mins",
                                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF0F766E), size: 30),
                                    onPressed: () => openTimerModal(task, origIndex),
                                    tooltip: "Start Timer",
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                                    onPressed: () => deleteTask(origIndex),
                                    tooltip: "Delete Task",
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 25),
                  Text(
                    "Completed Tasks (${completedTasks.length})",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (completedTasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          "No completed tasks yet. Finish a focus sprint to complete!",
                          style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: completedTasks.length,
                      itemBuilder: (context, idx) {
                        final task = completedTasks[idx];
                        final origIndex = tasks.indexOf(task);

                        return Opacity(
                          opacity: 0.6,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: ListTile(
                              leading: Checkbox(
                                activeColor: const Color(0xFF0F766E),
                                value: task["isCompleted"],
                                onChanged: (_) => toggleTask(origIndex),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              title: Text(
                                task["title"],
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              subtitle: Text(
                                "${task["subject"]} · ${task["durationMinutes"]} mins completed",
                                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () => deleteTask(origIndex),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        onPressed: openAddTaskBottomSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PomodoroTimerDialog extends StatefulWidget {
  final Map<String, dynamic> task;
  final VoidCallback onTimerComplete;

  const PomodoroTimerDialog({
    super.key,
    required this.task,
    required this.onTimerComplete,
  });

  @override
  State<PomodoroTimerDialog> createState() => _PomodoroTimerDialogState();
}

class _PomodoroTimerDialogState extends State<PomodoroTimerDialog> {
  late int secondsRemaining;
  Timer? timer;
  bool isPlaying = false;

  final List<String> breathingTips = [
    "Take a deep breath in through your nose...",
    "Hold it for a few seconds...",
    "Exhale slowly through your mouth...",
    "Relax your shoulders and jaw.",
    "Feel the tension leaving your body.",
    "Focus only on this single moment."
  ];
  int activeTipIdx = 0;
  Timer? tipTimer;

  @override
  void initState() {
    super.initState();
    secondsRemaining = (widget.task["durationMinutes"] as int) * 60;
    // Set up a rotating tips list every 12 seconds
    tipTimer = Timer.periodic(const Duration(seconds: 12), (t) {
      if (mounted) {
        setState(() {
          activeTipIdx = (activeTipIdx + 1) % breathingTips.length;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    tipTimer?.cancel();
    super.dispose();
  }

  void startTimer() {
    if (isPlaying) return;
    setState(() {
      isPlaying = true;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsRemaining > 0) {
        setState(() {
          secondsRemaining--;
        });
      } else {
        completeTimer();
      }
    });
  }

  void pauseTimer() {
    timer?.cancel();
    setState(() {
      isPlaying = false;
    });
  }

  void completeTimer() {
    timer?.cancel();
    widget.onTimerComplete();
    SystemSound.play(SystemSoundType.click);
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "🌟 Focus Session Complete!",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Great job! You successfully completed your study session for '${widget.task["title"]}'. Take a break!",
          style: GoogleFonts.outfit(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Awesome!", style: GoogleFonts.outfit()),
          )
        ],
      ),
    );
  }

  String getFormattedTime() {
    final mins = secondsRemaining ~/ 60;
    final secs = secondsRemaining % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  Widget _buildTimerCircle(double progress) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 170,
          height: 170,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 10,
            color: const Color(0xFF0F766E),
            backgroundColor: const Color(0xFFE2E8F0),
          ),
        ),
        Text(
          getFormattedTime(),
          style: GoogleFonts.outfit(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F766E),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = (widget.task["durationMinutes"] as int) * 60;
    final progress = secondsRemaining / totalSeconds;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Focusing Sprint",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.task["title"],
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),

            // Big interactive circular countdown with PulsingGlow when playing
            Center(
              child: isPlaying
                  ? PulsingGlow(
                      glowColor: const Color(0xFF0F766E),
                      child: _buildTimerCircle(progress),
                    )
                  : _buildTimerCircle(progress),
            ),
            const SizedBox(height: 24),

            // Rotating Mindfulness Prompt Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.spa_rounded, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        breathingTips[activeTipIdx],
                        key: ValueKey<int>(activeTipIdx),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color(0xFF15803D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.outfit(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                  ),
                ),
                FloatingActionButton(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  mini: true,
                  onPressed: isPlaying ? pauseTimer : startTimer,
                  child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                ),
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    completeTimer();
                  },
                  child: Text(
                    "Skip to Finish",
                    style: GoogleFonts.outfit(color: const Color(0xFF0F766E), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
