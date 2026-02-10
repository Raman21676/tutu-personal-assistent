/// App Constants - Centralized configuration values
class AppConstants {
  // App Info
  static const String appName = 'TuTu';
  static const String appVersion = '2.0.0';
  static const String appTagline = 'Your Personal Offline AI Assistant';

  // Storage Keys
  static const String keyUserName = 'user_name';
  static const String keyUserPreferences = 'user_preferences';
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyVoiceSettings = 'voice_settings';
  static const String keyDarkMode = 'dark_mode';
  static const String keyAutoSpeak = 'auto_speak';
  static const String keyModelPath = 'model_path';
  static const String keyActiveModel = 'active_model';

  // Limits
  static const int maxAgents = 20;
  static const int maxMessageHistory = 1000;
  static const int maxActiveMemory = 20;
  static const int maxRetrievedMemories = 5;
  static const int maxFaceDatabase = 100;
  static const int maxImageSize = 512;

  // Timeouts
  static const Duration inferenceTimeout = Duration(seconds: 120);
  static const Duration modelLoadTimeout = Duration(seconds: 60);

  // UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double avatarSize = 48.0;
  static const double messageBubbleRadius = 16.0;

  // Voice
  static const double defaultSpeechRate = 0.5;
  static const double defaultPitch = 1.0;
  static const double defaultVolume = 1.0;

  // Face Recognition
  static const double faceMatchThreshold = 0.6;
  static const double faceConfidenceThreshold = 0.75;

  // QA Bank
  static const double qaConfidenceThreshold = 0.75;

  // Memory
  static const int summarizationThreshold = 100;
  static const int memoryExpirationDays = 365;

  // Local LLM
  static const int defaultContextSize = 2048;
  static const int defaultThreads = 4;
  static const double defaultTemperature = 0.7;
  static const int defaultMaxTokens = 512;
}

/// Route names for navigation
class Routes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String agentList = '/agents';
  static const String chat = '/chat';
  static const String createAgent = '/create-agent';
  static const String settings = '/settings';
  static const String voiceSettings = '/voice-settings';
  static const String camera = '/camera';
  static const String modelManager = '/model-manager';
}

/// Asset paths
class Assets {
  static const String qaBank = 'assets/qa_bank.json';
  static const String defaultModel = 'assets/models/SmolLM2-360M-Instruct-Q4_K_M.gguf';
  static const String imagesDir = 'assets/images/';
  static const String modelsDir = 'assets/models/';
}

/// Default messages
class DefaultMessages {
  static const String welcomeMessage = 
      'Hello! I\'m TuTu, your personal AI assistant. I run entirely on your device - no internet needed! I can help you create agents, answer questions, or just chat. What would you like to do?';
  
  static const String offlineMessage = 
      'I\'m running completely offline on your device. Your conversations stay private and secure.';
  
  static const String errorMessage = 
      'Sorry, something went wrong. Please try again.';
  
  static const String typingIndicator = 'Thinking...';
  static const String modelLoading = 'Loading AI model...';
  static const String privacyMessage = 
      'Your privacy is our priority. All AI processing happens locally on your device.';
}

/// Sample agent suggestions
class AgentSuggestions {
  static const List<Map<String, String>> suggestions = [
    {
      'name': 'Maya',
      'role': 'Girlfriend',
      'avatar': '💕',
      'description': 'A caring and affectionate companion',
    },
    {
      'name': 'Alex',
      'role': 'Friend',
      'avatar': '😊',
      'description': 'A loyal and fun friend to chat with',
    },
    {
      'name': 'Prof. Chen',
      'role': 'Teacher',
      'avatar': '📚',
      'description': 'Patient and knowledgeable educator',
    },
    {
      'name': 'Sarah',
      'role': 'Therapist',
      'avatar': '🧠',
      'description': 'Empathetic listener and supporter',
    },
    {
      'name': 'Mike',
      'role': 'Fitness Coach',
      'avatar': '💪',
      'description': 'Motivating workout companion',
    },
    {
      'name': 'Zoe',
      'role': 'Career Coach',
      'avatar': '🚀',
      'description': 'Helps you reach your professional goals',
    },
  ];
}

/// Emojis for avatar selection
class AvatarEmojis {
  static const List<String> people = [
    '👩', '👨', '👧', '👦', '👵', '👴', '👱‍♀️', '👱‍♂️',
    '👮‍♀️', '👮‍♂️', '👩‍⚕️', '👨‍⚕️', '👩‍🌾', '👨‍🌾', '👩‍🍳', '👨‍🍳',
    '👩‍🎓', '👨‍🎓', '👩‍🏫', '👨‍🏫', '👩‍💼', '👨‍💼', '👩‍🔬', '👨‍🔬',
  ];

  static const List<String> characters = [
    '🤖', '👽', '👾', '🤡', '👻', '💀', '👽', '🎃',
    '🦄', '🐉', '🦊', '🐱', '🐶', '🐼', '🐨', '🐯',
    '💕', '💖', '💗', '💓', '💝', '🌟', '✨', '🔥',
  ];

  static const List<String> professions = [
    '⚖️', '💰', '📚', '🧠', '💪', '🚀', '🎨', '🎭',
    '🎵', '🎬', '✈️', '🚗', '🏠', '🍽️', '☕', '🎮',
  ];

  static List<String> get all => [...people, ...characters, ...professions];
}
