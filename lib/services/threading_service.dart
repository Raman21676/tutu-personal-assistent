/// threading_service.dart - Multi-threading manager for TuTu
/// 
/// This service manages Dart Isolates for background processing,
/// ensuring the UI remains responsive during heavy operations.
///
/// Features:
/// - Isolate pool for concurrent operations
/// - Message passing between UI and worker isolates
/// - Priority queue for tasks
/// - Cancellation support

import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Priority levels for tasks
enum TaskPriority {
  critical,   // UI-blocking, must complete immediately
  high,       // User-initiated actions
  normal,     // Standard background work
  low,        // Prefetching, cache updates
  background, // Non-essential maintenance
}

/// Task types for categorization
enum TaskType {
  inference,      // LLM inference
  modelLoad,      // Loading AI model
  ragSearch,      // RAG memory search
  faceDetect,     // Face recognition
  voiceSynth,     // Text-to-speech
  storage,        // Database operations
  export,         // Data export
  maintenance,    // Cleanup, optimization
}

/// Represents a background task
class BackgroundTask<T> {
  final String id;
  final TaskType type;
  final TaskPriority priority;
  final Future<T> Function() operation;
  final Completer<T> completer;
  final DateTime createdAt;
  final Duration? timeout;
  bool isCancelled;

  BackgroundTask({
    required this.id,
    required this.type,
    required this.priority,
    required this.operation,
    this.timeout,
  })  : completer = Completer<T>(),
        createdAt = DateTime.now(),
        isCancelled = false;

  /// Calculate priority score (lower = higher priority)
  int get priorityScore {
    int baseScore = priority.index * 1000;
    // Older tasks get slight priority boost
    int ageBonus = DateTime.now().difference(createdAt).inSeconds ~/ 10;
    return baseScore - ageBonus;
  }
}

/// Thread pool configuration
class ThreadPoolConfig {
  final int maxIsolates;
  final int maxConcurrentInference;
  final int maxConcurrentRAG;
  final Duration taskTimeout;
  final Duration idleTimeout;

  const ThreadPoolConfig({
    this.maxIsolates = 4,
    this.maxConcurrentInference = 1,
    this.maxConcurrentRAG = 2,
    this.taskTimeout = const Duration(seconds: 120),
    this.idleTimeout = const Duration(minutes: 5),
  });

  /// Default configuration optimized for mobile devices
  factory ThreadPoolConfig.mobile() {
    final processors = math.min(4, math.max(2, 
      (DateTime.now().millisecondsSinceEpoch % 4) + 2  // Simulated processor count
    ));
    
    return ThreadPoolConfig(
      maxIsolates: processors,
      maxConcurrentInference: 1,  // Only one inference at a time
      maxConcurrentRAG: math.min(2, processors),
      taskTimeout: const Duration(seconds: 120),
      idleTimeout: const Duration(minutes: 5),
    );
  }
}

/// Threading Service - Manages background isolates
class ThreadingService {
  static final ThreadingService _instance = ThreadingService._internal();
  factory ThreadingService() => _instance;
  ThreadingService._internal();

  // Configuration
  late final ThreadPoolConfig _config;
  
  // State
  bool _initialized = false;
  bool _disposed = false;
  
  // Isolate pool
  final List<_WorkerIsolate> _workers = [];
  final Queue<BackgroundTask> _taskQueue = Queue();
  final Map<String, BackgroundTask> _activeTasks = {};
  
  // Statistics
  final _stats = ThreadingStats();
  
  // Stream controllers
  final _statsController = StreamController<ThreadingStats>.broadcast();
  final _taskCompleteController = StreamController<String>.broadcast();
  
  // Getters
  bool get isInitialized => _initialized;
  ThreadingStats get stats => _stats;
  Stream<ThreadingStats> get statsStream => _statsController.stream;
  Stream<String> get taskCompleteStream => _taskCompleteController.stream;
  int get activeWorkerCount => _workers.where((w) => w.isBusy).length;
  int get pendingTaskCount => _taskQueue.length;
  int get activeTaskCount => _activeTasks.length;

