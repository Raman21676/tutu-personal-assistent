import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

import '../models/agent_model.dart';

/// Azure Neural TTS Service - High-quality text-to-speech with emotional voices
class AzureTTSService {
  static final AzureTTSService _instance = AzureTTSService._internal();
  factory AzureTTSService() => _instance;
  AzureTTSService._internal();

  // Azure TTS Configuration
  String? _subscriptionKey;
  String _region = 'eastus';
  String _endpoint = 'https://eastus.tts.speech.microsoft.com';
  
  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // State
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String _currentVoice = 'en-US-JennyNeural';
  double _speechRate = 1.0;
  double _pitch = 0.0;
  String _voiceStyle = 'default';
  
  // Callbacks
  VoidCallback? onSpeechStarted;
  VoidCallback? onSpeechFinished;
  Function(String)? onError;
  
  // Audio session
  AudioSession? _session;

  /// Initialize the service
  Future<bool> initialize({String? subscriptionKey, String? region}) async {
    if (_isInitialized) return true;
    
    try {
      _subscriptionKey = subscriptionKey;
      if (region != null) {
        _region = region;
        _endpoint = 'https://$_region.tts.speech.microsoft.com';
      }
      
      // Configure audio session
      _session = await AudioSession.instance;
      await _session?.configure(const AudioSessionConfiguration.speech());
      
      // Set up audio player listeners
      _audioPlayer.playerStateStream.listen((state) {
        if (state.playing) {
          _isSpeaking = true;
          onSpeechStarted?.call();
        } else if (state.processingState == ProcessingState.completed) {
          _isSpeaking = false;
          onSpeechFinished?.call();
        }
      });
      
      _audioPlayer.playbackEventStream.listen((event) {}, onError: (error) {
        _isSpeaking = false;
        onError?.call('Audio playback error: $error');
      });
      
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Failed to initialize Azure TTS: $e');
      return false;
    }
  }
  
  /// Check if Azure is configured
  bool get isConfigured => _subscriptionKey != null && _subscriptionKey!.isNotEmpty;
  
  /// Set Azure credentials
  Future<void> setCredentials(String subscriptionKey, String region) async {
    _subscriptionKey = subscriptionKey;
    _region = region;
    _endpoint = 'https://$_region.tts.speech.microsoft.com';
  }
  
