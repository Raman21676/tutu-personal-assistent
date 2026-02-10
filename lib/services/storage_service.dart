import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sembast/sembast.dart' as sembast;
import 'package:sembast/sembast_io.dart' as sembast_io;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/agent_model.dart';
import '../models/message_model.dart';
import '../models/memory_model.dart';
import '../models/face_model.dart';
// API config removed - app is now fully offline

/// Storage Service - Manages all local data persistence
/// Uses Sembast for NoSQL data and SharedPreferences for settings
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  sembast.Database? _db;
  SharedPreferences? _prefs;

  // Store references
  final _agentsStore = sembast.StoreRef<String, Map<String, dynamic>>('agents');
  final _messagesStore = sembast.StoreRef<String, Map<String, dynamic>>(
    'messages',
  );
  final _memoriesStore = sembast.StoreRef<String, Map<String, dynamic>>(
    'memories',
  );
  final _facesStore = sembast.StoreRef<String, Map<String, dynamic>>('faces');
  final _summariesStore = sembast.StoreRef<String, Map<String, dynamic>>(
    'summaries',
  );

  /// Initialize the storage service
  Future<void> initialize() async {
    if (_db != null) return;

    // Initialize Sembast
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDir.path, 'tutu.db');
    _db = await sembast_io.databaseFactoryIo.openDatabase(dbPath);

    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();

    // Create default TuTu agent if not exists
    await _createDefaultAgentIfNeeded();
  }

  /// Create default TuTu agent on first launch
  Future<void> _createDefaultAgentIfNeeded() async {
    final agents = await getAllAgents();
    if (agents.isEmpty) {
      await saveAgent(DefaultAgents.tutuAgent);
    }
  }

  // ==================== AGENT OPERATIONS ====================

  /// Save or update an agent
  Future<void> saveAgent(Agent agent) async {
    await _agentsStore.record(agent.id).put(_db!, agent.toJson());
  }

  /// Get an agent by ID
  Future<Agent?> getAgent(String agentId) async {
    final record = await _agentsStore.record(agentId).get(_db!);
    if (record == null) return null;
    return Agent.fromJson(record);
  }

  /// Get all agents
  Future<List<Agent>> getAllAgents() async {
    final records = await _agentsStore.find(_db!);
    return records.map((r) => Agent.fromJson(r.value)).toList();
  }

  /// Delete an agent and all associated data
  Future<void> deleteAgent(String agentId) async {
    // Don't delete default TuTu agent
    if (agentId == 'tutu_default') return;

    await _db!.transaction((txn) async {
      // Delete agent
      await _agentsStore.record(agentId).delete(txn);

      // Delete messages
      final messageFilter = sembast.Filter.equals('agentId', agentId);
      await _messagesStore.delete(
        txn,
        finder: sembast.Finder(filter: messageFilter),
      );

      // Delete memories
      final memoryFilter = sembast.Filter.equals('agentId', agentId);
      await _memoriesStore.delete(
        txn,
        finder: sembast.Finder(filter: memoryFilter),
      );

      // Delete faces
      final faceFilter = sembast.Filter.equals('agentId', agentId);
      await _facesStore.delete(txn, finder: sembast.Finder(filter: faceFilter));
    });
  }

  /// Update agent last interaction time
  Future<void> updateAgentInteraction(String agentId) async {
    final agent = await getAgent(agentId);
    if (agent != null) {
      final updated = agent.copyWith(lastInteractionAt: DateTime.now());
      await saveAgent(updated);
    }
  }

  // ==================== MESSAGE OPERATIONS ====================

  /// Save a message
  Future<void> saveMessage(Message message) async {
    await _messagesStore.record(message.id).put(_db!, message.toJson());
  }

  /// Save multiple messages in batch
  Future<void> saveMessagesBatch(List<Message> messages) async {
    await _db!.transaction((txn) async {
      for (final message in messages) {
        await _messagesStore.record(message.id).put(txn, message.toJson());
      }
    });
  }

  /// Get messages for an agent with pagination
  Future<List<Message>> getMessagesByAgent(
    String agentId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final filter = sembast.Filter.equals('agentId', agentId);
    final finder = sembast.Finder(
      filter: filter,
      sortOrders: [sembast.SortOrder('timestamp', false)],
      limit: limit,
      offset: offset,
    );

    final records = await _messagesStore.find(_db!, finder: finder);
    final messages = records.map((r) => Message.fromJson(r.value)).toList();

    // Sort by timestamp ascending for conversation view
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  /// Get message count for an agent
  Future<int> getMessageCount(String agentId) async {
    final filter = sembast.Filter.equals('agentId', agentId);
    return await _messagesStore.count(_db!, filter: filter);
  }

  /// Delete messages older than a date
  Future<int> deleteOldMessages(DateTime before) async {
    final filter = sembast.Filter.lessThan(
      'timestamp',
      before.toIso8601String(),
    );
    return await _messagesStore.delete(
      _db!,
      finder: sembast.Finder(filter: filter),
    );
  }

  // ==================== MEMORY OPERATIONS ====================

  /// Save a memory
  Future<void> saveMemory(Memory memory) async {
    await _memoriesStore.record(memory.id).put(_db!, memory.toJson());
  }

  /// Save multiple memories in batch
  Future<void> saveMemoriesBatch(List<Memory> memories) async {
    await _db!.transaction((txn) async {
      for (final memory in memories) {
        await _memoriesStore.record(memory.id).put(txn, memory.toJson());
      }
    });
  }

  /// Get all memories for an agent
  Future<List<Memory>> getMemoriesByAgent(String agentId) async {
    final filter = sembast.Filter.equals('agentId', agentId);
    final finder = sembast.Finder(filter: filter);
    final records = await _memoriesStore.find(_db!, finder: finder);
    return records.map((r) => Memory.fromJson(r.value)).toList()
      ..removeWhere((m) => m.isExpired);
  }

  /// Search memories by keywords
  Future<List<Memory>> searchMemories(
    String agentId,
    List<String> keywords, {
    int limit = 10,
  }) async {
    final agentFilter = sembast.Filter.equals('agentId', agentId);
    final records = await _memoriesStore.find(
      _db!,
      finder: sembast.Finder(filter: agentFilter),
    );

    final memories = records
        .map((r) => Memory.fromJson(r.value))
        .where((m) => !m.isExpired)
        .toList();

    // Score by keyword match
    final scored = <Memory, int>{};
    for (final memory in memories) {
      int score = 0;
      for (final keyword in keywords) {
        if (memory.keywords.contains(keyword.toLowerCase())) {
          score += 10;
        }
        if (memory.content.toLowerCase().contains(keyword.toLowerCase())) {
          score += 5;
        }
      }
      if (score > 0) {
        scored[memory] = score;
      }
    }

    // Sort by score and importance
    final sorted = scored.keys.toList()
      ..sort((a, b) {
        final scoreCompare = scored[b]!.compareTo(scored[a]!);
        if (scoreCompare != 0) return scoreCompare;
        return b.importance.compareTo(a.importance);
      });

    return sorted.take(limit).toList();
  }

  /// Delete expired memories
  Future<int> deleteExpiredMemories() async {
    final now = DateTime.now().toIso8601String();
    final filter = sembast.Filter.lessThan('expiresAt', now);
    return await _memoriesStore.delete(
      _db!,
      finder: sembast.Finder(filter: filter),
    );
  }

  // ==================== FACE OPERATIONS ====================

  /// Save a face
  Future<void> saveFace(Face face) async {
    await _facesStore.record(face.id).put(_db!, face.toJson());
  }

  /// Get all faces for an agent
  Future<List<Face>> getFacesByAgent(String agentId) async {
    final filter = sembast.Filter.equals('agentId', agentId);
    final finder = sembast.Finder(filter: filter);
    final records = await _facesStore.find(_db!, finder: finder);
    return records.map((r) => Face.fromJson(r.value)).toList();
  }

  /// Get face by ID
  Future<Face?> getFace(String faceId) async {
    final record = await _facesStore.record(faceId).get(_db!);
    if (record == null) return null;
    return Face.fromJson(record);
  }

  /// Delete a face
  Future<void> deleteFace(String faceId) async {
    await _facesStore.record(faceId).delete(_db!);
  }

  // ==================== CONVERSATION SUMMARY OPERATIONS ====================

  /// Save a conversation summary
  Future<void> saveSummary(ConversationSummary summary) async {
    await _summariesStore.record(summary.id).put(_db!, summary.toJson());
  }

  /// Get summaries for an agent
  Future<List<ConversationSummary>> getSummariesByAgent(String agentId) async {
    final filter = sembast.Filter.equals('agentId', agentId);
    final finder = sembast.Finder(
      filter: filter,
      sortOrders: [sembast.SortOrder('toDate', false)],
    );
    final records = await _summariesStore.find(_db!, finder: finder);
    return records.map((r) => ConversationSummary.fromJson(r.value)).toList();
  }

  // ==================== API CONFIG OPERATIONS (DEPRECATED) ====================
  // NOTE: API config removed - app is now fully offline with local LLM

  /// Deprecated: API config no longer used
  @deprecated
  Future<void> saveApiConfig(dynamic config) async {
    // No-op: App uses local LLM only
  }

  /// Deprecated: Always returns null (offline mode)
  @deprecated
  Future<dynamic> getApiConfig() async => null;

  /// Deprecated: No-op
  @deprecated
  Future<void> clearApiConfig() async {
    // No-op: App uses local LLM only
  }

  /// Always returns true - offline mode uses local LLM
  Future<bool> hasApiKey() async => true;

  // ==================== USER PREFERENCES ====================

  /// Save user preferences
  Future<void> saveUserPreferences(Map<String, dynamic> prefs) async {
    final json = jsonEncode(prefs);
    await _prefs!.setString('user_preferences', json);
  }

  /// Get user preferences
  Map<String, dynamic> getUserPreferences() {
    final json = _prefs!.getString('user_preferences');
    if (json == null) return {};
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Get user name
  String get userName => _prefs!.getString('user_name') ?? 'User';

  /// Set user name
  Future<void> setUserName(String name) async {
    await _prefs!.setString('user_name', name);
  }

  /// Check if onboarding is completed
  bool get isOnboardingCompleted =>
      _prefs!.getBool('onboarding_completed') ?? false;

  /// Set onboarding completed
  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs!.setBool('onboarding_completed', completed);
  }

  // ==================== UTILITY METHODS ====================

  /// Clear all data (dangerous!)
  Future<void> clearAllData() async {
    await _db!.transaction((txn) async {
      await _agentsStore.delete(txn);
      await _messagesStore.delete(txn);
      await _memoriesStore.delete(txn);
      await _facesStore.delete(txn);
      await _summariesStore.delete(txn);
    });
    await _prefs!.clear();
    await _createDefaultAgentIfNeeded();
  }

  /// Export all data
  Future<Map<String, dynamic>> exportAllData() async {
    final agents = await _agentsStore.find(_db!);
    final messages = await _messagesStore.find(_db!);
    final memories = await _memoriesStore.find(_db!);
    final faces = await _facesStore.find(_db!);

    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'agents': agents.map((r) => r.value).toList(),
      'messages': messages.map((r) => r.value).toList(),
      'memories': memories.map((r) => r.value).toList(),
      'faces': faces.map((r) => r.value).toList(),
    };
  }

  /// Get storage stats
  Future<Map<String, int>> getStorageStats() async {
    return {
      'agents': await _agentsStore.count(_db!),
      'messages': await _messagesStore.count(_db!),
      'memories': await _memoriesStore.count(_db!),
      'faces': await _facesStore.count(_db!),
    };
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _db?.close();
    _db = null;
    _prefs = null;
  }
}
