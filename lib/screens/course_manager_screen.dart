import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/academic_models.dart';
import '../widgets/interactive_animations.dart';

class CourseManagerScreen extends StatefulWidget {
  const CourseManagerScreen({super.key});

  @override
  State<CourseManagerScreen> createState() => _CourseManagerScreenState();
}

class _CourseManagerScreenState extends State<CourseManagerScreen> {
  final List<Course> courses = [];
  final TextEditingController codeController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController creditsController = TextEditingController(text: "3.0");
  final TextEditingController weakTopicsController = TextEditingController();

  String selectedGrade = 'A';
  String selectedSemester = 'Fall 2026';

  String totalCgpaLabel = "—";
  String targetCgpaLabel = "4.00";

  final List<String> gradeList = ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F'];
  final List<String> semesterList = ['Spring 2026', 'Summer 2026', 'Fall 2026'];

  @override
  void initState() {
    super.initState();
    _loadInitialCourses();
    _loadTotalCgpa();
  }

  Future<void> _loadTotalCgpa() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString('user_current_cgpa') ?? prefs.getString('sim_prev_cgpa');
      final target = prefs.getString('user_target_cgpa') ?? prefs.getString('sim_target_cgpa');
      if (mounted) {
        setState(() {
          if (val != null) totalCgpaLabel = val;
          if (target != null) targetCgpaLabel = target;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadInitialCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString('saved_student_courses');
      if (dataStr != null) {
        final List decoded = jsonDecode(dataStr);
        setState(() {
          courses.clear();
          courses.addAll(decoded.map((c) => Course.fromJson(c)).toList());
        });
      }
      // No pre-loaded sample courses — users add their own
    } catch (_) {}
  }

  Future<void> _saveCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'saved_student_courses', jsonEncode(courses.map((c) => c.toJson()).toList()));
    } catch (_) {}
  }

  @override
  void dispose() {
    codeController.dispose();
    titleController.dispose();
    creditsController.dispose();
    weakTopicsController.dispose();
    super.dispose();
  }

  double get currentGpa {
    if (courses.isEmpty) return 0.0;
    double totalPoints = 0;
    double totalCredits = 0;
    for (var c in courses) {
      totalPoints += (c.gradePoint * c.credits);
      totalCredits += c.credits;
    }
    return totalCredits > 0 ? totalPoints / totalCredits : 0.0;
  }

  List<Course> get weakCourses {
    return courses.where((c) => c.gradePoint < 3.00 || c.weakTopics.isNotEmpty).toList();
  }

  void _showAddCourseModal({Course? courseToEdit}) {
    if (courseToEdit != null) {
      codeController.text = courseToEdit.code;
      titleController.text = courseToEdit.title;
      creditsController.text = courseToEdit.credits.toString();
      selectedGrade = courseToEdit.grade;
      selectedSemester = courseToEdit.semester;
      weakTopicsController.text = courseToEdit.weakTopics.join(', ');
    } else {
      codeController.clear();
      titleController.clear();
      creditsController.text = "3.0";
      selectedGrade = 'A';
      selectedSemester = 'Fall 2026';
      weakTopicsController.clear();
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
                        courseToEdit != null ? "Edit Course" : "Add New Course",
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
                    controller: codeController,
                    style: GoogleFonts.outfit(),
                    decoration: const InputDecoration(
                      labelText: "Course Code (e.g. CSE-101)",
                      prefixIcon: Icon(Icons.code_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.outfit(),
                    decoration: const InputDecoration(
                      labelText: "Course Title (e.g. Data Structures)",
                      prefixIcon: Icon(Icons.book_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: creditsController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.outfit(),
                          decoration: const InputDecoration(
                            labelText: "Credits",
                            prefixIcon: Icon(Icons.numbers_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedGrade,
                          decoration: const InputDecoration(labelText: "Expected Grade"),
                          items: gradeList
                              .map((g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g, style: GoogleFonts.outfit()),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedGrade = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSemester,
                    decoration: const InputDecoration(labelText: "Semester"),
                    items: semesterList
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, style: GoogleFonts.outfit()),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedSemester = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: weakTopicsController,
                    style: GoogleFonts.outfit(),
                    decoration: const InputDecoration(
                      labelText: "Weak Topics (comma separated)",
                      prefixIcon: Icon(Icons.warning_amber_rounded),
                      hintText: "e.g., Recursion, Integration",
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
                        if (codeController.text.isEmpty || titleController.text.isEmpty) return;

                        final credits = double.tryParse(creditsController.text) ?? 3.0;
                        final gp = Course.gradeToPoint(selectedGrade);
                        final topics = weakTopicsController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();

                        setState(() {
                          if (courseToEdit != null) {
                            int idx = courses.indexWhere((c) => c.id == courseToEdit.id);
                            if (idx != -1) {
                              courses[idx] = Course(
                                id: courseToEdit.id,
                                code: codeController.text.trim(),
                                title: titleController.text.trim(),
                                credits: credits,
                                grade: selectedGrade,
                                gradePoint: gp,
                                semester: selectedSemester,
                                weakTopics: topics,
                              );
                            }
                          } else {
                            courses.add(Course(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              code: codeController.text.trim(),
                              title: titleController.text.trim(),
                              credits: credits,
                              grade: selectedGrade,
                              gradePoint: gp,
                              semester: selectedSemester,
                              weakTopics: topics,
                            ));
                          }
                        });

                        _saveCourses();
                        Navigator.pop(context);
                      },
                      child: Text(
                        courseToEdit != null ? "Save Changes" : "Add Course",
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
          "Course & Grade Manager",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF0F766E)),
            onPressed: () => _showAddCourseModal(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Current / Expected CGPA",
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          courses.isEmpty
                              ? (totalCgpaLabel != "—" ? totalCgpaLabel : "3.75")
                              : currentGpa.toStringAsFixed(2),
                          style: GoogleFonts.outfit(
                              fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "Target CGPA: $targetCgpaLabel",
                            style: GoogleFonts.outfit(
                                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${courses.length} Course${courses.length == 1 ? '' : 's'} Tracked",
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 80,
                    width: 120,
                    padding: const EdgeInsets.all(8),
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: courses.asMap().entries.map((e) {
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.gradePoint,
                                color: Colors.white,
                                width: 10,
                                borderRadius: BorderRadius.circular(4),
                              )
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Rule-Based Weak Topic Detection (v1)
            if (weakCourses.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.amber, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "Weak Topic & Risk Detection",
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.amber : const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: weakCourses.length,
                itemBuilder: (context, index) {
                  final c = weakCourses[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF332A15) : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${c.code} · ${c.title}",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? const Color(0xFFFEF3C7) : const Color(0xFF92400E),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Grade: ${c.grade}",
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        if (c.weakTopics.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: c.weakTopics.map((t) {
                              return Chip(
                                label: Text(t, style: GoogleFonts.outfit(fontSize: 11)),
                                backgroundColor: isDark
                                    ? const Color(0xFF451A03)
                                    : const Color(0xFFFEF3C7),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 25),
            ],

            // Course List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Enrolled Courses (${courses.length})",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddCourseModal(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text("Add Course", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final c = courses[index];
                return FadeInSlide(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                          child: Text(
                            c.grade,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF0F766E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${c.code} · ${c.title}",
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${c.credits} Credits · GP: ${c.gradePoint.toStringAsFixed(2)} · ${c.semester}",
                                style: GoogleFonts.outfit(
                                    fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                          onPressed: () => _showAddCourseModal(courseToEdit: c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 20, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              courses.removeAt(index);
                            });
                            _saveCourses();
                          },
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
}
