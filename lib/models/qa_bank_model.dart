/// QA Bank Model - For offline question answering
/// Stores question-answer pairs with search metadata
class QABankEntry {
  final String id;
  final String question;
  final String answer;
  final String category;
  final List<String> keywords;
  final double priority; // Higher priority for common questions

  QABankEntry({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.keywords,
    this.priority = 1.0,
  });

  /// Create from JSON
  factory QABankEntry.fromJson(Map<String, dynamic> json) {
    return QABankEntry(
      id: json['id'].toString(),
      question: json['question'] as String,
      answer: json['answer'] as String,
      category: json['category'] as String,
      keywords: List<String>.from(json['keywords'] as List),
      priority: (json['priority'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'keywords': keywords,
      'priority': priority,
    };
  }

  @override
  String toString() =>
      'QABankEntry(id: $id, question: ${question.substring(0, question.length > 40 ? 40 : question.length)}...)';
}

/// Categories for QA bank entries
class QACategories {
  static const String appUsage = 'app_usage';
  static const String agentCreation = 'agent_creation';
  static const String agentCustomization = 'agent_customization';
  static const String troubleshooting = 'troubleshooting';
  static const String features = 'features';
  static const String apiSetup = 'api_setup';
  static const String privacy = 'privacy';
  static const String voice = 'voice';
  static const String faceRecognition = 'face_recognition';

  static const List<String> all = [
    appUsage,
    agentCreation,
    agentCustomization,
    troubleshooting,
    features,
    apiSetup,
    privacy,
    voice,
    faceRecognition,
  ];

  static String getDisplayName(String category) {
    switch (category) {
      case appUsage:
        return 'App Usage';
      case agentCreation:
        return 'Agent Creation';
      case agentCustomization:
        return 'Customization';
      case troubleshooting:
        return 'Troubleshooting';
      case features:
        return 'Features';
      case apiSetup:
        return 'API Setup';
      case privacy:
        return 'Privacy & Security';
      case voice:
        return 'Voice Features';
      case faceRecognition:
        return 'Face Recognition';
      default:
        return 'General';
    }
  }
}

/// Search result from QA bank
class QASearchResult {
  final QABankEntry entry;
  final double confidence;
  final double levenshteinScore;
  final double keywordScore;

  QASearchResult({
    required this.entry,
    required this.confidence,
    required this.levenshteinScore,
    required this.keywordScore,
  });

  bool get isMatch => confidence >= 0.75;

  @override
  String toString() =>
      'QASearchResult(entry: ${entry.id}, confidence: ${confidence.toStringAsFixed(2)})';
}
