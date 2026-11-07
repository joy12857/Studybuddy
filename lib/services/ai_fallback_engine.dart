/// Local fallback engine that provides high-quality academic and wellness
/// responses when the Groq Cloud API key is unconfigured or unavailable.
class AiFallbackEngine {
  /// Generates a contextual response based on the student's query.
  static String generateFallbackResponse(String prompt) {
    final lower = prompt.toLowerCase();

    // 1. Check if the prompt is for an AI Quiz
    if (lower.contains('generate a 4-question multiple-choice quiz') ||
        lower.contains('json schema:')) {
      return _generateQuizJson(prompt);
    }

    // 2. Check if the prompt is for Notes Summarization / Flashcards
    if (lower.contains('summarize') || lower.contains('flashcard')) {
      return _generateSummary(prompt);
    }

    // 3. Subject-specific and obstacle-tailored study suggestion
    if (lower.contains('specialized study suggestions') ||
        lower.contains('study obstacles') ||
        lower.contains('study strategies')) {
      return _generateStudySuggestions(prompt);
    }

    // 4. Emotional wellness & stress coping
    if (lower.contains('anxious') ||
        lower.contains('anxiety') ||
        lower.contains('stress') ||
        lower.contains('panic') ||
        lower.contains('overwhelmed') ||
        lower.contains('scared') ||
        lower.contains('nervous')) {
      return '''
🌿 **Breathe with me: Let's calm your nervous system first.**

It is completely normal to feel overwhelmed or anxious when academic pressures pile up. Your feelings are valid, and you don't have to carry them alone.

### Quick Grounding Exercise (5-4-3-2-1):
- 👀 **5 things you can see** around you right now (a pen, the wall, a window).
- ✋ **4 things you can feel** (feet on the floor, texture of your desk).
- 👂 **3 things you can hear** (the fan, distant traffic, your breath).
- 👃 **2 things you can smell** (fresh air, coffee).
- 👅 **1 thing you can taste** (water or mint).

Take a slow breath in for 4 seconds, hold for 4 seconds, and exhale slowly for 6 seconds. When you're ready, we can tackle your study tasks one tiny step at a time! 💪''';
    }

    // 5. Burnout & exhaustion
    if (lower.contains('burnout') ||
        lower.contains('burnt out') ||
        lower.contains('tired') ||
        lower.contains('exhausted') ||
        lower.contains('sleep')) {
      return '''
🛑 **Your body and mind are signaling for restorative care.**

Academic burnout happens when high effort meets inadequate recovery. Pushing through exhaustion often yields diminishing returns.

### Action Plan for Today:
1. **Pencil in an intentional pause:** Step away from all screens for 20 minutes. Drink a glass of water.
2. **Permission to downscale:** Pick just **one** non-negotiable task today. Defer the rest to tomorrow morning.
3. **Sleep hygiene protocol:** Stop studying at least 45 minutes before sleep so your brain can consolidate learning into long-term memory.

Remember: Resting is an essential part of high performance, not a sign of weakness! 🛌✨''';
    }

    // 6. Procrastination & focus
    if (lower.contains('procrastinat') ||
        lower.contains('distract') ||
        lower.contains('focus') ||
        lower.contains('cant start') ||
        lower.contains("can't start")) {
      return '''
⏳ **Overcoming the "Starting Friction"**

Procrastination is usually emotional regulation, not laziness. The task feels intimidating or unclear, so your brain seeks easier dopamine.

### The "5-Minute Micro-Sprint" Method:
1. **Lower the barrier:** Promise yourself you only have to work for **5 minutes**. If you want to stop after 5 minutes, you have permission to stop. (Usually, the friction disappears once you begin).
2. **Remove micro-distractions:** Turn your phone face-down and put it across the room.
3. **Define step one:** Don't write "Finish Chapter 4". Write: *"Open textbook to page 82 and read the bold headings."*

Set a 5-minute timer right now. What's the smallest first step you can take? 🚀''';
    }

    // 7. Greetings
    if (lower.startsWith('hi') ||
        lower.startsWith('hello') ||
        lower.startsWith('hey') ||
        lower == 'help') {
      return '''
👋 Hello! I'm your **StudyBuddy AI Companion**.

I'm here to support both your academic growth and your mental wellbeing!
Here are some ways we can work together:
- 📚 **Subject Coaching:** Ask me to break down tough topics in Math, CS, Science, or Humanities.
- ⏱️ **Study Strategies:** Overcome procrastination, organize revision schedules, or master the Feynman technique.
- 🧘 **Wellness & Calming:** De-stress before exams, manage burnout, or practice quick grounding exercises.

How can I help you today? Feel free to ask a question or use the Study Focus panel below! ✨''';
    }

    // 8. General fallback academic explanation
    return '''
💡 **StudyBuddy Academic Insights:**

Here is a structured approach to tackle **"$prompt"**:

1. **Core Concept Breakdown:**
   Break down the problem into its foundational principles. Ask yourself: *"What are the knowns, what are the unknowns, and what rule connects them?"*

2. **The Feynman Explanation:**
   Try explaining this topic in simple, everyday language as if you were teaching a classmate who has never seen it before. Any point where you hesitate highlights where to review!

3. **Active Recall & Practice:**
   Instead of re-reading notes passively, close your materials and write down everything you remember on a blank sheet of paper, then check against the reference.

Would you like a step-by-step example, a practice quiz, or specific study tips for this subject? Let me know! 🎯''';
  }

