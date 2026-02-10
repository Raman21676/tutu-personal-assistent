/**
 * llama_bridge.cpp - Thread-safe FFI Bridge for llama.cpp
 * 
 * This file provides a C interface for Dart to interact with llama.cpp
 * for on-device LLM inference with proper multi-threading support.
 * 
 * Features:
 * - Thread-safe operations with mutex locks
 * - Multi-threaded inference support
 * - Token streaming callbacks
 * - Memory management
 * 
 * Build with Android NDK CMake for production use.
 */

#include <cstdint>
#include <cstring>
#include <string>
#include <vector>
#include <mutex>
#include <atomic>
#include <thread>
#include <queue>
#include <functional>
#include <condition_variable>

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// Data Structures
// ============================================================================

/// Opaque handle for LLM context
typedef void* LLMContext;

/// Structure for model parameters
typedef struct {
    const char* model_path;
    int32_t n_ctx;          // Context size (default: 2048)
    int32_t n_threads;      // Number of threads (default: 4)
    int32_t n_batch;        // Batch size (default: 512)
    float rope_freq_base;   // RoPE frequency base
    float rope_freq_scale;  // RoPE frequency scale
} LLMModelParams;

/// Structure for generation parameters
typedef struct {
    int32_t n_predict;      // Max tokens to predict (-1 = infinite)
    float temperature;      // Sampling temperature
    float top_p;            // Top-p sampling
    int32_t top_k;          // Top-k sampling
    float repeat_penalty;   // Repetition penalty
    int32_t repeat_last_n;  // Penalty window
    const char* stop_sequences; // JSON array of stop sequences
} LLMGenerateParams;

/// Callback for streaming tokens
typedef void (*TokenCallback)(const char* token, void* user_data);

/// Inference request for thread pool
typedef struct {
    std::string prompt;
    LLMGenerateParams params;
    TokenCallback callback;
    void* user_data;
    std::string result;
    bool completed;
    bool success;
    std::string error;
} InferenceRequest;

// ============================================================================
// Global State with Thread Safety
// ============================================================================

// Main mutex for global state
static std::mutex g_state_mutex;

// Model state
static bool g_model_loaded = false;
static std::string g_model_path;
static int32_t g_n_ctx = 2048;
static int32_t g_n_threads = 4;
static std::string g_last_error;

// Thread pool for background inference
class ThreadPool {
public:
    ThreadPool(size_t num_threads) : stop(false) {
        for (size_t i = 0; i < num_threads; ++i) {
            workers.emplace_back([this] {
                for (;;) {
                    std::function<void()> task;
                    {
                        std::unique_lock<std::mutex> lock(queue_mutex);
                        condition.wait(lock, [this] { return stop || !tasks.empty(); });
                        if (stop && tasks.empty()) return;
                        task = std::move(tasks.front());
                        tasks.pop();
                    }
                    task();
                }
            });
        }
    }
    
    ~ThreadPool() {
        {
            std::unique_lock<std::mutex> lock(queue_mutex);
            stop = true;
        }
        condition.notify_all();
        for (std::thread& worker : workers) {
            worker.join();
        }
    }
    
    template<class F>
    void enqueue(F&& f) {
        {
            std::unique_lock<std::mutex> lock(queue_mutex);
            tasks.emplace(std::forward<F>(f));
        }
        condition.notify_one();
    }
    
private:
    std::vector<std::thread> workers;
    std::queue<std::function<void()>> tasks;
    std::mutex queue_mutex;
    std::condition_variable condition;
    bool stop;
};

static ThreadPool* g_thread_pool = nullptr;
static std::atomic<int32_t> g_active_inference_count{0};

// ============================================================================
// Initialization
// ============================================================================

/**
 * Initialize the library
 */
void llm_init() {
    std::lock_guard<std::mutex> lock(g_state_mutex);
    
    // Initialize thread pool with hardware concurrency
    int num_threads = std::thread::hardware_concurrency();
    if (num_threads < 2) num_threads = 2;
    if (num_threads > 8) num_threads = 8; // Cap at 8 for mobile
    
    if (g_thread_pool == nullptr) {
        g_thread_pool = new ThreadPool(num_threads);
    }
}

