class Course {
  final String id;
  final String code;
  final String title;
  final double credits;
  final String grade;
  final double gradePoint;
  final String semester;
  final List<String> weakTopics;

  Course({
    required this.id,
    required this.code,
    required this.title,
    required this.credits,
    required this.grade,
    required this.gradePoint,
    required this.semester,
    this.weakTopics = const [],
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      title: json['title'] ?? '',
      credits: (json['credits'] as num?)?.toDouble() ?? 3.0,
      grade: json['grade'] ?? 'A',
      gradePoint: (json['gradePoint'] as num?)?.toDouble() ?? 4.0,
      semester: json['semester'] ?? 'Fall 2026',
      weakTopics: List<String>.from(json['weakTopics'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'credits': credits,
      'grade': grade,
      'gradePoint': gradePoint,
      'semester': semester,
      'weakTopics': weakTopics,
    };
  }

  static double gradeToPoint(String grade) {
    switch (grade.toUpperCase()) {
      case 'A+':
        return 4.00;
      case 'A':
        return 3.75;
      case 'A-':
        return 3.50;
      case 'B+':
        return 3.25;
      case 'B':
        return 3.00;
      case 'B-':
        return 2.75;
      case 'C+':
        return 2.50;
      case 'C':
        return 2.25;
      case 'C-':
        return 2.00;
      case 'D+':
        return 1.75;
      case 'D':
        return 1.50;
      case 'F':
      default:
        return 0.00;
    }
  }
}

class ImprovementCourse {
  String name;
  double credit;
  double currentGradePoint;
  double targetGradePoint;

  ImprovementCourse({
    required this.name,
    required this.credit,
    required this.currentGradePoint,
    required this.targetGradePoint,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'credit': credit,
        'currentGradePoint': currentGradePoint,
        'targetGradePoint': targetGradePoint,
      };

  factory ImprovementCourse.fromJson(Map<String, dynamic> json) =>
      ImprovementCourse(
        name: json['name'] ?? '',
        credit: (json['credit'] as num?)?.toDouble() ?? 3.0,
        currentGradePoint:
            (json['currentGradePoint'] as num?)?.toDouble() ?? 2.0,
        targetGradePoint: (json['targetGradePoint'] as num?)?.toDouble() ?? 4.0,
      );
}

class Flashcard {
  final String id;
  final String courseCode;
  final String question;
  final String answer;
  int intervalDays;
  DateTime nextReview;

  Flashcard({
    required this.id,
    required this.courseCode,
    required this.question,
    required this.answer,
    this.intervalDays = 1,
    DateTime? nextReview,
  }) : nextReview = nextReview ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseCode': courseCode,
        'question': question,
        'answer': answer,
        'intervalDays': intervalDays,
        'nextReview': nextReview.toIso8601String(),
      };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        id: json['id'] ?? '',
        courseCode: json['courseCode'] ?? '',
        question: json['question'] ?? '',
        answer: json['answer'] ?? '',
        intervalDays: json['intervalDays'] ?? 1,
        nextReview: json['nextReview'] != null
            ? DateTime.parse(json['nextReview'])
            : DateTime.now(),
      );
}

class ResourceItem {
  final String title;
  final String category;
  final String courseCode;
  final String type; // Video, eBook, Article, Course
  final String url;
  final String description;

  const ResourceItem({
    required this.title,
    required this.category,
    required this.courseCode,
    required this.type,
    required this.url,
    required this.description,
  });
}
