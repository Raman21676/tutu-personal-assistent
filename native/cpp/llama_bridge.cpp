/**
 * llama_bridge.cpp - FFI Bridge for llama.cpp
 * 
 * Simplified C interface for Dart to interact with llama.cpp
 */

#include <cstdint>
#include <cstring>
#include <string>
#include <mutex>

#ifdef __cplusplus
extern "C" {
#endif

// Global state
static std::mutex g_mutex;
static bool g_model_loaded = false;
static std::string g_last_error;
static int32_t g_n_ctx = 2048;

// ============================================================================
// Initialization
// ============================================================================

void llm_init() {
    // Initialize any global state
}

void llm_deinit() {
    std::lock_guard<std::mutex> lock(g_mutex);
    g_model_loaded = false;
}

// ============================================================================
// Error Handling
// ============================================================================

const char* llm_get_last_error() {
    std::lock_guard<std::mutex> lock(g_mutex);
    return g_last_error.c_str();
}

static void set_error(const std::string& error) {
    std::lock_guard<std::mutex> lock(g_mutex);
    g_last_error = error;
}

// ============================================================================
// Model Management
// ============================================================================

int32_t llm_load_model(const char* model_path, int32_t n_ctx, int32_t n_threads) {
    std::lock_guard<std::mutex> lock(g_mutex);
    
    if (model_path == nullptr) {
        set_error("Model path is null");
        return -1;
    }
    
    // Validate file exists
    FILE* file = fopen(model_path, "rb");
    if (!file) {
        set_error("Model file not found");
        return -1;
    }
    fclose(file);
    
    // In production: Load actual llama.cpp model here
    // For now, simulate success
    g_n_ctx = n_ctx > 0 ? n_ctx : 2048;
    g_model_loaded = true;
    
    return 0;
}

int32_t llm_is_model_loaded() {
    std::lock_guard<std::mutex> lock(g_mutex);
    return g_model_loaded ? 1 : 0;
}

void llm_unload_model() {
    std::lock_guard<std::mutex> lock(g_mutex);
    g_model_loaded = false;
}

// ============================================================================
// Inference
// ============================================================================

int32_t llm_generate(const char* prompt, char* output_buffer, int32_t buffer_size) {
    if (prompt == nullptr || output_buffer == nullptr || buffer_size <= 0) {
        set_error("Invalid parameters");
        return -1;
    }
    
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        if (!g_model_loaded) {
            set_error("No model loaded");
            return -1;
        }
    }
    
    // In production: Run actual inference with llama.cpp
    // For now, return a placeholder response
    const char* placeholder = "I'm a local AI assistant running on your device! I process everything locally without needing an internet connection. Your privacy is completely protected.";
    
    int32_t len = strlen(placeholder);
    if (len >= buffer_size) {
        len = buffer_size - 1;
    }
    
    memcpy(output_buffer, placeholder, len);
    output_buffer[len] = '\0';
    
    return len;
}

// ============================================================================
// Tokenization
// ============================================================================

int32_t llm_tokenize(const char* text) {
    if (text == nullptr) {
        return -1;
    }
    
    // Rough estimate: 1 token ~ 4 characters
    int32_t len = strlen(text);
    return len / 4;
}

// ============================================================================
// Model Information
// ============================================================================

int32_t llm_get_context_size() {
    std::lock_guard<std::mutex> lock(g_mutex);
    return g_model_loaded ? g_n_ctx : 0;
}

int32_t llm_get_vocab_size() {
    return 49152; // SmolLM2 vocab size
}

int32_t llm_has_gpu_support() {
    // Check for GPU support
    #ifdef GGML_USE_VULKAN
        return 1;
    #elif defined(GGML_USE_METAL)
        return 1;
    #elif defined(GGML_USE_CUDA)
        return 1;
    #else
        return 0;
    #endif
}

void llm_get_system_info(char* buffer, int32_t buffer_size) {
    std::string info = "Local LLM (SmolLM2-360M)\n";
    info += "Threads: 4\n";
    info += "GPU: ";
    info += llm_has_gpu_support() ? "YES" : "NO";
    
    strncpy(buffer, info.c_str(), buffer_size - 1);
    buffer[buffer_size - 1] = '\0';
}

#ifdef __cplusplus
}
#endif
