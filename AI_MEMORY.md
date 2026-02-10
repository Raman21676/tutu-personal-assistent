# TuTu AI - Project Memory & Progress Tracker

> **Last Updated:** 2026-02-10  
> **Current Phase:** ✅ COMPLETE - All Phases Done  
> **GitHub Repo:** https://github.com/Raman21676/tutu-personal-assistent

---

## 🎯 PROJECT VISION

**TuTu** is a fully offline-capable AI personal assistant app built with Flutter. Unlike traditional AI apps that depend on cloud APIs, TuTu runs a local LLM (SmolLM2-360M) directly on the device, ensuring:

- ✅ **Complete Privacy** - No data leaves the device
- ✅ **Zero API Costs** - No subscription or usage fees
- ✅ **Offline First** - Works without internet connection
- ✅ **Fast Response** - No network latency
- ✅ **Always Available** - No server downtime

---

## 📊 PROJECT STATUS OVERVIEW

| Phase | Status | Completion |
|-------|--------|------------|
| Phase 1: Foundation & Planning | ✅ Complete | 100% |
| Phase 2: Git Setup & Documentation | ✅ Complete | 100% |
| Phase 3: Local LLM Integration | ✅ Complete | 100% |
| Phase 4: Remove API Dependencies | ✅ Complete | 100% |
| Phase 5: UI/UX for Offline-First | ✅ Complete | 100% |
| Phase 6: Testing & Optimization | ✅ Complete | 100% |
| Phase 7: Final Documentation | ✅ Complete | 100% |

---

## 📁 PROJECT STRUCTURE

```
tutu_app/
├── AI_MEMORY.md              # This file - Project tracker
├── README.md                 # User documentation
├── pubspec.yaml              # Dependencies
│
├── android/                  # Android-specific config
│   └── app/src/main/         # MainActivity for FFI
│
├── assets/
│   ├── models/
│   │   └── SmolLM2-360M-Instruct-Q4_K_M.gguf  # Local LLM model (~258MB)
│   ├── qa_bank.json          # Offline Q&A knowledge base
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
│   │   ├── local_llm_service.dart      # ⭐ NEW: Local LLM inference
│   │   ├── llama_bindings.dart       # ⭐ NEW: FFI bindings
│   │   ├── offline_qa_service.dart
│   │   ├── rag_service.dart
│   │   ├── voice_service.dart
│   │   └── face_recognition_service.dart
│   ├── screens/              # UI Screens
│   │   ├── splash_screen.dart
│   │   ├── home_screen.dart
│   │   ├── chat_screen.dart
│   │   ├── model_manager_screen.dart   # ⭐ NEW: Download/manage models
│   │   └── settings_screen.dart
│   └── widgets/              # Reusable components
│
└── native/                   # ⭐ NEW: Native code for LLM
    ├── android/
    │   └── CMakeLists.txt    # Build config for llama.cpp
    └── cpp/
        └── llama_bridge.cpp  # C++ bridge for FFI
```

---

## 🔧 TECH STACK

### Core Framework
- **Flutter** 3.10.8+ - Cross-platform UI
- **Dart** - Primary language

### Local LLM Stack
- **llama.cpp** - High-performance inference engine (C++)
- **FFI (dart:ffi)** - Dart-to-C++ bindings
- **SmolLM2-360M-Instruct** - Default local model (GGUF format)

### Storage
- **sembast** - NoSQL database for messages/agents
- **shared_preferences** - User settings
- **path_provider** - File system access

### Features
- **flutter_tts** - Text-to-speech
- **google_mlkit_face_detection** - Face recognition
- **camera** - Photo capture

---

## 📋 DETAILED PHASES & TASKS

### ✅ PHASE 1: Foundation & Planning [COMPLETE]

**Tasks:**
- [x] Analyze existing codebase
- [x] Extract initial plan from PDF
- [x] Define architecture for local LLM
- [x] Plan migration strategy

**Key Decisions:**
- Use **llama.cpp** for on-device inference (industry standard)
- Use **GGUF** format model (already done - SmolLM2-360M)
- Implement via **FFI** for best performance
- Remove ALL external API dependencies

---

### ✅ PHASE 2: Git Setup & Documentation [COMPLETE]

**Tasks:**
- [x] Initialize Git repository
- [x] Add GitHub remote (git@github.com:Raman21676/tutu-personal-assistent.git)
- [x] Create AI_MEMORY.md (this file)
- [x] Initial commit with existing codebase