  /// Speak text with SSML support
  Future<void> speak(String text, {Agent? agent, String? voice}) async {
    if (text.trim().isEmpty) return;
    
    if (!isConfigured) {
      onError?.call('Azure TTS not configured. Please set up API credentials.');
      return;
    }
    
    try {
      // Stop any current speech
      await stop();
      
      // Determine voice to use
      final selectedVoice = voice ?? _getVoiceForAgent(agent);
      
      // Generate SSML
      final ssml = _generateSSML(text, selectedVoice);
      
      // Get audio from Azure
      final audioData = await _synthesizeSpeech(ssml);
      
      if (audioData != null) {
        // Play audio
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.dataFromBytes(audioData, mimeType: 'audio/wav')),
        );
        await _audioPlayer.play();
      }
    } catch (e) {
      _isSpeaking = false;
      onError?.call('Speech synthesis failed: $e');
    }
  }
  
  /// Stop speaking
  Future<void> stop() async {
    await _audioPlayer.stop();
    _isSpeaking = false;
  }
  
  /// Pause speaking
  Future<void> pause() async {
    await _audioPlayer.pause();
  }
  
  /// Resume speaking
  Future<void> resume() async {
    await _audioPlayer.play();
  }
  
  /// Generate SSML with styling
  String _generateSSML(String text, String voice) {
    final escapedText = _escapeXml(text);
    
    // Base prosody settings
    String rate = _speechRate == 1.0 ? 'default' : '${(_speechRate * 100).toInt()}%';
    String pitch = _pitch == 0 ? 'default' : '${_pitch > 0 ? '+' : ''}${_pitch}Hz';
    
    // Build SSML with optional style
    String ssmlContent;
    if (_voiceStyle != 'default' && _voiceStyle.isNotEmpty) {
      ssmlContent = '<mstts:express-as style="$_voiceStyle">$escapedText</mstts:express-as>';
    } else {
      ssmlContent = escapedText;
    }
    
    String ssml = '''<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xmlns:mstts="https://www.w3.org/2001/mstts" xml:lang="en-US">
  <voice name="$voice">
    <prosody rate="$rate" pitch="$pitch">$ssmlContent</prosody>
  </voice>
</speak>''';
    
    return ssml;
  }
  
  /// Synthesize speech using Azure TTS API
  Future<Uint8List?> _synthesizeSpeech(String ssml) async {
    final url = Uri.parse('$_endpoint/cognitiveservices/v1');
    
    final response = await http.post(
      url,
      headers: {
        'Ocp-Apim-Subscription-Key': _subscriptionKey!,
        'Content-Type': 'application/ssml+xml',
        'X-Microsoft-OutputFormat': 'riff-24khz-16bit-mono-pcm',
        'User-Agent': 'TuTuApp',
      },
      body: ssml,
    );
    
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Azure TTS error: ${response.statusCode} - ${response.body}');
    }
  }
  
  /// Get voice based on agent settings
  String _getVoiceForAgent(Agent? agent) {
    if (agent == null) return _currentVoice;
    
    // Map voice gender to appropriate neural voice
    if (agent.voiceGender == 'female') {
      return 'en-US-JennyNeural';
    } else if (agent.voiceGender == 'male') {
      return 'en-US-GuyNeural';
    }
    
    return _currentVoice;
  }
  
  /// Get available voices
  Future<List<Map<String, dynamic>>> getAvailableVoices() async {
    if (!isConfigured) {
      // Return default voice list if not configured
      return _defaultVoices;
    }
    
    try {
      final url = Uri.parse('$_endpoint/cognitiveservices/voices/list');
      final response = await http.get(
        url,
        headers: {
          'Ocp-Apim-Subscription-Key': _subscriptionKey!,
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> voices = jsonDecode(response.body);
        return voices
            .where((v) => v['VoiceType'] == 'Neural')
            .map((v) => {
                  'name': v['Name'],
                  'displayName': v['DisplayName'],
                  'locale': v['Locale'],
                  'gender': v['Gender'],
                  'styles': v['StyleList'] ?? [],
                })
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to fetch voices: $e');
    }
    
    return _defaultVoices;
  }
  
  /// Set current voice
  void setVoice(String voice) {
    _currentVoice = voice;
  }
  
  /// Set voice style (emotional tone)
  void setVoiceStyle(String style) {
    _voiceStyle = style;
  }
  
  /// Set speech rate
  void setSpeechRate(double rate) {
    _speechRate = rate.clamp(0.5, 2.0);
  }
  
  /// Set pitch
  void setPitch(double pitch) {
    _pitch = pitch.clamp(-20.0, 20.0);
  }
  
  /// Preview a voice
  Future<void> previewVoice(String voiceName) async {
    await speak('Hello! This is how I sound. I hope you like my voice!', voice: voiceName);
  }
  
  /// Get voice profiles (like Gemini's personas)
  List<VoiceProfile> getVoiceProfiles() {
    return [
      VoiceProfile(
        id: 'aria',
        name: 'Aria',
        description: 'Friendly Female',
        voiceName: 'en-US-AriaNeural',
        gender: 'Female',
        locale: 'en-US',
        emoji: '👩',
        style: 'friendly',
      ),
      VoiceProfile(
        id: 'orion',
        name: 'Orion',
        description: 'Professional Male',
        voiceName: 'en-US-DavisNeural',
        gender: 'Male',
        locale: 'en-US',
        emoji: '👨‍💼',
        style: 'default',
      ),
      VoiceProfile(
        id: 'nova',
        name: 'Nova',
        description: 'Cheerful Female',
        voiceName: 'en-GB-SoniaNeural',
        gender: 'Female',
        locale: 'en-GB',
        emoji: '🌟',
        style: 'cheerful',
      ),
      VoiceProfile(
        id: 'atlas',
        name: 'Atlas',
        description: 'Calm Male',
        voiceName: 'en-GB-RyanNeural',
        gender: 'Male',
        locale: 'en-GB',
        emoji: '🧘',
        style: 'calm',
      ),
      VoiceProfile(
        id: 'luna',
        name: 'Luna',
        description: 'Gentle Female',
        voiceName: 'en-US-JennyNeural',
        gender: 'Female',
        locale: 'en-US',
        emoji: '🌙',
        style: 'gentle',
      ),
      VoiceProfile(
        id: 'cosmo',
        name: 'Cosmo',
        description: 'Energetic Male',
        voiceName: 'en-US-GuyNeural',
        gender: 'Male',
        locale: 'en-US',
        emoji: '🚀',
        style: 'excited',
      ),
    ];
  }
  
  /// Get available voice styles
  List<String> getVoiceStyles() {
    return [
      'default',
      'cheerful',
      'sad',
      'angry',
      'excited',
      'friendly',
      'hopeful',
      'shouting',
      'terrified',
      'unfriendly',
      'whispering',
    ];
  }
  
  /// Check if speaking
  bool get isSpeaking => _isSpeaking;
  
  /// Current voice
  String get currentVoice => _currentVoice;
  
  /// Current style
  String get currentStyle => _voiceStyle;
  
  /// Escape XML special characters
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
  
  /// Default voices (fallback)
  final List<Map<String, dynamic>> _defaultVoices = [
    {'name': 'en-US-JennyNeural', 'displayName': 'Jenny', 'locale': 'en-US', 'gender': 'Female'},
    {'name': 'en-US-GuyNeural', 'displayName': 'Guy', 'locale': 'en-US', 'gender': 'Male'},
    {'name': 'en-US-AriaNeural', 'displayName': 'Aria', 'locale': 'en-US', 'gender': 'Female'},
    {'name': 'en-US-DavisNeural', 'displayName': 'Davis', 'locale': 'en-US', 'gender': 'Male'},
    {'name': 'en-GB-SoniaNeural', 'displayName': 'Sonia', 'locale': 'en-GB', 'gender': 'Female'},
    {'name': 'en-GB-RyanNeural', 'displayName': 'Ryan', 'locale': 'en-GB', 'gender': 'Male'},
  ];
}

/// Voice Profile Model
class VoiceProfile {
  final String id;
  final String name;
  final String description;
  final String voiceName;
  final String gender;
  final String locale;
  final String emoji;
  final String style;
  
  VoiceProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.voiceName,
    required this.gender,
    required this.locale,
    required this.emoji,
    required this.style,
  });
  
  String get displayTitle => '$emoji $name';
  String get subtitle => '$description · $locale';
}