  /// Initialize the threading service
  Future<void> initialize({ThreadPoolConfig? config}) async {
    if (_initialized) return;
    
    _config = config ?? ThreadPoolConfig.mobile();
    
    // Spawn worker isolates
    await _spawnWorkers();
    
    _initialized = true;
    debugPrint('ThreadingService initialized with ${_workers.length} workers');
  }

  /// Spawn worker isolates
  Future<void> _spawnWorkers() async {
    for (int i = 0; i < _config.maxIsolates; i++) {
      final worker = await _WorkerIsolate.spawn(i);
      _workers.add(worker);
    }
  }

  /// Submit a task for background execution
  Future<T> submit<T>({
    required TaskType type,
    required TaskPriority priority,
    required Future<T> Function() operation,
    String? taskId,
    Duration? timeout,
  }) async {
    if (_disposed) {
      throw StateError('ThreadingService has been disposed');
    }
    
    if (!_initialized) {
      await initialize();
    }

    final task = BackgroundTask<T>(
      id: taskId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      priority: priority,
      operation: operation,
      timeout: timeout ?? _config.taskTimeout,
    );

    // Check if we can execute immediately
    if (priority == TaskPriority.critical) {
      // Critical tasks run immediately on main isolate
      try {
        final result = await operation();
        task.completer.complete(result);
        _stats.recordCompletion(task.type, Duration.zero);
        return task.completer.future;
      } catch (e) {
        task.completer.completeError(e);
        _stats.recordError(task.type);
        return task.completer.future;
      }
    }

    // Check resource limits
    if (_shouldQueueTask(task)) {
      _taskQueue.add(task);
      _processQueue();
    } else {
      // Execute immediately
      _executeTask(task);
    }

    return task.completer.future;
  }

  /// Check if task should be queued based on resource limits
  bool _shouldQueueTask(BackgroundTask task) {
    switch (task.type) {
      case TaskType.inference:
      case TaskType.modelLoad:
        // Only one inference/model load at a time
        final activeInference = _activeTasks.values
            .where((t) => t.type == TaskType.inference || t.type == TaskType.modelLoad)
            .length;
        return activeInference >= _config.maxConcurrentInference;
        
      case TaskType.ragSearch:
        final activeRAG = _activeTasks.values
            .where((t) => t.type == TaskType.ragSearch)
            .length;
        return activeRAG >= _config.maxConcurrentRAG;
        
      default:
        // Other tasks can run concurrently up to worker limit
        return _activeTasks.length >= _workers.length;
    }
  }

  /// Process the task queue
  void _processQueue() {
    if (_taskQueue.isEmpty) return;
    
    // Sort by priority (lower score = higher priority)
    final sortedTasks = _taskQueue.toList()
      ..sort((a, b) => a.priorityScore.compareTo(b.priorityScore));
    
    _taskQueue.clear();
    _taskQueue.addAll(sortedTasks);
    
    // Try to execute pending tasks
    while (_taskQueue.isNotEmpty) {
      final task = _taskQueue.first;
      if (!_shouldQueueTask(task)) {
        _taskQueue.removeFirst();
        _executeTask(task);
      } else {
        break; // Resource limits reached
      }
    }
  }

