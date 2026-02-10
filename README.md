# TuTu - Personal Offline AI Assistant

TuTu is a fully offline-capable AI personal assistant built with Flutter. Unlike traditional AI apps that depend on cloud APIs, TuTu runs a local LLM (SmolLM2-360M) directly on your device - ensuring complete privacy, zero costs, and 100% availability.

## 🌟 Key Features

### 🔒 Privacy First
- **100% Offline** - No internet connection required
- **No Data Leaves Device** - All AI processing happens locally
- **Zero API Costs** - No subscriptions, no usage fees
- **Complete Control** - Your data, your device, your rules

### 🤖 AI Capabilities
- **Local LLM** - SmolLM2-360M runs directly on your device
- **Custom Agents** - Create multiple AI companions with unique personalities
- **Persistent Memory** - Agents remember conversations and learn preferences
- **Offline QA** - 1000+ question knowledge base

### 🎨 Advanced Features
- **Voice Synthesis** - Offline text-to-speech
- **Face Recognition** - Local face detection and recognition using ML Kit
- **RAG System** - Retrieval Augmented Generation for context-aware responses
- **Multi-Agent** - Switch between different AI personas

## 🏗️ Project Structure

```
tutu_app/
├── AI_MEMORY.md              # Project progress tracker
├── README.md                 # This file
├── pubspec.yaml              # Dependencies
│
├── android/                  # Android-specific config with NDK
│
├── assets/
│   ├── models/
│   │   └── SmolLM2-360M-Instruct-Q4_K_M.gguf  # Local LLM (~258MB)
│   ├── qa_bank.json          # Offline knowledge base
│   └── images/               # App images
│
├── lib/
│   ├── main.dart             # App entry point
│   ├── models/               # Data models
│   │   ├── agent_model.dart
│   │   ├── message_model.dart
│   │   ├── memory_model.dart
│   │   └── qa_bank_model.dart
│   ├── services/             # Business logic
│   │   ├── storage_service.dart
│   │   ├── local_llm_service.dart     # ⭐ Local LLM inference
│   │   ├── llama_bindings.dart        # ⭐ FFI bindings
│   │   ├── rag_service.dart
│   │   ├── offline_qa_service.dart
│   │   ├── voice_service.dart
│   │   └── face_recognition_service.dart
│   ├── screens/              # UI Screens
│   │   ├── splash_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── home_screen.dart
│   │   ├── chat_screen.dart
│   │   ├── agent_list_screen.dart
│   │   ├── create_agent_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── model_manager_screen.dart  # ⭐ Manage AI models
│   │   ├── voice_settings_screen.dart
│   │   └── camera_screen.dart
│   ├── widgets/              # Reusable UI components
│   └── utils/                # Utilities
│
└── native/                   # ⭐ Native code for LLM
    ├── android/
    │   └── CMakeLists.txt    # Android NDK build config
    └── cpp/
        └── llama_bridge.cpp  # C++ FFI bridge
```

## 📦 Dependencies

```yaml
dependencies:
  # Core
  flutter:
    sdk: flutter
  
  # FFI for native C++ bindings
  ffi: ^2.1.0
  
  # Storage & Database
  shared_preferences: ^2.2.2
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  sembast: ^3.5.0
  
  # State Management
  provider: ^6.1.1
  
  # Utilities
  uuid: ^4.2.1
  intl: ^0.18.1
  path: ^1.8.3
  
  # UI
  flutter_markdown: ^0.6.18
  animations: ^2.0.11
  flutter_animate: ^4.5.2
  
  # Voice
  flutter_tts: ^4.0.2
  speech_to_text: ^7.0.0
  permission_handler: ^11.3.0
  just_audio: ^0.9.42
  
  # Camera & Vision
  camera: ^0.11.0
  image_picker: ^1.0.7
  google_mlkit_face_detection: ^0.13.0
  image: ^4.1.3
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.10.8 or higher
- Android SDK with NDK (25.1.8937393)
- IDE (VS Code, Android Studio)
- 2GB+ free space for model files

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Raman21676/tutu-personal-assistent.git
   cd tutu_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Build the native library** (Optional - for custom builds)
   ```bash
   # The app includes a pre-built native bridge
   # For custom builds with full llama.cpp:
   cd native/cpp
   # Follow llama.cpp Android build instructions
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Android Setup

