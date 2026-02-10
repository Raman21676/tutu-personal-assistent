import 'dart:math';
import 'package:uuid/uuid.dart';

import '../models/agent_model.dart';
import '../models/message_model.dart';
import '../models/memory_model.dart';
import 'storage_service.dart';

/// RAG Service - Retrieval Augmented Generation
/// Provides semantic search over conversation history and memories
class RAGService {
  final StorageService _storage = StorageService();
  final _uuid = const Uuid();

  /// Maximum memories to retrieve for context
  static const int _maxRetrievedMemories = 5;

  /// Auto-summarization threshold
  static const int _summarizationThreshold = 100;

  /// Add content to agent's memory
  Future<void> addToMemory({
    required String agentId,
    required String content,
    MemoryType type = MemoryType.conversation,
    Map<String, dynamic>? metadata,
    String? category,
    double importance = 0.5,
    String? relatedFaceId,
  }) async {
    // Extract keywords from content
    final keywords = _extractKeywords(content);

    final memory = Memory(
      id: _uuid.v4(),
      agentId: agentId,
      content: content,
      type: type,
      createdAt: DateTime.now(),
      keywords: keywords,
      importance: importance,
      category: category,
      relatedFaceId: relatedFaceId,
      metadata: metadata,
    );

    await _storage.saveMemory(memory);
  }

  /// Search agent's memory for relevant content
  Future<List<MemorySearchResult>> searchMemory({
    required String agentId,
    required String query,
    int limit = _maxRetrievedMemories,
  }) async {
    // Get all memories for agent
    final memories = await _storage.getMemoriesByAgent(agentId);
    if (memories.isEmpty) return [];

    // Normalize query
    final normalizedQuery = _normalizeText(query);
    final queryWords = _tokenize(normalizedQuery);

    // Calculate TF-IDF scores
    final scoredMemories = <MemorySearchResult>[];

    for (final memory in memories) {
      final score = _calculateTFIDFScore(queryWords, memory);
      if (score > 0) {
        scoredMemories.add(MemorySearchResult(
          memory: memory,
          relevanceScore: score * memory.importance,
          tfidfScore: score,
        ));
      }
    }

    // Sort by relevance
    scoredMemories.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    return scoredMemories.take(limit).toList();
  }

  /// Process conversation for memory extraction
  Future<void> processConversation({
    required Agent agent,
    required List<Message> messages,
  }) async {
    if (messages.length < 2) return;

    final lastMessage = messages.last;
    
    // Only process user messages for memory extraction
    if (!lastMessage.isUser) return;

    // Extract important information
    final extractedInfo = _extractImportantInfo(lastMessage.content);
    
    for (final info in extractedInfo) {
      await addToMemory(
        agentId: agent.id,
        content: info.content,
        type: info.type,
        importance: info.importance,
        category: info.category,
      );
    }

    // Check if summarization is needed
    final messageCount = await _storage.getMessageCount(agent.id);
    if (messageCount >= _summarizationThreshold && 
        messageCount % _summarizationThreshold == 0) {
      await _createConversationSummary(agent.id, messages);
    }
  }

  /// Get context for LLM prompt
  Future<String> getContextForPrompt({
    required String agentId,
    required String currentQuery,
  }) async {
    final memories = await searchMemory(
      agentId: agentId,
      query: currentQuery,
    );

    if (memories.isEmpty) return '';

    final contextParts = <String>['Relevant information from memory:'];
    
    for (final result in memories) {
      contextParts.add('- ${result.memory.content}');
    }

    return '\n\n${contextParts.join('\n')}';
  }

  /// Create conversation summary
  Future<void> _createConversationSummary(
    String agentId,
    List<Message> messages,
  ) async {
    // Get last 100 messages for summarization
    final recentMessages = messages.length > 100
        ? messages.sublist(messages.length - 100)
        : messages;

    // Extract key topics (simplified)
    final topics = _extractTopics(recentMessages);
    
    // Create summary
    final summary = ConversationSummary(
      id: _uuid.v4(),
      agentId: agentId,
      summary: _generateSummaryText(recentMessages, topics),
      fromDate: recentMessages.first.timestamp,
      toDate: recentMessages.last.timestamp,
      messageCount: recentMessages.length,
      keyTopics: topics,
      createdAt: DateTime.now(),
    );

    await _storage.saveSummary(summary);

    // Also save as memory
    await addToMemory(
      agentId: agentId,
      content: summary.summary,
      type: MemoryType.summary,
      importance: 0.8,
      category: 'summary',
    );
  }