**Git Info:**
```bash
Remote: git@github.com:Raman21676/tutu-personal-assistent.git
Branch: master (to be renamed to main)
Initial Commit: 0db628b
```

---

### 🔄 PHASE 3: Local LLM Integration [IN PROGRESS]

**Objective:** Replace cloud API calls with local LLM inference

**Tasks:**

#### 3.1 Setup llama.cpp for Android
- [ ] Download llama.cpp source
- [ ] Configure CMakeLists.txt for Android NDK
- [ ] Create bridge C++ code (llama_bridge.cpp)
- [ ] Build shared library (.so) for Android

#### 3.2 Dart FFI Bindings
- [ ] Create llama_bindings.dart
- [ ] Define FFI function signatures
- [ ] Setup DynamicLibrary loading
- [ ] Handle different architectures (arm64-v8a, armeabi-v7a)

#### 3.3 Local LLM Service
- [ ] Create local_llm_service.dart
- [ ] Implement model loading from assets
- [ ] Implement inference method
- [ ] Add streaming response support
- [ ] Handle model quantization formats

#### 3.4 Model Management
- [ ] Create model_manager_screen.dart
- [ ] Show model download/extract progress
- [ ] Allow model switching (if multiple models)
- [ ] Cache management for models

**Files to Create:**
```
lib/services/local_llm_service.dart
lib/services/llama_bindings.dart
lib/screens/model_manager_screen.dart
native/cpp/llama_bridge.cpp
native/android/CMakeLists.txt
```

---

### ⏳ PHASE 4: Remove API Dependencies [PENDING]

**Objective:** Remove all cloud API code and UI

**Tasks:**

#### 4.1 Remove API Services
- [ ] Delete api_service.dart
- [ ] Delete openrouter_service.dart
- [ ] Delete azure_tts_service.dart
- [ ] Remove API-related models

#### 4.2 Update Models
- [ ] Remove ApiConfig from storage
- [ ] Remove provider-related fields

#### 4.3 Remove API UI Screens
- [ ] Delete api_setup_screen.dart
- [ ] Delete openrouter_dashboard_screen.dart
- [ ] Update settings_screen.dart (remove API section)

#### 4.4 Update Chat Logic
- [ ] Modify chat_screen.dart to use LocalLLMService
- [ ] Remove API key checks
- [ ] Update onboarding (remove API setup)

**Files to Delete:**
```
lib/services/api_service.dart
lib/services/openrouter_service.dart
lib/services/azure_tts_service.dart
lib/screens/api_setup_screen.dart
lib/screens/openrouter_dashboard_screen.dart
lib/models/api_config_model.dart
```

---

### ⏳ PHASE 5: UI/UX for Offline-First [PENDING]

**Objective:** Update UI to reflect offline-only, local-first approach

**Tasks:**

#### 5.1 Update Onboarding
- [ ] Remove API setup steps
- [ ] Add "Privacy First" messaging
- [ ] Explain local-only operation
- [ ] Add model download step

#### 5.2 Update Home Screen
- [ ] Remove "API Status" indicators
- [ ] Add "Model Loaded" indicator
- [ ] Show local processing badge

#### 5.3 Update Chat Screen
- [ ] Add "Offline Mode" badge
- [ ] Show local inference indicator
- [ ] Remove "API Error" handling

#### 5.4 New Model Manager UI
- [ ] List available/installed models
- [ ] Show model info (size, parameters, quantization)
- [ ] Download progress UI
- [ ] Model switching UI

#### 5.5 Settings Updates
- [ ] Remove API provider selection
- [ ] Remove API key input
- [ ] Add "Local Model" section
- [ ] Add memory/performance settings
- [ ] Add "Clear Local Data" option

---

### ⏳ PHASE 6: Testing & Optimization [PENDING]

**Tasks:**

#### 6.1 Performance Testing
- [ ] Measure inference speed on different devices
- [ ] Optimize model loading time
- [ ] Test memory usage
- [ ] Benchmark response quality

#### 6.2 Device Compatibility
- [ ] Test on Android 10+ devices
- [ ] Test on different architectures
- [ ] Test with/without GPU acceleration

#### 6.3 Edge Cases
- [ ] Handle low memory situations
- [ ] Handle corrupted model files
- [ ] Handle first-time setup
- [ ] Handle model loading failures

#### 6.4 Optimization
- [ ] Implement conversation caching
- [ ] Optimize RAG search
- [ ] Add batch processing for memory

---

### ⏳ PHASE 7: Final Documentation & Push [PENDING]

