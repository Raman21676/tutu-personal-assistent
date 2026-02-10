/// llama_bindings.dart - Dart FFI bindings for llama.cpp
/// 
/// This file provides Dart bindings to the C++ llama.cpp library
/// for on-device LLM inference with thread-safe operations.

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

// Load the dynamic library
DynamicLibrary _getDynamicLibrary() {
  if (Platform.isAndroid) {
    return DynamicLibrary.open('libllama_bridge.so');
  } else if (Platform.isIOS) {
    return DynamicLibrary.executable();
  } else if (Platform.isLinux) {
    return DynamicLibrary.open('libllama_bridge.so');
  } else if (Platform.isMacOS) {
    return DynamicLibrary.open('libllama_bridge.dylib');
  } else if (Platform.isWindows) {
    return DynamicLibrary.open('llama_bridge.dll');
  }
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}

// Global library instance with thread-safe initialization
DynamicLibrary? _lib;
final _libLock = Object();

DynamicLibrary get _library {
  if (_lib == null) {
    synchronized(_libLock, () {
      _lib ??= _getDynamicLibrary();
    });
  }
  return _lib!;
}

/// Simple synchronization helper
void synchronized(Object lock, void Function() action) {
  // In Dart, we can use Zone or other mechanisms for true synchronization
  // For FFI, the C++ side handles thread safety
  action();
}

/// Model parameters for loading a GGUF model
class LLMModelParams extends Struct {
  external Pointer<Utf8> model_path;
  
  @Int32()
  external int n_ctx;
  
  @Int32()
  external int n_threads;
  
  @Int32()
  external int n_batch;
  
  @Float()
  external double rope_freq_base;
  
  @Float()
  external double rope_freq_scale;

  factory LLMModelParams.allocate({
    required String modelPath,
    int nCtx = 2048,
    int nThreads = 4,
    int nBatch = 512,
    double ropeFreqBase = 10000.0,
    double ropeFreqScale = 1.0,
  }) {
    final ptr = calloc<LLMModelParams>();
    final params = ptr.ref;
    params.model_path = modelPath.toNativeUtf8();
    params.n_ctx = nCtx;
    params.n_threads = nThreads;
    params.n_batch = nBatch;
    params.rope_freq_base = ropeFreqBase;
    params.rope_freq_scale = ropeFreqScale;
    return params;
  }

  void free() {
    calloc.free(this);
  }
}

/// Generation parameters for inference
class LLMGenerateParams extends Struct {
  @Int32()
  external int n_predict;
  
  @Float()
  external double temperature;
  
  @Float()
  external double top_p;
  
  @Int32()
  external int top_k;
  
  @Float()
  external double repeat_penalty;
  
  @Int32()
  external int repeat_last_n;
  
  external Pointer<Utf8> stop_sequences;

  factory LLMGenerateParams.allocate({
    int nPredict = 256,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
    double repeatPenalty = 1.1,
    int repeatLastN = 64,
    String? stopSequences,
  }) {
    final ptr = calloc<LLMGenerateParams>();
    final params = ptr.ref;
    params.n_predict = nPredict;
    params.temperature = temperature;
    params.top_p = topP;
    params.top_k = topK;
    params.repeat_penalty = repeatPenalty;
    params.repeat_last_n = repeatLastN;
    params.stop_sequences = stopSequences?.toNativeUtf8() ?? nullptr;
    return params;
  }

  void free() {
    calloc.free(this);
  }
}

/// FFI Function signatures
typedef _LLMInitNative = Void Function();
typedef _LLMInit = void Function();

typedef _LLMDeinitNative = Void Function();
typedef _LLMDeinit = void Function();

typedef _LLMLoadModelNative = Int32 Function(Pointer<LLMModelParams> params);
typedef _LLMLoadModel = int Function(Pointer<LLMModelParams> params);

typedef _LLMIsModelLoadedNative = Int32 Function();
typedef _LLMIsModelLoaded = int Function();

typedef _LLMUnloadModelNative = Void Function();
typedef _LLMUnloadModel = void Function();

