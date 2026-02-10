# TuTu - Personal AI Agent Manager

TuTu is a comprehensive Flutter Android app that serves as your personal AI agent manager with persistent memory, local RAG (Retrieval Augmented Generation) system, voice synthesis, facial recognition, and OpenRouter integration.

## 🌟 Features

### Core Features
- **AI Agent Management**: Create and customize multiple AI companions with unique personalities
- **Persistent Memory**: Multi-layer memory system (Active, Short-term, Long-term with RAG)
- **Offline QA System**: 1000+ question knowledge base for offline responses
- **Multi-Provider Support**: OpenAI, Anthropic, Gemini, DeepSeek, OpenRouter, Custom endpoints

### Advanced Features
- **Voice Synthesis**: Text-to-speech with customizable pitch, rate, and gender
- **Face Recognition**: Local face detection and recognition using ML Kit
- **OpenRouter Integration**: Full dashboard with balance tracking and model selection
- **Privacy First**: All data stored locally, no cloud dependencies

## 🏗️ Project Structure

```
tutu_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/                      # Data models
│   │   ├── agent_model.dart
│   │   ├── message_model.dart
│   │   ├── memory_model.dart
│   │   ├── face_model.dart
│   │   ├── qa_bank_model.dart
│   │   └── api_config_model.dart
│   ├── services/                    # Business logic
│   │   ├── storage_service.dart     # Local database (Sembast)
│   │   ├── api_service.dart         # LLM API communication
│   │   ├── rag_service.dart         # RAG implementation
│   │   ├── offline_qa_service.dart  # Offline Q&A system
│   │   ├── voice_service.dart       # TTS functionality
│   │   ├── face_recognition_service.dart
│   │   └── openrouter_service.dart
│   ├── screens/                     # UI Screens
│   │   ├── splash_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── home_screen.dart
│   │   ├── chat_screen.dart
│   │   ├── agent_list_screen.dart
│   │   ├── create_agent_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── api_setup_screen.dart
│   │   ├── voice_settings_screen.dart
│   │   ├── openrouter_dashboard_screen.dart
│   │   └── camera_screen.dart
│   ├── widgets/                     # Reusable UI components
│   │   ├── agent_card.dart
│   │   ├── message_bubble.dart
│   │   ├── custom_app_bar.dart
│   │   └── typing_indicator.dart
│   └── utils/                       # Utilities
│       ├── constants.dart
│       ├── themes.dart
│       └── helpers.dart
├── assets/
│   ├── qa_bank.json                 # Offline knowledge base
│   └── images/
└── pubspec.yaml
```

## 📦 Dependencies

