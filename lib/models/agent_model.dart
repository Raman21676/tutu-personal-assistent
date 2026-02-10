/// Agent Model - Represents an AI agent in the TuTu app
/// Each agent has a unique personality, role, and configuration
class Agent {
  final String id;
  final String name;
  final String role;
  final String personality;
  final String? voiceId;
  final String avatar;
  final String? voiceGender;
  final DateTime createdAt;
  DateTime lastInteractionAt;
  final String? preferredModel;
  final bool isDefault;

  Agent({
    required this.id,
    required this.name,
    required this.role,
    required this.personality,
    this.voiceId,
    required this.avatar,
    this.voiceGender,
    required this.createdAt,
    required this.lastInteractionAt,
    this.preferredModel,
    this.isDefault = false,
  });

  /// Create Agent from JSON map
  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      personality: json['personality'] as String,
      voiceId: json['voiceId'] as String?,
      avatar: json['avatar'] as String,
      voiceGender: json['voiceGender'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastInteractionAt: DateTime.parse(json['lastInteractionAt'] as String),
      preferredModel: json['preferredModel'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// Convert Agent to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'personality': personality,
      'voiceId': voiceId,
      'avatar': avatar,
      'voiceGender': voiceGender,
      'createdAt': createdAt.toIso8601String(),
      'lastInteractionAt': lastInteractionAt.toIso8601String(),
      'preferredModel': preferredModel,
      'isDefault': isDefault,
    };
  }

  /// Create a copy of the agent with updated fields
  Agent copyWith({
    String? name,
    String? role,
    String? personality,
    String? voiceId,
    String? avatar,
    String? voiceGender,
    DateTime? lastInteractionAt,
    String? preferredModel,
  }) {
    return Agent(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      personality: personality ?? this.personality,
      voiceId: voiceId ?? this.voiceId,
      avatar: avatar ?? this.avatar,
      voiceGender: voiceGender ?? this.voiceGender,
      createdAt: createdAt,
      lastInteractionAt: lastInteractionAt ?? this.lastInteractionAt,
      preferredModel: preferredModel ?? this.preferredModel,
      isDefault: isDefault,
    );
  }

  /// Get display name with emoji
  String get displayName => '$avatar $name';

  /// Get system prompt for LLM
  String get systemPrompt {
    return '''You are $name, a $role. $personality

You are part of TuTu, a personal AI agent manager app. You have access to memory and context from previous conversations. Be helpful, engaging, and true to your character.

When responding:
- Stay in character as $name
- Reference previous conversations when relevant
- Be concise but engaging
- If you don't know something, be honest about it''';
  }

  @override
  String toString() => 'Agent(id: $id, name: $name, role: $role)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Agent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Predefined agent roles for easy creation
class AgentRoles {
  static const String girlfriend = 'girlfriend';
  static const String boyfriend = 'boyfriend';
  static const String lawyer = 'lawyer';
  static const String financialAdvisor = 'financial_advisor';
  static const String teacher = 'teacher';
  static const String friend = 'friend';
  static const String therapist = 'therapist';
  static const String careerCoach = 'career_coach';
  static const String custom = 'custom';

  static const List<String> all = [
    girlfriend,
    boyfriend,
    lawyer,
    financialAdvisor,
    teacher,
    friend,
    therapist,
    careerCoach,
    custom,
  ];

  static String getDisplayName(String role) {
    switch (role) {
      case girlfriend:
        return 'Girlfriend';
      case boyfriend:
        return 'Boyfriend';
      case lawyer:
        return 'Lawyer';
      case financialAdvisor:
        return 'Financial Advisor';
      case teacher:
        return 'Teacher';
      case friend:
        return 'Friend';
      case therapist:
        return 'Therapist';
      case careerCoach:
        return 'Career Coach';
      default:
        return 'Custom';
    }
  }

  static String getDefaultPersonality(String role) {
    switch (role) {
      case girlfriend:
        return 'You are a caring, affectionate, and supportive girlfriend. You love having deep conversations, sharing your day, and being there for your partner. You have a warm personality and enjoy romantic gestures.';
      case boyfriend:
        return 'You are a caring, protective, and supportive boyfriend. You enjoy meaningful conversations, sharing experiences, and being there for your partner. You have a charming personality.';
      case lawyer:
        return 'You are a knowledgeable and professional lawyer. You provide clear legal guidance, explain complex concepts in simple terms, and help users understand their rights and options.';
      case financialAdvisor:
        return 'You are a wise and experienced financial advisor. You help users with budgeting, investing, and financial planning. You provide practical advice tailored to individual situations.';
      case teacher:
        return 'You are a patient and enthusiastic teacher. You love explaining concepts, answering questions, and helping people learn. You adapt your teaching style to each student.';
      case friend:
        return 'You are a loyal and fun friend. You enjoy casual conversations, giving advice, sharing jokes, and being a supportive presence in the user\'s life.';
      case therapist:
        return 'You are an empathetic and professional therapist. You listen actively, provide emotional support, and help users work through their thoughts and feelings in a safe space.';
      case careerCoach:
        return 'You are a motivating career coach. You help users with professional development, job searches, interviews, and career transitions. You believe in their potential.';
      default:
        return 'You are a helpful AI assistant with a unique personality.';
    }
  }

  static String getDefaultAvatar(String role) {
    switch (role) {
      case girlfriend:
        return '💕';
      case boyfriend:
        return '🤗';
      case lawyer:
        return '⚖️';
      case financialAdvisor:
        return '💰';
      case teacher:
        return '📚';
      case friend:
        return '😊';
      case therapist:
        return '🧠';
      case careerCoach:
        return '🚀';
      default:
        return '🤖';
    }
  }
}

/// Default TuTu agent configuration
class DefaultAgents {
  static Agent get tutuAgent => Agent(
        id: 'tutu_default',
        name: 'TuTu',
        role: 'assistant',
        personality: '''You are TuTu, the smart assistant managing this personal AI agent app. You help users understand the app, create agents, and manage their AI companions. 

You have access to an extensive knowledge base about the app. For questions about:
- How to use the app
- Creating and customizing agents
- Troubleshooting issues
- API setup and configuration

Always check your offline knowledge base first before using external APIs.

Be concise, friendly, and helpful. If a question is not in your knowledge base and doesn't require real-time information, say "Let me connect you to the internet for that."

Personality traits:
- Efficient and organized
- Warm and welcoming
- Knowledgeable about the app
- Patient with new users''',
        avatar: '🐧',
        createdAt: DateTime.now(),
        lastInteractionAt: DateTime.now(),
        isDefault: true,
      );
}