typedef _LLMGenerateNative = Int32 Function(
  Pointer<Utf8> prompt,
  Pointer<LLMGenerateParams> params,
  Pointer<Utf8> output_buffer,
  Int32 buffer_size,
);
typedef _LLMGenerate = int Function(
  Pointer<Utf8> prompt,
  Pointer<LLMGenerateParams> params,
  Pointer<Utf8> output_buffer,
  int buffer_size,
);

typedef _LLMTokenizeNative = Int32 Function(
  Pointer<Utf8> text,
  Pointer<Int32> tokens,
  Int32 max_tokens,
);
typedef _LLMTokenize = int Function(
  Pointer<Utf8> text,
  Pointer<Int32> tokens,
  int max_tokens,
);

typedef _LLMGetContextSizeNative = Int32 Function();
typedef _LLMGetContextSize = int Function();

typedef _LLMGetVocabSizeNative = Int32 Function();
typedef _LLMGetVocabSize = int Function();

typedef _LLMHasGpuSupportNative = Int32 Function();
typedef _LLMHasGpuSupport = int Function();

typedef _LLMGetSystemInfoNative = Void Function(Pointer<Utf8> buffer, Int32 buffer_size);
typedef _LLMGetSystemInfo = void Function(Pointer<Utf8> buffer, int buffer_size);

typedef _LLMGetLastErrorNative = Pointer<Utf8> Function();
typedef _LLMGetLastError = Pointer<Utf8> Function();

/// Thread-safe singleton for llama bindings
class LlamaBindings {
  static LlamaBindings? _instance;
  static final _instanceLock = Object();
  
  late final _LLMInit _init;
  late final _LLMDeinit _deinit;
  late final _LLMLoadModel _loadModel;
  late final _LLMIsModelLoaded _isModelLoaded;
  late final _LLMUnloadModel _unloadModel;
  late final _LLMGenerate _generate;
  late final _LLMTokenize _tokenize;
  late final _LLMGetContextSize _getContextSize;
  late final _LLMGetVocabSize _getVocabSize;
  late final _LLMHasGpuSupport _hasGpuSupport;
  late final _LLMGetSystemInfo _getSystemInfo;
  late final _LLMGetLastError _getLastError;
  
  bool _initialized = false;
  bool _modelLoaded = false;
  final _operationLock = Object();

  /// Thread-safe singleton factory
  factory LlamaBindings() {
    if (_instance == null) {
      synchronized(_instanceLock, () {
        _instance ??= LlamaBindings._internal();
      });
    }
    return _instance!;
  }
  
  LlamaBindings._internal() {
    _init = _library.lookup<NativeFunction<_LLMInitNative>>('llm_init').asFunction();
    _deinit = _library.lookup<NativeFunction<_LLMDeinitNative>>('llm_deinit').asFunction();
    _loadModel = _library.lookup<NativeFunction<_LLMLoadModelNative>>('llm_load_model').asFunction();
    _isModelLoaded = _library.lookup<NativeFunction<_LLMIsModelLoadedNative>>('llm_is_model_loaded').asFunction();
    _unloadModel = _library.lookup<NativeFunction<_LLMUnloadModelNative>>('llm_unload_model').asFunction();
    _generate = _library.lookup<NativeFunction<_LLMGenerateNative>>('llm_generate').asFunction();
    _tokenize = _library.lookup<NativeFunction<_LLMTokenizeNative>>('llm_tokenize').asFunction();
    _getContextSize = _library.lookup<NativeFunction<_LLMGetContextSizeNative>>('llm_get_context_size').asFunction();
    _getVocabSize = _library.lookup<NativeFunction<_LLMGetVocabSizeNative>>('llam_get_vocab_size').asFunction();
    _hasGpuSupport = _library.lookup<NativeFunction<_LLMHasGpuSupportNative>>('llm_has_gpu_support').asFunction();
    _getSystemInfo = _library.lookup<NativeFunction<_LLMGetSystemInfoNative>>('llm_get_system_info').asFunction();
    _getLastError = _library.lookup<NativeFunction<_LLMGetLastErrorNative>>('llm_get_last_error').asFunction();
  }
  
  /// Initialize the library (thread-safe)
  void initialize() {
    synchronized(_operationLock, () {
      if (_initialized) return;
      _init();
      _initialized = true;
    });
  }
  
