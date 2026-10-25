import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  int activeTab = 0; // 0: Counselors, 1: My Bookings
  List<Map<String, dynamic>> bookedSessions = [];

  final List<Map<String, dynamic>> counselors = [
    {
      "name": "Dr. Sarah Jenkins",
      "specialization": "Stress & Anxiety Management",
      "rating": "4.9",
      "reviews": "120 reviews",
      "avatar": "SJ",
      "color": Colors.teal,
    },
    {
      "name": "Prof. Alan Vance",
      "specialization": "Academic Adjustments & Focus",
      "rating": "4.8",
      "reviews": "84 reviews",
      "avatar": "AV",
      "color": Colors.blue,
    },
    {
      "name": "Dr. Emily Taylor",
      "specialization": "Relationship & Social Wellness",
      "rating": "4.9",
      "reviews": "96 reviews",
      "avatar": "ET",
      "color": Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  Future<void> loadBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('booked_appointments');
    if (data != null) {
      setState(() {
        bookedSessions = List<Map<String, dynamic>>.from(json.decode(data));
      });
    }
  }

  Future<void> saveBookings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('booked_appointments', json.encode(bookedSessions));
  }

  void cancelAppointment(int index) {
    setState(() {
      bookedSessions.removeAt(index);
    });
    saveBookings();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text("Appointment cancelled successfully.", style: GoogleFonts.outfit()),
      ),
    );
  }

  void openBookingModal(Map<String, dynamic> counselor) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedTime = "10:30 AM";
    final notesController = TextEditingController();

    final List<String> timeSlots = [
      "09:00 AM",
      "10:30 AM",
      "01:30 PM",
      "03:00 PM",
      "04:30 PM",
    ];

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
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Book Session",
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Counselor Profile Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: (counselor["color"] as Color).withValues(alpha: 0.1),
                          child: Text(
                            counselor["avatar"],
                            style: GoogleFonts.outfit(
                              color: counselor["color"] as Color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                counselor["name"],
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                counselor["specialization"],
                                style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const Divider(height: 30),
                    // Date picker (horizontal list)
                    Text(
                      "Select Date",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 70,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 7,
                        itemBuilder: (context, i) {
                          final date = DateTime.now().add(Duration(days: i + 1));
                          final isSelected = DateFormat('yy-MM-dd').format(date) ==
                              DateFormat('yy-MM-dd').format(selectedDate);

                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: InkWell(
                              onTap: () {
                                setModalState(() {
                                  selectedDate = date;
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 60,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFEF4444) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFEF4444) : Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('E').format(date),
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? Colors.white : Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('d').format(date),
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
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
                    const SizedBox(height: 20),
                    // Time Slots Grid
                    Text(
                      "Select Time Slot",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: timeSlots.map((slot) {
                        final isSelected = selectedTime == slot;
                        return ChoiceChip(
                          label: Text(
                            slot,
                            style: GoogleFonts.outfit(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFEF4444),
                          backgroundColor: Colors.grey.shade50,
                          onSelected: (val) {
                            if (val) {
                              setModalState(() {
                                selectedTime = slot;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Notes field
                    TextField(
                      controller: notesController,
                      style: GoogleFonts.outfit(),
                      decoration: const InputDecoration(
                        labelText: "Reason for counseling (Optional)",
                        alignLabelWithHint: true,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    // Confirmation button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            bookedSessions.add({
                              "counselor_name": counselor["name"],
                              "specialization": counselor["specialization"],
                              "date": DateFormat('EEEE, MMMM dd').format(selectedDate),
                              "time": selectedTime,
                              "note": notesController.text.trim(),
                              "avatar": counselor["avatar"],
                            });
                          });
                          saveBookings();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Colors.teal.shade800,
                              content: Text("Booking confirmed successfully!", style: GoogleFonts.outfit()),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                        ),
                        child: Text(
                          "Confirm Booking",
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
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
    ).then((_) => notesController.dispose());
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
          "Counselor Directory",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Segmented Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          activeTab = 0;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: activeTab == 0 ? const Color(0xFFEF4444) : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "Counselors",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: activeTab == 0 ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          activeTab = 1;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: activeTab == 1 ? const Color(0xFFEF4444) : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "My Bookings (${bookedSessions.length})",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: activeTab == 1 ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: activeTab == 0
                ? _buildCounselorsTab(theme)
                : _buildBookingsTab(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildCounselorsTab(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: counselors.length,
      itemBuilder: (context, index) {
        final c = counselors[index];
        final Color avatarColor = c["color"];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: avatarColor.withValues(alpha: 0.1),
                      child: Text(
                        c["avatar"],
                        style: GoogleFonts.outfit(
                          color: avatarColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c["name"],
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: theme.textTheme.titleMedium?.color),
                          ),
                          Text(
                            c["specialization"],
                            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                c["rating"],
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF334155)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "(${c["reviews"]})",
                                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Available Tomorrow",
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => openBookingModal(c),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        "Book Session",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingsTab(ThemeData theme) {
    if (bookedSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_rounded, size: 50, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(
              "No upcoming appointments.",
              style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: bookedSessions.length,
      itemBuilder: (context, index) {
        final b = bookedSessions[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      child: Text(
                        b["avatar"] ?? "C",
                        style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b["counselor_name"] ?? "Counselor",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.titleSmall?.color),
                          ),
                          Text(
                            b["specialization"] ?? "Therapy",
                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF475569)),
                    const SizedBox(width: 8),
                    Text(
                      b["date"] ?? "",
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF475569)),
                    const SizedBox(width: 8),
                    Text(
                      b["time"] ?? "",
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                    ),
                  ],
                ),
                if (b["note"] != null && (b["note"] as String).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    "Reason for session:",
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    b["note"],
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
                const Divider(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => cancelAppointment(index),
                    child: Text(
                      "Cancel Appointment",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}