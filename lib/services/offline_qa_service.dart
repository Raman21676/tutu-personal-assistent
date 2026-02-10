import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

import '../models/qa_bank_model.dart';

/// Offline QA Service - Provides answers without internet
/// Uses fuzzy matching and keyword search on local QA bank
class OfflineQAService {
  static final OfflineQAService _instance = OfflineQAService._internal();
  factory OfflineQAService() => _instance;
  OfflineQAService._internal();

  List<QABankEntry> _qaBank = [];
  bool _isLoaded = false;

  /// Minimum confidence threshold for a match (0.0 - 1.0)
  static const double _confidenceThreshold = 0.75;

  /// Load QA bank from assets
  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString('assets/qa_bank.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      _qaBank = jsonList
          .map((json) => QABankEntry.fromJson(json as Map<String, dynamic>))
          .toList();
      
      _isLoaded = true;
    } catch (e) {
      // If loading fails, use fallback QA bank
      _qaBank = _fallbackQABank;
      _isLoaded = true;
    }
  }

  /// Find best matching answer for a query
  Future<QASearchResult?> findAnswer(String query) async {
    if (!_isLoaded) {
      await initialize();
    }

    final normalizedQuery = _normalizeText(query);
    final queryWords = _tokenize(normalizedQuery);

    QABankEntry? bestMatch;
    double bestScore = 0.0;
    double bestLevenshtein = 0.0;
    double bestKeyword = 0.0;

    for (final entry in _qaBank) {
      // Calculate Levenshtein similarity with question
      final normalizedQuestion = _normalizeText(entry.question);
      final levScore = _levenshteinSimilarity(normalizedQuery, normalizedQuestion);

      // Calculate keyword overlap score
      final entryWords = _tokenize(normalizedQuestion);
      final entryKeywords = entry.keywords.map(_normalizeText).toList();
      final keyScore = _keywordScore(queryWords, entryWords, entryKeywords);

      // Combine scores with weights
      final combinedScore = (levScore * 0.6) + (keyScore * 0.4);
      final weightedScore = combinedScore * entry.priority;

      if (weightedScore > bestScore) {
        bestScore = weightedScore;
        bestLevenshtein = levScore;
        bestKeyword = keyScore;
        bestMatch = entry;
      }
    }

    if (bestMatch != null && bestScore >= _confidenceThreshold) {
      return QASearchResult(
        entry: bestMatch,
        confidence: bestScore,
        levenshteinScore: bestLevenshtein,
        keywordScore: bestKeyword,
      );
    }

    return null;
  }

  /// Check if we have an answer for this query
  Future<bool> hasAnswer(String query) async {
    final result = await findAnswer(query);
    return result != null;
  }

  /// Get answer or fallback message
  Future<String> getAnswerOrFallback(String query) async {
    final result = await findAnswer(query);
    
    if (result != null) {
      return result.entry.answer;
    }
    
    return "I don't have information about that in my offline knowledge base. "
           "Please connect to the internet and set up an API key for more help.";
  }

  /// Search QA bank by category
  List<QABankEntry> searchByCategory(String category) {
    return _qaBank.where((e) => e.category == category).toList();
  }

  /// Get random entry from category (for suggestions)
  QABankEntry? getRandomFromCategory(String category) {
    final entries = searchByCategory(category);
    if (entries.isEmpty) return null;
    return entries[Random().nextInt(entries.length)];
  }

  /// Get all categories
  List<String> get categories {
    return _qaBank.map((e) => e.category).toSet().toList();
  }

  /// Get total QA entries count
  int get entryCount => _qaBank.length;

  /// Normalize text for comparison
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Tokenize text into words
  List<String> _tokenize(String text) {
    return text.split(' ').where((w) => w.length > 2).toList();
  }

  /// Calculate Levenshtein similarity (0.0 - 1.0)
  double _levenshteinSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = _levenshteinDistance(s1, s2);
    final maxLen = max(s1.length, s2.length);
    return 1.0 - (distance / maxLen);
  }

  /// Calculate Levenshtein distance
  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final previousRow = List<int>.filled(s2.length + 1, 0);
    final currentRow = List<int>.filled(s2.length + 1, 0);

    for (int j = 0; j <= s2.length; j++) {
      previousRow[j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      currentRow[0] = i;

      for (int j = 1; j <= s2.length; j++) {
        final cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
        currentRow[j] = min(
          min(currentRow[j - 1] + 1, previousRow[j] + 1),
          previousRow[j - 1] + cost,
        );
      }

      for (int j = 0; j <= s2.length; j++) {
        previousRow[j] = currentRow[j];
      }
    }

    return currentRow[s2.length];
  }

  /// Calculate keyword score based on word overlap
  double _keywordScore(
    List<String> queryWords,
    List<String> entryWords,
    List<String> entryKeywords,
  ) {
    if (queryWords.isEmpty) return 0.0;

    int matches = 0;
    int keywordMatches = 0;

    for (final word in queryWords) {
      if (entryWords.contains(word)) {
        matches++;
      }
      if (entryKeywords.contains(word)) {
        keywordMatches += 2; // Keywords weighted more
      }
    }

    final wordScore = matches / queryWords.length;
    final keyScore = entryKeywords.isEmpty 
        ? 0.0 
        : keywordMatches / (entryKeywords.length * 2);

    return (wordScore * 0.4) + (keyScore * 0.6);
  }

  /// Fallback QA bank if file fails to load
  List<QABankEntry> get _fallbackQABank => [
        QABankEntry(
          id: '1',
          question: 'What is TuTu?',
          answer: 'TuTu is your personal AI agent manager app. It allows you to create and customize AI companions with persistent memory, offline capabilities, and advanced features like voice synthesis and face recognition.',
          category: QACategories.appUsage,
          keywords: ['what', 'tutu', 'app', 'about'],
          priority: 2.0,
        ),
        QABankEntry(
          id: '2',
          question: 'How do I create a new agent?',
          answer: 'Tap the "+" button on the home screen, choose a role (Girlfriend, Lawyer, Teacher, etc.), give your agent a name and personality, then tap "Create Agent". Your new agent will be ready to chat!',
          category: QACategories.agentCreation,
          keywords: ['create', 'new', 'agent', 'add', 'make'],
          priority: 2.0,
        ),
        QABankEntry(
          id: '3',
          question: 'How do I set up my API key?',
          answer: 'Go to Settings > API Configuration. Choose your provider (OpenAI, OpenRouter, etc.), enter your API key, and tap "Test Connection". You can get API keys from the provider\'s website.',
          category: QACategories.apiSetup,
          keywords: ['api', 'key', 'setup', 'configure', 'openai', 'openrouter'],
          priority: 2.0,
        ),
        QABankEntry(
          id: '4',
          question: 'Why do I need an API key?',
          answer: 'An API key allows your agents to use advanced AI models like GPT-4 and Claude. Without it, TuTu can only answer questions from its offline knowledge base.',
          category: QACategories.apiSetup,
          keywords: ['why', 'need', 'api', 'key', 'required'],
          priority: 1.5,
        ),
        QABankEntry(
          id: '5',
          question: 'How does memory work?',
          answer: 'TuTu has a multi-layer memory system: Active Memory (last 20 messages), Short-term Memory (last 500 messages), and Long-term Memory (all conversations with RAG search). This helps agents remember your conversations.',
          category: QACategories.features,
          keywords: ['memory', 'remember', 'how', 'work', 'storage'],
          priority: 1.5,
        ),
        QABankEntry(
          id: '6',
          question: 'Can I customize my agent?',
          answer: 'Yes! You can customize your agent\'s name, role, personality, avatar, and voice. Tap on any agent to edit their settings.',
          category: QACategories.agentCustomization,
          keywords: ['customize', 'edit', 'change', 'personality', 'avatar'],
          priority: 1.5,
        ),
        QABankEntry(
          id: '7',
          question: 'Is my data private?',
          answer: 'Yes! All your data is stored locally on your device. Face data and conversations never leave your phone. You can delete all data anytime in Settings.',
          category: QACategories.privacy,
          keywords: ['privacy', 'private', 'data', 'secure', 'safe'],
          priority: 1.5,
        ),
        QABankEntry(
          id: '8',
          question: 'How do I use voice features?',
          answer: 'Enable voice in Settings > Voice. In chat, tap the speaker icon on any message to hear it spoken. You can also enable auto-speak to have all responses read aloud.',
          category: QACategories.voice,
          keywords: ['voice', 'speak', 'talk', 'audio', 'sound'],
          priority: 1.5,
        ),
        QABankEntry(
          id: '9',
          question: 'How does face recognition work?',
          answer: 'Tap the camera icon in chat to capture a photo. TuTu will detect faces and either recognize them or let you register a new person. This works completely offline.',
          category: QACategories.faceRecognition,
          keywords: ['face', 'recognition', 'camera', 'photo', 'identify'],
          priority: 1.5,
        ),
        QABankEntry(
          id: '10',
          question: 'My API key is not working',
          answer: 'Make sure you\'ve copied the entire key correctly. Check that you\'ve selected the correct provider. If using OpenRouter, ensure your account has credits. Try testing the connection in Settings.',
          category: QACategories.troubleshooting,
          keywords: ['api', 'key', 'not working', 'error', 'problem'],
          priority: 1.5,
        ),
        QABankEntry(
          id: '11',
          question: 'What agents can I create?',
          answer: 'You can create various agents: Girlfriend, Boyfriend, Lawyer, Financial Advisor, Teacher, Friend, Therapist, Career Coach, or fully custom agents with unique personalities.',
          category: QACategories.agentCreation,
          keywords: ['agents', 'types', 'create', 'roles', 'options'],
          priority: 1.5,
        ),
        QABankEntry(
          id: '12',
          question: 'Can agents talk to each other?',
          answer: 'Not yet! This is a planned feature. Currently, each agent has its own separate conversations and memories.',
          category: QACategories.features,
          keywords: ['agents', 'talk', 'each other', 'multi-agent', 'together'],
          priority: 1.0,
        ),
        QABankEntry(
          id: '13',
          question: 'How do I delete an agent?',
          answer: 'Go to the Agents list, swipe left on the agent you want to delete, or tap and hold for options. Note: The default TuTu agent cannot be deleted.',
          category: QACategories.agentCreation,
          keywords: ['delete', 'remove', 'agent', 'erase'],
          priority: 1.5,
        ),
        QABankEntry(
          id: '14',
          question: 'Can I export my data?',
          answer: 'Yes! Go to Settings > Memory Management > Export Data. You can export all your conversations, agents, and memories as a JSON file.',
          category: QACategories.features,
          keywords: ['export', 'backup', 'save', 'data'],
          priority: 1.0,
        ),
        QABankEntry(
          id: '15',
          question: 'What is OpenRouter?',
          answer: 'OpenRouter is a service that provides access to multiple AI models (GPT-4, Claude, Gemini, etc.) through a single API. It\'s a great option if you want to try different models.',
          category: QACategories.apiSetup,
          keywords: ['openrouter', 'what', 'api', 'models'],
          priority: 1.5,
        ),
      ];
}