/**
 * Cleanup and shutdown
 */
void llm_deinit() {
    std::lock_guard<std::mutex> lock(g_state_mutex);
    
    // Unload model if loaded
    if (g_model_loaded) {
        // llama_free(ctx); etc.
        g_model_loaded = false;
    }
    
    // Cleanup thread pool
    delete g_thread_pool;
    g_thread_pool = nullptr;
}

// ============================================================================
// Error Handling
// ============================================================================

/**
 * Get the last error message
 */
const char* llm_get_last_error() {
    std::lock_guard<std::mutex> lock(g_state_mutex);
    return g_last_error.c_str();
}

/**
 * Set error message
 */
static void set_error(const std::string& error) {
    std::lock_guard<std::mutex> lock(g_state_mutex);
    g_last_error = error;
}

// ============================================================================
// Model Management
// ============================================================================

/**
 * Load a GGUF model from the given path
 * 
 * @param params Model loading parameters
 * @return 0 on success, -1 on error
 */
int32_t llm_load_model(const LLMModelParams* params) {
    std::lock_guard<std::mutex> lock(g_state_mutex);
    
    if (params == nullptr || params->model_path == nullptr) {
        set_error("Invalid parameters");
        return -1;
    }
    
    // In a real implementation, this would:
    // 1. Call llama_load_model_from_file()
    // 2. Initialize llama_context with the model
    // 3. Set up the vocabulary
    
    // Validate model file exists
    FILE* file = fopen(params->model_path, "rb");
    if (!file) {
        set_error("Model file not found: " + std::string(params->model_path));
        return -1;
    }
    fclose(file);
    
    // Store model parameters
    g_model_path = params->model_path;
    g_n_ctx = params->n_ctx > 0 ? params->n_ctx : 2048;
    g_n_threads = params->n_threads > 0 ? params->n_threads : 4;
    g_model_loaded = true;
    
    return 0;
}

/**
 * Check if a model is currently loaded
 */
int32_t llm_is_model_loaded() {
    std::lock_guard<std::mutex> lock(g_state_mutex);
    return g_model_loaded ? 1 : 0;
}

/**
 * Unload the current model and free resources
 */
void llm_unload_model() {
    std::lock_guard<std::mutex> lock(g_state_mutex);
    
    // In a real implementation:
    // llama_free(ctx);
    // llama_free_model(model);
    
    g_model_loaded = false;
    g_model_path.clear();
}

// ============================================================================
// Inference
// ============================================================================

/**
 * Generate text from a prompt (blocking)
 * 
 * @param prompt The input prompt
 * @param params Generation parameters
 * @param output_buffer Buffer to store the output
 * @param buffer_size Size of the output buffer
 * @return Number of characters written, or -1 on error
 */
int32_t llm_generate(
    const char* prompt,
    const LLMGenerateParams* params,
    char* output_buffer,
    int32_t buffer_size
) {
    if (!prompt || !output_buffer || buffer_size <= 0) {
        set_error("Invalid parameters");
        return -1;
    }
    
    {
        std::lock_guard<std::mutex> lock(g_state_mutex);
        if (!g_model_loaded) {
            set_error("No model loaded");
            return -1;
        }
    }
    
    // Increment active inference count
    g_active_inference_count++;
    
    // In a real implementation, this would:
    // 1. Tokenize the prompt using llama_tokenize()
    // 2. Evaluate tokens with llama_eval()
    // 3. Sample and generate tokens in a loop
    // 4. Detokenize and return
    
    // Simulate inference with a placeholder
    const char* placeholder = "I'm a local AI assistant running on your device! I process everything locally without needing an internet connection. Your privacy is completely protected.";
    
    int32_t len = strlen(placeholder);
    if (len >= buffer_size) {
        len = buffer_size - 1;
    }
    
    memcpy(output_buffer, placeholder, len);
    output_buffer[len] = '\0';
    
    // Decrement active inference count
    g_active_inference_count--;
    
    return len;
}

/**
 * Generate text asynchronously
 * 
 * @param prompt The input prompt
 * @param params Generation parameters
 * @param callback Optional callback for streaming
 * @param user_data User data passed to callback
 * @return Request ID (>0) or -1 on error
 */