  /// Execute a task on an available worker
  Future<void> _executeTask(BackgroundTask task) async {
    if (task.isCancelled) {
      task.completer.completeError(Exception('Task was cancelled'));
      return;
    }

    _activeTasks[task.id] = task;
    _stats.recordStart(task.type);
    final stopwatch = Stopwatch()..start();

    try {
      // Find available worker or use compute for simple tasks
      final result = await _runInIsolate(task);
      
      stopwatch.stop();
      _stats.recordCompletion(task.type, stopwatch.elapsed);
      
      if (!task.isCancelled && !task.completer.isCompleted) {
        task.completer.complete(result);
      }
      
      _taskCompleteController.add(task.id);
    } catch (e, stackTrace) {
      stopwatch.stop();
      _stats.recordError(task.type);
      
      if (!task.isCancelled && !task.completer.isCompleted) {
        task.completer.completeError(e, stackTrace);
      }
    } finally {
      _activeTasks.remove(task.id);
      _processQueue(); // Process next tasks
    }
  }

  /// Run task in an isolate using compute
  Future<dynamic> _runInIsolate(BackgroundTask task) async {
    // Use Flutter's compute for simple function execution
    return compute(_isolateEntry, _IsolateMessage(
      taskId: task.id,
      operation: task.operation,
    ));
  }

  /// Cancel a pending or active task
  bool cancelTask(String taskId) {
    // Check pending queue
    final pendingTask = _taskQueue.cast<BackgroundTask?>()
        .firstWhere((t) => t?.id == taskId, orElse: () => null);
    
    if (pendingTask != null) {
      pendingTask.isCancelled = true;
      _taskQueue.remove(pendingTask);
      pendingTask.completer.completeError(Exception('Task was cancelled'));
      return true;
    }

    // Check active tasks
    final activeTask = _activeTasks[taskId];
    if (activeTask != null) {
      activeTask.isCancelled = true;
      // Note: Actual cancellation of running isolate is complex
      // This marks it to complete with error when done
      return true;
    }

    return false;
  }

  /// Cancel all tasks of a specific type
  int cancelTasksByType(TaskType type) {
    int cancelled = 0;
    
    // Cancel pending tasks
    final toCancel = _taskQueue.where((t) => t.type == type).toList();
    for (final task in toCancel) {
      task.isCancelled = true;
      _taskQueue.remove(task);
      task.completer.completeError(Exception('Task was cancelled'));
      cancelled++;
    }
    
    return cancelled;
  }

  /// Get current queue information
  List<Map<String, dynamic>> getQueueInfo() {
    return [
      ..._taskQueue.map((t) => {
        'id': t.id,
        'type': t.type.toString(),
        'priority': t.priority.toString(),
        'age': DateTime.now().difference(t.createdAt).inSeconds,
      }),
    ];
  }

  /// Dispose the service and cleanup resources
  Future<void> dispose() async {
    _disposed = true;
    
    // Cancel all pending tasks
    while (_taskQueue.isNotEmpty) {
      final task = _taskQueue.removeFirst();
      task.isCancelled = true;
      if (!task.completer.isCompleted) {
        task.completer.completeError(Exception('Service disposed'));
      }
    }

    // Kill all workers
    for (final worker in _workers) {
      await worker.kill();
    }
    _workers.clear();

    await _statsController.close();
    await _taskCompleteController.close();
    
    _initialized = false;
  }
}

/// Message sent to isolate
class _IsolateMessage {
  final String taskId;
  final Future<dynamic> Function() operation;

  _IsolateMessage({
    required this.taskId,
    required this.operation,
  });
}

/// Entry point for isolate
Future<dynamic> _isolateEntry(_IsolateMessage message) async {
  return message.operation();
}

/// Worker isolate wrapper
class _WorkerIsolate {
  final int id;
  final Isolate isolate;
  final ReceivePort receivePort;
  final SendPort sendPort;
  bool isBusy = false;
  bool isAlive = true;

  _WorkerIsolate({
    required this.id,
    required this.isolate,
    required this.receivePort,
    required this.sendPort,
  });

  static Future<_WorkerIsolate> spawn(int id) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _workerEntry,
      receivePort.sendPort,
      debugName: 'TuTuWorker_$id',
    );

    final sendPort = await receivePort.first as SendPort;

    return _WorkerIsolate(
      id: id,
      isolate: isolate,
      receivePort: receivePort,
      sendPort: sendPort,
    );
  }

  Future<void> kill() async {
    isAlive = false;
    isolate.kill(priority: Isolate.immediate);
    receivePort.close();
  }
}

