/// llama_bindings.dart - Dart FFI bindings for llama.cpp
/// 
/// This file provides Dart bindings to the C++ llama.cpp library
/// for on-device LLM inference with thread-safe operations.

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

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

// Global library instance
DynamicLibrary? _lib;

DynamicLibrary get _library {
  _lib ??= _getDynamicLibrary();
  return _lib!;
}

/// FFI Function signatures
typedef _LLMInitNative = Void Function();
typedef _LLMInit = void Function();

typedef _LLMDeinitNative = Void Function();
typedef _LLMDeinit = void Function();

typedef _LLMLoadModelNative = Int32 Function(Pointer<Utf8> model_path, Int32 n_ctx, Int32 n_threads);
typedef _LLMLoadModel = int Function(Pointer<Utf8> model_path, int n_ctx, int n_threads);

typedef _LLMIsModelLoadedNative = Int32 Function();
typedef _LLMIsModelLoaded = int Function();

typedef _LLMUnloadModelNative = Void Function();
typedef _LLMUnloadModel = void Function();

typedef _LLMGenerateNative = Int32 Function(
  Pointer<Utf8> prompt,
  Pointer<Utf8> output_buffer,
  Int32 buffer_size,
);
typedef _LLMGenerate = int Function(
  Pointer<Utf8> prompt,
  Pointer<Utf8> output_buffer,
  int buffer_size,
);

typedef _LLMTokenizeNative = Int32 Function(
  Pointer<Utf8> text,
);
typedef _LLMTokenize = int Function(
  Pointer<Utf8> text,
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

/// Llama FFI Bindings class
class LlamaBindings {
  static LlamaBindings? _instance;
  
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

  factory LlamaBindings() {
    _instance ??= LlamaBindings._internal();
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
    _getVocabSize = _library.lookup<NativeFunction<_LLMGetVocabSizeNative>>('llm_get_vocab_size').asFunction();
    _hasGpuSupport = _library.lookup<NativeFunction<_LLMHasGpuSupportNative>>('llm_has_gpu_support').asFunction();
    _getSystemInfo = _library.lookup<NativeFunction<_LLMGetSystemInfoNative>>('llm_get_system_info').asFunction();
    _getLastError = _library.lookup<NativeFunction<_LLMGetLastErrorNative>>('llm_get_last_error').asFunction();
  }
  
  /// Initialize the library
  void initialize() {
    if (_initialized) return;
    _init();
    _initialized = true;
  }
  
  /// Cleanup resources
  void dispose() {
    if (!_initialized) return;
    _deinit();
    _initialized = false;
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
  
  /// Load a model from the given path
  bool loadModel(String modelPath, {int nCtx = 2048, int nThreads = 4}) {
    final pathPtr = modelPath.toNativeUtf8();
    try {
      final result = _loadModel(pathPtr, nCtx, nThreads);
      return result == 0;
    } finally {
      calloc.free(pathPtr);
    }
  }
  
  /// Check if a model is currently loaded
  bool get isModelLoaded => _isModelLoaded() == 1;
  
  /// Unload the current model
  void unloadModel() => _unloadModel();
  
  /// Generate text from a prompt
  String generate(String prompt) {
    final promptPtr = prompt.toNativeUtf8();
    final outputBuffer = calloc.allocate<Uint8>(8192).cast<Utf8>();
    
    try {
      final result = _generate(promptPtr, outputBuffer, 8192);
      
      if (result < 0) {
        throw LlamaException(getLastError());
      }
      
      return outputBuffer.toDartString();
    } finally {
      calloc.free(promptPtr);
      calloc.free(outputBuffer);
    }
  }
  
  /// Tokenize text and return token count
  int tokenize(String text) {
    final textPtr = text.toNativeUtf8();
    try {
      return _tokenize(textPtr);
    } finally {
      calloc.free(textPtr);
    }
  }
  
  /// Get the context size of the loaded model
  int get contextSize => _getContextSize();
  
  /// Get vocabulary size
  int get vocabSize => _getVocabSize();
  
  /// Check if GPU acceleration is available
  bool get hasGpuSupport => _hasGpuSupport() == 1;
  
  /// Get system information
  String get systemInfo {
    final buffer = calloc.allocate<Uint8>(1024).cast<Utf8>();
    try {
      _getSystemInfo(buffer, 1024);
      return buffer.toDartString();
    } finally {
      calloc.free(buffer);
    }
  }
  
  /// Get the last error message
  String getLastError() {
    final ptr = _getLastError();
    return ptr.toDartString();
  }
}

/// Exception thrown by LLM operations
class LlamaException implements Exception {
  final String message;
  
  LlamaException(this.message);
  
  @override
  String toString() => 'LlamaException: $message';
}

/// Model parameters for loading a GGUF model
class LLMModelParams {
  final String modelPath;
  final int nCtx;
  final int nThreads;
  final int nBatch;
  final double ropeFreqBase;
  final double ropeFreqScale;

  LLMModelParams({
    required this.modelPath,
    this.nCtx = 2048,
    this.nThreads = 4,
    this.nBatch = 512,
    this.ropeFreqBase = 10000.0,
    this.ropeFreqScale = 1.0,
  });
}

/// Generation parameters for inference
class LLMGenerateParams {
  final int nPredict;
  final double temperature;
  final double topP;
  final int topK;
  final double repeatPenalty;
  final int repeatLastN;
  final String? stopSequences;

  LLMGenerateParams({
    this.nPredict = 256,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.topK = 40,
    this.repeatPenalty = 1.1,
    this.repeatLastN = 64,
    this.stopSequences,
  });
}