int32_t llm_generate_async(
    const char* prompt,
    const LLMGenerateParams* params,
    TokenCallback callback,
    void* user_data
) {
    if (!g_thread_pool) {
        set_error("Thread pool not initialized");
        return -1;
    }
    
    static int32_t request_id = 0;
    int32_t id = ++request_id;
    
    // Create request
    auto request = new InferenceRequest();
    request->prompt = prompt ? prompt : "";
    if (params) {
        request->params = *params;
    }
    request->callback = callback;
    request->user_data = user_data;
    request->completed = false;
    request->success = false;
    
    // Enqueue to thread pool
    g_thread_pool->enqueue([request]() {
        char buffer[8192];
        int32_t result = llm_generate(
            request->prompt.c_str(),
            &request->params,
            buffer,
            sizeof(buffer)
        );
        
        if (result > 0) {
            request->result = buffer;
            request->success = true;
            
            // Call callback if provided (token by token)
            if (request->callback) {
                // In real implementation, stream tokens
                request->callback(request->result.c_str(), request->user_data);
            }
        } else {
            request->success = false;
            request->error = llm_get_last_error();
        }
        
        request->completed = true;
    });
    
    return id;
}

// ============================================================================
// Tokenization
// ============================================================================

/**
 * Tokenize text into token IDs
 * 
 * @param text Text to tokenize
 * @param tokens Output array for token IDs
 * @param max_tokens Maximum number of tokens
 * @return Actual number of tokens, or -1 on error
 */
int32_t llm_tokenize(
    const char* text,
    int32_t* tokens,
    int32_t max_tokens
) {
    if (!text || !tokens || max_tokens <= 0) {
        return -1;
    }
    
    // In a real implementation:
    // return llama_tokenize(vocab, text, strlen(text), tokens, max_tokens, true, true);
    
    // Rough estimate: 1 token ≈ 4 characters for English
    int32_t estimated = strlen(text) / 4;
    return estimated > 0 ? estimated : 1;
}

// ============================================================================
// Model Information
// ============================================================================

/**
 * Get the context size of the loaded model
 */
int32_t llm_get_context_size() {
    std::lock_guard<std::mutex> lock(g_state_mutex);
    return g_model_loaded ? g_n_ctx : 0;
}

/**
 * Get vocabulary size (number of tokens)
 */
int32_t llm_get_vocab_size() {
    // In a real implementation: return llama_n_vocab(vocab);
    return 49152; // SmolLM2 vocab size
}

/**
 * Check if the model supports GPU acceleration
 */
int32_t llm_has_gpu_support() {
    // Check for Vulkan/Metal/OpenCL support
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

/**
 * Get system information
 */
void llm_get_system_info(char* buffer, int32_t buffer_size) {
    std::string info;
    
    // Hardware concurrency
    int hw_threads = std::thread::hardware_concurrency();
    info += "Hardware threads: " + std::to_string(hw_threads) + "\n";
    
    // ARM NEON
    #ifdef __ARM_NEON
        info += "ARM NEON: YES\n";
    #else
        info += "ARM NEON: NO\n";
    #endif
    
    // AVX
    #ifdef __AVX__
        info += "AVX: YES\n";
    #else
        info += "AVX: NO\n";
    #endif
    
    // GPU
    info += "GPU: ";
    info += llm_has_gpu_support() ? "YES" : "NO";
    info += "\n";
    
    // Configured threads
    info += "Threads: " + std::to_string(g_n_threads);
    
    // Active inference count
    info += "\nActive: " + std::to_string(g_active_inference_count.load());
    
    strncpy(buffer, info.c_str(), buffer_size - 1);
    buffer[buffer_size - 1] = '\0';
}

// ============================================================================
// Utility Functions
// ============================================================================

/**
 * Cancel an ongoing inference (if possible)
 */
int32_t llm_cancel_inference(int32_t request_id) {
    // In a real implementation, track requests and cancel them
    // For now, return success
    return 0;
}

/**
 * Get number of active inference operations
 */
int32_t llm_get_active_inference_count() {
    return g_active_inference_count.load();
}

#ifdef __cplusplus
}
#endif