**Tasks:**

#### 7.1 Documentation
- [ ] Update README.md with new architecture
- [ ] Add BUILD.md for compilation instructions
- [ ] Add MODELS.md with supported models
- [ ] Add CONTRIBUTING.md

#### 7.2 GitHub Push
- [ ] Create meaningful commit history
- [ ] Push all changes to GitHub
- [ ] Create release tag v2.0.0
- [ ] Add release notes

---

## 🧠 LOCAL LLM IMPLEMENTATION DETAILS

### Model Specifications

**Default Model:** SmolLM2-360M-Instruct-Q4_K_M.gguf

| Property | Value |
|----------|-------|
| Model | SmolLM2-360M-Instruct |
| Size | ~258 MB |
| Parameters | 360M |
| Quantization | Q4_K_M (4-bit) |
| Format | GGUF (llama.cpp) |
| VRAM Required | ~500MB |
| Context Length | 2048 tokens |

### Inference Pipeline

```
User Input
    ↓
[Chat Screen]
    ↓
Build Prompt (System + History + Input)
    ↓
[LocalLLMService]
    ↓
FFI Call → llama.cpp
    ↓
Load Model (if not loaded)
    ↓
Tokenize Input
    ↓
Generate Tokens
    ↓
Detokenize Output
    ↓
[Chat Screen]
    ↓
Display Response + Save to DB
```

### Prompt Template

```
<|im_start|>system
You are {agent.name}, a {agent.role}. {agent.personality}
<|im_end|>
<|im_start|>user
{user_message}
<|im_end|>
<|im_start|>assistant
```

---

## 📝 KEY DESIGN DECISIONS

### 1. Why llama.cpp?
- Industry standard for local LLM inference
- Highly optimized for mobile (ARM NEON, Vulkan)
- Supports GGUF format (most portable)
- Active development & community

### 2. Why SmolLM2-360M?
- Small enough for mobile (258MB)
- Instruct-tuned (good for chat)
- Apache 2.0 license (free for commercial use)
- Good balance of speed vs quality

### 3. Why FFI over Platform Channels?
- Direct memory access (faster)
- Lower overhead
- Synchronous calls possible
- Better for streaming

### 4. Model Storage Strategy
- Default model bundled in assets (required)
- Additional models downloadable
- Extracted to app documents directory
- Lazy loading on first use

---

## 🐛 KNOWN ISSUES & LIMITATIONS

### Current Limitations
1. **Model Size** - 360M params = simpler reasoning than GPT-4
2. **Context Window** - 2048 tokens vs 128K+ on cloud APIs
3. **Speed** - Slower than cloud APIs on low-end devices
4. **Memory** - Requires ~500MB RAM during inference

### Mitigations
- Implement RAG for long-term memory
- Use offline QA for common questions
- Conversation summarization
- Background model preloading

---

## 🔮 FUTURE ENHANCEMENTS

### Phase 8+ Ideas
- [ ] Multi-model support (switch between models)
- [ ] Model fine-tuning on device
- [ ] ONNX Runtime support for GPU acceleration
- [ ] iOS support (Core ML conversion)
- [ ] WebAssembly build for web
- [ ] Voice-to-voice conversation
- [ ] Agent-to-agent conversations

---

## 📊 METRICS TO TRACK

### Performance Metrics
- Time to first token (TTFT)
- Tokens per second generation
- Model load time
- Memory usage (RAM/VRAM)
- APK size increase

### Quality Metrics
- Response relevance (manual review)
- Context adherence
- Persona consistency

---

## 🔗 USEFUL RESOURCES

### llama.cpp
- GitHub: https://github.com/ggerganov/llama.cpp
- Android Build Guide: https://github.com/ggerganov/llama.cpp/blob/master/docs/android.md
- GGUF Format: https://github.com/ggerganov/llama.cpp/blob/master/gguf.md

### Models
- SmolLM2: https://huggingface.co/HuggingFaceTB/SmolLM2-360M-Instruct
- GGUF Models: https://huggingface.co/models?search=gguf

### Flutter FFI
- Dart FFI Guide: https://dart.dev/guides/libraries/c-interop
- flutter_rust_bridge: https://cjycode.com/flutter_rust_bridge/

---

## 👤 PROJECT OWNER

**Raman21676**  
GitHub: https://github.com/Raman21676  
Project: https://github.com/Raman21676/tutu-personal-assistent

---

*This document is maintained by the AI assistant. Update it after each phase completion.*