Add the following to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Camera -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Text-to-Speech -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

## 🎯 Usage

### First Launch
1. Complete the onboarding process
2. The app automatically extracts and loads the AI model (may take 1-2 minutes on first launch)
3. Start chatting with TuTu, your default AI assistant

### Creating an Agent
1. Tap the "+" button on the home screen
2. Choose a role (Girlfriend, Lawyer, Teacher, etc.)
3. Customize name, personality, avatar, and voice
4. Start chatting!

### Managing Models
1. Go to Settings > Manage Models
2. View installed models and their details
3. Download additional models (optional)
4. Switch between models

### Using Voice
1. Go to Settings > Voice to configure TTS
2. In chat, tap the speaker icon on any message
3. Enable "Auto-speak" for automatic voice responses

### Face Recognition
1. Tap the camera icon in chat
2. Position the face in the frame
3. TuTu will recognize known faces or let you register new ones

## 🔒 Privacy & Security

### Local-Only Processing
- **AI Model**: Runs entirely on your device using llama.cpp
- **Face Recognition**: Processed locally with Google ML Kit
- **Voice Synthesis**: Device TTS, no cloud calls
- **Data Storage**: All data stored in app documents directory

### What This Means
- ✅ No account required
- ✅ No API keys to manage
- ✅ No internet connection needed
- ✅ No data sent to servers
- ✅ No usage limits
- ✅ No subscription fees

### Data You Control
- Conversation history
- Agent configurations
- Face recognition data
- Voice preferences
- Memory embeddings

## 🧠 Technical Details

### Local LLM Implementation

**Model**: SmolLM2-360M-Instruct-Q4_K_M
- Size: ~258 MB
- Parameters: 360M
- Quantization: Q4_K_M (4-bit)
- Context Length: 2048 tokens
- Inference: llama.cpp via FFI

**Performance**
- First load: 5-15 seconds (model extraction)
- Subsequent loads: 1-3 seconds
- Inference speed: 5-20 tokens/second (device dependent)
- Memory usage: ~500MB during inference

### Architecture

```
User Input
    ↓
Chat Screen
    ↓
LocalLLMService (Dart)
    ↓
FFI Bindings (dart:ffi)
    ↓
Native Bridge (C++)
    ↓
llama.cpp (Inference)
    ↓
Response
```

## 🐛 Troubleshooting

### Model Loading Issues
**Problem**: "Failed to load model" error
**Solution**: 
- Ensure sufficient storage space (500MB+ free)
- Restart the app
- Check Settings > Manage Models for model integrity

### Slow Responses
**Problem**: AI responses are slow
**Solution**:
- Lower context size in settings (reduces memory usage)
- Close other apps to free RAM
- Use a more powerful device (newer phones perform better)

### Out of Memory
**Problem**: App crashes during inference
**Solution**:
- The app will automatically fall back to offline QA
- Clear conversation history in Settings
- Use shorter messages

### Face Recognition Not Working
**Problem**: Camera or face detection issues
**Solution**:
- Grant camera permissions in Android settings
- Ensure adequate lighting
- Try different angles

## 🗺️ Roadmap

### Phase 1: Core (✅ Complete)
- [x] Local LLM integration
- [x] FFI bindings
- [x] Model management
- [x] Basic chat interface

### Phase 2: Features (✅ Complete)
- [x] Offline QA system
- [x] RAG implementation
- [x] Voice synthesis
- [x] Face recognition

### Phase 3: Polish (🔄 In Progress)
- [ ] Streaming responses
- [ ] Model quantization options
- [ ] Conversation export/import
- [ ] Widget support

### Phase 4: Expansion (📅 Planned)
- [ ] iOS support
- [ ] Larger model support (1.7B+)
- [ ] Agent-to-agent conversations
- [ ] Community model marketplace

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

- **Flutter Team** for the amazing framework
- **llama.cpp** by Georgi Gerganov for on-device LLM inference
- **SmolLM2** by HuggingFace for the efficient local model
- **Google ML Kit** for on-device face detection

## 📞 Support

For support, please:
1. Check this README and in-app help
2. Visit Settings > Help & Support
3. Open an issue on GitHub: https://github.com/Raman21676/tutu-personal-assistent

---

Built with ❤️ using Flutter & llama.cpp

**Privacy First. Always Available. Completely Yours.**