/// Worker isolate entry point
void _workerEntry(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    // Handle messages from main isolate
    if (message is Map<String, dynamic>) {
      final operation = message['operation'] as Function;
      final replyPort = message['replyPort'] as SendPort;
      
      try {
        final result = operation();
        replyPort.send({'success': true, 'result': result});
      } catch (e) {
        replyPort.send({'success': false, 'error': e.toString()});
      }
    }
  });
}

/// Threading statistics
class ThreadingStats {
  final Map<TaskType, int> _completedTasks = {};
  final Map<TaskType, int> _errorTasks = {};
  final Map<TaskType, List<Duration>> _taskDurations = {};
  
  DateTime _lastReset = DateTime.now();

  void recordStart(TaskType type) {
    // Track start if needed
  }

  void recordCompletion(TaskType type, Duration duration) {
    _completedTasks[type] = (_completedTasks[type] ?? 0) + 1;
    _taskDurations.putIfAbsent(type, () => []).add(duration);
    
    // Keep only last 100 durations
    if (_taskDurations[type]!.length > 100) {
      _taskDurations[type]!.removeAt(0);
    }
  }

  void recordError(TaskType type) {
    _errorTasks[type] = (_errorTasks[type] ?? 0) + 1;
  }

  int getCompletedCount(TaskType type) => _completedTasks[type] ?? 0;
  int getErrorCount(TaskType type) => _errorTasks[type] ?? 0;
  
  Duration? getAverageDuration(TaskType type) {
    final durations = _taskDurations[type];
    if (durations == null || durations.isEmpty) return null;
    
    final total = durations.fold<Duration>(
      Duration.zero, 
      (sum, d) => sum + d
    );
    return Duration(microseconds: total.inMicroseconds ~/ durations.length);
  }

  Map<String, dynamic> toJson() {
    return {
      'completed': _completedTasks.map((k, v) => MapEntry(k.toString(), v)),
      'errors': _errorTasks.map((k, v) => MapEntry(k.toString(), v)),
      'avgDurations': _taskDurations.map((k, v) {
        final avg = getAverageDuration(k);
        return MapEntry(k.toString(), avg?.inMilliseconds ?? 0);
      }),
      'lastReset': _lastReset.toIso8601String(),
    };
  }

  void reset() {
    _completedTasks.clear();
    _errorTasks.clear();
    _taskDurations.clear();
    _lastReset = DateTime.now();
  }
}

/// Extension for easy task submission
extension ThreadingServiceExtensions on ThreadingService {
  /// Submit inference task
  Future<T> runInference<T>(Future<T> Function() operation, {
    TaskPriority priority = TaskPriority.high,
    String? taskId,
  }) => submit(
    type: TaskType.inference,
    priority: priority,
    operation: operation,
    taskId: taskId,
  );

  /// Submit RAG search task
  Future<T> runRAG<T>(Future<T> Function() operation, {
    TaskPriority priority = TaskPriority.normal,
    String? taskId,
  }) => submit(
    type: TaskType.ragSearch,
    priority: priority,
    operation: operation,
    taskId: taskId,
  );

  /// Submit face detection task
  Future<T> runFaceDetection<T>(Future<T> Function() operation, {
    TaskPriority priority = TaskPriority.normal,
    String? taskId,
  }) => submit(
    type: TaskType.faceDetect,
    priority: priority,
    operation: operation,
    taskId: taskId,
  );

  /// Submit storage operation
  Future<T> runStorage<T>(Future<T> Function() operation, {
    TaskPriority priority = TaskPriority.low,
    String? taskId,
  }) => submit(
    type: TaskType.storage,
    priority: priority,
    operation: operation,
    taskId: taskId,
  );
}
