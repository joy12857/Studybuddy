import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../widgets/interactive_animations.dart';
import 'home_screen.dart';

class AcademicOnboardingScreen extends StatefulWidget {
  const AcademicOnboardingScreen({super.key});

  @override
  State<AcademicOnboardingScreen> createState() =>
      _AcademicOnboardingScreenState();
}

class _AcademicOnboardingScreenState extends State<AcademicOnboardingScreen> {
  final AuthService _auth = AuthService();

  int _currentStep = 0;
  bool _isSaving = false;

  final TextEditingController departmentController = TextEditingController();
  final TextEditingController currentCgpaController = TextEditingController();
  final TextEditingController lastSemCgpaController = TextEditingController();
  final TextEditingController totalCreditController = TextEditingController();
  final TextEditingController completedCreditController = TextEditingController();
  final TextEditingController targetCgpaController = TextEditingController();

  String selectedSemester = "Semester 1";

  final List<String> semesterOptions = [
    "Semester 1",
    "Semester 2",
    "Semester 3",
    "Semester 4",
    "Semester 5",
    "Semester 6",
    "Semester 7",
    "Semester 8",
  ];

  // Department predefined basic topics
  final Map<String, List<String>> departmentBasics = {
    "Computer Science": [
      "Mathematics",
      "Statistics & Probability",
      "Object-Oriented Programming (OOP)",
      "Data Structures & Algorithms",
      "Calculus & Numericals",
      "Smartphone Applications",
      "Database Systems",
      "System Architecture",
    ],
    "Electrical Engineering": [
      "Calculus & Numericals",
      "Circuit Analysis",
      "Signal Processing",
      "Electromagnetics",
      "Embedded Systems",
      "Programming (C/C++)",
      "Control Systems",
    ],
    "Business Administration": [
      "Statistics",
      "Accounting & Finance",
      "Microeconomics",
      "Business Writing",
      "Marketing Strategy",
      "Data Analysis",
    ],
    "General / Other": [
      "Mathematics",
      "Statistics",
      "Calculus & Numericals",
      "Object-Oriented Programming (OOP)",
      "Writing & Communication",
      "Analytical Logic",
    ],
  };

  final Set<String> strongBasics = {};
  final Set<String> weakBasics = {};

  List<String> get currentDeptBasics {
    final dept = departmentController.text.trim();
    if (departmentBasics.containsKey(dept)) {
      return departmentBasics[dept]!;
    }
    return departmentBasics["Computer Science"]!;
  }

  @override
  void initState() {
    super.initState();
    _loadExistingProfileData();
  }

