import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/academic_models.dart';
import '../widgets/interactive_animations.dart';

class CgpaSimulatorScreen extends StatefulWidget {
  const CgpaSimulatorScreen({super.key});

  @override
  State<CgpaSimulatorScreen> createState() => _CgpaSimulatorScreenState();
}

class _CgpaSimulatorScreenState extends State<CgpaSimulatorScreen> {
  final TextEditingController totalCreditController = TextEditingController();
  final TextEditingController completedCreditController = TextEditingController();
  final TextEditingController previousCgpaController = TextEditingController();
  final TextEditingController targetCgpaController = TextEditingController();

  final List<ImprovementCourse> improvementCourses = [];
  List<String> userStrongBasics = [];
  List<String> userWeakBasics = [];

  // Controllers for adding a new improvement course
  final TextEditingController courseNameController = TextEditingController();
  final TextEditingController courseCreditController =
      TextEditingController(text: "3");
  double selectedCurrentGp = 2.0; // Grade C
  double selectedTargetGp = 4.0; // Grade A

  final List<Map<String, dynamic>> gradeOptions = [
    {"label": "A+ (4.00)", "value": 4.00},
    {"label": "A (3.75)", "value": 3.75},
    {"label": "A- (3.50)", "value": 3.50},
    {"label": "B+ (3.25)", "value": 3.25},
    {"label": "B (3.00)", "value": 3.00},
    {"label": "B- (2.75)", "value": 2.75},
    {"label": "C+ (2.50)", "value": 2.50},
    {"label": "C (2.25)", "value": 2.25},
    {"label": "C- (2.00)", "value": 2.00},
    {"label": "D+ (1.75)", "value": 1.75},
    {"label": "D (1.50)", "value": 1.50},
    {"label": "F (0.00)", "value": 0.00},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final total = prefs.getString('sim_total_credit') ?? prefs.getString('user_total_credit');
      final completed = prefs.getString('sim_completed_credit') ?? prefs.getString('user_completed_credit');
      final prevCgpa = prefs.getString('sim_prev_cgpa') ?? prefs.getString('user_current_cgpa');
      final targetCgpa = prefs.getString('sim_target_cgpa') ?? prefs.getString('user_target_cgpa');
      final coursesJson = prefs.getString('sim_improvement_courses');

      final strongJson = prefs.getString('user_strong_basics');
      final weakJson = prefs.getString('user_weak_basics');

      setState(() {
        if (total != null) totalCreditController.text = total;
        if (completed != null) completedCreditController.text = completed;
        if (prevCgpa != null) previousCgpaController.text = prevCgpa;
        if (targetCgpa != null) targetCgpaController.text = targetCgpa;

        if (strongJson != null) {
          userStrongBasics = List<String>.from(jsonDecode(strongJson));
        }
        if (weakJson != null) {
          userWeakBasics = List<String>.from(jsonDecode(weakJson));
        }

        if (coursesJson != null) {
          final List list = jsonDecode(coursesJson);
          improvementCourses.clear();
          improvementCourses.addAll(
              list.map((item) => ImprovementCourse.fromJson(item)).toList());
        }
      });
    } catch (_) {}
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sim_total_credit', totalCreditController.text);
      await prefs.setString(
          'sim_completed_credit', completedCreditController.text);
      await prefs.setString('sim_prev_cgpa', previousCgpaController.text);
      await prefs.setString('sim_target_cgpa', targetCgpaController.text);
      await prefs.setString(
        'sim_improvement_courses',
        jsonEncode(improvementCourses.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    totalCreditController.dispose();
    completedCreditController.dispose();
    previousCgpaController.dispose();
    targetCgpaController.dispose();
    courseNameController.dispose();
    courseCreditController.dispose();
    super.dispose();
  }

  // Flexible Keyword & Aptitude Matching Engine
  Map<String, String> _predictCourseAptitude(String courseName) {
    final c = courseName.trim().toLowerCase();

    bool matchesTopic(String topic, String course) {
      final t = topic.trim().toLowerCase();

      if (course.contains(t) || t.contains(course)) return true;

      // Math / Statistics / Numericals domain
      bool isMathOrStat = course.contains("stat") ||
          course.contains("numerical") ||
          course.contains("math") ||
          course.contains("calculus") ||
          course.contains("algebra");

      if (isMathOrStat &&
          (t.contains("math") || t.contains("stat") || t.contains("numerical") || t.contains("calculus"))) {
        return true;
      }

      // OOP / Programming / Mobile App domain
      bool isOopOrApp = course.contains("app") ||
          course.contains("oop") ||
          course.contains("object") ||
          course.contains("programming") ||
          course.contains("java") ||
          course.contains("python") ||
          course.contains("software") ||
          course.contains("mobile");

      if (isOopOrApp &&
          (t.contains("oop") || t.contains("object") || t.contains("programming") || t.contains("app"))) {
        return true;
      }

      return false;
    }

    bool isStrong = userStrongBasics.any((s) => matchesTopic(s, c));
    bool isWeak = userWeakBasics.any((w) => matchesTopic(w, c));

    if (isStrong && !isWeak) {
      return {
        "status": "High Probability of Success ⭐",
        "color": "teal",
        "reason":
            "Aligns with your strong basics (${userStrongBasics.join(', ')}). You will probably do very well in this course!",
      };
    } else if (isWeak) {
      return {
        "status": "Requires Extra Effort / Higher Challenge ⚠️",
        "color": "amber",
        "reason":
            "Relies on ${userWeakBasics.join(', ')}, which is listed as a weak basic in your profile. Focus on fundamentals first!",
      };
    } else if (isStrong && isWeak) {
      return {
        "status": "Moderate Feasibility 👍",
        "color": "blue",
        "reason": "Combines elements of both your strong and weak basics. Balanced effort required.",
      };
    } else {
      return {
        "status": "Moderate Feasibility 👍",
        "color": "blue",
        "reason": "Standard effort required to reach your target grade.",
      };
    }
  }

  // Algorithm Calculations
  Map<String, dynamic> _calculateSimulation() {
    final double totalProgCredits =
        double.tryParse(totalCreditController.text) ?? 0.0;
    final double completedCredits =
        double.tryParse(completedCreditController.text) ?? 0.0;
    final double prevCgpa =
        double.tryParse(previousCgpaController.text) ?? 0.0;
    final double targetCgpa =
        double.tryParse(targetCgpaController.text) ?? 0.0;

    final double earnedPointsSoFar = completedCredits * prevCgpa;

    double netPointGain = 0.0;
    for (var course in improvementCourses) {
      double delta = course.targetGradePoint - course.currentGradePoint;
      if (delta > 0) {
        netPointGain += delta * course.credit;
      }
    }

    final double newEarnedPoints = earnedPointsSoFar + netPointGain;
    final double simulatedCurrentCgpa = completedCredits > 0
        ? (newEarnedPoints / completedCredits).clamp(0.0, 4.0)
        : prevCgpa;

    final double cgpaBoost = simulatedCurrentCgpa - prevCgpa;

    final double remainingCredits = (totalProgCredits - completedCredits)
        .clamp(0.0, totalProgCredits);

    final double requiredTotalPointsForTarget = targetCgpa * totalProgCredits;
    final double pointsNeededFromRemaining =
        requiredTotalPointsForTarget - newEarnedPoints;

    double requiredRemainingGpa = 0.0;
    if (remainingCredits > 0) {
      requiredRemainingGpa = pointsNeededFromRemaining / remainingCredits;
    }

    bool isTargetAchievable = requiredRemainingGpa <= 4.00;
    bool isAlreadyAchieved = simulatedCurrentCgpa >= targetCgpa && targetCgpa > 0;

    return {
      "simulatedCgpa": simulatedCurrentCgpa,
      "cgpaBoost": cgpaBoost,
      "earnedPointsSoFar": earnedPointsSoFar,
      "netPointGain": netPointGain,
      "remainingCredits": remainingCredits,
      "requiredRemainingGpa": requiredRemainingGpa,
      "isTargetAchievable": isTargetAchievable,
      "isAlreadyAchieved": isAlreadyAchieved,
      "targetCgpa": targetCgpa,
    };
  }

  void _showAddImprovementModal() {
    courseNameController.clear();
    courseCreditController.text = "3";
    selectedCurrentGp = 2.0;
    selectedTargetGp = 4.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
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
                          "Add Retake / Improvement Course",
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
                      controller: courseNameController,
                      style: GoogleFonts.outfit(),
                      decoration: const InputDecoration(
                        labelText: "Course Title / Code",
                        prefixIcon: Icon(Icons.book_rounded),
                        hintText: "e.g., Statistics, Numericals, Mobile App",
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: courseCreditController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.outfit(),
                      decoration: const InputDecoration(
                        labelText: "Course Credits",
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Original / Current Grade",
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<double>(
                      initialValue: selectedCurrentGp,
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.history_rounded)),
                      items: gradeOptions
                          .map((g) => DropdownMenuItem<double>(
                                value: g["value"],
                                child: Text(g["label"], style: GoogleFonts.outfit()),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedCurrentGp = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Targeted New Grade",
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<double>(
                      initialValue: selectedTargetGp,
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.stars_rounded)),
                      items: gradeOptions
                          .map((g) => DropdownMenuItem<double>(
                                value: g["value"],
                                child: Text(g["label"], style: GoogleFonts.outfit()),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedTargetGp = val);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          final name = courseNameController.text.trim().isEmpty
                              ? "Course #${improvementCourses.length + 1}"
                              : courseNameController.text.trim();
                          final credit =
                              double.tryParse(courseCreditController.text) ?? 3.0;

                          setState(() {
                            improvementCourses.add(ImprovementCourse(
                              name: name,
                              credit: credit,
                              currentGradePoint: selectedCurrentGp,
                              targetGradePoint: selectedTargetGp,
                            ));
                          });
                          _saveData();
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Add to Retake Plan",
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final results = _calculateSimulation();

    final double simulatedCgpa = results["simulatedCgpa"];
    final double cgpaBoost = results["cgpaBoost"];
    final double requiredRemainingGpa = results["requiredRemainingGpa"];
    final bool isTargetAchievable = results["isTargetAchievable"];
    final bool isAlreadyAchieved = results["isAlreadyAchieved"];
    final double remainingCredits = results["remainingCredits"];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "CGPA What-If Simulator",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Result Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Simulated CGPA",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            simulatedCgpa > 0 ? simulatedCgpa.toStringAsFixed(2) : "--",
                            style: GoogleFonts.outfit(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.trending_up_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              "+${cgpaBoost.toStringAsFixed(2)} Boost",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const Divider(color: Colors.white30, height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _resultStat(
                        "Target CGPA",
                        results["targetCgpa"] > 0
                            ? results["targetCgpa"].toStringAsFixed(2)
                            : "--",
                      ),
                      _resultStat(
                        "Req. Rem. GPA",
                        remainingCredits > 0 && requiredRemainingGpa > 0
                            ? (requiredRemainingGpa <= 4.0
                                ? requiredRemainingGpa.toStringAsFixed(2)
                                : "N/A (>4.0)")
                            : "--",
                      ),
                      _resultStat(
                        "Rem. Credits",
                        "${remainingCredits.toStringAsFixed(0)} Cr",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Target Status Badge
            if (results["targetCgpa"] > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isAlreadyAchieved
                      ? Colors.teal.shade50
                      : (isTargetAchievable
                          ? Colors.blue.shade50
                          : Colors.amber.shade50),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isAlreadyAchieved
                        ? Colors.teal
                        : (isTargetAchievable
                            ? Colors.blue
                            : Colors.amber.shade700),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAlreadyAchieved
                          ? Icons.check_circle_rounded
                          : (isTargetAchievable
                              ? Icons.stars_rounded
                              : Icons.warning_amber_rounded),
                      color: isAlreadyAchieved
                          ? Colors.teal
                          : (isTargetAchievable
                              ? Colors.blue.shade800
                              : Colors.amber.shade800),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isAlreadyAchieved
                            ? "Congratulations! Your retake plan reaches or exceeds your target CGPA!"
                            : (isTargetAchievable
                                ? "Achievable! You need an average GPA of ${requiredRemainingGpa.toStringAsFixed(2)} on your remaining ${remainingCredits.toStringAsFixed(0)} credits."
                                : "Target is ambitious! You would need >4.0 GPA on remaining credits. Try adding more courses to improve!"),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isAlreadyAchieved
                              ? Colors.teal.shade900
                              : (isTargetAchievable
                                  ? Colors.blue.shade900
                                  : Colors.amber.shade900),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Academic Base Parameters Inputs
            Text(
              "1. Academic Parameters (Enter your credit & CGPA data)",
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

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
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: totalCreditController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) {
                            setState(() {});
                            _saveData();
                          },
                          decoration: const InputDecoration(
                            labelText: "Total Program Credits",
                            hintText: "e.g. 140",
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: completedCreditController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) {
                            setState(() {});
                            _saveData();
                          },
                          decoration: const InputDecoration(
                            labelText: "Completed Credits",
                            hintText: "e.g. 70",
                            prefixIcon: Icon(Icons.check_circle_outline),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: previousCgpaController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) {
                            setState(() {});
                            _saveData();
                          },
                          decoration: const InputDecoration(
                            labelText: "Current CGPA",
                            hintText: "e.g. 3.25",
                            prefixIcon: Icon(Icons.grade_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: targetCgpaController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) {
                            setState(() {});
                            _saveData();
                          },
                          decoration: const InputDecoration(
                            labelText: "Target CGPA",
                            hintText: "e.g. 3.65",
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Multiple Improvement Courses List with Aptitude Predictions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "2. Retake Courses & Aptitude Predictor (${improvementCourses.length})",
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddImprovementModal,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    "Add Course",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),

            if (userStrongBasics.isNotEmpty || userWeakBasics.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology_outlined,
                        color: Color(0xFF0F766E), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Profile Aptitude: Strong in [${userStrongBasics.join(', ')}] · Weak in [${userWeakBasics.join(', ')}]",
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F766E)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            if (improvementCourses.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 40, color: theme.colorScheme.primary),
                    const SizedBox(height: 10),
                    Text(
                      "No Retake Courses Added Yet",
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tap '+ Add Course' to enter your retake subjects (e.g. Statistics, Numericals, Mobile App) and see personalized success probability predictions based on your basics!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: improvementCourses.length,
                itemBuilder: (context, index) {
                  final item = improvementCourses[index];
                  final double gain =
                      (item.targetGradePoint - item.currentGradePoint) *
                          item.credit;
                  final prediction = _predictCourseAptitude(item.name);

                  final bool isTeal = prediction["color"] == "teal";
                  final bool isAmber = prediction["color"] == "amber";

                  return FadeInSlide(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isTeal
                              ? Colors.teal.shade400
                              : (isAmber
                                  ? Colors.amber.shade400
                                  : (isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0))),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isTeal
                                      ? Colors.teal.shade50
                                      : (isAmber
                                          ? Colors.amber.shade50
                                          : const Color(0xFF0F766E)
                                              .withValues(alpha: 0.1)),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  isTeal
                                      ? Icons.star_rounded
                                      : (isAmber
                                          ? Icons.warning_amber_rounded
                                          : Icons.book_rounded),
                                  color: isTeal
                                      ? Colors.teal
                                      : (isAmber
                                          ? Colors.amber.shade800
                                          : const Color(0xFF0F766E)),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${item.credit} Credits · Current: ${item.currentGradePoint.toStringAsFixed(2)} ➔ Target: ${item.targetGradePoint.toStringAsFixed(2)}",
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "+${gain.toStringAsFixed(1)} pts",
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F766E),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  setState(() {
                                    improvementCourses.removeAt(index);
                                  });
                                  _saveData();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Smart Success Probability Recommendation Pill
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isTeal
                                  ? (isDark
                                      ? const Color(0xFF0F2728)
                                      : Colors.teal.shade50)
                                  : (isAmber
                                      ? (isDark
                                          ? const Color(0xFF332A15)
                                          : Colors.amber.shade50)
                                      : (isDark
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFFF1F5F9))),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prediction["status"]!,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isTeal
                                        ? Colors.teal
                                        : (isAmber
                                            ? Colors.amber.shade900
                                            : Colors.blue.shade800),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  prediction["reason"]!,
                                  style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _resultStat(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
