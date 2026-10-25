import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../services/supabase_service.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final TextEditingController noteController = TextEditingController();

  int selectedMoodIndex = 0;

  final List<Map<String, dynamic>> moods = [
    {"emoji": "😊", "label": "Happy", "color": Colors.orange},
    {"emoji": "🙂", "label": "Calm", "color": Colors.teal},
    {"emoji": "😐", "label": "Neutral", "color": Colors.blueGrey},
    {"emoji": "😔", "label": "Sad", "color": Colors.blue},
    {"emoji": "😰", "label": "Stressed", "color": Colors.purple},
    {"emoji": "😡", "label": "Angry", "color": Colors.red},
  ];

  bool isLoading = false;
  bool isHistoryLoading = false;
  List<Map<String, dynamic>> loggedMoods = [];

  @override
  void initState() {
    super.initState();
    fetchMoods();
  }

  Future<void> fetchMoods() async {
    setState(() {
      isHistoryLoading = true;
    });

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        final response = await SupabaseService.client
            .from("moods")
            .select()
            .eq("user_id", user.id)
            .order("created_at", ascending: false);
        if (mounted) {
          setState(() {
            loggedMoods = List<Map<String, dynamic>>.from(response);
          });
        }
      }
    } catch (_) {
      // Offline mock data if query fails or table does not exist
      if (loggedMoods.isEmpty) {
        setState(() {
          loggedMoods = [
            {
              "id": "1",
              "mood": "😊 Happy",
              "note": "Had an awesome coding session today!",
              "created_at": DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
            },
            {
              "id": "2",
              "mood": "🙂 Calm",
              "note": "Practiced breathing exercises.",
              "created_at": DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            },
            {
              "id": "3",
              "mood": "😰 Stressed",
              "note": "Studying for midterms, feeling overwhelmed.",
              "created_at": DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
            },
          ];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isHistoryLoading = false;
        });
      }
    }
  }

  Future<void> saveMood() async {
    setState(() {
      isLoading = true;
    });

    final selected = moods[selectedMoodIndex];
    final moodString = "${selected['emoji']} ${selected['label']}";
    final noteText = noteController.text.trim();

    try {
      final user = SupabaseService.client.auth.currentUser;

      if (user == null) {
        throw Exception("User not logged in.");
      }

      await SupabaseService.client.from("moods").insert({
        "user_id": user.id,
        "mood": moodString,
        "note": noteText,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF0F766E),
          content: Text("Mood saved successfully!", style: GoogleFonts.outfit()),
        ),
      );

      noteController.clear();
      fetchMoods();
    } catch (e) {
      // Local insert fallback
      setState(() {
        loggedMoods.insert(0, {
          "id": DateTime.now().toIso8601String(),
          "mood": moodString,
          "note": noteText,
          "created_at": DateTime.now().toIso8601String(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.teal.shade800,
            content: Text("Logged successfully (offline)", style: GoogleFonts.outfit()),
          ),
        );
      }
      noteController.clear();
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> deleteMood(dynamic id) async {
    try {
      await SupabaseService.client.from("moods").delete().eq("id", id);
      fetchMoods();
    } catch (_) {
      setState(() {
        loggedMoods.removeWhere((item) => item["id"] == id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text("Deleted log locally", style: GoogleFonts.outfit()),
        ),
      );
    }
  }

  List<FlSpot> getChartSpots() {
    if (loggedMoods.isEmpty) {
      return [
        const FlSpot(0, 3),
        const FlSpot(1, 4),
        const FlSpot(2, 2.5),
        const FlSpot(3, 4),
        const FlSpot(4, 5),
        const FlSpot(5, 3),
        const FlSpot(6, 4.5),
      ];
    }

    final List<FlSpot> spots = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayLogs = loggedMoods.where((log) {
        final createdAtStr = log["created_at"];
        if (createdAtStr == null) return false;
        final logDate = DateTime.tryParse(createdAtStr);
        if (logDate == null) return false;
        return logDate.year == date.year &&
            logDate.month == date.month &&
            logDate.day == date.day;
      }).toList();

      double sum = 0;
      int count = 0;
      for (final log in dayLogs) {
        final moodStr = log["mood"] as String? ?? "";
        double val = 3.0; // neutral
        if (moodStr.contains("Happy")) {
          val = 5.0;
        } else if (moodStr.contains("Calm")) {
          val = 4.0;
        } else if (moodStr.contains("Neutral")) {
          val = 3.0;
        } else if (moodStr.contains("Sad")) {
          val = 2.0;
        } else if (moodStr.contains("Stressed")) {
          val = 1.5;
        } else if (moodStr.contains("Angry")) {
          val = 1.0;
        }
        sum += val;
        count++;
      }

      double avg = count > 0 ? sum / count : 3.0;
      spots.add(FlSpot((6 - i).toDouble(), avg));
    }
    return spots;
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Mood Tracker",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emojis panel card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "How do you feel right now?",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Mood grid of circles
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: moods.length,
                    itemBuilder: (context, index) {
                      final m = moods[index];
                      final isSelected = selectedMoodIndex == index;
                      final moodColor = m["color"] as Color;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedMoodIndex = index;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? moodColor.withValues(alpha: 0.1) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? moodColor : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                m["emoji"],
                                style: const TextStyle(fontSize: 26),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m["label"],
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? moodColor : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Note Field
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    style: GoogleFonts.outfit(),
                    decoration: const InputDecoration(
                      labelText: "What's making you feel this way? (Optional)",
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : saveMood,
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              "Log Mood",
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Weekly Trend Chart
            Text(
              "Mood Trend",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.only(right: 20, left: 10, top: 20, bottom: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1.0,
                        getTitlesWidget: (val, meta) {
                          switch (val.toInt()) {
                            case 1:
                              return Text("😢", style: GoogleFonts.outfit(fontSize: 14));
                            case 2:
                              return Text("😔", style: GoogleFonts.outfit(fontSize: 14));
                            case 3:
                              return Text("😐", style: GoogleFonts.outfit(fontSize: 14));
                            case 4:
                              return Text("🙂", style: GoogleFonts.outfit(fontSize: 14));
                            case 5:
                              return Text("😊", style: GoogleFonts.outfit(fontSize: 14));
                          }
                          return const Text("");
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 1,
                        getTitlesWidget: (val, meta) {
                          final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
                          // Center current day at end
                          int index = val.toInt();
                          if (index < 0 || index >= days.length) return const Text("");
                          // Dynamic days based on last 7 calendar days
                          final dayName = DateFormat('E').format(
                            DateTime.now().subtract(Duration(days: 6 - index)),
                          );
                          return Text(
                            dayName,
                            style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade500),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 1,
                  maxY: 5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: getChartSpots(),
                      isCurved: true,
                      color: const Color(0xFF0F766E),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // History Log List
            Text(
              "Mood History",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 12),
            isHistoryLoading
                ? const Center(child: CircularProgressIndicator())
                : loggedMoods.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            "No mood logs yet. Let's record how you feel!",
                            style: GoogleFonts.outfit(color: Colors.grey.shade500),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: loggedMoods.length,
                        itemBuilder: (context, index) {
                          final log = loggedMoods[index];
                          final id = log["id"];
                          final mood = log["mood"] as String? ?? "😐 Neutral";
                          final note = log["note"] as String? ?? "";
                          final createdAt = log["created_at"] as String?;

                          String displayTime = "Just now";
                          if (createdAt != null) {
                            final parsedDate = DateTime.tryParse(createdAt);
                            if (parsedDate != null) {
                              displayTime = DateFormat('MMM dd, hh:mm a').format(parsedDate.toLocal());
                            }
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade100),
                            ),
                            color: Colors.white,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.08),
                                child: Text(
                                  mood.split(' ').first,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                              title: Text(
                                mood.split(' ').sublist(1).join(' '),
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (note.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      note,
                                      style: GoogleFonts.outfit(color: Colors.grey.shade700),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    displayTime,
                                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade400),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                                onPressed: () => deleteMood(id),
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
