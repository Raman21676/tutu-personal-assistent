/// Message Model - Represents a single message in a conversation
/// Supports both user and assistant messages with metadata for RAG
class Message {
  final String id;
  final String agentId;
  final String role; // "user" or "assistant"
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final List<String>? referencedMemories; // IDs of memories used
  final bool isOfflineResponse;
  final String? errorMessage;
  final MessageType type;
  final String? imagePath; // For multi-modal messages

  Message({
    required this.id,
    required this.agentId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
    this.referencedMemories,
    this.isOfflineResponse = false,
    this.errorMessage,
    this.type = MessageType.text,
    this.imagePath,
  });

  /// Create Message from JSON map
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      agentId: json['agentId'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      referencedMemories: json['referencedMemories'] != null
          ? List<String>.from(json['referencedMemories'] as List)
          : null,
      isOfflineResponse: json['isOfflineResponse'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
      type: MessageType.values.byName(json['type'] as String? ?? 'text'),
      imagePath: json['imagePath'] as String?,
    );
  }

  /// Convert Message to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agentId': agentId,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'referencedMemories': referencedMemories,
      'isOfflineResponse': isOfflineResponse,
      'errorMessage': errorMessage,
      'type': type.name,
      'imagePath': imagePath,
    };
  }

  /// Create a copy of the message with updated fields
  Message copyWith({
    String? content,
    Map<String, dynamic>? metadata,
    List<String>? referencedMemories,
    bool? isOfflineResponse,
    String? errorMessage,
    MessageType? type,
    String? imagePath,
  }) {
    return Message(
      id: id,
      agentId: agentId,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      metadata: metadata ?? this.metadata,
      referencedMemories: referencedMemories ?? this.referencedMemories,
      isOfflineResponse: isOfflineResponse ?? this.isOfflineResponse,
      errorMessage: errorMessage ?? this.errorMessage,
      type: type ?? this.type,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  /// Check if message is from user
  bool get isUser => role == 'user';

  /// Check if message is from assistant
  bool get isAssistant => role == 'assistant';

  /// Check if message contains an error
  bool get hasError => errorMessage != null;

  /// Get formatted timestamp
  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Get date string for grouping
  String get dateString {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Convert to OpenAI/LLM message format
  Map<String, String> toLLMFormat() {
    return {
      'role': role,
      'content': content,
    };
  }

  @override
  String toString() =>
      'Message(id: $id, role: $role, content: ${content.substring(0, content.length > 30 ? 30 : content.length)}...)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Message types for different content
enum MessageType {
  text,
  image,
  voice,
  system,
  error,
}

/// Conversation model - Groups messages for an agent
class Conversation {
  final String agentId;
  final List<Message> messages;
  final DateTime createdAt;
  DateTime updatedAt;
  final String? summary; // Auto-generated summary of conversation

  Conversation({
    required this.agentId,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.summary,
  });

  /// Create Conversation from JSON
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      agentId: json['agentId'] as String,
      messages: (json['messages'] as List)
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      summary: json['summary'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'summary': summary,
    };
  }

  /// Get message count
  int get messageCount => messages.length;

  /// Get last message
  Message? get lastMessage => messages.isNotEmpty ? messages.last : null;

  /// Get messages sorted by timestamp (newest last)
  List<Message> get sortedMessages {
    final sorted = List<Message>.from(messages);
    sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sorted;
  }

  /// Get recent messages (for context)
  List<Message> getRecentMessages(int count) {
    final sorted = sortedMessages;
    if (sorted.length <= count) return sorted;
    return sorted.sublist(sorted.length - count);
  }

  /// Add a message to the conversation
  void addMessage(Message message) {
    messages.add(message);
    updatedAt = DateTime.now();
  }

  /// Check if conversation needs summarization (100+ messages)
  bool get needsSummarization => messages.length >= 100;

  @override
  String toString() =>
      'Conversation(agentId: $agentId, messages: ${messages.length})';
}
