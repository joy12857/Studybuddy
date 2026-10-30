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
  bool isEditing = false;

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final localName = prefs.getString('user_name');
      final dept = prefs.getString('user_dept');
      final sem = prefs.getString('user_semester');
      final current = prefs.getString('user_current_cgpa') ?? prefs.getString('sim_prev_cgpa');
      final lastSem = prefs.getString('user_last_sem_cgpa');
      final target = prefs.getString('user_target_cgpa') ?? prefs.getString('sim_target_cgpa');
      final total = prefs.getString('user_total_credit') ?? prefs.getString('sim_total_credit');
      final completed = prefs.getString('user_completed_credit') ?? prefs.getString('sim_completed_credit');
      final strongJson = prefs.getString('user_strong_basics');
      final weakJson = prefs.getString('user_weak_basics');
      final goalsJson = prefs.getString('user_academic_goals');

      if (localName != null && localName.isNotEmpty) nameController.text = localName;
      if (dept != null && dept.isNotEmpty) departmentController.text = dept;
      if (sem != null && sem.isNotEmpty) selectedSemester = sem;
      _setIfValid(currentCgpaController, current);
      _setIfValid(lastSemCgpaController, lastSem);
      _setIfValid(targetCgpaController, target);
      _setIfValid(totalCreditController, total);
      _setIfValid(completedCreditController, completed);

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
      if (goalsJson != null) {
        final List list = jsonDecode(goalsJson);
        academicGoals.clear();
        academicGoals.addAll(list.cast<String>());
      }

      final user = auth.currentUser;
      if (user != null) {
        final meta = user.userMetadata;
        if (meta != null) {
          if (nameController.text.isEmpty && meta['full_name'] != null && meta['full_name'].toString().isNotEmpty) {
            nameController.text = meta['full_name'].toString();
          }
          if (departmentController.text.isEmpty && meta['department'] != null && meta['department'].toString().isNotEmpty) {
            departmentController.text = meta['department'].toString();
          }
        }

        try {
          final data = await SupabaseService.client
              .from('profiles')
              .select('full_name, department, semester, current_cgpa, last_sem_cgpa, total_credits, completed_credits, target_cgpa, strong_basics, weak_basics, academic_goals')
              .eq('id', user.id)
              .maybeSingle();

          if (data != null) {
            if (nameController.text.isEmpty && data['full_name'] != null && data['full_name'].toString().isNotEmpty) {
              nameController.text = data['full_name'];
            }
            if (departmentController.text.isEmpty && data['department'] != null && data['department'].toString().isNotEmpty) {
              departmentController.text = data['department'];
            }
            if (data['semester'] != null && data['semester'].toString().isNotEmpty) {
              selectedSemester = data['semester'];
            }
            _setIfValidFromDb(currentCgpaController, data['current_cgpa']);
            _setIfValidFromDb(lastSemCgpaController, data['last_sem_cgpa']);
            _setIfValidFromDb(totalCreditController, data['total_credits']);
            _setIfValidFromDb(completedCreditController, data['completed_credits']);
            _setIfValidFromDb(targetCgpaController, data['target_cgpa']);

            if (data['strong_basics'] != null && strongBasics.isEmpty) {
              strongBasics.addAll(List<String>.from(data['strong_basics']));
            }
            if (data['weak_basics'] != null && weakBasics.isEmpty) {
              weakBasics.addAll(List<String>.from(data['weak_basics']));
            }
            if (data['academic_goals'] != null && academicGoals.isEmpty) {
              academicGoals.addAll(List<String>.from(data['academic_goals']));
            }
          }
        } catch (_) {}
      }

      await _persistToLocalPrefs(prefs);
    } catch (_) {}

    if (mounted) {
      setState(() { isLoading = false; });
    }
  }

  void _setIfValid(TextEditingController ctrl, String? val) {
    if (ctrl.text.isEmpty && val != null && val.isNotEmpty && val != "0.0" && val != "0") {
      ctrl.text = val;
    }
  }

  void _setIfValidFromDb(TextEditingController ctrl, dynamic val) {
    if (ctrl.text.isEmpty && val != null) {
      final s = val.toString();
      if (s.isNotEmpty && s != "0.0" && s != "0") ctrl.text = s;
    }
  }

  Future<void> _persistToLocalPrefs(SharedPreferences prefs) async {
    if (nameController.text.isNotEmpty) await prefs.setString('user_name', nameController.text);
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
    await prefs.setString('user_strong_basics', jsonEncode(strongBasics.toList()));
    await prefs.setString('user_weak_basics', jsonEncode(weakBasics.toList()));
    await prefs.setString('user_academic_goals', jsonEncode(academicGoals));
  }

  Future<void> _saveProfile() async {
    setState(() { isSaving = true; });
    try {
      final user = auth.currentUser;
      final name = nameController.text.trim();
      final dept = departmentController.text.trim();
      final currentCgpa = currentCgpaController.text.trim();
      final lastSemCgpa = lastSemCgpaController.text.trim();
      final targetCgpa = targetCgpaController.text.trim();
      final totalCredit = totalCreditController.text.trim();
      final completedCredit = completedCreditController.text.trim();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
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
      await prefs.setString('user_academic_goals', jsonEncode(academicGoals));

      if (user != null) {
        try {
          await SupabaseService.client.from('profiles').upsert({
            'id': user.id,
            'full_name': name,
            'department': dept,
            'semester': selectedSemester,
            'current_cgpa': double.tryParse(currentCgpa) ?? 0.0,
            'last_sem_cgpa': double.tryParse(lastSemCgpa) ?? 0.0,
            'total_credits': double.tryParse(totalCredit) ?? 0.0,
            'completed_credits': double.tryParse(completedCredit) ?? 0.0,
            'target_cgpa': double.tryParse(targetCgpa) ?? 0.0,
            'strong_basics': strongBasics.toList(),
            'weak_basics': weakBasics.toList(),
            'academic_goals': academicGoals,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
      }

      if (mounted) {
        setState(() { isEditing = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: const Color(0xFF0F766E),
            content: Text("Profile saved successfully! \u2713",
                style: GoogleFonts.outfit(color: Colors.white)),
          ),
        );
      }
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
      if (mounted) setState(() { isSaving = false; });
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
        actions: [
          if (!isLoading)
            isEditing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: isSaving ? null : () => setState(() => isEditing = false),
                        child: Text("Cancel",
                            style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600)),
                      ),
                      TextButton(
                        onPressed: isSaving ? null : _saveProfile,
                        child: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E)),
                              )
                            : Text("Save",
                                style: GoogleFonts.outfit(
                                    color: const Color(0xFF0F766E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                      ),
                    ],
                  )
                : IconButton(
                    tooltip: "Edit Profile",
                    icon: const Icon(Icons.edit_rounded, color: Color(0xFF0F766E)),
                    onPressed: () => setState(() => isEditing = true),
                  ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(isDark),
                  const SizedBox(height: 24),
                  _buildSectionLabel("Academic Information & Credits"),
                  const SizedBox(height: 12),
                  _buildAcademicInfoCard(isDark),
                  const SizedBox(height: 24),
                  _buildSectionLabel("Strong & Weak Basics Profile"),
                  const SizedBox(height: 12),
                  _buildBasicsCard(isDark),
                  const SizedBox(height: 24),
                  _buildSectionLabel("Academic Goals"),
                  const SizedBox(height: 12),
                  _buildGoalsCard(isDark),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold));
  }

  Widget _buildProfileHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F766E).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Text(
              nameController.text.isNotEmpty ? nameController.text.substring(0, 1).toUpperCase() : "S",
              style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameController.text.isNotEmpty ? nameController.text : "Student Name",
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  "${departmentController.text.isNotEmpty ? departmentController.text : 'Department'} \u00b7 $selectedSemester",
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
                ),
                if (currentCgpaController.text.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text("CGPA: ${currentCgpaController.text}",
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                  ]),
                ],
              ],
            ),
          ),
          if (!isEditing)
            GestureDetector(
              onTap: () => setState(() => isEditing = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text("Edit", style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAcademicInfoCard(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEditing
              ? const Color(0xFF0F766E).withValues(alpha: 0.6)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isEditing ? 1.5 : 1,
        ),
        boxShadow: isEditing
            ? [BoxShadow(color: const Color(0xFF0F766E).withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]
            : [],
      ),
      child: Column(
        children: [
          isEditing
              ? TextFormField(
                  controller: nameController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person_outline_rounded)),
                )
              : _buildReadonlyField(icon: Icons.person_outline_rounded, label: "Full Name", value: nameController.text, isDark: isDark),
          const SizedBox(height: 14),
          isEditing
              ? TextFormField(
                  controller: departmentController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: "Department / Major", prefixIcon: Icon(Icons.school_outlined)),
                )
              : _buildReadonlyField(icon: Icons.school_outlined, label: "Department / Major", value: departmentController.text, isDark: isDark),
          const SizedBox(height: 14),
          isEditing
              ? DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: semesterOptions.contains(selectedSemester) ? selectedSemester : semesterOptions.first,
                  decoration: const InputDecoration(labelText: "Current Semester", prefixIcon: Icon(Icons.calendar_today_outlined)),
                  items: semesterOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.outfit()))).toList(),
                  onChanged: (val) { if (val != null) setState(() => selectedSemester = val); },
                )
              : _buildReadonlyField(icon: Icons.calendar_today_outlined, label: "Current Semester", value: selectedSemester, isDark: isDark),
          const SizedBox(height: 14),
          isEditing
              ? Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: currentCgpaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "Current Total CGPA", prefixIcon: Icon(Icons.grade_outlined)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: lastSemCgpaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "Last Sem CGPA", prefixIcon: Icon(Icons.history_edu_outlined)),
                    ),
                  ),
                ])
              : Row(children: [
                  Expanded(child: _buildReadonlyField(icon: Icons.grade_outlined, label: "Current Total CGPA", value: currentCgpaController.text, isDark: isDark)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildReadonlyField(icon: Icons.history_edu_outlined, label: "Last Sem CGPA", value: lastSemCgpaController.text, isDark: isDark)),
                ]),
          const SizedBox(height: 14),
          isEditing
              ? Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: totalCreditController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Total Program Credits", prefixIcon: Icon(Icons.numbers_outlined)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: completedCreditController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Completed Credits", prefixIcon: Icon(Icons.check_circle_outline)),
                    ),
                  ),
                ])
              : Row(children: [
                  Expanded(child: _buildReadonlyField(icon: Icons.numbers_outlined, label: "Total Program Credits", value: totalCreditController.text, isDark: isDark)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildReadonlyField(icon: Icons.check_circle_outline, label: "Completed Credits", value: completedCreditController.text, isDark: isDark)),
                ]),
          if (isEditing) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: targetCgpaController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: "Target CGPA", prefixIcon: Icon(Icons.flag_outlined)),
            ),
          ] else if (targetCgpaController.text.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildReadonlyField(icon: Icons.flag_outlined, label: "Target CGPA", value: targetCgpaController.text, isDark: isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildReadonlyField({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final isEmpty = value.isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isEmpty ? Colors.grey.shade400 : const Color(0xFF0F766E)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  isEmpty ? "Not set" : value,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isEmpty ? Colors.grey.shade400 : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicsCard(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEditing
              ? const Color(0xFF0F766E).withValues(alpha: 0.6)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isEditing ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Strong Basics \u2b50",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.teal.shade700, fontSize: 14)),
          const SizedBox(height: 8),
          isEditing
              ? Wrap(
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
                          if (val) { strongBasics.add(topic); weakBasics.remove(topic); }
                          else { strongBasics.remove(topic); }
                        });
                      },
                    );
                  }).toList(),
                )
              : strongBasics.isEmpty
                  ? Text("No strong basics selected",
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade400))
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: strongBasics.map((topic) => Chip(
                            label: Text(topic, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white)),
                            backgroundColor: const Color(0xFF0F766E),
                            padding: EdgeInsets.zero,
                          )).toList(),
                    ),
          const SizedBox(height: 16),
          Text("Weak Basics \u26a0\ufe0f",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 14)),
          const SizedBox(height: 8),
          isEditing
              ? Wrap(
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
                          if (val) { weakBasics.add(topic); strongBasics.remove(topic); }
                          else { weakBasics.remove(topic); }
                        });
                      },
                    );
                  }).toList(),
                )
              : weakBasics.isEmpty
                  ? Text("No weak basics selected",
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade400))
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: weakBasics.map((topic) => Chip(
                            label: Text(topic, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white)),
                            backgroundColor: Colors.amber.shade800,
                            padding: EdgeInsets.zero,
                          )).toList(),
                    ),
        ],
      ),
    );
  }

  Widget _buildGoalsCard(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEditing
              ? const Color(0xFF0F766E).withValues(alpha: 0.6)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isEditing ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isEditing) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: newGoalController,
                    decoration: const InputDecoration(
                      hintText: "Add new academic goal...",
                      prefixIcon: Icon(Icons.task_alt_rounded),
                    ),
                    onSubmitted: (_) => _addGoal(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF0F766E), size: 32),
                  onPressed: _addGoal,
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (academicGoals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                isEditing ? "Add your academic goals above" : "No academic goals set yet",
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade400),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: academicGoals.length,
              itemBuilder: (context, idx) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF0F766E)),
                  title: Text(academicGoals[idx], style: GoogleFonts.outfit()),
                  trailing: isEditing
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                          onPressed: () => setState(() => academicGoals.removeAt(idx)),
                        )
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }
}
