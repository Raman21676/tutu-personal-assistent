/// Memory Model - Represents a stored memory for RAG system
/// Used to persist important information across conversations
class Memory {
  final String id;
  final String agentId;
  final String content;
  final MemoryType type;
  final DateTime createdAt;
  final DateTime? expiresAt; // Some memories might expire
  final Map<String, dynamic>? metadata;
  final List<String> keywords; // For search indexing
  final double importance; // 0.0 to 1.0
  final String? category; // e.g., "preference", "fact", "event"
  final String? relatedFaceId; // Link to face recognition

  Memory({
    required this.id,
    required this.agentId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.expiresAt,
    this.metadata,
    required this.keywords,
    this.importance = 0.5,
    this.category,
    this.relatedFaceId,
  });

  /// Create from JSON
  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] as String,
      agentId: json['agentId'] as String,
      content: json['content'] as String,
      type: MemoryType.values.byName(json['type'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      keywords: List<String>.from(json['keywords'] as List),
      importance: (json['importance'] as num).toDouble(),
      category: json['category'] as String?,
      relatedFaceId: json['relatedFaceId'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agentId': agentId,
      'content': content,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'metadata': metadata,
      'keywords': keywords,
      'importance': importance,
      'category': category,
      'relatedFaceId': relatedFaceId,
    };
  }

  /// Check if memory is expired
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Check if memory is high importance
  bool get isImportant => importance >= 0.7;

  @override
  String toString() =>
      'Memory(id: $id, type: $type, content: ${content.substring(0, content.length > 30 ? 30 : content.length)}...)';
}

/// Types of memories
enum MemoryType {
  conversation, // Extracted from conversations
  explicit, // User explicitly told the agent
  inferred, // Agent inferred from context
  summary, // Conversation summary
  faceRecognition, // Face recognition event
  preference, // User preference
  fact, // General fact about user
  event, // Important event
}

/// Conversation Summary Model
class ConversationSummary {
  final String id;
  final String agentId;
  final String summary;
  final DateTime fromDate;
  final DateTime toDate;
  final int messageCount;
  final List<String> keyTopics;
  final DateTime createdAt;

  ConversationSummary({
    required this.id,
    required this.agentId,
    required this.summary,
    required this.fromDate,
    required this.toDate,
    required this.messageCount,
    required this.keyTopics,
    required this.createdAt,
  });

  /// Create from JSON
  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: json['id'] as String,
      agentId: json['agentId'] as String,
      summary: json['summary'] as String,
      fromDate: DateTime.parse(json['fromDate'] as String),
      toDate: DateTime.parse(json['toDate'] as String),
      messageCount: json['messageCount'] as int,
      keyTopics: List<String>.from(json['keyTopics'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agentId': agentId,
      'summary': summary,
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'messageCount': messageCount,
      'keyTopics': keyTopics,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Memory search result
class MemorySearchResult {
  final Memory memory;
  final double relevanceScore;
  final double tfidfScore;

  MemorySearchResult({
    required this.memory,
    required this.relevanceScore,
    required this.tfidfScore,
  });

  @override
  String toString() =>
      'MemorySearchResult(memory: ${memory.id}, score: ${relevanceScore.toStringAsFixed(2)})';
}