  static String _generateStudySuggestions(String prompt) {
    // Extract subject and topic if mentioned
    String subject = "your subject";
    final subMatch = RegExp(r'\*\*([^*]+)\*\*').firstMatch(prompt);
    if (subMatch != null) {
      subject = subMatch.group(1) ?? "your subject";
    }

    return '''
📋 **Customized Study Action Plan for $subject**

Here is your tailored strategy to conquer your study session with clarity and low stress:

### 🎯 1. Structured Pomodoro Sprint
- **Sprint 1 (25 min):** Active comprehension — Read key sections and summarize core concepts in your own words.
- **Short Break (5 min):** Step away, stretch, drink water (no social media scrolling).
- **Sprint 2 (25 min):** Hands-on application — Solve 2 to 3 practice problems or write flashcards.
- **Sprint 3 (25 min):** Error diagnosis — Review what you got wrong and document *why*.

### 🧠 2. Active Recall & The Feynman Technique
- Do not merely highlight text. Close your book and draw out a concept map or formula tree from memory.
- If you find yourself stuck, refer back to your notes for 30 seconds, then explain the concept out loud.

### 🛡️ 3. Wellness & Anxiety Control
- Remember: Quality of focused study trumps sheer hours of distracted cramming.
- Keep a glass of water nearby and breathe deeply before each study block.

You've got this! Let's start with your first 25-minute sprint. 🌟''';
  }

  static String _generateQuizJson(String prompt) {
    // Extract topic
    String topic = "Core Concepts";
    final match = RegExp(r'topic "([^"]+)"').firstMatch(prompt);
    if (match != null) {
      topic = match.group(1) ?? "Core Concepts";
    }

    return '''
[
  {
    "question": "Which of the following best describes the fundamental principle of $topic?",
    "options": [
      "A systematic approach to problem solving and concept mastery",
      "A purely theoretical model with no practical applications",
      "A technique used only for final stage exam review",
      "An outdated method replaced by passive reading"
    ],
    "correctIndex": 0,
    "explanation": "The core of $topic is founded on structured problem solving and active comprehension."
  },
  {
    "question": "When applying active recall to $topic, what is the most effective first step?",
    "options": [
      "Highlighting entire paragraphs in the textbook",
      "Testing oneself from memory before checking the answer",
      "Listening to background music while skimming notes",
      "Memorizing without understanding the underlying logic"
    ],
    "correctIndex": 1,
    "explanation": "Active recall forces cognitive retrieval, creating stronger synaptic connections for $topic."
  },
  {
    "question": "What is a common pitfall students encounter when studying $topic?",
    "options": [
      "Breaking complex concepts into smaller sub-components",
      "Passive re-reading leading to an illusion of competence",
      "Practicing step-by-step problem sets",
      "Taking scheduled restorative breaks"
    ],
    "correctIndex": 1,
    "explanation": "Passive re-reading creates an illusion of knowing the material without actual retention."
  },
  {
    "question": "How can the Feynman Technique be leveraged to master $topic?",
    "options": [
      "By explaining the concept in simple, plain terms without jargon",
      "By cramming the night before an exam without sleeping",
      "By memorizing complex definitions word-for-word",
      "By avoiding questions or practice exercises"
    ],
    "correctIndex": 0,
    "explanation": "Simplifying concepts and teaching them in plain terms highlights gaps in your understanding."
  }
]''';
  }

  static String _generateSummary(String prompt) {
    return '''
📝 **AI Study Notes Summary & Key Takeaways**

### 📌 Core Key Concepts
- **Foundational Idea:** The material centers on identifying core mechanisms, structural rules, and practical problem-solving applications.
- **Key Relationships:** Notice how each sub-concept builds directly upon the preceding fundamentals.
- **Application Focus:** Understanding the underlying "why" enables solving novel exam questions rather than just memorized samples.

### 📐 Formulas & Definitions to Remember
- **Definition 1:** Master the precise terminology and domain constraints.
- **Rule of Thumb:** Always verify edge cases, boundary values, and units before concluding an answer.

### 🃏 Review Flashcard Prompts
1. **Q:** What is the main objective of this topic?
   *A:* To provide a structured method to analyze and resolve domain problems.
2. **Q:** What are the key pitfalls to avoid?
   *A:* Skipping foundational definitions and relying only on intuition.
3. **Q:** How can you test your understanding?
   *A:* Explain the mechanism step-by-step without referencing source material.
''';
  }
}