  /// Extract important information from message
  List<_ExtractedInfo> _extractImportantInfo(String content) {
    final extracted = <_ExtractedInfo>[];
    final normalized = _normalizeText(content);

    // Pattern matching for important information
    
    // Names ("My name is...", "I am...", "Call me...")
    final namePattern = RegExp(
      r"(?:my name is|i am|call me|name\s*:\s*)([a-z]+)",
      caseSensitive: false,
    );
    final nameMatch = namePattern.firstMatch(normalized);
    if (nameMatch != null) {
      extracted.add(_ExtractedInfo(
        content: 'User\'s name is ${nameMatch.group(1)}',
        type: MemoryType.preference,
        importance: 0.9,
        category: 'name',
      ));
    }

    // Dates and events ("On Monday...", "Tomorrow...", "Next week...")
    final datePattern = RegExp(
      r"(?:on|this|next)\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday|week|month)",
      caseSensitive: false,
    );
    if (datePattern.hasMatch(normalized)) {
      // Extract the sentence containing the date reference
      final sentences = content.split(RegExp(r'[.!?]+'));
      for (final sentence in sentences) {
        if (datePattern.hasMatch(sentence)) {
          extracted.add(_ExtractedInfo(
            content: sentence.trim(),
            type: MemoryType.event,
            importance: 0.7,
            category: 'event',
          ));
          break;
        }
      }
    }

    // Preferences ("I like...", "I prefer...", "I love...", "I hate...")
    final prefPattern = RegExp(
      r"(?:i like|i prefer|i love|i enjoy|i dislike|i hate)\s+(.+?)(?:\.|,|\$)",
      caseSensitive: false,
    );
    final prefMatches = prefPattern.allMatches(normalized);
    for (final match in prefMatches) {
      final preference = match.group(0)?.trim();
      if (preference != null && preference.length > 10) {
        extracted.add(_ExtractedInfo(
          content: 'User $preference',
          type: MemoryType.preference,
          importance: 0.6,
          category: 'preference',
        ));
      }
    }

    // Facts ("I work at...", "I live in...", "I'm from...")
    final factPatterns = [
      RegExp(r"i work at\s+(.+?)(?:\.|,|\$)", caseSensitive: false),
      RegExp(r"i live in\s+(.+?)(?:\.|,|\$)", caseSensitive: false),
      RegExp(r"i'm from\s+(.+?)(?:\.|,|\$)", caseSensitive: false),
    ];
    for (final pattern in factPatterns) {
      final match = pattern.firstMatch(normalized);
      if (match != null) {
        final fact = match.group(0)?.trim();
        if (fact != null) {
          extracted.add(_ExtractedInfo(
            content: 'User $fact',
            type: MemoryType.fact,
            importance: 0.7,
            category: 'fact',
          ));
        }
      }
    }

    return extracted;
  }

  /// Extract keywords from text
  List<String> _extractKeywords(String text) {
    final normalized = _normalizeText(text);
    final words = _tokenize(normalized);
    
    // Remove common stop words
    final stopWords = {
      'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been',
      'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will',
      'would', 'could', 'should', 'may', 'might', 'must', 'shall',
      'can', 'need', 'dare', 'ought', 'used', 'to', 'of', 'in',
      'for', 'on', 'with', 'at', 'by', 'from', 'as', 'into',
      'through', 'during', 'before', 'after', 'above', 'below',
      'between', 'under', 'and', 'but', 'or', 'yet', 'so', 'if',
      'because', 'although', 'though', 'while', 'where', 'when',
      'that', 'which', 'who', 'whom', 'whose', 'what', 'this',
      'these', 'those', 'i', 'you', 'he', 'she', 'it', 'we', 'they',
      'me', 'him', 'her', 'us', 'them', 'my', 'your', 'his', 'her',
      'its', 'our', 'their', 'mine', 'yours', 'hers', 'ours', 'theirs',
    };

    return words
        .where((w) => !stopWords.contains(w))
        .toSet()
        .toList();
  }

  /// Extract topics from messages
  List<String> _extractTopics(List<Message> messages) {
    final allWords = <String>[];
    
    for (final msg in messages) {
      allWords.addAll(_extractKeywords(msg.content));
    }

    // Count word frequency
    final wordCounts = <String, int>{};
    for (final word in allWords) {
      wordCounts[word] = (wordCounts[word] ?? 0) + 1;
    }

    // Return top topics
    final sorted = wordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(5).map((e) => e.key).toList();
  }

  /// Generate summary text
  String _generateSummaryText(List<Message> messages, List<String> topics) {
    final fromDate = messages.first.timestamp;
    final toDate = messages.last.timestamp;
    
    final duration = toDate.difference(fromDate);
    final days = duration.inDays;
    
    String timeRange;
    if (days == 0) {
      timeRange = 'today';
    } else if (days == 1) {
      timeRange = 'over 1 day';
    } else {
      timeRange = 'over $days days';
    }

    return 'Conversation summary ($timeRange): ${messages.length} messages. '
           'Main topics: ${topics.join(', ')}.';
  }

  /// Calculate TF-IDF score for a memory
  double _calculateTFIDFScore(List<String> queryWords, Memory memory) {
    if (queryWords.isEmpty) return 0.0;

    // Calculate term frequency
    double score = 0.0;
    final memoryText = '${memory.content} ${memory.keywords.join(' ')}';
    final memoryWords = _tokenize(_normalizeText(memoryText));

    for (final queryWord in queryWords) {
      // TF: frequency in memory
      final tf = memoryWords.where((w) => w == queryWord).length / 
                 max(memoryWords.length, 1);
      
      // IDF: inverse document frequency (simplified)
      // We assume a corpus size of 1000 for approximation
      const idf = 1.0; // Simplified IDF
      
      score += tf * idf;
    }

    // Normalize by query length
    return score / queryWords.length;
  }

  /// Normalize text
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Tokenize text
  List<String> _tokenize(String text) {
    return text
        .split(' ')
        .where((w) => w.length > 2)
        .toList();
  }
}

/// Helper class for extracted information
class _ExtractedInfo {
  final String content;
  final MemoryType type;
  final double importance;
  final String category;

  _ExtractedInfo({
    required this.content,
    required this.type,
    required this.importance,
    required this.category,
  });
}
