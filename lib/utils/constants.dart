/// App Constants - Centralized configuration values
class AppConstants {
  // App Info
  static const String appName = 'TuTu';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Your Personal AI Agent Manager';

  // Storage Keys
  static const String keyApiConfig = 'api_config';
  static const String keyUserName = 'user_name';
  static const String keyUserPreferences = 'user_preferences';
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyVoiceSettings = 'voice_settings';
  static const String keyDarkMode = 'dark_mode';
  static const String keyAutoSpeak = 'auto_speak';

  // Limits
  static const int maxAgents = 20;
  static const int maxMessageHistory = 1000;
  static const int maxActiveMemory = 20;
  static const int maxRetrievedMemories = 5;
  static const int maxFaceDatabase = 100;
  static const int maxImageSize = 512;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 60);
  static const Duration connectionTimeout = Duration(seconds: 10);

  // API Retry
  static const int maxRetries = 3;
  static const Duration baseRetryDelay = Duration(seconds: 1);

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
  static const String apiSetup = '/api-setup';
  static const String voiceSettings = '/voice-settings';
  static const String camera = '/camera';
  static const String openRouterDashboard = '/openrouter-dashboard';
}

/// Asset paths
class Assets {
  static const String qaBank = 'assets/qa_bank.json';
  static const String imagesDir = 'assets/images/';
}

/// Default messages
class DefaultMessages {
  static const String welcomeMessage = 
      'Hello! I\'m TuTu, your AI assistant. I can help you create agents, answer questions about the app, or just chat. What would you like to do?';
  
  static const String apiKeyRequired = 
      'To chat with me and other agents, please set up an API key in Settings. You can use OpenAI, OpenRouter, or other providers.';
  
  static const String offlineMessage = 
      'I\'m currently in offline mode. I can answer questions from my knowledge base, but for more advanced conversations, please connect to the internet and set up an API key.';
  
  static const String errorMessage = 
      'Sorry, something went wrong. Please try again or check your connection.';
  
  static const String typingIndicator = 'Typing...';
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
