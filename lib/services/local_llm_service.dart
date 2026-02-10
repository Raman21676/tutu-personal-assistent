/// local_llm_service.dart - High-level service for local LLM inference
/// 
/// This service manages the local LLM model, handles inference,
/// and provides a clean API for the chat interface.
/// 
/// Features:
/// - Multi-threaded inference using Dart Isolates
/// - Non-blocking model loading
/// - Streaming token generation
/// - Priority-based task scheduling

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../models/agent_model.dart';
import '../models/message_model.dart';
import 'llama_bindings.dart';
import 'storage_service.dart';
import 'threading_service.dart';

/// Service state
enum LLMServiceState {
  uninitialized,
  extractingModel,
  loading,
  ready,
  generating,
  error,
}

/// Local LLM Service - Manages on-device inference
class LocalLLMService extends ChangeNotifier {
  static final LocalLLMService _instance = LocalLLMService._internal();
  factory LocalLLMService() => _instance;
  LocalLLMService._internal();
  
  // Dependencies
  final LlamaBindings _bindings = LlamaBindings();
  final StorageService _storage = StorageService();
  final ThreadingService _threading = ThreadingService();
  
  // State
  LLMServiceState _state = LLMServiceState.uninitialized;
  String? _error;
  String? _modelPath;
  bool _isModelExtracted = false;
  
  // Generation state
  bool _isGenerating = false;
  String? _currentTaskId;
  final StreamController<String> _generationController = StreamController<String>.broadcast();
  
  // Model info
  String _modelName = 'SmolLM2-360M-Instruct';
  int _contextSize = 2048;
  int _vocabSize = 49152;
  int _optimalThreads = 4;
  
  // Configuration
  static const String _defaultModelAsset = 'assets/models/SmolLM2-360M-Instruct-Q4_K_M.gguf';
  static const String _modelFileName = 'SmolLM2-360M-Instruct-Q4_K_M.gguf';
  
  // Performance tracking
  final List<InferenceMetrics> _metrics = [];
  
  // Getters
  LLMServiceState get state => _state;
  String? get error => _error;
  bool get isReady => _state == LLMServiceState.ready;
  bool get isGenerating => _isGenerating;
  bool get isModelExtracted => _isModelExtracted;
  
  String get modelName => _modelName;
  int get contextSize => _contextSize;
  int get vocabSize => _vocabSize;
  int get optimalThreads => _optimalThreads;
  String? get modelPath => _modelPath;
  
  bool get hasGpuSupport => _bindings.hasGpuSupport;
  String get systemInfo => _bindings.systemInfo;
  Stream<String> get generationStream => _generationController.stream;
  List<InferenceMetrics> get metrics => List.unmodifiable(_metrics);
  
  /// Initialize the service with multi-threading
  Future<void> initialize() async {
    if (_state != LLMServiceState.uninitialized) return;
    
    // Initialize threading service first
    await _threading.initialize();
    
    _setState(LLMServiceState.extractingModel);
    
    try {
      // Calculate optimal thread count
      _optimalThreads = _calculateOptimalThreads();
      debugPrint('Using $_optimalThreads threads for inference');
      
      // Check if FFI is available (on main thread)
      if (!LlamaBindings.isAvailable) {
        throw Exception('Native library not available. Please rebuild with native support.');
      }
      
      // Extract model in background
      await _threading.submit(
        type: TaskType.modelLoad,
        priority: TaskPriority.critical,
        operation: _ensureModelExtracted,
      );
      
      _setState(LLMServiceState.loading);
      
      // Load the model in background
      await _threading.submit(
        type: TaskType.modelLoad,
        priority: TaskPriority.critical,
        operation: _loadModel,
      );
      
      _setState(LLMServiceState.ready);
    } catch (e) {
      _error = e.toString();
      _setState(LLMServiceState.error);
      debugPrint('LocalLLMService initialization error: $e');
    }
  }
  
  /// Calculate optimal thread count based on device
  int _calculateOptimalThreads() {
    final processors = Platform.numberOfProcessors;
    // Use 75% of available cores, max 4 for mobile
    // Leave cores for UI and other services
    return math.min(4, math.max(2, processors * 3 ~/ 4));
  }
  
  /// Extract model from assets to app documents
  Future<void> _ensureModelExtracted() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory(path.join(appDir.path, 'models'));
    
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    
    final modelFile = File(path.join(modelDir.path, _modelFileName));
    _modelPath = modelFile.path;
    
    if (await modelFile.exists()) {
      _isModelExtracted = true;
      return;
    }
    
