import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/openai_service.dart';
import '../widgets/interactive_animations.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController messageController = TextEditingController();
  final TextEditingController topicController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<Map<String, dynamic>> messages = [];
  final OpenAIService _openai = OpenAIService();
  bool isTyping = false;

  // Study suggestion customization state
  String selectedSubject = "Mathematics";
  final Set<String> selectedIssues = {};
  bool isCustomizerExpanded = true;
  String? activeFocusSummary; // Holds the summary of the active focus (e.g. "Mathematics - Calculus")

  final List<Map<String, dynamic>> subjects = [
    {"name": "Mathematics", "icon": Icons.architecture_rounded, "color": const Color(0xFF0F766E)},
    {"name": "Computer Science", "icon": Icons.code_rounded, "color": const Color(0xFF0284C7)},
    {"name": "Science", "icon": Icons.science_rounded, "color": const Color(0xFF7C3AED)},
    {"name": "History", "icon": Icons.history_edu_rounded, "color": const Color(0xFFD97706)},
    {"name": "Literature", "icon": Icons.menu_book_rounded, "color": const Color(0xFFDB2777)},
    {"name": "Other", "icon": Icons.more_horiz_rounded, "color": const Color(0xFF475569)},
  ];

  final List<Map<String, dynamic>> issuesList = [
    {"name": "Procrastination", "icon": Icons.timer_outlined},
    {"name": "Hard to Focus", "icon": Icons.psychology_outlined},
    {"name": "Hard to Understand", "icon": Icons.extension_outlined},
    {"name": "Exam Anxiety", "icon": Icons.sentiment_very_dissatisfied_outlined},
    {"name": "Time Management", "icon": Icons.schedule_rounded},
    {"name": "Feeling Burnt Out", "icon": Icons.battery_alert_rounded},
  ];

  @override
  void initState() {
    super.initState();
    messages.add({
      "sender": "bot",
      "message":
          "👋 Hello! I'm your StudyBuddy AI Companion.\n\nI'm here to support you in a safe, judgement-free space. Tap the panel below if you want tailored study suggestions for a specific subject, topic, and study issue!",
      "time": DateFormat('hh:mm a').format(DateTime.now())
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    topicController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || isTyping) return;

    setState(() {
      messages.add({
        "sender": "user",
        "message": text,
        "time": DateFormat('hh:mm a').format(DateTime.now())
      });
      isTyping = true;
    });

    messageController.clear();
    _scrollToBottom();

    try {
      final reply = await _openai.sendMessage(text);
      if (!mounted) return;
      setState(() {
        messages.add({
          "sender": "bot",
          "message": reply,
          "time": DateFormat('hh:mm a').format(DateTime.now())
        });
        isTyping = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        messages.add({
          "sender": "bot",
          "message": "🌐 Unable to reach AI right now. Please check your connection and try again.",
          "time": DateFormat('hh:mm a').format(DateTime.now())
        });
        isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      messages.clear();
      messages.add({
        "sender": "bot",
        "message":
            "👋 Hello! I'm your StudyBuddy AI Companion.\n\nI'm here to support you in a safe, judgement-free space. Tap the panel below if you want tailored study suggestions for a specific subject, topic, and study issue!",
        "time": DateFormat('hh:mm a').format(DateTime.now())
      });
      selectedSubject = "Mathematics";
      topicController.clear();
      selectedIssues.clear();
      activeFocusSummary = null;
      isCustomizerExpanded = true;
    });
    _openai.clearHistory();
  }

  Future<void> _generateStudySuggestions() async {
    final topic = topicController.text.trim();
    final issuesList = selectedIssues.toList();

    setState(() {
      String summary = selectedSubject;
      if (topic.isNotEmpty) {
        summary += " - $topic";
      }
      if (issuesList.isNotEmpty) {
        summary += " (${issuesList.join(', ')})";
      }
      activeFocusSummary = summary;
      isCustomizerExpanded = false;
      isTyping = true;
    });

    // Formulate a beautiful user-facing message bubble
    String userDisplayMsg = "📚 *Study Suggestion Request*\n"
        "• **Subject:** $selectedSubject\n"
        "• **Topic:** ${topic.isNotEmpty ? topic : 'General Study Help'}\n"
        "• **Challenges:** ${issuesList.isNotEmpty ? issuesList.join(', ') : 'None specified'}\n\n"
        "Please provide personalized suggestions, strategies, and coping tips to help me study this successfully!";

    setState(() {
      messages.add({
        "sender": "user",
        "message": userDisplayMsg,
        "time": DateFormat('hh:mm a').format(DateTime.now())
      });
    });

    _scrollToBottom();

    // Formulate the prompt sent to the AI
    String apiPrompt = "I need specialized study suggestions for the subject **$selectedSubject**.\n";
    if (topic.isNotEmpty) {
      apiPrompt += "The specific topic is: **$topic**.\n";
    }
    if (issuesList.isNotEmpty) {
      apiPrompt += "The personal study obstacles/challenges I am facing are: **${issuesList.join(', ')}**.\n";
    }
    apiPrompt += "Provide me with compassionate, actionable study strategies (like custom schedules, specific studying methods, or mental wellness coping tips) targeting these parameters.";

    try {
      final reply = await _openai.sendMessage(apiPrompt);
      if (!mounted) return;
      setState(() {
        messages.add({
          "sender": "bot",
          "message": reply,
          "time": DateFormat('hh:mm a').format(DateTime.now())
        });
        isTyping = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        messages.add({
          "sender": "bot",
          "message": "🌐 Unable to reach AI right now. Please check your connection and try again.",
          "time": DateFormat('hh:mm a').format(DateTime.now())
        });
        isTyping = false;
      });
    }

    _scrollToBottom();
  }

  Widget _buildStudyCustomizer(ThemeData theme) {
    return AnimatedCrossFade(
      firstChild: InkWell(
        onTap: () {
          setState(() {
            isCustomizerExpanded = true;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_stories_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeFocusSummary == null
                          ? "Want tailored study suggestions?"
                          : "Active Study Focus",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeFocusSummary ?? "Tap to choose subject, topics, and study issues.",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: activeFocusSummary == null
                            ? const Color(0xFF64748B)
                            : theme.colorScheme.primary,
                        fontWeight: activeFocusSummary != null ? FontWeight.bold : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.tune_rounded,
                color: theme.colorScheme.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
      secondChild: Builder(builder: (context) {
        final t = Theme.of(context);
        return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: t.brightness == Brightness.dark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: Color(0xFF0F766E), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Customize Study Suggestions",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: t.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (activeFocusSummary != null || messages.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        isCustomizerExpanded = false;
                      });
                    },
                  ),
              ],
            ),
            Divider(height: 20, color: t.dividerColor),

            // 1. Subject selection
            Text(
              "1. Select Subject",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: t.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: subjects.length,
                itemBuilder: (context, idx) {
                  final sub = subjects[idx];
                  final isSelected = selectedSubject == sub["name"];
                  final color = sub["color"] as Color;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        sub["name"],
                        style: GoogleFonts.outfit(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : t.textTheme.bodySmall?.color,
                        ),
                      ),
                      avatar: Icon(
                        sub["icon"] as IconData,
                        color: isSelected ? Colors.white : color,
                        size: 16,
                      ),
                      selected: isSelected,
                      selectedColor: color,
                      backgroundColor: t.brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            selectedSubject = sub["name"];
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // 2. Topic Input
            Text(
              "2. Specify Topic (optional)",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: t.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: topicController,
              style: GoogleFonts.outfit(fontSize: 14, color: t.textTheme.bodyMedium?.color),
              decoration: InputDecoration(
                hintText: "e.g., Integration, Data Structures, Genetics...",
                hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                fillColor: t.brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                filled: true,
                prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Issue / Challenges
            Text(
              "3. Select Study Challenge(s)",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: t.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: issuesList.map((issue) {
                final name = issue["name"] as String;
                final isSelected = selectedIssues.contains(name);
                return FilterChip(
                  label: Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : t.textTheme.bodySmall?.color,
                    ),
                  ),
                  avatar: Icon(
                    issue["icon"] as IconData,
                    color: isSelected ? Colors.white : t.textTheme.bodySmall?.color,
                    size: 15,
                  ),
                  selected: isSelected,
                  selectedColor: t.colorScheme.primary,
                  backgroundColor: t.brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  checkmarkColor: Colors.white,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        selectedIssues.add(name);
                      } else {
                        selectedIssues.remove(name);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 4. Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _generateStudySuggestions,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Generate Study Suggestions",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      }),
      crossFadeState: isCustomizerExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
    );
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
          "StudyBuddy AI",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "New conversation",
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark ? const Color(0xFF0C4A6E).withValues(alpha: 0.4) : const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: theme.brightness == Brightness.dark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Powered by Google Gemini AI · Not a replacement for professional therapy.",
                    style: GoogleFonts.outfit(fontSize: 12, color: theme.brightness == Brightness.dark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1)),
                  ),
                ),
              ],
            ),
          ),
          // Study Customizer Selection Panel
          _buildStudyCustomizer(theme),
          // Chat list
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg["sender"] == "user";
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return FadeInSlide(
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment:
                          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                theme.colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(Icons.auto_awesome_rounded,
                                size: 18, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: isUser
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF0F766E),
                                        Color(0xFF0D9488)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isUser
                                  ? null
                                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft:
                                    Radius.circular(isUser ? 18 : 4),
                                bottomRight:
                                    Radius.circular(isUser ? 4 : 18),
                              ),
                              border: isUser
                                  ? null
                                  : Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.015),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg["message"],
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: isUser
                                      ? Colors.white
                                      : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  msg["time"],
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: isUser
                                        ? Colors.white70
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.teal.shade700,
                          child: const Icon(Icons.person_outline_rounded,
                              size: 20, color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              );
              },
            ),
          ),

          // Typing indicator
          if (isTyping)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "StudyBuddy AI is thinking...",
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      style: GoogleFonts.outfit(),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                      enabled: !isTyping,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: isTyping
                            ? "Please wait..."
                            : "Ask me anything...",
                        hintStyle: GoogleFonts.outfit(
                            color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        fillColor: theme.brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        filled: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isTyping
                        ? Colors.grey.shade300
                        : theme.colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                      onPressed: isTyping ? null : sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