  /// Pre-populate existing profile data from registration and SharedPreferences
  Future<void> _loadExistingProfileData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final meta = user.userMetadata;
        if (meta != null && meta['department'] != null && meta['department'].toString().isNotEmpty) {
          departmentController.text = meta['department'].toString();
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final dept = prefs.getString('user_dept');
      final sem = prefs.getString('user_semester');
      final current = prefs.getString('user_current_cgpa') ?? prefs.getString('sim_prev_cgpa');
      final lastSem = prefs.getString('user_last_sem_cgpa');
      final target = prefs.getString('user_target_cgpa') ?? prefs.getString('sim_target_cgpa');
      final total = prefs.getString('user_total_credit') ?? prefs.getString('sim_total_credit');
      final completed = prefs.getString('user_completed_credit') ?? prefs.getString('sim_completed_credit');
      final strongJson = prefs.getString('user_strong_basics');
      final weakJson = prefs.getString('user_weak_basics');

      if (dept != null && dept.isNotEmpty) departmentController.text = dept;
      if (sem != null && sem.isNotEmpty) selectedSemester = sem;
      if (current != null && current.isNotEmpty && current != "0.0" && current != "0") {
        currentCgpaController.text = current;
      }
      if (lastSem != null && lastSem.isNotEmpty && lastSem != "0.0" && lastSem != "0") {
        lastSemCgpaController.text = lastSem;
      }
      if (target != null && target.isNotEmpty && target != "0.0" && target != "0") {
        targetCgpaController.text = target;
      }
      if (total != null && total.isNotEmpty && total != "0.0" && total != "0") {
        totalCreditController.text = total;
      }
      if (completed != null && completed.isNotEmpty && completed != "0.0" && completed != "0") {
        completedCreditController.text = completed;
      }

      if (strongJson != null) {
        final List list = jsonDecode(strongJson);
        strongBasics.clear();
        strongBasics.addAll(list.cast<String>());
      }
      if (weakJson != null) {
        final List list = jsonDecode(weakJson);
        weakBasics.clear();
        weakBasics.addAll(list.cast<String>());
      }

      if (departmentController.text.isEmpty) {
        departmentController.text = "Computer Science";
      }

      if (user != null) {
        try {
          final data = await SupabaseService.client
              .from('profiles')
              .select('department, semester, current_cgpa, last_sem_cgpa, total_credits, completed_credits, target_cgpa, strong_basics, weak_basics')
              .eq('id', user.id)
              .maybeSingle();

          if (data != null) {
            if (data['department'] != null && data['department'].toString().isNotEmpty) {
              departmentController.text = data['department'].toString();
            }
            if (data['semester'] != null && data['semester'].toString().isNotEmpty) {
              selectedSemester = data['semester'].toString();
            }

            void setIfValid(TextEditingController ctrl, dynamic val) {
              if (ctrl.text.isEmpty && val != null) {
                final s = val.toString();
                if (s.isNotEmpty && s != "0.0" && s != "0") {
                  ctrl.text = s;
                }
              }
            }

            setIfValid(currentCgpaController, data['current_cgpa']);
            setIfValid(lastSemCgpaController, data['last_sem_cgpa']);
            setIfValid(totalCreditController, data['total_credits']);
            setIfValid(completedCreditController, data['completed_credits']);
            setIfValid(targetCgpaController, data['target_cgpa']);

            if (data['strong_basics'] != null && strongBasics.isEmpty) {
              strongBasics.addAll(List<String>.from(data['strong_basics']));
            }
            if (data['weak_basics'] != null && weakBasics.isEmpty) {
              weakBasics.addAll(List<String>.from(data['weak_basics']));
            }
          }
        } catch (_) {}
      }

      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    departmentController.dispose();
    currentCgpaController.dispose();
    lastSemCgpaController.dispose();
    totalCreditController.dispose();
    completedCreditController.dispose();
    targetCgpaController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final user = _auth.currentUser;
      final dept = departmentController.text.trim();
      final currentCgpa = currentCgpaController.text.trim();
      final lastSemCgpa = lastSemCgpaController.text.trim();
      final totalCredit = totalCreditController.text.trim();
      final completedCredit = completedCreditController.text.trim();

      // 1. Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // Persist name from user metadata so profile screen shows it immediately
      if (user != null) {
        final meta = user.userMetadata;
        if (meta != null && meta['full_name'] != null && meta['full_name'].toString().isNotEmpty) {
          await prefs.setString('user_name', meta['full_name'].toString());
        }
      }

      await prefs.setString('user_dept', dept);
      await prefs.setString('user_semester', selectedSemester);
      await prefs.setString('user_current_cgpa', currentCgpa);
      await prefs.setString('user_last_sem_cgpa', lastSemCgpa);
      await prefs.setString('user_total_credit', totalCredit);
      await prefs.setString('user_completed_credit', completedCredit);
      await prefs.setString('user_target_cgpa', targetCgpaController.text.trim());

      // Pre-fill simulator inputs from onboarding entries
      await prefs.setString('sim_total_credit', totalCredit);
      await prefs.setString('sim_completed_credit', completedCredit);
      await prefs.setString('sim_prev_cgpa', currentCgpa);
      await prefs.setString('sim_target_cgpa', targetCgpaController.text.trim());

      await prefs.setString('user_strong_basics', jsonEncode(strongBasics.toList()));
      await prefs.setString('user_weak_basics', jsonEncode(weakBasics.toList()));
      await prefs.setBool('onboarding_completed', true);

      // 2. Save to Supabase Profile if logged in
      if (user != null) {
        try {
          await SupabaseService.client.from('profiles').upsert({
            'id': user.id,
            'department': dept,
            'semester': selectedSemester,
            'current_cgpa': double.tryParse(currentCgpa) ?? 0.0,
            'last_sem_cgpa': double.tryParse(lastSemCgpa) ?? 0.0,
            'total_credits': double.tryParse(totalCredit) ?? 0.0,
            'completed_credits': double.tryParse(completedCredit) ?? 0.0,
            'target_cgpa': double.tryParse(targetCgpaController.text.trim()) ?? 0.0,
            'strong_basics': strongBasics.toList(),
            'weak_basics': weakBasics.toList(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint("Supabase profile sync warning: $e");
        }
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress Indicator Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
                    child: const Icon(Icons.school_rounded,
                        color: Color(0xFF0F766E)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome to StudyBuddy!",
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F766E)),
                        ),
                        Text(
                          "Step ${_currentStep + 1} of 2 · Academic Profile Setup",
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: (_currentStep + 1) / 2,
              backgroundColor: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              color: const Color(0xFF0F766E),
              minHeight: 4,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _currentStep == 0
                    ? _buildStepOne(isDark, theme)
                    : _buildStepTwo(isDark, theme),
              ),
            ),

            // Bottom Navigation Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                    top: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => setState(() => _currentStep--),
                      child: Text("Back",
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold)),
                    ),
                  const Spacer(),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isSaving
                          ? null
                          : () {
                              if (_currentStep == 0) {
                                setState(() => _currentStep = 1);
                              } else {
                                _completeOnboarding();
                              }
                            },
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Row(
                              children: [
                                Text(
                                  _currentStep == 0
                                      ? "Next: Basics Profile"
                                      : "Finish Setup",
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.white),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 18),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepOne(bool isDark, ThemeData theme) {
    return FadeInSlide(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Academic Details & Credits",
            style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 6),
          Text(
            "Enter your department, semester, credits, and CGPA history to configure your profile.",
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Department & Semester Selection
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: departmentController,
                  onChanged: (_) => setState(() {
                    strongBasics.clear();
                    weakBasics.clear();
                  }),
                  decoration: const InputDecoration(
                    labelText: "Department / Major",
                    prefixIcon: Icon(Icons.school_outlined),
                    hintText: "e.g., Computer Science",
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: departmentBasics.keys.map((dept) {
                    final isSel = departmentController.text.trim() == dept;
                    return ChoiceChip(
                      label: Text(dept,
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? Colors.white : null)),
                      selected: isSel,
                      selectedColor: const Color(0xFF0F766E),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            departmentController.text = dept;
                            strongBasics.clear();
                            weakBasics.clear();
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: selectedSemester,
                  decoration: const InputDecoration(
                    labelText: "Current Semester",
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  items: semesterOptions
                      .map((sem) => DropdownMenuItem(
                            value: sem,
                            child: Text(sem, style: GoogleFonts.outfit()),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedSemester = val);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // GPA & Credits Input Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
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
                        controller: currentCgpaController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: "Current Total CGPA",
                          hintText: "e.g. 3.25",
                          prefixIcon: Icon(Icons.grade_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: lastSemCgpaController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: "Last Sem CGPA",
                          hintText: "e.g. 3.40",
                          prefixIcon: Icon(Icons.history_edu_outlined),
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
                        controller: totalCreditController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: "Total Program Credits",
                          hintText: "e.g. 140",
                          prefixIcon: Icon(Icons.numbers_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: completedCreditController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: "Completed Credits",
                          hintText: "e.g. 70",
                          prefixIcon: Icon(Icons.check_circle_outline),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Target CGPA card
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Target CGPA 🎯",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: theme.colorScheme.primary)),
                const SizedBox(height: 6),
                Text(
                  "Set your desired cumulative GPA. StudyBuddy will calculate what you need each semester.",
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: targetCgpaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: "Target CGPA (e.g. 3.80)",
                    hintText: "e.g. 3.80",
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                ),
                Builder(builder: (context) {
                  final current = double.tryParse(currentCgpaController.text);
                  final target = double.tryParse(targetCgpaController.text);
                  final completed = double.tryParse(completedCreditController.text);
                  final total = double.tryParse(totalCreditController.text);

                  if (current == null || target == null || completed == null || total == null) {
                    return const SizedBox.shrink();
                  }
                  final remaining = total - completed;
                  if (remaining <= 0) return const SizedBox.shrink();

                  // Avg GPA required across remaining credits to hit target cumulative GPA
                  // Formula: (target * total - current * completed) / remaining
                  final required = (target * total - current * completed) / remaining;
                  final clamped = required.clamp(0.0, 4.0);
                  final feasible = required <= 4.0;

                  return Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: feasible
                          ? (isDark ? const Color(0xFF0D2420) : const Color(0xFFECFDF5))
                          : (isDark ? const Color(0xFF3B1515) : const Color(0xFFFFF1F2)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: feasible
                              ? const Color(0xFF0F766E)
                              : Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          feasible ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                          color: feasible ? const Color(0xFF0F766E) : Colors.red.shade400,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                feasible
                                    ? "Avg GPA Required: ${clamped.toStringAsFixed(2)} / semester"
                                    : "Target not achievable — try a lower target",
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: feasible
                                        ? const Color(0xFF0F766E)
                                        : Colors.red.shade600),
                              ),
                              if (feasible)
                                Text(
                                  "Over ${remaining.toStringAsFixed(0)} remaining credits",
                                  style: GoogleFonts.outfit(
                                      fontSize: 12, color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTwo(bool isDark, ThemeData theme) {
    final availableBasics = currentDeptBasics;

    return FadeInSlide(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Strong & Weak Basics Profile",
            style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 6),
          Text(
            "Select your academic strengths and weaknesses. StudyBuddy will predict your improvement probability in retake courses!",
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // 1. Strong Basics Selection
          Text(
            "1. Select Strong Basics / Strengths ⭐",
            style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableBasics.map((topic) {
              final isSelected = strongBasics.contains(topic);
              return FilterChip(
                label: Text(
                  topic,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : null,
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF0F766E),
                checkmarkColor: Colors.white,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      strongBasics.add(topic);
                      weakBasics.remove(topic);
                    } else {
                      strongBasics.remove(topic);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // 2. Weak Basics Selection
          Text(
            "2. Select Weak Basics / Weaknesses ⚠️",
            style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableBasics.map((topic) {
              final isSelected = weakBasics.contains(topic);
              return FilterChip(
                label: Text(
                  topic,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : null,
                  ),
                ),
                selected: isSelected,
                selectedColor: Colors.amber.shade800,
                checkmarkColor: Colors.white,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      weakBasics.add(topic);
                      strongBasics.remove(topic);
                    } else {
                      weakBasics.remove(topic);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