```yaml
dependencies:
  # Storage & Database
  shared_preferences: ^2.2.2
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  sembast: ^3.5.0
  
  # Networking
  http: ^1.1.0
  
  # State Management
  provider: ^6.1.1
  
  # Utilities
  uuid: ^4.2.1
  intl: ^0.18.1
  path: ^1.8.3
  
  # UI
  flutter_markdown: ^0.6.18
  
  # Voice & Camera
  flutter_tts: ^3.8.5
  camera: ^0.10.5+9
  google_mlkit_face_detection: ^0.9.0
  image: ^4.1.3
  
  # Web & URL
  url_launcher: ^6.2.1
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.10.8 or higher
- Android SDK
- IDE (VS Code, Android Studio, etc.)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd tutu_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Android Setup

Add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Internet -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Camera -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Text-to-Speech -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

## 🎯 Usage

### First Launch
1. Complete the onboarding process
2. Set up your API key (OpenAI, OpenRouter, etc.) or skip for offline mode
3. Start chatting with TuTu, the default assistant

### Creating an Agent
1. Tap the "+" button on the home screen
2. Choose a role (Girlfriend, Lawyer, Teacher, etc.)
3. Customize name, personality, avatar, and voice
4. Start chatting!

### Using Voice
1. Go to Settings > Voice to configure TTS
2. In chat, tap the speaker icon on any message
3. Enable "Auto-speak" for automatic voice responses

### Face Recognition
1. Tap the camera icon in chat
2. Position the face in the frame
3. TuTu will recognize known faces or let you register new ones

### OpenRouter Integration
1. Go to Settings > OpenRouter Dashboard
2. View balance, usage, and available models
3. Select your preferred model for each agent

## 🔧 Configuration

### API Providers

#### OpenAI
- Get API key: https://platform.openai.com/api-keys
- Default model: gpt-4-turbo-preview

#### OpenRouter
- Sign up: https://openrouter.ai
- Access multiple models through single API
- View pricing: https://openrouter.ai/models

#### Anthropic (Claude)
- Get API key: https://console.anthropic.com/settings/keys
- Default model: claude-3-sonnet-20240229

#### Google Gemini
- Get API key: https://makersuite.google.com/app/apikey
- Default model: gemini-pro

#### DeepSeek
- Get API key: https://platform.deepseek.com/api_keys
- Default model: deepseek-chat

## 🔒 Privacy & Security

- **Local Storage**: All data stored on device using Sembast/SQLite
- **Face Data**: Never leaves your device, processed locally with ML Kit
- **Conversations**: Stored locally, not synced to cloud
- **API Keys**: Stored securely in SharedPreferences (consider encryption for production)
- **Offline First**: Core functionality works without internet

## 🧠 Memory System

TuTu implements a 4-layer memory system:

1. **Active Memory**: Last 20 messages in RAM
2. **Short-term Memory**: Last 500 messages in SQLite
3. **Long-term Memory**: All messages with TF-IDF search
4. **Episodic Memory**: Important events, summaries, preferences

### RAG Implementation
- Keyword extraction and indexing
- TF-IDF scoring for relevance
- Auto-summarization every 100 messages
- Memory injection into LLM prompts

## 🗣️ Voice Synthesis

- Uses `flutter_tts` package
- Adjustable speech rate, pitch, and volume
- Male/Female voice selection per agent
- Offline text-to-speech support

## 👤 Face Recognition

- Uses Google ML Kit Face Detection
- Custom face encoding (20-30 dimensional vector)
- Euclidean distance matching (threshold: 0.6)
- Multiple face versions per person
- Completely offline processing

## 📊 OpenRouter Dashboard

- Real-time balance tracking
- Usage statistics
- Model browser with pricing
- Category filtering (Free, Cheap, Balanced, Premium)
- Direct top-up links

## 🎨 Customization

### Themes
- Light and Dark mode support
- Material Design 3
- Purple/Blue gradient accent colors

### Agent Personalities
Create agents with custom:
- Names and avatars
- Roles and personalities
- Voice gender
- Preferred AI models

## 🐛 Troubleshooting

### Common Issues

**API Key Not Working**
- Verify the key is copied correctly
- Check provider selection matches key type
- Test connection in API Setup

**Voice Not Working**
- Check TTS engine is installed on device
- Verify voice settings in Settings > Voice
- Some devices may need specific TTS app

**Camera Not Working**
- Grant camera permissions in Android settings
- Ensure device has camera hardware
- Check for conflicting camera apps

**App Crashes on Startup**
- Clear app data and restart
- Check Flutter SDK version compatibility
- Verify all dependencies are installed

## 📝 Todo / Roadmap

- [ ] Push notifications for agent messages
- [ ] Cloud backup/sync option
- [ ] Agent-to-agent conversations
- [ ] Image generation integration
- [ ] Desktop/Web support
- [ ] Widget support for home screen
- [ ] Import/export agent configurations
- [ ] Community agent marketplace

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- Flutter Team for the amazing framework
- OpenAI, Anthropic, Google for AI APIs
- OpenRouter for unified API access
- ML Kit team for on-device ML capabilities

## 📞 Support

For support, please:
1. Check this README and in-app help
2. Visit Settings > Help & Support
3. Open an issue on GitHub

---

Built with ❤️ using Flutter