  /// Cleanup resources (thread-safe)
  void dispose() {
    synchronized(_operationLock, () {
      if (!_initialized) return;
      _deinit();
      _initialized = false;
      _modelLoaded = false;
    });
  }
  
  /// Check if library is available
  static bool get isAvailable {
    try {
      _getDynamicLibrary();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Load a model from the given path (thread-safe)
  bool loadModel(LLMModelParams params) {
    return synchronized(_operationLock, () {
      final ptr = calloc<LLMModelParams>()..ref = params;
      try {
        final result = _loadModel(ptr);
        _modelLoaded = result == 0;
        return _modelLoaded;
      } finally {
        calloc.free(ptr);
      }
    });
  }
  
  /// Check if a model is currently loaded
  bool get isModelLoaded {
    return synchronized(_operationLock, () {
      return _isModelLoaded() == 1;
    });
  }
  
  /// Unload the current model (thread-safe)
  void unloadModel() {
    synchronized(_operationLock, () {
      _unloadModel();
      _modelLoaded = false;
    });
  }
  
  /// Generate text from a prompt (thread-safe)
  String generate(
    String prompt, {
    LLMGenerateParams? params,
  }) {
    return synchronized(_operationLock, () {
      final promptPtr = prompt.toNativeUtf8();
      final paramsPtr = params != null 
          ? (calloc<LLMGenerateParams>()..ref = params)
          : nullptr;
      final outputBuffer = calloc<Utf8>(8192);
      
      try {
        final result = _generate(
          promptPtr,
          paramsPtr,
          outputBuffer,
          8192,
        );
        
        if (result < 0) {
          throw LlamaException(getLastError());
        }
        
        return outputBuffer.toDartString();
      } finally {
        calloc.free(promptPtr);
        if (paramsPtr != nullptr) calloc.free(paramsPtr);
        calloc.free(outputBuffer);
      }
    });
  }
  
  /// Tokenize text and return token count (thread-safe)
  int tokenize(String text) {
    return synchronized(_operationLock, () {
      final textPtr = text.toNativeUtf8();
      final tokens = calloc<Int32>(4096);
      
      try {
        return _tokenize(textPtr, tokens, 4096);
      } finally {
        calloc.free(textPtr);
        calloc.free(tokens);
      }
    });
  }
  
  /// Get the context size of the loaded model
  int get contextSize {
    return synchronized(_operationLock, () {
      return _getContextSize();
    });
  }
  
  /// Get vocabulary size
  int get vocabSize {
    return synchronized(_operationLock, () {
      return _getVocabSize();
    });
  }
  
  /// Check if GPU acceleration is available
  bool get hasGpuSupport {
    return synchronized(_operationLock, () {
      return _hasGpuSupport() == 1;
    });
  }
  
  /// Get system information
  String get systemInfo {
    return synchronized(_operationLock, () {
      final buffer = calloc<Utf8>(1024);
      try {
        _getSystemInfo(buffer, 1024);
        return buffer.toDartString();
      } finally {
        calloc.free(buffer);
      }
    });
  }
  
  /// Get the last error message
  String getLastError() {
    return synchronized(_operationLock, () {
      final ptr = _getLastError();
      return ptr.toDartString();
    });
  }
}

/// Exception thrown by LLM operations
class LlamaException implements Exception {
  final String message;
  
  LlamaException(this.message);
  
  @override
  String toString() => 'LlamaException: $message';
}

/// Memory allocation helpers
final calloc = _Calloc();

class _Calloc {
  Pointer<T> call<T extends NativeType>(int size) {
    return _allocate<T>(size);
  }
  
  void free(Pointer ptr) {
    _free(ptr);
  }
}

// Import native allocation functions
final _nativeMalloc = DynamicLibrary.process().lookupFunction<
  Pointer<Void> Function(IntPtr size),
  Pointer<Void> Function(int size)
>('malloc');

final _nativeFree = DynamicLibrary.process().lookupFunction<
  Void Function(Pointer<Void> ptr),
  void Function(Pointer<Void> ptr)
>('free');

Pointer<T> _allocate<T extends NativeType>(int size) {
  return _nativeMalloc(size).cast<T>();
}

void _free(Pointer ptr) {
  _nativeFree(ptr.cast<Void>());
}
