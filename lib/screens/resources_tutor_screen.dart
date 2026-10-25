import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/academic_models.dart';
import '../widgets/interactive_animations.dart';

class ResourcesTutorScreen extends StatefulWidget {
  const ResourcesTutorScreen({super.key});

  @override
  State<ResourcesTutorScreen> createState() => _ResourcesTutorScreenState();
}

class _ResourcesTutorScreenState extends State<ResourcesTutorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<ResourceItem> _resources = const [
    ResourceItem(
      title: "MIT OpenCourseWare: Algorithms & Data Structures",
      category: "Computer Science",
      courseCode: "CS",
      type: "Course",
      url: "https://ocw.mit.edu/courses/6-006-introduction-to-algorithms-spring-2020/",
      description: "Comprehensive lecture notes, problem sets, and exams from MIT's algorithms course.",
    ),
    ResourceItem(
      title: "Khan Academy Official YouTube Channel",
      category: "Free Resources",
      courseCode: "ALL",
      type: "Channel",
      url: "https://www.youtube.com/@khanacademy",
      description: "Official Khan Academy YouTube channel with free video lessons across math, science, and computing.",
    ),
    ResourceItem(
      title: "Khan Academy: Statistics & Probability (YouTube)",
      category: "Mathematics",
      courseCode: "MATH",
      type: "Video",
      url: "https://www.youtube.com/playlist?list=PL1328115D3D8A2566",
      description: "Interactive video lessons, practice exercises, and step-by-step solutions on YouTube.",
    ),
    ResourceItem(
      title: "CS50: Introduction to Computer Science — Harvard",
      category: "Computer Science",
      courseCode: "CS",
      type: "Course",
      url: "https://cs50.harvard.edu/x/",
      description: "Harvard's famous intro CS course, free on edX. Covers C, Python, SQL & more.",
    ),
    ResourceItem(
      title: "Khan Academy: Multivariable Calculus (YouTube)",
      category: "Mathematics",
      courseCode: "MATH",
      type: "Video",
      url: "https://www.youtube.com/@khanacademy",
      description: "Interactive YouTube video series on partial derivatives, gradients and integrals.",
    ),
    ResourceItem(
      title: "Coursera: OOP with Java — Duke University",
      category: "Computer Science",
      courseCode: "CS",
      type: "Course",
      url: "https://www.coursera.org/learn/object-oriented-java",
      description: "Master object-oriented programming principles with real-world projects.",
    ),
    ResourceItem(
      title: "Feynman Technique Study Guide & Active Recall Sheet",
      category: "Study Methods",
      courseCode: "ALL",
      type: "eBook",
      url: "https://fs.blog/feynman-technique/",
      description: "Learn how to simplify complex ideas and master exam material with the Feynman method.",
    ),
    ResourceItem(
      title: "Physics Classroom: Electromagnetism Simulations",
      category: "Physics",
      courseCode: "PHY",
      type: "Tutorial",
      url: "https://www.physicsclassroom.com/class/estatics",
      description: "Visual simulations and diagnostic quiz questions on electrostatics.",
    ),
    ResourceItem(
      title: "freeCodeCamp: Full Stack Web Development",
      category: "Computer Science",
      courseCode: "CS",
      type: "Course",
      url: "https://www.freecodecamp.org/learn",
      description: "Learn HTML, CSS, JavaScript, React and more — completely free with certifications.",
    ),
    ResourceItem(
      title: "Brilliant: Data Science & Statistics",
      category: "Mathematics",
      courseCode: "MATH",
      type: "Tutorial",
      url: "https://brilliant.org/courses/statistics/",
      description: "Interactive, hands-on problem solving for data science, statistics and probability.",
    ),
    ResourceItem(
      title: "Anki Flashcard Mastery Guide",
      category: "Study Methods",
      courseCode: "ALL",
      type: "eBook",
      url: "https://ankiweb.net/shared/info/",
      description: "Use spaced-repetition to memorize any subject faster. Free for desktop & Android.",
    ),
  ];


  final List<Map<String, dynamic>> _peerTutors = [
    {
      "name": "Dr. Sarah Jenkins",
      "specialization": "Calculus & Linear Algebra Specialist",
      "rating": "4.9",
      "reviews": "120 sessions",
      "avatar": "SJ",
      "color": Colors.teal,
    },
    {
      "name": "Prof. Alan Vance",
      "specialization": "Data Structures & Algorithm Coach",
      "rating": "4.8",
      "reviews": "95 sessions",
      "avatar": "AV",
      "color": Colors.blue,
    },
    {
      "name": "Elena Rostova",
      "specialization": "Physics & Electromagnetism Peer Tutor",
      "rating": "5.0",
      "reviews": "64 sessions",
      "avatar": "ER",
      "color": Colors.purple,
    }
  ];

  String _selectedCategoryFilter = "All";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredResources = _selectedCategoryFilter == "All"
        ? _resources
        : _resources.where((r) => r.category == _selectedCategoryFilter).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Resources & Peer Tutors",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0F766E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF0F766E),
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded), text: "Free Resources"),
            Tab(icon: Icon(Icons.group_rounded), text: "Book Tutor Session"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Free Learning Resources Hub
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Curated Free Learning Resources (v1)",
                    style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("Handpicked open-source courses, ebooks, and tutorials for your subjects.",
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 14),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["All", "Computer Science", "Mathematics", "Physics", "Study Methods"]
                        .map((cat) {
                      final isSel = _selectedCategoryFilter == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat,
                              style: GoogleFonts.outfit(
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  color: isSel ? Colors.white : null)),
                          selected: isSel,
                          selectedColor: const Color(0xFF0F766E),
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategoryFilter = cat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredResources.length,
                  itemBuilder: (context, index) {
                    final res = filteredResources[index];
                    return FadeInSlide(
                      child: InkWell(
                        onTap: () async {
                          final uri = Uri.tryParse(res.url);
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Could not open link', style: GoogleFonts.outfit()),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Chip(
                                    label: Text(res.type,
                                        style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                    backgroundColor: const Color(0xFF0F766E),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  Text(res.courseCode,
                                      style: GoogleFonts.outfit(
                                          fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(res.title,
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(res.description,
                                  style: GoogleFonts.outfit(
                                      fontSize: 13, color: Colors.grey.shade600)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.open_in_new_rounded, size: 14,
                                            color: const Color(0xFF0F766E)),
                                        const SizedBox(width: 4),
                                        Text("Open Course",
                                            style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF0F766E))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 2. Peer Study Group & Tutor Session Booking
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Peer Tutors & Study Group Leaders",
                    style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("Schedule 1-on-1 peer mentoring or join open study group sessions.",
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 14),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _peerTutors.length,
                  itemBuilder: (context, index) {
                    final tutor = _peerTutors[index];
                    final Color col = tutor["color"];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: col.withValues(alpha: 0.2),
                            child: Text(tutor["avatar"],
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold, color: col, fontSize: 18)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tutor["name"],
                                    style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(tutor["specialization"],
                                    style: GoogleFonts.outfit(
                                        fontSize: 12, color: Colors.grey.shade600)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text("${tutor["rating"]} (${tutor["reviews"]})",
                                        style: GoogleFonts.outfit(
                                            fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "Booked session with ${tutor["name"]} successfully!",
                                      style: GoogleFonts.outfit()),
                                  backgroundColor: const Color(0xFF0F766E),
                                ),
                              );
                            },
                            child: Text("Book",
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold, color: Colors.white)),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