    // Extract model from assets
    debugPrint('Extracting model from assets...');
    try {
      final byteData = await rootBundle.load(_defaultModelAsset);
      final bytes = byteData.buffer.asUint8List();
      
      // Write in chunks to avoid memory spikes
      const chunkSize = 1024 * 1024; // 1MB chunks
      final raf = await modelFile.open(mode: FileMode.write);
      
      for (int i = 0; i < bytes.length; i += chunkSize) {
        final end = math.min(i + chunkSize, bytes.length);
        await raf.writeFrom(bytes.sublist(i, end));
        
        // Allow UI to update
        await Future.delayed(Duration.zero);
      }
      
      await raf.close();
      _isModelExtracted = true;
      
      debugPrint('Model extracted successfully (${bytes.length ~/ 1024 ~/ 1024} MB)');
    } catch (e) {
      throw Exception('Failed to extract model: $e');
    }
  }
  
  /// Load the model into memory
  Future<void> _loadModel() async {
    if (_modelPath == null) {
      throw Exception('Model path not set');
    }
    
    final params = LLMModelParams.allocate(
      modelPath: _modelPath!,
      nCtx: 2048,
      nThreads: _optimalThreads,
      nBatch: 512,
    );
    
    final success = _bindings.loadModel(params);
    
    if (!success) {
      throw Exception('Failed to load model: ${_bindings.getLastError()}');
    }
    
    // Get model info
    _contextSize = _bindings.contextSize;
    _vocabSize = _bindings.vocabSize;
    
    debugPrint('Model loaded successfully');
    debugPrint('Context size: $_contextSize');
    debugPrint('Vocab size: $_vocabSize');
  }
  
  /// Send a message and get a response (non-blocking)
  Future<Message> sendMessage({
    required String content,
    required Agent agent,
    required List<Message> conversationHistory,
  }) async {
    if (!isReady) {
      throw Exception('LLM Service not ready. Current state: $_state');
    }
    
    if (_isGenerating) {
      throw Exception('Already generating a response');
    }
    
    _isGenerating = true;
    notifyListeners();
    
    final taskId = 'inference_${DateTime.now().millisecondsSinceEpoch}';
    _currentTaskId = taskId;
    
    try {
      // Build the prompt
      final prompt = _buildPrompt(
        content: content,
        agent: agent,
        history: conversationHistory,
      );
      
      // Check prompt length on main thread (fast)
      final tokenCount = _bindings.tokenize(prompt);
      if (tokenCount > _contextSize - 256) {
        throw Exception('Input too long ($tokenCount tokens). Maximum: ${_contextSize - 256}');
      }
      
      // Run inference in background isolate
      final response = await _threading.runInference(
        () => _runInference(prompt, agent),
        priority: TaskPriority.high,
        taskId: taskId,
      );
      
      // Clean up the response
      final cleanedResponse = _cleanResponse(response);
      
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        agentId: agent.id,
        role: 'assistant',
        content: cleanedResponse,
        timestamp: DateTime.now(),
        metadata: {
          'model': _modelName,
          'tokens_generated': _bindings.tokenize(response),
          'local': true,
          'threads': _optimalThreads,
        },
      );
    } finally {
      _isGenerating = false;
      _currentTaskId = null;
      notifyListeners();
    }
  }
  
  /// Run inference in isolate
  String _runInference(String prompt, Agent agent) {
    final stopwatch = Stopwatch()..start();
    
    // Generate response using bindings
    final params = LLMGenerateParams.allocate(
      nPredict: 512,
      temperature: 0.7,
      topP: 0.9,
      topK: 40,
      repeatPenalty: 1.1,
      repeatLastN: 64,
      stopSequences: '["<|im_end|>", "User:", "<|endoftext|>"]',
    );
    
    final response = _bindings.generate(
      prompt,
      params: params,
    );
    
    stopwatch.stop();
    
    // Track metrics
    final metrics = InferenceMetrics(
      timestamp: DateTime.now(),
      duration: stopwatch.elapsed,
      inputTokens: _bindings.tokenize(prompt),
      outputTokens: _bindings.tokenize(response),
      threadsUsed: _optimalThreads,
    );
    _metrics.add(metrics);
    
    // Keep only last 100 metrics
    if (_metrics.length > 100) {
      _metrics.removeAt(0);
    }
    
    return response;
  }
  
  /// Build the chat prompt
  String _buildPrompt({
    required String content,
    required Agent agent,
    required List<Message> history,
  }) {
    final buffer = StringBuffer();
    
    // System prompt
    buffer.writeln('<|im_start|>system');
    buffer.writeln(agent.systemPrompt);
    buffer.writeln('<|im_end|>');
    
    // Conversation history (last 10 messages)
    final recentHistory = history.length > 10 
        ? history.sublist(history.length - 10) 
        : history;
    
    for (final msg in recentHistory) {
      final role = msg.role == 'user' ? 'user' : 'assistant';
      buffer.writeln('<|im_start|>$role');
      buffer.writeln(msg.content);
      buffer.writeln('<|im_end|>');
    }
    
    // Current message
    buffer.writeln('<|im_start|>user');
    buffer.writeln(content);
    buffer.writeln('<|im_end|>');
    
    // Assistant prefix
    buffer.write('<|im_start|>assistant\n');
    
    return buffer.toString();
  }
  
  /// Clean up the model response
  String _cleanResponse(String response) {
    // Remove special tokens
    var cleaned = response
        .replaceAll('<|im_end|>', '')
        .replaceAll('<|im_start|>', '')
        .replaceAll('<|endoftext|>', '')
        .replaceAll('assistant', '')
        .replaceAll('user', '');
    
    // Trim whitespace
    cleaned = cleaned.trim();
    
    return cleaned;
  }
  
  /// Stream generation with real-time token streaming
  /// 
  /// This uses a separate isolate for generation while streaming
  /// tokens back to the UI through a StreamController
  Stream<String> generateStream({
    required String content,
    required Agent agent,
    required List<Message> conversationHistory,
  }) async* {
    if (!isReady) {
      throw Exception('LLM Service not ready');
    }
    
    if (_isGenerating) {
      throw Exception('Already generating a response');
    }
    
    _isGenerating = true;
    notifyListeners();
    
    final buffer = StringBuffer();
    final taskId = 'stream_${DateTime.now().millisecondsSinceEpoch}';
    _currentTaskId = taskId;
    
    try {
      final prompt = _buildPrompt(
        content: content,
        agent: agent,
        history: conversationHistory,
      );
      
      // For now, simulate streaming with word-by-word output
      // In production, this would hook into llama.cpp's token callback
      final fullResponse = await _threading.runInference(
        () => _runInference(prompt, agent),
        priority: TaskPriority.high,
        taskId: taskId,
      );
      
      // Stream words for UI responsiveness
      final words = fullResponse.split(' ');
      for (int i = 0; i < words.length; i++) {
        final word = words[i];
        buffer.write(word);
        if (i < words.length - 1) buffer.write(' ');
        
        yield buffer.toString();
        _generationController.add(buffer.toString());
        
        // Small delay for streaming effect
        await Future.delayed(const Duration(milliseconds: 20));
      }
    } finally {
      _isGenerating = false;
      _currentTaskId = null;
      notifyListeners();
    }
  }
  
  /// Cancel current generation
  bool cancelGeneration() {
    if (_currentTaskId != null && _isGenerating) {
      final cancelled = _threading.cancelTask(_currentTaskId!);
      if (cancelled) {
        _isGenerating = false;
        notifyListeners();
      }
      return cancelled;
    }
    return false;
  }
  
  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    if (_metrics.isEmpty) {
      return {'message': 'No metrics available yet'};
    }
    
    final avgDuration = _metrics.fold<Duration>(
      Duration.zero, 
      (sum, m) => sum + m.duration
    ) ~/ _metrics.length;
    
    final avgTokensPerSecond = _metrics.fold<double>(
      0,
      (sum, m) => sum + m.tokensPerSecond
    ) / _metrics.length;
    
    final fastest = _metrics.reduce((a, b) => 
      a.duration < b.duration ? a : b
    );
    
    final slowest = _metrics.reduce((a, b) => 
      a.duration > b.duration ? a : b
    );
    
    return {
      'totalInferences': _metrics.length,
      'averageDuration': '${avgDuration.inMilliseconds}ms',
      'averageTokensPerSecond': avgTokensPerSecond.toStringAsFixed(2),
      'fastest': '${fastest.duration.inMilliseconds}ms',
      'slowest': '${slowest.duration.inMilliseconds}ms',
      'threadsUsed': _optimalThreads,
      'recentMetrics': _metrics.take(5).map((m) => m.toJson()).toList(),
    };
  }
  
  /// Unload model and free resources
  Future<void> unload() async {
    _bindings.unloadModel();
    _setState(LLMServiceState.uninitialized);
  }
  
  /// Dispose the service
  @override
  void dispose() {
    cancelGeneration();
    _generationController.close();
    _bindings.dispose();
    _threading.dispose();
    super.dispose();
  }
  
  /// Set state and notify listeners
  void _setState(LLMServiceState newState) {
    _state = newState;
    notifyListeners();
  }
  
  /// Get estimated memory usage
  String get estimatedMemoryUsage {
    // SmolLM2-360M Q4_K_M is about 258MB on disk
    // Loaded in memory it's about 400-500MB
    return '~450 MB';
  }
  
  /// Check if model needs to be re-extracted
  Future<bool> checkModelIntegrity() async {
    if (_modelPath == null) return false;
    
    final file = File(_modelPath!);
    if (!await file.exists()) return false;
    
    final size = await file.length();
    const expectedSize = 258 * 1024 * 1024;
    
    return (size - expectedSize).abs() < 10 * 1024 * 1024;
  }
}

/// Inference performance metrics
class InferenceMetrics {
  final DateTime timestamp;
  final Duration duration;
  final int inputTokens;
  final int outputTokens;
  final int threadsUsed;

  InferenceMetrics({
    required this.timestamp,
    required this.duration,
    required this.inputTokens,
    required this.outputTokens,
    required this.threadsUsed,
  });

  double get tokensPerSecond => 
    outputTokens / duration.inMilliseconds * 1000;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'durationMs': duration.inMilliseconds,
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'tokensPerSecond': tokensPerSecond.toStringAsFixed(2),
    'threadsUsed': threadsUsed,
  };
}

/// Exception for LLM service errors
class LLMServiceException implements Exception {
  final String message;
  final LLMServiceState state;
  
  LLMServiceException(this.message, {required this.state});
  
  @override
  String toString() => 'LLMServiceException: $message (state: $state)';
}
