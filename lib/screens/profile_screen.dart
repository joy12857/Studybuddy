import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService auth = AuthService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController currentCgpaController = TextEditingController();
  final TextEditingController lastSemCgpaController = TextEditingController();
  final TextEditingController targetCgpaController = TextEditingController();
  final TextEditingController totalCreditController = TextEditingController();
  final TextEditingController completedCreditController = TextEditingController();

  String selectedSemester = "Semester 5";

  final Set<String> strongBasics = {};
  final Set<String> weakBasics = {};

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

  List<String> get availableBasics {
    final dept = departmentController.text.trim();
    final List<String> list = [];
    if (departmentBasics.containsKey(dept)) {
      list.addAll(departmentBasics[dept]!);
    } else {
      list.addAll(departmentBasics["Computer Science"]!);
    }
    for (final topic in strongBasics) {
      if (!list.contains(topic)) list.add(topic);
    }
    for (final topic in weakBasics) {
      if (!list.contains(topic)) list.add(topic);
    }
    return list;
  }

  final List<String> academicGoals = [];

  final TextEditingController newGoalController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  bool enableExamWarnings = true;
  bool enableLowGpaAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      // 1. Load from SharedPreferences FIRST (with fallback to sim_* keys)
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

      // 2. Merge Supabase profiles data if logged in (only use valid non-zero numbers if local field is empty)
      final user = auth.currentUser;
      if (user != null) {
        final meta = user.userMetadata;
        if (meta != null) {
          if (meta['full_name'] != null && meta['full_name'].toString().isNotEmpty && nameController.text.isEmpty) {
            nameController.text = meta['full_name'].toString();
          }
          if (meta['department'] != null && meta['department'].toString().isNotEmpty && departmentController.text.isEmpty) {
            departmentController.text = meta['department'].toString();
          }
        }

        try {
          final data = await SupabaseService.client
              .from('profiles')
              .select('full_name, department, semester, current_cgpa, last_sem_cgpa, total_credits, completed_credits, target_cgpa, strong_basics, weak_basics')
              .eq('id', user.id)
              .maybeSingle();

          if (data != null) {
            if (data['full_name'] != null && data['full_name'].toString().isNotEmpty && nameController.text.isEmpty) {
              nameController.text = data['full_name'];
            }
            if (data['department'] != null && data['department'].toString().isNotEmpty && departmentController.text.isEmpty) {
              departmentController.text = data['department'];
            }
            if (data['semester'] != null && data['semester'].toString().isNotEmpty) {
              selectedSemester = data['semester'];
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

      // 3. Immediately persist loaded valid fields back to SharedPreferences
      if (departmentController.text.isNotEmpty) await prefs.setString('user_dept', departmentController.text);
      await prefs.setString('user_semester', selectedSemester);
      if (currentCgpaController.text.isNotEmpty) {
        await prefs.setString('user_current_cgpa', currentCgpaController.text);
        await prefs.setString('sim_prev_cgpa', currentCgpaController.text);
      }
      if (lastSemCgpaController.text.isNotEmpty) await prefs.setString('user_last_sem_cgpa', lastSemCgpaController.text);
      if (targetCgpaController.text.isNotEmpty) {
        await prefs.setString('user_target_cgpa', targetCgpaController.text);
        await prefs.setString('sim_target_cgpa', targetCgpaController.text);
      }
      if (totalCreditController.text.isNotEmpty) {
        await prefs.setString('user_total_credit', totalCreditController.text);
        await prefs.setString('sim_total_credit', totalCreditController.text);
      }
      if (completedCreditController.text.isNotEmpty) {
        await prefs.setString('user_completed_credit', completedCreditController.text);
        await prefs.setString('sim_completed_credit', completedCreditController.text);
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      isSaving = true;
    });

    try {
      final user = auth.currentUser;
      final dept = departmentController.text.trim();
      final currentCgpa = currentCgpaController.text.trim();
      final lastSemCgpa = lastSemCgpaController.text.trim();
      final targetCgpa = targetCgpaController.text.trim();
      final totalCredit = totalCreditController.text.trim();
      final completedCredit = completedCreditController.text.trim();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_dept', dept);
      await prefs.setString('user_semester', selectedSemester);
      await prefs.setString('user_current_cgpa', currentCgpa);
      await prefs.setString('user_last_sem_cgpa', lastSemCgpa);
      await prefs.setString('user_target_cgpa', targetCgpa);
      await prefs.setString('user_total_credit', totalCredit);
      await prefs.setString('user_completed_credit', completedCredit);

      await prefs.setString('sim_total_credit', totalCredit);
      await prefs.setString('sim_completed_credit', completedCredit);
      await prefs.setString('sim_prev_cgpa', currentCgpa);
      await prefs.setString('sim_target_cgpa', targetCgpa);

      await prefs.setString('user_strong_basics', jsonEncode(strongBasics.toList()));
      await prefs.setString('user_weak_basics', jsonEncode(weakBasics.toList()));

      if (user != null) {
        try {
          await SupabaseService.client.from('profiles').upsert({
            'id': user.id,
            'full_name': nameController.text.trim(),
            'department': dept,
            'semester': selectedSemester,
            'current_cgpa': double.tryParse(currentCgpa) ?? 0.0,
            'last_sem_cgpa': double.tryParse(lastSemCgpa) ?? 0.0,
            'total_credits': double.tryParse(totalCredit) ?? 0.0,
            'completed_credits': double.tryParse(completedCredit) ?? 0.0,
            'target_cgpa': double.tryParse(targetCgpa) ?? 0.0,
            'strong_basics': strongBasics.toList(),
            'weak_basics': weakBasics.toList(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF0F766E),
          content: Text("Academic Profile & Basics Saved!", style: GoogleFonts.outfit(color: Colors.white)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.red.shade800,
          content: Text("Error: ${e.toString().replaceFirst("Exception: ", "")}",
              style: GoogleFonts.outfit(color: Colors.white)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    departmentController.dispose();
    currentCgpaController.dispose();
    lastSemCgpaController.dispose();
    targetCgpaController.dispose();
    totalCreditController.dispose();
    completedCreditController.dispose();
    newGoalController.dispose();
    super.dispose();
  }

  void _addGoal() {
    if (newGoalController.text.trim().isEmpty) return;
    setState(() {
      academicGoals.add(newGoalController.text.trim());
      newGoalController.clear();
    });
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
          "Student Academic Profile",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white24,
                          child: Text(
                            nameController.text.isNotEmpty
                                ? nameController.text.substring(0, 1).toUpperCase()
                                : "S",
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nameController.text.isNotEmpty
                                    ? nameController.text
                                    : "Student Name",
                                style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${departmentController.text.isNotEmpty ? departmentController.text : 'Department'} · $selectedSemester",
                                style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Academic Details Form
                  Text("Academic Information & Credits",
                      style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: "Full Name",
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: departmentController,
                          decoration: const InputDecoration(
                            labelText: "Department / Major",
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: currentCgpaController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: "Current Total CGPA",
                                  prefixIcon: Icon(Icons.grade_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: lastSemCgpaController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: "Last Sem CGPA",
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
                              child: TextFormField(
                                controller: totalCreditController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Total Program Credits",
                                  prefixIcon: Icon(Icons.numbers_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: completedCreditController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Completed Credits",
                                  prefixIcon: Icon(Icons.check_circle_outline),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Strong & Weak Basics Selector Card
                  Text("Strong & Weak Basics Profile",
                      style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Strong Basics ⭐",
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                                fontSize: 14)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: availableBasics.map((topic) {
                            final isSel = strongBasics.contains(topic);
                            return FilterChip(
                              label: Text(topic, style: GoogleFonts.outfit(fontSize: 12)),
                              selected: isSel,
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
                        const SizedBox(height: 16),
                        Text("Weak Basics ⚠️",
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                                fontSize: 14)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: availableBasics.map((topic) {
                            final isSel = weakBasics.contains(topic);
                            return FilterChip(
                              label: Text(topic, style: GoogleFonts.outfit(fontSize: 12)),
                              selected: isSel,
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
                  ),
                  const SizedBox(height: 24),

                  // Academic Goals Section
                  Text("Academic Goals",
                      style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: newGoalController,
                                decoration: const InputDecoration(
                                  hintText: "Add new academic goal...",
                                  prefixIcon: Icon(Icons.task_alt_rounded),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_circle_rounded,
                                  color: Color(0xFF0F766E), size: 32),
                              onPressed: _addGoal,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: academicGoals.length,
                          itemBuilder: (context, idx) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.check_circle_outline_rounded,
                                  color: Color(0xFF0F766E)),
                              title: Text(academicGoals[idx], style: GoogleFonts.outfit()),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.grey, size: 20),
                                onPressed: () {
                                  setState(() {
                                    academicGoals.removeAt(idx);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: isSaving ? null : _saveProfile,
                      child: isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text("Save Academic Profile",
                              style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}