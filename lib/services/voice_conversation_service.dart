import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/agent_model.dart';
import 'azure_tts_service.dart';

/// Voice Conversation Service - Handles speech-to-text and Azure text-to-speech
/// Enables natural voice conversations with AI agents using neural voices
class VoiceConversationService {
  static final VoiceConversationService _instance =
      VoiceConversationService._internal();
  factory VoiceConversationService() => _instance;
  VoiceConversationService._internal();

  // Speech to Text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechInitialized = false;
  bool _isListening = false;
  final String _currentLocaleId = 'en_US';

  // Azure TTS
  final AzureTTSService _azureTts = AzureTTSService();
  bool _isAzureInitialized = false;

  // Callbacks
  Function(String)? onSpeechResult;
  Function(String)? onPartialResult;
  Function()? onListeningStarted;
  Function()? onListeningFinished;
  Function(String)? onError;
  Function()? onSpeechStarted;
  Function()? onSpeechFinished;

  // Available languages
  List<stt.LocaleName> _availableLocales = [];

  /// Initialize both STT and TTS
  Future<bool> initialize({String? azureKey, String? azureRegion}) async {
    final sttResult = await _initSpeech();
    final ttsResult = await _initTTS(
      azureKey: azureKey,
      azureRegion: azureRegion,
    );
    return sttResult && ttsResult;
  }

  /// Initialize Speech to Text
  Future<bool> _initSpeech() async {
    if (_isSpeechInitialized) return true;

    try {
      _isSpeechInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech error: $error');
          onError?.call('Speech error: ${error.errorMsg}');
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
        },
      );

      if (_isSpeechInitialized) {
        _availableLocales = await _speech.locales();
        debugPrint('Available locales: ${_availableLocales.length}');
      }

      return _isSpeechInitialized;
    } catch (e) {
      debugPrint('Failed to initialize speech: $e');
      return false;
    }
  }

  /// Initialize Azure TTS
  Future<bool> _initTTS({String? azureKey, String? azureRegion}) async {
    if (_isAzureInitialized) return true;

    try {
      // Set up TTS callbacks
      _azureTts.onSpeechStarted = () {
        onSpeechStarted?.call();
      };

      _azureTts.onSpeechFinished = () {
        onSpeechFinished?.call();
      };

      _azureTts.onError = (msg) {
        debugPrint('TTS Error: $msg');
        onError?.call(msg);
      };

      _isAzureInitialized = await _azureTts.initialize(
        subscriptionKey: azureKey,
        region: azureRegion,
      );

      return _isAzureInitialized;
    } catch (e) {
      debugPrint('Failed to initialize Azure TTS: $e');
      return false;
    }
  }

  /// Configure Azure credentials
  Future<void> configureAzure(String key, String region) async {
    await _azureTts.setCredentials(key, region);
  }

  /// Check if Azure is configured
  bool get isAzureConfigured => _azureTts.isConfigured;

  /// Start listening for voice input
  Future<bool> startListening({
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
  }) async {
    if (!_isSpeechInitialized) {
      final initialized = await _initSpeech();
      if (!initialized) {
        onError?.call('Speech recognition not available');
        return false;
      }
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      final available = await _speech.initialize();
      if (!available) {
        onError?.call('Speech recognition not available on this device');
        return false;
      }

      _isListening = true;
      onListeningStarted?.call();

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (result.finalResult) {
            debugPrint('Final result: ${result.recognizedWords}');
            onSpeechResult?.call(result.recognizedWords);
          } else {
            debugPrint('Partial result: ${result.recognizedWords}');
            onPartialResult?.call(result.recognizedWords);
          }
        },
        listenFor: listenFor ?? const Duration(minutes: 1),
        pauseFor: pauseFor ?? const Duration(seconds: 3),
        localeId: localeId ?? _currentLocaleId,
        cancelOnError: false,
        partialResults: true,
        listenMode: stt.ListenMode.confirmation,
      );

      return true;
    } catch (e) {
      _isListening = false;
      onError?.call('Failed to start listening: $e');
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;
    await _speech.stop();
    onListeningFinished?.call();
  }

  /// Cancel listening without processing results
  Future<void> cancelListening() async {
    if (!_isListening) return;

    _isListening = false;
    await _speech.cancel();
    onListeningFinished?.call();
  }

  /// Speak text with agent's voice settings using Azure TTS
  Future<void> speak(String text, {Agent? agent, String? voice}) async {
    if (text.trim().isEmpty) return;

    if (!_isAzureInitialized) {
      await _initTTS();
    }

    await _azureTts.speak(text, agent: agent, voice: voice);
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _azureTts.stop();
  }

  /// Pause speaking
  Future<void> pauseSpeaking() async {
    await _azureTts.pause();
  }

  /// Resume speaking
  Future<void> resumeSpeaking() async {
    await _azureTts.resume();
  }

  /// Get voice profiles
  List<VoiceProfile> getVoiceProfiles() {
    return _azureTts.getVoiceProfiles();
  }

  /// Set voice profile
  void setVoiceProfile(String voiceName) {
    _azureTts.setVoice(voiceName);
  }

  /// Set voice style
  void setVoiceStyle(String style) {
    _azureTts.setVoiceStyle(style);
  }

  /// Set speech rate
  void setSpeechRate(double rate) {
    _azureTts.setSpeechRate(rate);
  }

  /// Set pitch
  void setPitch(double pitch) {
    _azureTts.setPitch(pitch);
  }

  /// Preview a voice
  Future<void> previewVoice(String voiceName) async {
    await _azureTts.previewVoice(voiceName);
  }

  /// Get available languages for STT
  List<stt.LocaleName> get availableLocales => _availableLocales;

  /// Get available voices from Azure
  Future<List<Map<String, dynamic>>> getAvailableVoices() async {
    return await _azureTts.getAvailableVoices();
  }

  /// Get available voice styles
  List<String> getVoiceStyles() {
    return _azureTts.getVoiceStyles();
  }

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Check if currently speaking
  bool get isSpeaking => _azureTts.isSpeaking;

  /// Check if speech is available
  bool get isSpeechAvailable => _isSpeechInitialized;

  /// Check if TTS is available
  bool get isTtsAvailable => _isAzureInitialized;

  /// Current voice
  String get currentVoice => _azureTts.currentVoice;

  /// Current style
  String get currentStyle => _azureTts.currentStyle;

  /// Dispose resources
  Future<void> dispose() async {
    await stopListening();
    await stopSpeaking();
    await _speech.cancel();
    await _azureTts.dispose();
  }

  /// Request microphone permission
  static Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }
}

/// Voice state for UI management
class VoiceState {
  final bool isListening;
  final bool isSpeaking;
  final String? recognizedText;
  final String? error;
  final double soundLevel;
  final bool isAzureConfigured;

  VoiceState({
    this.isListening = false,
    this.isSpeaking = false,
    this.recognizedText,
    this.error,
    this.soundLevel = 0.0,
    this.isAzureConfigured = false,
  });

  VoiceState copyWith({
    bool? isListening,
    bool? isSpeaking,
    String? recognizedText,
    String? error,
    double? soundLevel,
    bool? isAzureConfigured,
  }) {
    return VoiceState(
      isListening: isListening ?? this.isListening,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      recognizedText: recognizedText ?? this.recognizedText,
      error: error,
      soundLevel: soundLevel ?? this.soundLevel,
      isAzureConfigured: isAzureConfigured ?? this.isAzureConfigured,
    );
  }
}

/// Enum for voice conversation states
enum VoiceConversationState { idle, listening, processing, speaking, error }
